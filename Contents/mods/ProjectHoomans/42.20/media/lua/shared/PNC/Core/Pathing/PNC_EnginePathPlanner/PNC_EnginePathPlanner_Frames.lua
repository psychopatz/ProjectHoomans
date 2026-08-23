-- Zombie-update and dedicated-server route dispatch.

local Planner = PNC.EnginePathPlanner
local Internal = Planner.Internal
local Core = PNC.Core

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
    return Planner.Pump(record, body, "zombie_update")
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
