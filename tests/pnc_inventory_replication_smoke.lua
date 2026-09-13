local T = require "tests/support/test"

T.addPackagePaths()

local EventBus = require "PsychopatzCore/Events/PC_EventBus"
local tickHandler
local pushes = {}

-- The server hook must use the native PZ event table, not the shared
-- PsychopatzCore event bus table with the same conventional name.
Events = {
    OnTick = {
        Add = function(handler) tickHandler = handler end,
    },
}

PNC = {
    Core = { IsAuthority = function() return true end },
    Network = {
        PushInventoryDelta = function(record)
            pushes[#pushes + 1] = record
            return 1
        end,
    },
}

local replication = T.load("ProjectHoomans", "server",
    "PNC/Server/ServerInventory/PNC_ServerInventory_Replication.lua")

T.truthy(tickHandler, "inventory replication registers one native tick hook")
local record = { id = "npc-replication", inventory = { revision = 2 } }
local eventType = PNC.EventTypes.NPC_INVENTORY_CHANGED

EventBus.emit(eventType, record, {}, "food_use")
EventBus.emit(eventType, record, {}, "drink_use")
T.equal(#pushes, 0, "inventory mutations wait for the coalesced flush")
T.equal(replication.pendingCount, 1, "same-tick mutations share one pending NPC")

tickHandler()
T.equal(#pushes, 1, "one delta push is made for coalesced mutations")
T.equal(pushes[1], record, "the authoritative record reaches the network")
T.equal(replication.pendingCount, 0, "flush clears the pending count")

tickHandler()
T.equal(#pushes, 1, "idle ticks do not perform inventory work")

T.finish("pnc_inventory_replication_smoke")
