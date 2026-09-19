-- Scavenge request transport and local service projection.
PNC = PNC or {}
PNC.Client = PNC.Client or {}

local Client = PNC.Client
local Const = PNC.Const
local Core = PNC.Core

local SCAVENGE_LOCAL_METHODS = {
    start_search = "StartSearch",
    cancel_search = "CancelSearch",
    queue_pickup = "QueuePickup",
    queue_multiple = "QueueMultiple",
    start_collection = "StartCollection",
    cancel_collection = "CancelCollection",
    pause = "Pause",
    disband = "Disband",
    set_auto_grab = "SetAutoGrab",
    remove_auto_grab = "RemoveAutoGrab",
    set_preferences = "SetSearchPreferences",
    request_policy = "RequestPolicy",
    request_snapshot = "RequestSnapshot",
}

function Client.SendScavengeRequest(action, payload)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    if not player then return false, "player_unavailable" end
    local args = Core.DeepCopy(payload or {})
    args.action = tostring(action or "")
    local method = SCAVENGE_LOCAL_METHODS[args.action]
    if args.action == "debug_dump" then
        if not Client.CanUseDebug() then return false, "debug_denied" end
        if Core.IsClientOnly and Core.IsClientOnly() then
            if not sendClientCommand then return false, "network_unavailable" end
            sendClientCommand(player, Const.MODULE, Const.CMD_SCAVENGE_REQUEST,
                args)
            return true, "request_sent"
        end
        local service = PNC.ScavengeService
        local session = service and service.GetSession(args.sessionId)
        if not session then return false, "session_not_found" end
        local snapshot = service.BuildSnapshot(session)
        snapshot.debugDiagnostics = service.GetDiagnostics()
        snapshot.scavengeDebug = service.BuildSessionDiagnostics(session)
        Client.Internal.ApplyScavengeSnapshot(snapshot)
        return true, "debug_snapshot", snapshot
    end
    if not method then return false, "scavenge_action_invalid" end
    if Core.IsClientOnly and Core.IsClientOnly() then
        if not sendClientCommand then return false, "network_unavailable" end
        sendClientCommand(player, Const.MODULE, Const.CMD_SCAVENGE_REQUEST,
            args)
        return true, "request_sent"
    end
    local service = PNC.ScavengeService
    if not service or type(service[method]) ~= "function" then
        return false, "scavenge_service_unavailable"
    end
    local ok, reason, snapshot = service[method](player, args)
    -- Session services publish through SendSnapshot, including local games.
    -- Applying their return value here would duplicate every UI rebuild and
    -- bypass server-side snapshot throttling. Policy-only replies are not
    -- published by the service and still need direct delivery.
    if snapshot and snapshot.policyOnly == true
        and Client.Internal.ApplyScavengeSnapshot
    then
        Client.Internal.ApplyScavengeSnapshot(snapshot)
    end
    return ok == true, reason, snapshot
end

return PNC.Client

