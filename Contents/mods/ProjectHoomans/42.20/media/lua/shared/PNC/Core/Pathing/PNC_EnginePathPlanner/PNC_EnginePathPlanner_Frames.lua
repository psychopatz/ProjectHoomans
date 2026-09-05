-- Zombie-update and dedicated-server route dispatch.

local Planner = PNC.EnginePathPlanner
local Internal = Planner.Internal
local Core = PNC.Core

local function recordSinglePlayerNativeFrame(
    record,
    body,
    lane,
    navigation,
    now,
    state,
    fromX,
    fromY,
    fromZ
)
    local pathService = PNC.PathService
    local pathInternal = pathService and pathService.Internal or nil
    local terminalResult = state == "engine_path_succeeded"
        or state == "engine_path_failed"
        or state == "engine_path_timeout"
    if not navigation
        or (navigation.nativeActive ~= true and not terminalResult)
        or lane.traversalAction
        or lane.blockedStepToX ~= nil
        or not pathInternal
        or not pathInternal.recordNativeMove
    then
        return nil
    end
    -- PathService.Pump is intentionally bypassed for an active single-player
    -- native lane. Reuse its progress/timeout/passage accounting after the
    -- one authoritative Behavior2 update, without pumping Behavior2 again.
    return pathInternal.recordNativeMove(
        record,
        body,
        lane,
        navigation,
        Planner,
        now,
        state,
        fromX,
        fromY,
        fromZ
    )
end

function Planner.PumpFrame(record, body)
    if Core and Core.IsAuthority and not Core.IsAuthority() then
        return false, "client_replica"
    end
    local lane = record and record.runtime and record.runtime.pathing or nil
    if not lane or lane.phase ~= "active" then
        return false, "move_lane_inactive"
    end
    local navigation = record and record.runtime
        and record.runtime.localNavigation or nil
    local fromX
    local fromY
    local fromZ
    local handled
    local state
    local recovered
    local recoveryState
    recovered, recoveryState = Internal.RecoverStaleNativeBump(
        record,
        body,
        navigation,
        Core and Core.Now and Core.Now() or 0
    )
    if recovered then
        Internal.InvalidateRecoveredNativeBump(
            record,
            body,
            navigation,
            recoveryState
        )
        local pathService = PNC.PathService
        local pathInternal = pathService and pathService.Internal or nil
        if pathInternal and pathInternal.logMoveWarning then
            pathInternal.logMoveWarning(
                record,
                body,
                record and record.runtime and record.runtime.pathing or nil,
                "native_bump_recovery",
                recoveryState,
                "action=bumped"
            )
        end
        return true, recoveryState
    end
    if (lane.traversalAction or lane.blockedStepToX ~= nil)
        and PNC.PathService
        and PNC.PathService.AdvanceScriptedPassage
    then
        return PNC.PathService.AdvanceScriptedPassage(
            record,
            body,
            "zombie_update_path_service"
        )
    end
    if navigation
        and navigation.controllerMode == "behavior2_move"
        and Internal.IsBodyCollided
        and Internal.IsBodyCollided(body)
    then
        if PNC.PathService and PNC.PathService.AdvanceScriptedPassage then
            return PNC.PathService.AdvanceScriptedPassage(
                record,
                body,
                "zombie_update_collision"
            )
        end
        return true, "native_collision_waiting"
    end
    fromX = body:getX()
    fromY = body:getY()
    fromZ = body:getZ()
    handled, state = Planner.Pump(record, body, "zombie_update")
    if handled then
        local progressedHandled, progressedState =
            recordSinglePlayerNativeFrame(
                record,
                body,
                lane,
                navigation,
                Core and Core.Now and Core.Now() or 0,
                state,
                fromX,
                fromY,
                fromZ
            )
        if progressedHandled ~= nil then
            return progressedHandled, progressedState
        end
    end
    return handled, state
end

function Planner.PumpServerFrame()
    if not Internal.IsMultiplayerAuthority() then return 0 end
    local pumped = 0
    for record, navigation in pairs(Planner.ActiveServerRoutes) do
        local lane = record and record.runtime and record.runtime.pathing or nil
        local body = navigation and navigation.body or nil
        if PNC.Registry
            and PNC.Registry.GetLiveZombie
            and record
            and record.id
        then
            local liveBody = PNC.Registry.GetLiveZombie(record.id)
            if liveBody ~= body then body = nil end
        end
        if navigation
            and navigation.nativeActive == true
            and navigation.serverMovementLease == true
            and lane
            and lane.phase == "active"
            and body
        then
            Planner.Pump(record, body, "server_tick")
            pumped = pumped + 1
        else
            Internal.ClearEngineRequest(body, navigation)
        end
    end
    return pumped
end
