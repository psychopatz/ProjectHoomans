-- Map command transport.
PNC = PNC or {}
PNC.Client = PNC.Client or {}

local Client = PNC.Client
local Const = PNC.Const
local Core = PNC.Core

function Client.SendMapCommand(commandID, npcIds, target, options)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local args = {
        requestId = Core.GenerateID
            and Core.GenerateID("map_command") or tostring(Core.Now()),
        commandID = tostring(commandID or ""),
        npcIds = Core.DeepCopy(npcIds or {}),
        target = Core.DeepCopy(target or {}),
        options = Core.DeepCopy(options or {}),
    }
    if args.commandID == "" or #args.npcIds <= 0 then return false end
    if Core.IsClientOnly and Core.IsClientOnly() then
        if not player or not sendClientCommand then return false end
        sendClientCommand(
            player,
            Const.MODULE,
            Const.CMD_MAP_COMMAND,
            args
        )
        return true
    end
    local result = PNC.MapCommandService
        and PNC.MapCommandService.Execute
        and PNC.MapCommandService.Execute(player, args, {
            debugAuthorized = Client.CanUseDebug(),
            source = "local",
        }) or {
            requestId = args.requestId,
            commandID = args.commandID,
            ok = false,
            reason = "map_commands_unavailable",
        }
    if PNC.MapCommands and PNC.MapCommands.HandleResult then
        PNC.MapCommands.HandleResult(result)
    end
    return result.ok == true, result
end

return PNC.Client

