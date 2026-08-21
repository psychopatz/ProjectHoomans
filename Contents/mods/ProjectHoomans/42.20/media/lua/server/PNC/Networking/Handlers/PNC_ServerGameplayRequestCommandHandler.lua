-- Gameplay request adapters. Domain services retain policy and mutation.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

local Router = PNC.ServerCommandRouter
local Const = PNC.Const
local CompanionCommands = PNC.CompanionCommands
local MapCommandService = PNC.MapCommandService

Router.Register(Const.CMD_COMPANION_COMMAND, function(player, args)
    if not args.commandID then return end
    if CompanionCommands and CompanionCommands.Execute then
        CompanionCommands.Execute(player, args)
    end
end)

Router.Register(Const.CMD_MAP_COMMAND, function(player, args)
    local result = MapCommandService and MapCommandService.Execute
        and MapCommandService.Execute(player, args, {
            debugAuthorized = Router.CanUseDebug(player),
            source = "network",
        }) or {
            ok = false,
            reason = "map_commands_unavailable",
        }
    if sendServerCommand then
        sendServerCommand(
            player,
            Const.MODULE,
            Const.CMD_MAP_COMMAND_RESULT,
            result
        )
    end
end)

Router.Register(Const.CMD_FACTION_TOLL_RESPONSE, function(player, args)
    local tolls = PNC.FactionTolls
    if tolls and tolls.HandleResponse then
        tolls.HandleResponse(player, args)
    end
end)

local SCAVENGE_ACTIONS = {
    start_search = "StartSearch",
    cancel_search = "CancelSearch",
    queue_pickup = "QueuePickup",
    queue_multiple = "QueueMultiple",
    start_collection = "StartCollection",
    cancel_collection = "CancelCollection",
    pause = "Pause",
    set_auto_grab = "SetAutoGrab",
    remove_auto_grab = "RemoveAutoGrab",
    set_preferences = "SetSearchPreferences",
    request_policy = "RequestPolicy",
    request_snapshot = "RequestSnapshot",
}

Router.Register(Const.CMD_SCAVENGE_REQUEST, function(player, args)
    args = type(args) == "table" and args or {}
    if args.action == "debug_dump" then
        if not Router.CanUseDebug(player) then return end
        local service = PNC.ScavengeService
        local session = service and service.GetSession(args.sessionId)
        local allowed = session and service.RequestSnapshot(player, args)
        if allowed == true and sendServerCommand then
            local payload = service.BuildSnapshot(session)
            payload.debugDiagnostics = service.GetDiagnostics()
            sendServerCommand(player, Const.MODULE,
                Const.CMD_SCAVENGE_STATE, payload)
        end
        return
    end
    local method = SCAVENGE_ACTIONS[tostring(args.action or "")]
    local service = PNC.ScavengeService
    if not method or not service or type(service[method]) ~= "function" then
        return
    end
    local ok, reason, snapshot = service[method](player, args)
    if snapshot and snapshot.policyOnly == true and sendServerCommand then
        sendServerCommand(player, Const.MODULE, Const.CMD_SCAVENGE_STATE,
            snapshot)
    elseif ok ~= true and sendServerCommand then
        sendServerCommand(player, Const.MODULE, Const.CMD_SCAVENGE_STATE, {
            requestFailed = true,
            reason = tostring(reason or "scavenge_request_failed"),
            sessionId = args.sessionId,
            npcId = args.npcId,
        })
    end
end)
