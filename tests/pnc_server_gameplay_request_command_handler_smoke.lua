local SERVER_ROOT = "Contents/mods/ProjectHoomans/42.20/media/lua/server/"
package.path = SERVER_ROOT .. "?.lua;" .. package.path

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local player = {
    access = "admin",
    getAccessLevel = function(self) return self.access end,
}
local companion
local map
local toll
local sent

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
assertEqual(Router.Handle("CompanionCommand", player, companionArgs), true,
    "companion command handled")
assertEqual(companion.player, player, "companion player")
assertEqual(companion.args, companionArgs, "companion payload identity")

companion = nil
assertEqual(Router.Handle("CompanionCommand", player, nil), true,
    "malformed companion command consumed")
assertEqual(companion, nil, "malformed companion command invoked service")

local mapArgs = { action = "travel" }
assertEqual(Router.Handle("MapCommand", player, mapArgs), true,
    "map command handled")
assertEqual(map.player, player, "map player")
assertEqual(map.args, mapArgs, "map payload identity")
assertEqual(map.context.debugAuthorized, true,
    "map debug authorization changed")
assertEqual(map.context.source, "network", "map source changed")
assertEqual(sent.player, player, "map response player")
assertEqual(sent.module, "PNC", "map response module")
assertEqual(sent.command, "MapCommandResult", "map response command")
assertEqual(sent.args.marker, "result", "map response payload")

player.access = ""
Router.Handle("MapCommand", player, mapArgs)
assertEqual(map.context.debugAuthorized, false,
    "non-admin map debug authorization changed")
player.access = "admin"

map = nil
Router.Handle("MapCommand", player, nil)
assertEqual(type(map.args), "table", "nil map payload not normalized")

PNC.MapCommandService.Execute = nil
Router.Handle("MapCommand", player, mapArgs)
assertEqual(sent.args.ok, false, "unavailable map command reported success")
assertEqual(sent.args.reason, "map_commands_unavailable",
    "unavailable map command reason changed")

local tollArgs = { demandID = "demand-1", accepted = true }
assertEqual(Router.Handle("FactionTollResponse", player, tollArgs), true,
    "faction toll response handled")
assertEqual(toll.player, player, "faction toll player")
assertEqual(toll.args, tollArgs, "faction toll payload identity")

Router.Handle("FactionTollResponse", player, nil)
assertEqual(type(toll.args), "table", "nil toll payload not normalized")

PNC.FactionTolls = nil
assertEqual(Router.Handle("FactionTollResponse", player, tollArgs), true,
    "unavailable faction toll command not consumed")

print("pnc_server_gameplay_request_command_handler_smoke: ok")
