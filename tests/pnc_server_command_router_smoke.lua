local T = require "tests/support/test"
T.addPackagePaths({ { "ProjectHoomans", "server" } })

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
            T.equal(receivedPlayer, player, "transfer player")
            transferArgs = args
        end,
        Action = function(receivedPlayer, args)
            T.equal(receivedPlayer, player, "action player")
            actionArgs = args
        end,
    },
}

local Router = require "PNC/Networking/PNC_ServerCommandRouting"
local transferPayload = { id = "npc-1", direction = "player_to_npc" }
local actionPayload = { id = "npc-1", actionID = "favorite" }

T.equal(Router.Handle("InventoryTransfer", player, transferPayload), true,
    "transfer command handled")
T.equal(transferArgs, transferPayload, "transfer payload identity")
T.equal(Router.Handle("InventoryAction", player, actionPayload), true,
    "action command handled")
T.equal(actionArgs, actionPayload, "action payload identity")
T.equal(Router.Handle("UnknownCommand", player, {}), false,
    "unknown command fallthrough")

local source = T.read("ProjectHoomans", "server", "PNC/PNC_Server.lua")
local moduleGate = T.truthy(string.find(source, "module ~= Const.MODULE", 1, true))
local routerCall = T.truthy(string.find(
    source,
    "CommandRouter.Handle(command, player, args)",
    1,
    true
))
T.truthy(moduleGate < routerCall,
    "module namespace must be validated before domain routing")

T.finish("pnc_server_command_router_smoke")
