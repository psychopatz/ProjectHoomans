local T = require "tests/support/test"

T.addPackagePaths()

PNC = {
    Const = {
        INVENTORY_ITEM_STATE_MAX_STRING_LENGTH = 1024,
        INVENTORY_ITEM_STATE_MAX_MODDATA_KEYS = 64,
    },
    Core = {
        DeepCopy = function(value)
            if type(value) ~= "table" then return value end
            local output = {}
            for key, entry in pairs(value) do
                output[key] = PNC.Core.DeepCopy(entry)
            end
            return output
        end,
        LogWarn = function() end,
    },
}

T.load("ProjectHoomans", "shared",
    "PNC/Core/Inventory/PNC_Inventory/PNC_Inventory_Model.lua")

local C = require "PsychopatzCore/Inventory/PsychopatzInventoryConstants"
local StateCodec = T.load("ProjectHoomans", "shared",
    "PNC/Core/Inventory/PNC_Inventory/Persistence/PNC_Inventory_CoreStateCodec.lua")

local raw = {
    condition = 0,
    usedDelta = 0,
    age = 2.5,
    cooked = true,
    hungChange = -0.15,
    fluidAmount = 1.0,
    fluidType = "Water",
    fluidPrimaryType = "Water",
    fluidCapacity = 2.0,
    fluidCanPlayerEmpty = false,
    fluidInputLocked = true,
    fluids = {
        { type = "Water", amount = 0.6 },
        { type = "Coffee", amount = 0.4 },
    },
    modData = { source = "state-test" },
}
local state = PNC.Inventory.SanitizeItemState(raw)
T.equal(state.condition, 0, "zero condition preserved")
T.equal(state.usedDelta, 0, "zero use state preserved")
T.equal(state.fluidCanPlayerEmpty, false, "false fluid state preserved")
T.equal(state.fluidInputLocked, true, "fluid lock state preserved")
T.equal(#state.fluids, 2, "bounded mixture state preserved")
T.equal(state.fluids[2].type, "Coffee", "mixture type preserved")

local pseudo = StateCodec.pseudoItem({
    type = "Base.WaterBottle", cond = 0, uses = 0, itemState = state,
})
T.truthy(pseudo.fluidState, "pseudo item exposes fluid state")
T.equal(pseudo.condition, 0, "pseudo item keeps zero condition")
T.equal(pseudo.usedDelta, 0, "pseudo item keeps zero uses")
T.equal(pseudo:getHungChange(), -0.15, "pseudo item keeps food state")

local networkPayload = PNC.Inventory.Internal.itemToNetworkPayload({
    id = "water", type = "Base.WaterBottle", uses = 0, cond = 0,
    fav = false, itemState = state,
})
T.equal(networkPayload.itemState.condition, nil,
    "network state omits top-level condition duplicate")
T.equal(networkPayload.itemState.usedDelta, nil,
    "network state omits top-level uses duplicate")
T.equal(networkPayload.itemState.fluidType, nil,
    "network state omits legacy fluid alias")
T.truthy(networkPayload.itemState.fluids,
    "network state keeps mixed-fluid components")
T.equal(networkPayload.itemState.modData, nil,
    "network state omits arbitrary modData")

local spec = StateCodec.readState({
    [C.FLAGS] = C.FLAG_FLUID,
    [C.STATE] = { {
        fluidAmount = 1.0,
        fluidType = "Water",
        fluids = { { type = "Water", amount = 1.0 } },
    } },
})
T.equal(spec.itemState.fluidType, "Water", "fluid delta state decoded")
T.equal(spec.itemState.fluids[1].amount, 1.0,
    "fluid component delta state decoded")

PNC.Const.INVENTORY_OPLOG_MAX = 8
PNC.Inventory.EnsureRecordInventory = function(record)
    return record.inventory
end
PNC.Inventory.SyncEquipmentFromInventory = function() end
PNC.Inventory.RebuildCaches = function() end
T.load("ProjectHoomans", "shared",
    "PNC/Core/Inventory/PNC_Inventory/PNC_Inventory_Mutations/PNC_Inventory_Mutations_Delta.lua")
local mutationRecord = {
    inventory = {
        revision = 0, persistenceMode = "FULL", items = {
            water = { id = "water", type = "Base.WaterBottle", stack = 1 },
        },
    },
    runtime = { inventory = { nextItemSerial = 0, opLog = {} } },
}
local applied, operations = PNC.Inventory.ApplyDelta(mutationRecord, {
    {
        op = "update", itemID = "water",
        itemState = {
            fluidAmount = 0.5, fluidType = "Water",
            fluids = { { type = "Water", amount = 0.5 } },
        },
    },
}, "fluid_state_test")
T.truthy(applied, "state-bearing inventory update applied")
T.equal(operations[1].itemState.fluidPrimaryType, "Water",
    "state-bearing update emitted canonical fluid type")
T.falsy(operations[1].itemState.fluidType,
    "state-bearing update omitted legacy fluid alias")
T.falsy(operations[1].itemState.fluids,
    "single-fluid update omitted redundant component list")
T.equal(mutationRecord.inventory.items.water.itemState.fluidAmount, 0.5,
    "state-bearing update stored fluid state")

PNC.Const.CMD_CHARACTER_PAYLOAD = "CharacterPayload"
PNC.Const.CMD_INVENTORY_DELTA = "InventoryDelta"
PNC.Const.CMD_INVENTORY_RESULT = "InventoryResult"
PNC.Network = { ClientState = { characterPayloads = {} } }
PNC.Client = { Internal = {} }
local clientHandlers = {}
PNC.Client.Internal.RegisterServerCommand = function(command, handler)
    clientHandlers[command] = handler
end
PNC.Client.RequestCharacterPayload = function() end
T.load("ProjectHoomans", "client",
    "PNC/Networking/PNC_ClientInventoryCommands.lua")
PNC.Network.ClientState.characterPayloads.npc = {
    revision = 1,
    inventory = {
        revision = 1, summary = { revision = 1 },
        items = { water = { id = "water", type = "Base.WaterBottle" } },
        containers = { root = { items = { "water" } } },
    },
}
clientHandlers[PNC.Const.CMD_INVENTORY_DELTA]({
    npcId = "npc", fromRevision = 1, inventoryRevision = 2,
    ops = { {
        op = "update", itemID = "water",
        itemState = { fluidAmount = 0.5, fluidPrimaryType = "Water" },
    } },
    summary = { revision = 2 }, equipment = {},
})
T.equal(PNC.Network.ClientState.characterPayloads.npc.inventory.items.water
    .itemState.fluidAmount, 0.5,
    "client delta applied fluid state")

T.finish("pnc_inventory_state_roundtrip_smoke")
