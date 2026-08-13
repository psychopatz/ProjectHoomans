local SERVER_ROOT = "Contents/mods/ProjectHoomans/42.20/media/lua/server/"
package.path = SERVER_ROOT .. "?.lua;" .. package.path

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local transferArgs
local actionArgs
local player = {}

PNC = {
    Const = {
        CMD_INVENTORY_TRANSFER = "InventoryTransfer",
        CMD_INVENTORY_ACTION = "InventoryAction",
    },
    ServerInventory = {
        Transfer = function(receivedPlayer, args)
            assertEqual(receivedPlayer, player, "transfer player")
            transferArgs = args
        end,
        Action = function(receivedPlayer, args)
            assertEqual(receivedPlayer, player, "action player")
            actionArgs = args
        end,
    },
}

local Router = require "PNC/Networking/PNC_ServerCommandRouting"
local transferPayload = { id = "npc-1", direction = "player_to_npc" }
local actionPayload = { id = "npc-1", actionID = "favorite" }

assertEqual(Router.Handle("InventoryTransfer", player, transferPayload), true,
    "transfer command handled")
assertEqual(transferArgs, transferPayload, "transfer payload identity")
assertEqual(Router.Handle("InventoryAction", player, actionPayload), true,
    "action command handled")
assertEqual(actionArgs, actionPayload, "action payload identity")
assertEqual(Router.Handle("UnknownCommand", player, {}), false,
    "unknown command fallthrough")

local sourcePath = SERVER_ROOT .. "PNC/PNC_Server.lua"
local sourceFile = assert(io.open(sourcePath, "rb"))
local source = sourceFile:read("*a")
sourceFile:close()
local moduleGate = assert(string.find(source, "module ~= Const.MODULE", 1, true))
local routerCall = assert(string.find(
    source,
    "CommandRouter.Handle(command, player, args)",
    1,
    true
))
assert(moduleGate < routerCall,
    "module namespace must be validated before domain routing")

print("pnc_server_command_router_smoke: ok")
