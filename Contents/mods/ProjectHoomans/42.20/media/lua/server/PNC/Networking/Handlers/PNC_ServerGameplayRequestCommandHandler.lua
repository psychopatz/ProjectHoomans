-- Gameplay request adapters. Domain services retain policy and mutation.

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
