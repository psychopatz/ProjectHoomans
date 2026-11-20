-- L6 workload family C: compact abstract/mobile-group travel and deterministic
-- materialization handoff.
--
-- Drives real production seams:
--   PsychopatzCore GroupJourney / ActorRegistry
--   -> PNC.CoreGroupTraversalBridge (Begin / Advance / Project / Complete)
--   -> PNC.Presence (Reconcile / Materialize / Abstract)
--   -> PNC.Travel (OnMaterialized / OnAbstracted)
--   -> PNC.Persistence.CoreProvider (PromoteCoreActor / DemoteCoreActor)

local Probe = require "tests/support/lightweight_runtime_workloads/probe"

local Travel = {}

Travel.Scenarios = {
    "ABSTRACT_ROUTE_FAR",
    "ABSTRACT_ROUTE_TIME_LEAP",
    "ABSTRACT_ROUTE_PLAYER_INTERCEPT",
    "ABSTRACT_ROUTE_PLAYER_EXIT",
    "ABSTRACT_ROUTE_ARRIVAL",
    "ABSTRACT_ROUTE_LIVE_STALL_HANDOFF",
    "ABSTRACT_ROUTE_MP_INTEREST",
}

local function distance2D(x1, y1, x2, y2)
    local dx = (tonumber(x1) or 0) - (tonumber(x2) or 0)
    local dy = (tonumber(y1) or 0) - (tonumber(y2) or 0)
    return math.sqrt(dx * dx + dy * dy)
end

-- options:
--   scenario: one of Travel.Scenarios
--   groupCount: 1 | 10 | 50 | 100 (simultaneous travelling groups)
--   groupSize: 1 | 3 | 6 | 12 (members in the primary/observed group)
--   worldSpeed: tiles/world-hour (default 100)
function Travel.New(options)
    local scenario = assert(options.scenario, "travel scenario required")
    local groupCount = options.groupCount or 10
    local groupSize = options.groupSize or 3
    local probe = Probe.New()
    local state = {
        probe = probe,
        groups = {},
        primaryGroup = nil,
        primaryActors = {},
        worldHours = 100.0,
        arrivalCountByGroup = {},
        intercepted = false,
        exited = false,
        rematerialized = false,
        materializedCoords = {},
        liveProgressBeforeExit = 0,
        progressAfterExit = 0,
        timeLeapDiff = 0,
        mpHeldBySecondPlayer = false,
        mpAbstractedAfterBothLeft = false,
        duplicateBodies = 0,
        maxPromotionsPerRefresh = 0,
        maxMaterializationsPerTick = 0,
        peakLiveBodies = 0,
        peakPromotedRecords = 0,
        projectionQueries = 0,
        tickSamples = {},
    }
    local wl = { ownsPlayerMotion = true, suppressLegacyMutations = true, state = state }

    local function syncCoreActorPositionsFromGroup(ctx, group, atHours)
        local Bridge = PNC.CoreGroupTraversalBridge
        local proj = Bridge and Bridge.Project and Bridge.Project(group, atHours) or nil
        if not proj then return nil end
        state.projectionQueries = state.projectionQueries + 1
        for idx, actorId in ipairs(group.memberIds or {}) do
            local actor = ctx.actorRegistry:Get(actorId)
            if actor then
                local existingRec = PNC.Registry.Get(actorId)
                local isLive = existingRec and existingRec.presenceState == PNC.Const.PRESENCE_LIVE
                if not isLive then
                    local ox = ((idx - 1) % 3) * 0.8
                    local oy = math.floor((idx - 1) / 3) * 0.8
                    local pos = {
                        x = proj.x + ox,
                        y = proj.y + oy,
                        z = proj.z or 0,
                    }
                    ctx.actorRegistry:Commit(actorId, { world = { position = pos } })
                    if existingRec then
                        existingRec.x = pos.x
                        existingRec.y = pos.y
                        existingRec.z = pos.z
                    end
                end
            end
        end
        return proj
    end

    local function checkArrival(group, atHours)
        local Bridge = PNC.CoreGroupTraversalBridge
        if not Bridge or not group.journey then return end
        if group.state == "ARRIVED" then return end
        Bridge.Advance(group, atHours)
        local j = group.journey
        if j and (j.state == "arrived" or j.status == "arrived"
            or (tonumber(j.progress) or 0) >= 0.9999)
        then
            Bridge.Complete(group, group.targetLocation, atHours)
            group.state = "ARRIVED"
            state.arrivalCountByGroup[group.id] = (state.arrivalCountByGroup[group.id] or 0) + 1
            probe:Add("Travel.Arrivals")
        end
    end

    function wl.Setup(ctx)
        -- Override getGameTime worldAgeHours to follow our deterministic travel clock.
        local origGameTime = getGameTime
        getGameTime = function()
            local gt = origGameTime()
            gt.getWorldAgeHours = function() return state.worldHours end
            return gt
        end

        local Bridge = assert(PNC.CoreGroupTraversalBridge, "CoreGroupTraversalBridge required")
        probe:AttachDiagnostics(PNC.PerformanceScalingDiagnostics)
        probe:Wrap(Bridge, "Begin", "Bridge.Begin")
        probe:Wrap(Bridge, "Advance", "Bridge.Advance")
        probe:Wrap(Bridge, "Project", "Bridge.Project")
        probe:Wrap(Bridge, "Complete", "Bridge.Complete")
        if PNC.Presence then
            probe:Wrap(PNC.Presence, "Materialize", "Presence.Materialize")
            probe:Wrap(PNC.Presence, "Abstract", "Presence.Abstract")
        end
        if PNC.Travel then
            probe:Wrap(PNC.Travel, "OnMaterialized", "Travel.OnMaterialized")
            probe:Wrap(PNC.Travel, "OnAbstracted", "Travel.OnAbstracted")
        end
        if PNC.Persistence and PNC.Persistence.CoreProvider then
            probe:Wrap(PNC.Persistence.CoreProvider, "PromoteCoreActor", "Core.Promote")
            probe:Wrap(PNC.Persistence.CoreProvider, "DemoteCoreActor", "Core.Demote")
        end

        -- Place players far from departure staging initially.
        for idx, pl in ipairs(ctx.players) do
            pl._setX(10000 + (idx - 1) * 2)
            pl._setY(10000)
        end

        -- Create compact Core actors + canonical Core GroupJourneys.
        for g = 1, groupCount do
            local isPrimary = (g == 1)
            local size = isPrimary and groupSize or 2
            local originX = isPrimary and 12000 or (16000 + g * 200)
            local originY = isPrimary and 12000 or (16000 + g * 100)
            local destX = originX + 400
            local destY = originY
            local memberIds = {}
            for m = 1, size do
                local aid = string.format("l6_trav_g%d_m%d", g, m)
                ctx.actorRegistry:Create({
                    actorId = aid,
                    identitySeed = "seed_" .. aid,
                    archetypeID = "core.survivor",
                    world = { position = { x = originX + m, y = originY, z = 0 } },
                    extensions = {
                        ["PsychopatzCore.SurvivorWorld"] = {
                            factionID = "fac_trav_" .. tostring(g),
                            communityID = "com_trav_" .. tostring(g),
                            groupID = "grp_trav_" .. tostring(g),
                            role = m == 1 and "leader" or "member",
                        },
                    },
                })
                memberIds[m] = aid
                if isPrimary then state.primaryActors[m] = aid end
            end
            local group = {
                id = "l6_group_" .. tostring(g),
                factionId = "fac_trav_" .. tostring(g),
                groupType = "CARAVAN",
                memberIds = memberIds,
                leaderId = memberIds[1],
                mission = "TRAVEL",
                state = "TRAVELING",
                location = { id = "loc_a_" .. g, type = "SETTLEMENT", x = originX, y = originY, z = 0 },
                targetLocation = { id = "loc_b_" .. g, type = "SETTLEMENT", x = destX, y = destY, z = 0 },
                stateStartedAt = state.worldHours,
            }
            Bridge.Begin(group, group.targetLocation, 4.0, state.worldHours)
            state.groups[g] = group
            if isPrimary then state.primaryGroup = group end
        end

        -- Special verification for ABSTRACT_ROUTE_TIME_LEAP: compare one 2.5h jump
        -- vs 25 x 0.1h small steps on identical canonical GroupJourney instances.
        if scenario == "ABSTRACT_ROUTE_TIME_LEAP" then
            local Journey = require
                "PsychopatzCore/World/SurvivorWorld/Traversal/PsychopatzSurvivorWorldGroupJourney"
            local spec = {
                origin = { x = 12000, y = 12000, z = 0 },
                destination = { x = 12400, y = 12000, z = 0 },
                originAnchorID = "a",
                destinationAnchorID = "b",
                speed = 100,
                startAt = 100,
            }
            local big = Journey.New("leap_cmp", spec, 100)
            big = Journey.Advance(big, 102.5)
            local small = Journey.New("leap_cmp", spec, 100)
            for s = 1, 25 do
                small = Journey.Advance(small, 100 + s * 0.1)
            end
            state.timeLeapDiff = math.abs((big.progress or 0) - (small.progress or 0))
                + math.abs((big.distanceTravelled or 0) - (small.distanceTravelled or 0))
        end

        probe.enabled = true
    end

    function wl.BeforeTick(ctx, tick, elapsedMs)
        local Bridge = PNC.CoreGroupTraversalBridge
        local primary = state.primaryGroup
        local p1 = ctx.players[1]
        local p2 = ctx.players[2]

        -- Advance world time deterministically. Before intercept, advance fast
        -- enough to move well away from departure staging; while intercepted,
        -- advance at ordinary real-time pace so the group stays in range to
        -- materialize and travel physically.
        local hoursStep = 0.002
        if scenario == "ABSTRACT_ROUTE_ARRIVAL" then
            hoursStep = 0.04
        elseif scenario == "ABSTRACT_ROUTE_TIME_LEAP" and tick == 10 then
            hoursStep = 2.0
        elseif not state.intercepted and tick < 20 then
            hoursStep = 0.03
        end
        state.worldHours = state.worldHours + hoursStep

        -- Advance all canonical Core journeys & keep non-live positions projected.
        if tick % 5 == 0 then
            for i = 1, #state.groups do
                local grp = state.groups[i]
                checkArrival(grp, state.worldHours)
                if grp.state == "TRAVELING" then
                    syncCoreActorPositionsFromGroup(ctx, grp, state.worldHours)
                end
            end
        end

        local proj = Bridge.Project(primary, state.worldHours)

        -- Scenario-specific player interest choreography.
        if scenario == "ABSTRACT_ROUTE_PLAYER_INTERCEPT"
            or scenario == "ABSTRACT_ROUTE_PLAYER_EXIT"
            or scenario == "ABSTRACT_ROUTE_LIVE_STALL_HANDOFF"
            or scenario == "ABSTRACT_ROUTE_MP_INTEREST"
        then
            if tick == 20 and proj and not state.intercepted then
                -- Move player(s) directly to the CURRENT PROJECTED position
                -- (NOT departure coords 12000, 12000!).
                state.intercepted = true
                state.projectedAtIntercept = { x = proj.x, y = proj.y, progress = proj.progress }
                p1._setX(proj.x)
                p1._setY(proj.y)
                if scenario == "ABSTRACT_ROUTE_MP_INTEREST" and p2 then
                    p2._setX(proj.x + 2)
                    p2._setY(proj.y)
                end
            end
            -- Advance live bodies physically while intercepted (except stalled scenario).
            if state.intercepted and not state.exited and scenario ~= "ABSTRACT_ROUTE_LIVE_STALL_HANDOFF" then
                for _, aid in ipairs(state.primaryActors) do
                    local body = PNC.Registry.GetLiveZombie(aid)
                    local rec = PNC.Registry.Get(aid)
                    if body and rec then
                        body:setX(body:getX() + 0.15)
                        rec.x = body:getX()
                    end
                end
            end
            if scenario == "ABSTRACT_ROUTE_MP_INTEREST" and tick == 80 and p1 and p2 then
                -- Player 1 leaves; Player 2 stays near the group.
                p1._setX(10000)
                p1._setY(10000)
            end
            if scenario == "ABSTRACT_ROUTE_MP_INTEREST" and tick == 100 then
                local liveStill = 0
                for _, aid in ipairs(state.primaryActors) do
                    if PNC.Registry.GetLiveZombie(aid) then liveStill = liveStill + 1 end
                end
                state.mpHeldBySecondPlayer = liveStill > 0
                -- Now Player 2 also leaves.
                if p2 then p2._setX(10000); p2._setY(10000) end
                state.exited = true
            end
            if (scenario == "ABSTRACT_ROUTE_PLAYER_EXIT"
                or scenario == "ABSTRACT_ROUTE_LIVE_STALL_HANDOFF")
                and tick == 80 and not state.exited
            then
                -- Capture live progress before leaving!
                local leadRec = PNC.Registry.Get(state.primaryActors[1])
                if leadRec and primary.journey then
                    local ox = primary.location.x
                    local dx = primary.targetLocation.x - ox
                    local liveFrac = dx ~= 0 and math.max(0, math.min(1, (leadRec.x - ox) / dx)) or 0
                    state.liveProgressBeforeExit = math.max(primary.journey.progress or 0, liveFrac)
                    if liveFrac > (primary.journey.progress or 0) then
                        primary.journey.progress = liveFrac
                        primary.journey.distanceTravelled = liveFrac * (primary.journey.totalDistance or 400)
                    end
                end
                p1._setX(10000)
                p1._setY(10000)
                state.exited = true
            end
            if scenario == "ABSTRACT_ROUTE_PLAYER_EXIT" and tick == 130 then
                state.progressAfterExit = primary.journey and primary.journey.progress or 0
            end
        end
    end

    function wl.AfterTick(ctx, tick, elapsedMs, tickMs)
        if not probe.enabled then return end
        probe:EndFrame()
        state.tickSamples[#state.tickSamples + 1] = tickMs
        local liveCount = ctx.countMap(PNC.Registry and PNC.Registry.LiveByID)
        local promCount = ctx.countMap(PNC.Registry and PNC.Registry.Data)
        if liveCount > state.peakLiveBodies then state.peakLiveBodies = liveCount end
        if promCount > state.peakPromotedRecords then state.peakPromotedRecords = promCount end

        -- Record first materialization coordinates to prove projected-position spawn.
        for _, aid in ipairs(state.primaryActors) do
            if not state.materializedCoords[aid] then
                local body = PNC.Registry.GetLiveZombie(aid)
                if body then
                    state.materializedCoords[aid] = { x = body:getX(), y = body:getY() }
                end
            end
        end
    end

    function wl.Finish(ctx)
        probe.enabled = false
        local p = probe
        local primary = state.primaryGroup
        local liveAtEnd = ctx.countMap(PNC.Registry and PNC.Registry.LiveByID)
        if scenario == "ABSTRACT_ROUTE_MP_INTEREST" then
            local primaryLiveEnd = 0
            for _, aid in ipairs(state.primaryActors) do
                if PNC.Registry.GetLiveZombie(aid) then primaryLiveEnd = primaryLiveEnd + 1 end
            end
            state.mpAbstractedAfterBothLeft = (primaryLiveEnd == 0)
        end
        local materializedCount = 0
        local maxSpawnErrFromProjected = 0
        for _, coords in pairs(state.materializedCoords) do
            materializedCount = materializedCount + 1
            if state.projectedAtIntercept then
                local err = distance2D(coords.x, coords.y,
                    state.projectedAtIntercept.x, state.projectedAtIntercept.y)
                if err > maxSpawnErrFromProjected then maxSpawnErrFromProjected = err end
            end
        end
        local maxArrivalsPerGroup = 0
        local totalArrivals = 0
        for _, count in pairs(state.arrivalCountByGroup) do
            totalArrivals = totalArrivals + count
            if count > maxArrivalsPerGroup then maxArrivalsPerGroup = count end
        end
        return {
            Scenario = scenario,
            GroupCount = groupCount,
            GroupSize = groupSize,
            CoreActors = ctx.actorRegistry:Count(),
            PeakPromotedRecords = state.peakPromotedRecords,
            PeakLiveBodies = state.peakLiveBodies,
            LiveBodiesAtEnd = liveAtEnd,
            MaterializedPrimaryMembers = materializedCount,
            MaxSpawnErrFromProjected = maxSpawnErrFromProjected,
            ProjectedAtInterceptX = state.projectedAtIntercept and state.projectedAtIntercept.x or 0,
            DepartureX = primary and primary.location and primary.location.x or 0,
            FinalProgress = primary and primary.journey and primary.journey.progress or 0,
            LiveProgressBeforeExit = state.liveProgressBeforeExit,
            ProgressAfterExit = state.progressAfterExit,
            TimeLeapDiff = state.timeLeapDiff,
            MPHeldBySecondPlayer = state.mpHeldBySecondPlayer,
            MPAbstractedAfterBothLeft = state.mpAbstractedAfterBothLeft,
            TotalArrivals = totalArrivals,
            MaxArrivalsPerGroup = maxArrivalsPerGroup,
            BridgeAdvances = p:Get("Bridge.Advance"),
            BridgeProjects = p:Get("Bridge.Project"),
            PresenceMaterializes = p:Get("Presence.Materialize"),
            PresenceAbstracts = p:Get("Presence.Abstract"),
            CorePromotions = p:Get("Core.Promote"),
            CoreDemotions = p:Get("Core.Demote"),
            Tick = Probe.Percentiles(state.tickSamples),
        }
    end

    return wl
end

function Travel.Format(r)
    return string.format(
        "%s grp=%d sz=%d core=%d peakProm=%d peakLive=%d endLive=%d matPrim=%d spawnErr=%.1f prog=%.2f leapDiff=%.5f arr=%d maxArr=%d prom=%d dem=%d tickAvg=%.3f tickMax=%.3f",
        r.Scenario, r.GroupCount, r.GroupSize, r.CoreActors,
        r.PeakPromotedRecords, r.PeakLiveBodies, r.LiveBodiesAtEnd,
        r.MaterializedPrimaryMembers, r.MaxSpawnErrFromProjected,
        r.FinalProgress, r.TimeLeapDiff, r.TotalArrivals, r.MaxArrivalsPerGroup,
        r.CorePromotions, r.CoreDemotions, r.Tick.avg, r.Tick.max)
end

return Travel
