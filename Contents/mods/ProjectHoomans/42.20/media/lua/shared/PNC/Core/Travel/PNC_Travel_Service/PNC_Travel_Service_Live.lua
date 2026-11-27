local Service = PNC.Travel.Service
local Internal = Service.Internal
local Projection = PNC.Travel.Projection
local Const = PNC.Const or {}
local Core = PNC.Core

-- Live progress bookkeeping is per live stint. It must not leak across a
-- presence flip (a fresh body would inherit a stale stall clock) and it is not
-- persisted, so a reload starts a clean stint as well.
local function clearLiveStallState(journey)
    journey.liveLastX = nil
    journey.liveLastY = nil
    journey.liveLastZ = nil
    journey.liveLastDistance = nil
    journey.liveLastProgressAt = nil
    journey.liveStallCount = 0
    journey.liveLastRecoveryAt = nil
end

-- Hand the journey to the elapsed-time abstract lane. The body is not removed
-- here: the presence pass owns presence transitions and this runs inside the
-- behavior tick.
local function requestHandoff(record, journey, now)
    journey.handoffForced = true
    journey.handoffReason = "live_stalled"
    record.runtime = record.runtime or {}
    record.runtime.forcePresenceCheck = true
    if PNC.SimulationClock and PNC.SimulationClock.Wake then
        PNC.SimulationClock.Wake(record, "presence", now)
    end
    return true
end

-- Escalation ladder for a live journey whose movement lane keeps stalling: ask
-- for the abstract lane first, then end the journey explicitly so it can never
-- stay active without a lane that can advance it.
local function escalateLiveFailure(record, journey, now)
    local cooldown = math.max(
        1000,
        tonumber(Const.TRAVEL_LIVE_ESCALATION_COOLDOWN_MS) or 15000
    )
    local maxEscalations = tonumber(Const.TRAVEL_LIVE_MAX_ESCALATIONS) or 2
    local lastEscalation = tonumber(journey.liveLastEscalationAt)
    if lastEscalation ~= nil and now - lastEscalation < cooldown then
        return false
    end
    journey.liveLastEscalationAt = now
    journey.liveEscalationCount =
        (tonumber(journey.liveEscalationCount) or 0) + 1
    Internal.LogTravelDiag(
        record,
        journey,
        "live_escalation",
        journey.liveEscalationCount > maxEscalations
            and "live_unreachable" or "handoff_requested"
    )
    if journey.liveEscalationCount > maxEscalations then
        Service.FailJourney(record, "live_unreachable", "live_stall")
        return true
    end
    return requestHandoff(record, journey, now)
end

local function liveBodyPosition(record, body)
    return body and body.getX and body:getX() or tonumber(record and record.x) or 0,
        body and body.getY and body:getY() or tonumber(record and record.y) or 0,
        body and body.getZ and body:getZ() or tonumber(record and record.z) or 0
end

local function noteLiveProgress(journey, x, y, z, distance, now)
    local previousX = tonumber(journey.liveLastX)
    local previousY = tonumber(journey.liveLastY)
    local previousZ = tonumber(journey.liveLastZ)
    local previousDistance = tonumber(journey.liveLastDistance)
    local moved
    local routeMoved
    if previousX == nil or previousY == nil or previousZ == nil then
        journey.liveLastX = x
        journey.liveLastY = y
        journey.liveLastZ = z
        journey.liveLastDistance = distance
        journey.liveLastProgressAt = now
        journey.liveStallCount = 0
        return true
    end
    moved = ((x - previousX) * (x - previousX))
        + ((y - previousY) * (y - previousY))
        + ((z - previousZ) * (z - previousZ)) >= 0.0025
    routeMoved = distance > (previousDistance or distance) + 0.001
    journey.liveLastX = x
    journey.liveLastY = y
    journey.liveLastZ = z
    journey.liveLastDistance = distance
    if moved or routeMoved then
        journey.liveLastProgressAt = now
        journey.liveStallCount = 0
        return true
    end
    return false
end

local function recoverLiveStall(record, body, journey, now)
    local recoveryCooldown = math.max(
        1000,
        tonumber(Const.TRAVEL_LIVE_RECOVERY_COOLDOWN_MS) or 5000
    )
    local lastRecovery = tonumber(journey.liveLastRecoveryAt)
    local reason = "travel_live_stall"
    local fallback = false
    local router = PNC.NavigationRouter
    local planner = PNC.EnginePathPlanner
    local pathService = PNC.PathService
    if lastRecovery ~= nil and now - lastRecovery < recoveryCooldown then
        return false
    end

    journey.liveLastRecoveryAt = now
    journey.liveStallCount = (tonumber(journey.liveStallCount) or 0) + 1
    journey.liveLastProgressAt = now

    -- Release the native provider first. The next behavior tick will publish
    -- the same travel target into the bounded scripted fallback lane, keeping
    -- the durable journey and its task lease intact.
    if router and router.ActivateFallback then
        fallback = router.ActivateFallback(
            record,
            reason,
            tonumber(Const.ENGINE_PATH_FALLBACK_COOLDOWN_MS) or 5000
        ) == true
    end
    if not fallback and planner and planner.Invalidate then
        planner.Invalidate(record, reason, body)
    end
    if pathService and pathService.Commands
        and pathService.Commands.Reset
    then
        pathService.Commands.Reset(record, body, reason)
    elseif pathService and pathService.Reset then
        pathService.Reset(body, record)
    elseif record and record.runtime then
        record.runtime.moveIntent = nil
        record.runtime.pathing = nil
        record.runtime.localNavigation = nil
    end

    journey.liveRecoveryCount = (tonumber(journey.liveRecoveryCount) or 0) + 1
    if journey.liveRecoveryCount
        > (tonumber(Const.TRAVEL_LIVE_MAX_RECOVERIES) or 3)
        and escalateLiveFailure(record, journey, now)
    then
        return true
    end
    journey.lastStateReason = fallback
        and "travel_live_stall_fallback"
        or "travel_live_stall_replan"
    journey.revision = (tonumber(journey.revision) or 0) + 1
    if PNC.PerformanceScalingDiagnostics then
        PNC.PerformanceScalingDiagnostics.Increment(
            "Pathing.LiveTravelStalls")
    end
    if Core and Core.LogWarn then
        Core.LogWarn(
            "live_travel_recovery npc=" .. tostring(record and record.id)
                .. " journey=" .. tostring(journey.journeyId)
                .. " recovery=" .. tostring(journey.liveRecoveryCount)
                .. " mode=" .. (fallback and "fallback" or "replan")
        )
    end
    return true
end

local function homeZoneReached(record, journey)
    local action = journey and journey.arrivalAction or nil
    local home = PNC.HomeDutyService
    if not action or tostring(action.type or "") ~= "colony_home"
        or not home or type(home.IsAtHome) ~= "function"
    then
        return false
    end
    return home.IsAtHome(record, action.baseId) == true
end

function Service.CheckLiveProgress(recordOrID, body, now)
    local record = Internal.ResolveRecord(recordOrID)
    local journey = record and record.travel or nil
    local x
    local y
    local z
    local progressed
    local lastProgress
    local timeoutMs
    local recovered
    if not journey or journey.state ~= "en_route" or not body then
        return false, "not_en_route"
    end
    now = tonumber(now) or (Core and Core.Now and Core.Now() or 0)
    x, y, z = liveBodyPosition(record, body)
    progressed = noteLiveProgress(
        journey,
        x,
        y,
        z,
        tonumber(journey.distanceTravelled) or 0,
        now
    )
    if progressed then return false, "progressing" end
    lastProgress = tonumber(journey.liveLastProgressAt) or now
    timeoutMs = math.max(
        1000,
        tonumber(Const.TRAVEL_LIVE_PROGRESS_TIMEOUT_MS) or 12000
    )
    if now - lastProgress < timeoutMs then
        return false, "waiting_for_progress"
    end
    recovered = recoverLiveStall(record, body, journey, now)
    return recovered, recovered and "recovered" or "recovery_cooldown"
end

function Service.TickLive(recordOrID, body, atWorldHour)
    local record = Internal.ResolveRecord(recordOrID)
    local journey = record and record.travel or nil
    if not journey or not body then return nil, "journey_or_body_missing" end
    atWorldHour = tonumber(atWorldHour) or Internal.WorldHour()
    local previousState = journey.state
    local elapsed = math.max(
        0,
        atWorldHour - (tonumber(journey.lastAdvancedWorldHour) or atWorldHour)
    )

    Service.SyncLivePosition(record, body, atWorldHour)
    -- The home anchor is a valid arrival boundary. Direct home routes can
    -- stop at a fence or furniture edge after the NPC has already entered the
    -- authoritative base zone; leaving the journey en_route then makes the
    -- return-home percentage persist forever and keeps the movement owner
    -- alive against an unreachable final tile.
    if journey.state == "en_route" and homeZoneReached(record, journey) then
        -- The base zone is a valid arrival boundary, so anchor the route
        -- distance with it. Otherwise the journey reports less than 100%
        -- forever and keeps a movement lane alive against an unreachable tile.
        journey.distanceTravelled = math.max(
            tonumber(journey.distanceTravelled) or 0,
            tonumber(journey.distanceTotal) or 0
        )
        Service.SetState(record, "arrived", "home_zone_reached")
    end
    -- Live bodies can drift just beyond the final stop radius after their
    -- route projection has already reached the endpoint. Without this guard,
    -- the UI reports 100% forever while the live movement order keeps trying
    -- to reach an endpoint the engine pather has effectively missed.
    if journey.state == "en_route"
        and (tonumber(journey.distanceTotal) or 0) > 0
        and (tonumber(journey.distanceTravelled) or 0)
            >= (tonumber(journey.distanceTotal) or 0) - 0.001
    then
        Service.ReachCurrentWaypoint(record, atWorldHour)
    end
    if journey.state == "waiting" then
        journey.waitRemainingWorldHours = math.max(
            0,
            (tonumber(journey.waitRemainingWorldHours) or 0) - elapsed
        )
        if journey.waitRemainingWorldHours <= 0 then
            journey.state = "en_route"
            journey.revision = (tonumber(journey.revision) or 0) + 1
            journey.lastStateReason = "wait_complete"
        end
    end

    if journey.state == "en_route" then
        local target = Service.GetCurrentTarget(record)
        if not target then
            Service.SetState(record, "arrived", "route_complete")
        else
            local x = body.getX and body:getX() or record.x
            local y = body.getY and body:getY() or record.y
            local z = body.getZ and body:getZ() or record.z
            local dx = (tonumber(target.x) or 0) - (tonumber(x) or 0)
            local dy = (tonumber(target.y) or 0) - (tonumber(y) or 0)
            local dz = (tonumber(target.z) or 0) - (tonumber(z) or 0)
            local radius = math.max(
                0.1,
                tonumber(target.stopDistance) or 1
            )
            if (dx * dx) + (dy * dy) + (dz * dz) <= radius * radius then
                Service.ReachCurrentWaypoint(record, atWorldHour)
            end
        end
    end

    if journey.state == "en_route" then
        Service.CheckLiveProgress(record, body, Core and Core.Now
            and Core.Now() or 0)
    end

    if previousState ~= journey.state
        and previousState == "waiting"
        and journey.state == "en_route"
    then
        Internal.MarkChanged(record, "travel", "travel_wait_complete", false)
        Service.Emit(
            "state_changed",
            record,
            journey,
            previousState .. ":" .. journey.state
        )
    end
    if journey.state == "arrived" then
        Service.EnsureArrivalHandled(record, "live_arrival")
    end
    Projection.UpdateETA(journey, atWorldHour)
    return Service.GetCurrentTarget(record), journey.state
end

function Service.GetCurrentTarget(recordOrID)
    local record = Internal.ResolveRecord(recordOrID)
    local journey = record and record.travel or nil
    if Service.IsFollowOwned and Service.IsFollowOwned(record) then
        return nil
    end
    if not journey or not journey.route then return nil end
    local segment = journey.route.segments
        and journey.route.segments[journey.segmentIndex] or nil
    if not segment then return nil end
    return {
        x = segment.toX,
        y = segment.toY,
        z = segment.toZ,
        stopDistance = journey.arrivalRadius,
        mode = PNC.Travel.Providers.GetLiveMode(
            journey.speedProfile,
            journey.mode
        ),
        tag = segment.tag,
    }
end

local function resolveTravelingGroupForRecord(record)
    if not record or not record.id or record.recruited == true then
        return nil
    end
    local groups = PNC.AbstractGroups
    if not groups or type(groups.FindByMember) ~= "function" then
        return nil
    end
    local group = groups.FindByMember(record.id)
    if type(group) ~= "table" or group.state ~= "TRAVELING" then
        return nil
    end
    if type(group.journey) ~= "table" or group.journey.state ~= "en_route" then
        return nil
    end
    return group
end

local function attachGroupJourneyHandoff(record, body)
    local bridge = PNC.CoreGroupTraversalBridge
    if not bridge or type(bridge.ExtractRemainingWaypoints) ~= "function" then
        return nil
    end
    local group = resolveTravelingGroupForRecord(record)
    if not group then
        return nil
    end
    local bx, by, bz = liveBodyPosition(record, body)
    local waypoints = bridge.ExtractRemainingWaypoints(group, bx, by, bz)
    if type(waypoints) ~= "table" or #waypoints == 0 then
        return nil
    end
    local dest = waypoints[#waypoints]
    local routePoints = {
        { x = bx, y = by, z = bz, tag = "origin" },
    }
    for i = 1, #waypoints do
        routePoints[#routePoints + 1] = waypoints[i]
    end
    local started = Service.Start and Service.Start(record, {
        origin = { x = bx, y = by, z = bz },
        destination = dest,
        route = routePoints,
        routeProvider = "corridor",
        ownerRef = "group_journey_handoff",
        speedProfile = "walk",
    }) or nil
    if type(started) == "table" then
        started.ephemeralGroupHandoff = true
        started.handoffGroupId = group.id
        if type(record.orderSpec) == "table" then
            record.orderSpec.ephemeralDefault = true
        end
        local diag = PNC.PerformanceScalingDiagnostics
        if diag and type(diag.IsPresenceTraversalAuditEnabled) == "function"
            and diag.IsPresenceTraversalAuditEnabled() == true
            and type(diag.LogPresenceTraversal) == "function"
        then
            diag.LogPresenceTraversal("group_journey_handoff_attached", {
                "npc=" .. tostring(record.id),
                "group=" .. tostring(group.id),
                "waypoints=" .. tostring(#waypoints),
                "dest=" .. tostring(math.floor(dest.x or 0)) .. "," .. tostring(math.floor(dest.y or 0)),
            })
        end
    end
    return started
end

local function attachScavengeBuildingGoal(record)
    if not record or not record.id or record.recruited == true then
        return false
    end
    if type(record.orderSpec) == "table" and record.orderSpec.ephemeralDefault ~= true then
        return false
    end
    local groups = PNC.AbstractGroups
    if not groups or type(groups.FindByMember) ~= "function" then
        return false
    end
    local group = groups.FindByMember(record.id)
    if type(group) ~= "table" or group.state == "TRAVELING" then
        return false
    end
    if group.mission ~= "SCAVENGE" and group.groupType ~= "SCAVENGER"
        and group.groupType ~= "LOOTER"
    then
        return false
    end
    local resolver = PNC.CommunitySiteResolver
    if not resolver or type(resolver.FindAvailableNear) ~= "function" then
        return false
    end
    local site = resolver.FindAvailableNear(
        tonumber(record.x) or 0,
        tonumber(record.y) or 0,
        tonumber(record.z) or 0,
        60
    )
    if type(site) ~= "table" or type(site.home) ~= "table" then
        return false
    end
    record.orderSpec = {
        kind = Const.ORDER_CAMP or "camp",
        x = site.home.x,
        y = site.home.y,
        z = site.home.z or 0,
        radius = math.max(8, tonumber(site.home.radius) or 12),
        ambientVisit = true,
        ephemeralDefault = true,
        scavengeMission = true,
    }
    return true
end

function Service.OnMaterialized(record)
    local journey = record and record.travel or nil
    local body
    if Service.IsFollowOwned and Service.IsFollowOwned(record) then
        return
    end
    body = PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record and record.id) or nil
    if not journey then
        journey = attachGroupJourneyHandoff(record, body)
    end
    if not journey then
        attachScavengeBuildingGoal(record)
        return
    end
    clearLiveStallState(journey)
    Service.Advance(record, Internal.WorldHour())
    -- Symmetric with OnAbstracted: the fresh body is the source of truth for
    -- route progress, so a body that spawned away from the linear projection
    -- cannot leave the live lane targeting a segment it never reached.
    if body then
        Service.SyncLivePosition(record, body, Internal.WorldHour())
    end
    journey.controller = "live"
    journey.lastAdvancedWorldHour = Internal.WorldHour()
    Service.Emit("materialized", record, journey, "presence_live")
end

function Service.OnAbstracted(record, body)
    local journey = record and record.travel or nil
    if not journey
        or (Service.IsFollowOwned and Service.IsFollowOwned(record))
    then
        return
    end
    local nowHour = Internal.WorldHour()
    if body then
        Service.SyncLivePosition(record, body, nowHour)
    end
    -- If a player colonist abstracted while actively fleeing an overwhelming
    -- live threat, hand off cleanly to the off-camera SOS refuge policy now
    -- that live zombies have stopped chasing them.
    local wasFleeing = record.runtime and record.runtime.fleeingFromThreat == true
    if record.runtime then
        record.runtime.travelTactics = nil
        record.runtime.fleeingFromThreat = nil
    end
    if wasFleeing and record.recruited == true
        and PNC.AbstractHazardResolver
        and type(PNC.AbstractHazardResolver.ApplyColonistLossPolicy) == "function"
    then
        local bx, by = liveBodyPosition(record, body)
        PNC.AbstractHazardResolver.ApplyColonistLossPolicy(
            record,
            bx,
            by,
            nowHour,
            "live_flee_escape",
            tostring(record.id) .. ":flee_abstract"
        )
        return
    end
    if journey.ephemeralGroupHandoff == true then
        local bridge = PNC.CoreGroupTraversalBridge
        local groups = PNC.AbstractGroups
        local group = journey.handoffGroupId
            and groups and type(groups.Get) == "function"
            and groups.Get(journey.handoffGroupId) or nil
        if group and bridge and type(bridge.SyncMemberLivePosition) == "function" then
            local bx, by, bz = liveBodyPosition(record, body)
            bridge.SyncMemberLivePosition(group, bx, by, bz, nowHour)
        end
        record.travel = nil
        if type(record.orderSpec) == "table"
            and tostring(record.orderSpec.kind or "") == tostring(Const.ORDER_TRAVEL or "travel")
            and record.orderSpec.ephemeralDefault == true
        then
            record.orderSpec = nil
        end
        Service.Emit("abstracted", record, journey, "group_journey_handoff_released")
        return
    end
    clearLiveStallState(journey)
    journey.controller = "abstract"
    journey.handoffForced = nil
    journey.handoffReason = nil
    journey.lastAdvancedWorldHour = nowHour
    Service.Emit("abstracted", record, journey, "presence_abstract")
end
