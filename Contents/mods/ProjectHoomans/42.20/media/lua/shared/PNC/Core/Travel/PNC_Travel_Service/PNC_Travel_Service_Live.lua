local Service = PNC.Travel.Service
local Internal = Service.Internal
local Projection = PNC.Travel.Projection
local Const = PNC.Const or {}
local Core = PNC.Core

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

function Service.OnMaterialized(record)
    local journey = record and record.travel or nil
    if not journey then return end
    Service.Advance(record, Internal.WorldHour())
    journey.controller = "live"
    journey.lastAdvancedWorldHour = Internal.WorldHour()
    Service.Emit("materialized", record, journey, "presence_live")
end

function Service.OnAbstracted(record, body)
    local journey = record and record.travel or nil
    if not journey then return end
    if body then
        Service.SyncLivePosition(record, body, Internal.WorldHour())
    end
    journey.controller = "abstract"
    journey.lastAdvancedWorldHour = Internal.WorldHour()
    Service.Emit("abstracted", record, journey, "presence_abstract")
end
