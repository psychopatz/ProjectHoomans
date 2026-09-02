local T = require "tests/support/test"

local SERVER_ROOT = T.path("ProjectHoomans", "server", "")
T.addPackagePaths()

local player = {
    access = "admin",
    getAccessLevel = function(self) return self.access end,
}
local companion
local map
local toll
local sent
local commandLogs = {}

PNC = {
    Const = {
        MODULE = "PNC",
        CMD_COMPANION_COMMAND = "CompanionCommand",
        CMD_MAP_COMMAND = "MapCommand",
        CMD_MAP_COMMAND_RESULT = "MapCommandResult",
        CMD_FACTION_TOLL_RESPONSE = "FactionTollResponse",
    },
    CompanionCommands = {
        Execute = function(receivedPlayer, args)
            companion = { player = receivedPlayer, args = args }
            return args and args.commandID == "manual_corpse_haul"
                and 0 or 1,
                args and args.commandID == "manual_corpse_haul"
                and "NPC_NOT_AT_HOME" or "commanded"
        end,
    },
    MapCommandService = {
        Execute = function(receivedPlayer, args, context)
            map = {
                player = receivedPlayer,
                args = args,
                context = context,
            }
            return { ok = true, marker = "result" }
        end,
    },
    FactionTolls = {
        HandleResponse = function(receivedPlayer, args)
            toll = { player = receivedPlayer, args = args }
        end,
    },
    Core = {
        Log = function(level, message)
            commandLogs[#commandLogs + 1] = {
                level = level, message = message,
            }
        end,
    },
}

isServer = function() return true end
sendServerCommand = function(receivedPlayer, module, command, args)
    sent = {
        player = receivedPlayer,
        module = module,
        command = command,
        args = args,
    }
end

local Router = require "PNC/Networking/PNC_ServerCommandRouter"
require "PNC/Networking/Handlers/PNC_ServerGameplayRequestCommandHandler"

local companionArgs = { commandID = "follow" }
T.equal(Router.Handle("CompanionCommand", player, companionArgs), true,
    "companion command handled")
T.equal(companion.player, player, "companion player")
T.equal(companion.args, companionArgs, "companion payload identity")

Router.Handle("CompanionCommand", player, {
    commandID = "manual_corpse_haul", id = "npc:one",
    requestID = "manual:one", commandSource = "colonist_activities",
})
T.truthy(commandLogs[#commandLogs]
    and string.find(commandLogs[#commandLogs].message,
        "reason=NPC_NOT_AT_HOME", 1, true),
    "manual corpse command logs the server routing rejection reason")

companion = nil
T.equal(Router.Handle("CompanionCommand", player, nil), true,
    "malformed companion command consumed")
T.equal(companion, nil, "malformed companion command invoked service")

local mapArgs = { action = "travel" }
T.equal(Router.Handle("MapCommand", player, mapArgs), true,
    "map command handled")
T.equal(map.player, player, "map player")
T.equal(map.args, mapArgs, "map payload identity")
T.equal(map.context.debugAuthorized, true,
    "map debug authorization changed")
T.equal(map.context.source, "network", "map source changed")
T.equal(sent.player, player, "map response player")
T.equal(sent.module, "PNC", "map response module")
T.equal(sent.command, "MapCommandResult", "map response command")
T.equal(sent.args.marker, "result", "map response payload")

player.access = ""
Router.Handle("MapCommand", player, mapArgs)
T.equal(map.context.debugAuthorized, false,
    "non-admin map debug authorization changed")
player.access = "admin"

map = nil
Router.Handle("MapCommand", player, nil)
T.equal(type(map.args), "table", "nil map payload not normalized")

PNC.MapCommandService.Execute = nil
Router.Handle("MapCommand", player, mapArgs)
T.equal(sent.args.ok, false, "unavailable map command reported success")
T.equal(sent.args.reason, "map_commands_unavailable",
    "unavailable map command reason changed")

local tollArgs = { demandID = "demand-1", accepted = true }
T.equal(Router.Handle("FactionTollResponse", player, tollArgs), true,
    "faction toll response handled")
T.equal(toll.player, player, "faction toll player")
T.equal(toll.args, tollArgs, "faction toll payload identity")

Router.Handle("FactionTollResponse", player, nil)
T.equal(type(toll.args), "table", "nil toll payload not normalized")

PNC.FactionTolls = nil
T.equal(Router.Handle("FactionTollResponse", player, tollArgs), true,
    "unavailable faction toll command not consumed")
T.finish("pnc_server_gameplay_request_command_handler_smoke")

T.finish("pnc_server_gameplay_request_command_handler_smoke")
