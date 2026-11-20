-- L6 workload family A: continuous live FollowOwner movement.
--
-- Drives the composed production chain
--   Scheduler/SimulationLOD -> BehaviorCompanion FollowOwner -> owner motion
--   -> formation -> move intent (Common.MoveRecord) -> PathService
--   -> EnginePathPlanner -> narrow deterministic native route adapter
-- while the simulated owner moves on every simulation step.
--
-- Only the native route executor is faked: the adapter advances a live shell
-- toward the route goal that production published on its navigation lane
-- (client-delegated MP route in this server-authority simulator).

local Probe = require "tests/support/lightweight_runtime_workloads/probe"

local Follow = {}

local WALK_SPEED = 2.5   -- tiles/s, owner walk
local RUN_SPEED = 4.5    -- tiles/s, owner run
local FOLLOWER_WALK = 2.9
local FOLLOWER_RUN = 5.2

-- Trajectory segments: { ms, fx, fy, moving, running }
local TRAJECTORIES = {
    FOLLOW_WALK_OPEN = {
        { 10000, 1, 0, true, false },
        { 5000, 0, 1, true, false },
        { 7000, 1, 0, true, true },
        { 3000, 1, 0, false, false },
    },
    FOLLOW_WALK_TURN_STOP = {
        { 6000, 1, 0, true, false },
        { 4000, 0, 1, true, false },
        { 4000, 0, 1, false, false },
        { 6000, 0, 1, true, false },
        { 1000, 1, 0, false, false },
        { 3000, 1, 0, true, false },
        { 3000, 1, 0, false, false },
    },
    FOLLOW_WALK_OBSTACLE = {
        { 12000, 1, 0, true, false },
        { 6000, 0, 1, true, false },
        { 4000, 0, 1, false, false },
    },
    FOLLOW_WALK_STALL = {
        { 12000, 1, 0, true, false },
        { 6000, 0, 1, true, false },
        { 4000, 0, 1, false, false },
    },
}
Follow.Scenarios = {
    "FOLLOW_WALK_OPEN", "FOLLOW_WALK_TURN_STOP", "FOLLOW_WALK_OBSTACLE", "FOLLOW_WALK_STALL",
}

local function trajectoryLength(segments)
    local total = 0
    for i = 1, #segments do total = total + segments[i][1] end
    return total
end

function Follow.SimulatedMs(scenario, warmupMs)
    return (warmupMs or 8000) + trajectoryLength(TRAJECTORIES[scenario]) + 500
end

local function segmentAt(segments, t)
    local acc = 0
    for i = 1, #segments do
        acc = acc + segments[i][1]
        if t < acc then return segments[i], i end
    end
    return nil, #segments + 1
end

-- options: scenario, followers, warmupMs, extraSetup(ctx, state), extraFinish
function Follow.New(options)
    local scenario = options.scenario or "FOLLOW_WALK_OPEN"
    local followerCount = options.followers or 6
    local warmupMs = options.warmupMs or 8000
    local segments = assert(TRAJECTORIES[scenario], "unknown follow scenario " .. tostring(scenario))
    local probe = Probe.New()
    local state = {
        probe = probe,
        records = {},
        shells = {},
        startedAt = nil,
        lastSegmentIndex = nil,
        ownerTransitions = 0,
        tickSamples = {},
        passageDelayUntil = {},
        passageCrossed = {},
        stalledId = nil,
        maxActiveRoutes = 0,
        nativeRouteSteps = 0,
        followerSpeedSamples = 0,
        ownerTravel = 0,
        maxLagDistance = 0,
        lagSamples = {},
        warmupLive = 0,
    }
    local wl = { ownsPlayerMotion = true, suppressLegacyMutations = true, state = state }

    local function navigationOf(record)
        return record and record.runtime and record.runtime.localNavigation or nil
    end

    local function nativeAdapterStep(ctx, stepMs)
        local owner = ctx.players[1]
        local ownerRunning = owner:isRunning()
        local active = 0
        local obstacleX = state.obstacleX
        for i, record in ipairs(state.records) do
            local body = PNC.Registry.GetLiveZombie(record.id)
            local nav = navigationOf(record)
            if body and nav and nav.nativeActive and nav.requestX then
                active = active + 1
                local stalled = record.id == state.stalledId
                local now = ctx.now()
                local bx, by = body:getX(), body:getY()
                if obstacleX and not state.passageCrossed[record.id]
                    and bx < obstacleX and (nav.requestX or bx) > obstacleX
                    and bx + 0.6 >= obstacleX
                then
                    -- Deterministic native passage delay (door/fence-class
                    -- crossing). The native executor makes no progress while
                    -- crossing; production observes it as a slow route.
                    state.passageDelayUntil[record.id] = state.passageDelayUntil[record.id] or (now + 1500)
                    if now >= state.passageDelayUntil[record.id] then
                        state.passageCrossed[record.id] = true
                        probe:Add("Adapter.PassageCrossings")
                    else
                        stalled = true
                        probe:Add("Adapter.PassageDelaySteps")
                    end
                end
                if not stalled then
                    local dx = nav.requestX - bx
                    local dy = (nav.requestY or by) - by
                    local dist = math.sqrt(dx * dx + dy * dy)
                    local speed = (ownerRunning or dist > 6) and FOLLOWER_RUN or FOLLOWER_WALK
                    local stepDist = speed * stepMs / 1000
                    if dist > 0.05 then
                        local f = math.min(1, stepDist / dist)
                        body:setX(bx + dx * f)
                        body:setY(by + dy * f)
                        probe:Add("Adapter.NativeRouteSteps")
                    end
                end
            end
        end
        if active > state.maxActiveRoutes then state.maxActiveRoutes = active end
        probe:Add("Adapter.ActiveRouteSamples", active)
    end

    function wl.Setup(ctx)
        local owner = ctx.players[1]
        state.ctx = ctx
        local originalAdd = addZombiesInOutfit
        addZombiesInOutfit = function(...)
            local list = originalAdd(...)
            local shell = list and list:get(0)
            if shell then
                -- Narrow native capability: the MP authority path requires
                -- pathToLocationF; execution is modelled by the adapter.
                shell.pathToLocationF = function() probe:Add("Adapter.PathToLocationF") end
                state.shells[#state.shells + 1] = shell
            end
            return list
        end
        for i = 1, followerCount do
            local column = (i - 1) % 4
            local row = math.floor((i - 1) / 4)
            local record = assert(PNC.API.Spawn({
                id = "l6_follower_" .. tostring(i),
                displayName = "L6 Follower " .. tostring(i),
                x = owner:getX() - 1.5 - row,
                y = owner:getY() - 1.5 + column,
                z = 0,
            }))
            local ok, reason = PNC.Recruitment.Assign(owner, record)
            assert(ok, reason)
            state.records[i] = record
        end
        if scenario == "FOLLOW_WALK_STALL" then
            state.stalledId = state.records[math.min(#state.records, 2)].id
        end
        if scenario == "FOLLOW_WALK_OBSTACLE" then
            state.obstacleX = owner:getX() + 12
        end

        probe:AttachDiagnostics(PNC.PerformanceScalingDiagnostics)
        local C = PNC.BehaviorCompanion
        local CI = C.Internal
        probe:Wrap(CI, "TickFollowOwner", "Follow.Decisions")
        probe:Wrap(CI, "ResolveSampledFollowSlot", "Follow.SampledSlotQueries")
        probe:Wrap(CI, "ResolveFollowSlot", "Follow.FormationResolves")
        probe:Wrap(CI, "ResolveFollowHeading", "Follow.FormationHeadingSamples")
        probe:Wrap(CI, "ShouldIssueFollowMove", "Follow.MoveIntentChecks", function(issue)
            return issue and "issued" or "suppressed"
        end)
        probe:Wrap(CI, "HoldAndFaceOwner", "Follow.Holds")
        probe:Wrap(PNC.PathService, "MoveToward", "PathService.MoveToward")
        probe:Wrap(PNC.PathService, "Reset", "PathService.Reset")
        probe:Wrap(PNC.PathService, "Pump", "PathService.Pump")
        local PI = PNC.EnginePathPlanner and PNC.EnginePathPlanner.Internal
        probe:Wrap(PI, "BeginRequest", "Planner.BeginRequest", function(ok)
            return ok and "accepted" or "rejected"
        end)
        probe:Wrap(PI, "ClearEngineRequest", "Planner.ClearEngineRequest")
        probe:Wrap(PNC.WorldCensus, "Refresh", "Census.Refresh")
        probe:WrapByArg(PNC.Registry, "MarkDirty", "Registry.MarkDirty", function(_, reason) return reason end)
        if PNC.PersistenceCoordinator then
            probe:WrapByArg(PNC.PersistenceCoordinator, "Commit", "Persistence.Commit", function(reason) return reason end)
            probe:Wrap(PNC.PersistenceCoordinator, "Pump", "Persistence.Pump")
        end
        if PNC.Network then
            probe:Wrap(PNC.Network, "BroadcastRecord", "Network.BroadcastRecord")
        end
    end

    function wl.BeforeTick(ctx, tick, elapsedMs)
        local owner = ctx.players[1]
        local stepMs = ctx.cfg.stepMs
        if not state.startedAt then
            owner._setMotion(false, false, 1, 0)
            local live = 0
            for _, record in ipairs(state.records) do
                if record.presenceState == PNC.Const.PRESENCE_LIVE then live = live + 1 end
            end
            state.warmupLive = live
            if elapsedMs >= warmupMs then
                state.startedAt = elapsedMs
                state.liveAtStart = live
                probe:Reset()
                probe.enabled = true
                state.censusGen0 = tonumber(PNC.WorldCensus and PNC.WorldCensus.Generation) or 0
            else
                nativeAdapterStep(ctx, stepMs)
                return
            end
        end
        local t = elapsedMs - state.startedAt
        local segment, index = segmentAt(segments, t)
        if index ~= state.lastSegmentIndex then
            if state.lastSegmentIndex ~= nil then state.ownerTransitions = state.ownerTransitions + 1 end
            state.lastSegmentIndex = index
        end
        if segment and segment[4] then
            local speed = segment[5] and RUN_SPEED or WALK_SPEED
            local d = speed * stepMs / 1000
            owner._setMotion(true, segment[5], segment[2], segment[3])
            owner._setX(owner:getX() + segment[2] * d)
            owner._setY(owner:getY() + segment[3] * d)
            state.ownerTravel = state.ownerTravel + d
        else
            owner._setMotion(false, false, segment and segment[2] or 1, segment and segment[3] or 0)
        end
        nativeAdapterStep(ctx, stepMs)
    end

    function wl.AfterTick(ctx, tick, elapsedMs, tickMs)
        if not probe.enabled then return end
        state.spikes = state.spikes or {}
        local spikes = state.spikes
        if #spikes < 5 or tickMs > spikes[#spikes].ms then
            local frame = {}
            for k, v in pairs(probe.frame) do frame[k] = v end
            spikes[#spikes + 1] = { ms = tickMs, at = elapsedMs, frame = frame }
            table.sort(spikes, function(a, b) return a.ms > b.ms end)
            if #spikes > 5 then spikes[6] = nil end
        end
        probe:EndFrame()
        state.tickSamples[#state.tickSamples + 1] = tickMs
        local owner = ctx.players[1]
        local maxLag = 0
        for _, record in ipairs(state.records) do
            if record.id ~= state.stalledId then
                local dx, dy = record.x - owner:getX(), record.y - owner:getY()
                local d = math.sqrt(dx * dx + dy * dy)
                if d > maxLag then maxLag = d end
            end
        end
        if maxLag > state.maxLagDistance then state.maxLagDistance = maxLag end
        state.lagSamples[#state.lagSamples + 1] = maxLag
    end

    function wl.Finish(ctx)
        probe.enabled = false
        local owner = ctx.players[1]
        local live, follow = 0, 0
        local finalLag = {}
        for _, record in ipairs(state.records) do
            if record.presenceState == PNC.Const.PRESENCE_LIVE then live = live + 1 end
            if record.orderSpec and record.orderSpec.kind == "follow" then follow = follow + 1 end
            local dx, dy = record.x - owner:getX(), record.y - owner:getY()
            finalLag[#finalLag + 1] = math.sqrt(dx * dx + dy * dy)
        end
        local stalledRecord = state.stalledId and PNC.Registry.Get(state.stalledId) or nil
        local stalledNav = stalledRecord and navigationOf(stalledRecord) or nil
        local p = probe
        local report = {
            Scenario = scenario,
            Followers = followerCount,
            LiveAtStart = state.liveAtStart or state.warmupLive,
            FollowOrdersAtEnd = follow,
            OwnerTransitions = state.ownerTransitions,
            OwnerTravel = state.ownerTravel,
            FollowDecisions = p:Get("Follow.Decisions"),
            SampledSlotQueries = p:Get("Follow.SampledSlotQueries"),
            FormationResolves = p:Get("Follow.FormationResolves"),
            FormationBuilds = p:Get("Follow.FormationHeadingSamples"),
            FormationCacheHits = math.max(0, p:Get("Follow.FormationResolves") - p:Get("Follow.FormationHeadingSamples")),
            SampledTargetChanges = p:Get("Follow.FormationResolves"),
            MoveIntentChecks = p:Get("Follow.MoveIntentChecks"),
            MoveIntentsIssued = p:Get("Follow.MoveIntentChecks.issued"),
            MoveIntentSuppressions = p:Get("Follow.MoveIntentChecks.suppressed"),
            Holds = p:Get("Follow.Holds"),
            PathServiceRequests = p:Get("PathService.MoveToward"),
            PathServiceResets = p:Get("PathService.Reset"),
            PathPumps = p:Get("PathService.Pump"),
            EnginePathRequests = p:Get("D:Pathing.EnginePathRequests"),
            PlannerBeginAccepted = p:Get("Planner.BeginRequest.accepted"),
            PlannerBeginRejected = p:Get("Planner.BeginRequest.rejected"),
            PlannerRouteClears = p:Get("Planner.ClearEngineRequest"),
            PathRequests = p:Get("D:Pathing.PathRequests"),
            Replans = p:Get("D:Pathing.Replans"),
            Retries = p:Get("D:Pathing.Retries"),
            Timeouts = p:Get("D:Pathing.Timeouts"),
            StallBackoffs = p:Get("D:Pathing.StallBackoffs"),
            BlockedRoutes = p:Get("D:Pathing.BlockedRoutes"),
            FailedRoutes = p:Get("D:Pathing.FailedRoutes"),
            CompletedRoutes = p:Get("D:Pathing.CompletedRoutes"),
            NativeFallbacks = p:Get("D:Pathing.NativeFallbacks"),
            TraversalEscapes = p:Get("D:Pathing.UnsafeNativeTraversalEscapes"),
            PassageCrossings = p:Get("Adapter.PassageCrossings"),
            MaxActiveRoutes = state.maxActiveRoutes,
            CensusRefreshes = (tonumber(PNC.WorldCensus and PNC.WorldCensus.Generation) or 0) - (state.censusGen0 or 0),
            CensusRefreshCalls = p:Get("Census.Refresh"),
            DuplicatePumpSkips = p:Get("D:Pathing.DuplicatePumpSameFrame"),
            SpatialCellsExamined = p:Get("D:Spatial.ZombieCellsExamined"),
            NetworkBroadcasts = p:Get("Network.BroadcastRecord"),
            MaxFrameEnginePathRequests = p:MaxFrame("D:Pathing.EnginePathRequests"),
            MaxFramePathRequests = p:MaxFrame("D:Pathing.PathRequests"),
            MaxFrameReplans = p:MaxFrame("D:Pathing.Replans"),
            MaxFrameMoveIntents = p:MaxFrame("Follow.MoveIntentChecks.issued"),
            MaxFrameFollowDecisions = p:MaxFrame("Follow.Decisions"),
            MaxFrameFormationBuilds = p:MaxFrame("Follow.FormationHeadingSamples"),
            MaxLagDistance = state.maxLagDistance,
            LagP95 = Probe.Percentiles(state.lagSamples).p95,
            FinalMaxLag = math.max(0, table.unpack(finalLag)),
            StalledId = state.stalledId,
            StalledLastPlanReason = stalledNav and stalledNav.lastPlanReason or nil,
            Tick = Probe.Percentiles(state.tickSamples),
            MissingSeams = probe.missing,
            Spikes = state.spikes,
            Counters = p.totals,
        }
        return report
    end

    return wl
end

function Follow.Format(r)
    return string.format(
        "%s n=%d live0=%d dec=%d slotQ=%d formRes=%d formBuild=%d intents=%d supp=%d holds=%d psReq=%d psReset=%d engReq=%d accept=%d reject=%d clears=%d pathReq=%d replan=%d retry=%d tmo=%d stall=%d blocked=%d failed=%d done=%d maxAct=%d census=%d net=%d maxFrEng=%d maxFrIntent=%d maxFrForm=%d lagP95=%.1f lagMax=%.1f tickAvg=%.3f p95=%.3f max=%.3f",
        r.Scenario, r.Followers, r.LiveAtStart, r.FollowDecisions, r.SampledSlotQueries,
        r.FormationResolves, r.FormationBuilds, r.MoveIntentsIssued, r.MoveIntentSuppressions,
        r.Holds, r.PathServiceRequests, r.PathServiceResets, r.EnginePathRequests,
        r.PlannerBeginAccepted, r.PlannerBeginRejected, r.PlannerRouteClears,
        r.PathRequests, r.Replans, r.Retries, r.Timeouts, r.StallBackoffs, r.BlockedRoutes,
        r.FailedRoutes, r.CompletedRoutes, r.MaxActiveRoutes, r.CensusRefreshes,
        r.NetworkBroadcasts, r.MaxFrameEnginePathRequests, r.MaxFrameMoveIntents,
        r.MaxFrameFormationBuilds, r.LagP95, r.MaxLagDistance,
        r.Tick.avg, r.Tick.p95, r.Tick.max)
end

return Follow
