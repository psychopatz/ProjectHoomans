local Scene = PNC.ConversationScene
local Internal = Scene.Internal

function Scene.HandleClientCommand(player, command, args)
    local registry
    local record
    local zombie
    args = type(args) == "table" and args or {}
    registry = PNC.Registry
    record = registry and registry.Get and registry.Get(args.id) or nil
    zombie = record and registry.GetLiveZombie(record.id) or nil
    if command == Scene.CMD_BEGIN then
        return Scene.Begin(record, zombie, player, args.token, {
            maximumDistance = args.maximumDistance,
            dangerRadius = args.dangerRadius,
            allowHostileParley = args.allowHostileParley == true,
        })
    end
    if command == Scene.CMD_END then
        return Scene.End(
            record,
            zombie,
            args.token,
            args.reason or "conversation_client_close",
            { llmRequestID = args.llmRequestID, player = player }
        )
    end
    if command == Scene.CMD_CEASEFIRE then
        return Internal.HandleCeasefire(
            player,
            record,
            zombie,
            args.token
        )
    end
    return false, "unknown_command"
end
