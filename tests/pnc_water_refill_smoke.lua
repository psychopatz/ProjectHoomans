local T = require "tests/support/test"

T.addPackagePaths()

local function copy(value)
    if type(value) ~= "table" then return value end
    local output = {}
    for key, entry in pairs(value) do output[key] = copy(entry) end
    return output
end

local refillLogs = {}
local payloadSyncCount = 0
local payloadSyncRecord
local ownerPlayer = {}
PNC = {
    Const = {
        GENERATOR_VERSION = 3,
        INVENTORY_OPLOG_MAX = 32,
        INVENTORY_ITEM_STATE_MAX_STRING_LENGTH = 1024,
        INVENTORY_ITEM_STATE_MAX_MODDATA_KEYS = 64,
    },
    Core = {
        DeepCopy = copy,
        LogInfo = function(message) refillLogs[#refillLogs + 1] = message end,
        ResolvePlayerByUsername = function(username)
            return username == "alice" and ownerPlayer or nil
        end,
    },
    Equipment = {},
    Network = {
        SendCharacterPayload = function(player, receivedRecord)
            if player == ownerPlayer then payloadSyncCount = payloadSyncCount + 1 end
            payloadSyncRecord = receivedRecord
        end,
    },
}

local function makeFluidContainer(initialAmount)
    local amount = tonumber(initialAmount) or 0
    local primary
    local container = {}
    function container:getAmount() return amount end
    function container:getCapacity() return 1 end
    function container:isInputLocked() return false end
    function container:canPlayerEmpty() return true end
    function container:getPrimaryFluid() return primary end
    function container:getSpecificFluidAmount(fluid)
        local name = fluid and fluid.getFluidTypeString
            and fluid:getFluidTypeString() or ""
        local current = primary and primary.getFluidTypeString
            and primary:getFluidTypeString() or ""
        return name == current and amount or 0
    end
    function container:setCapacity() return true end
    function container:setInputLocked() return true end
    function container:setCanPlayerEmpty() return true end
    function container:Empty() amount, primary = 0, nil; return true end
    function container:addFluid(fluid, value)
        primary, amount = fluid, amount + value
        return true
    end
    function container:adjustAmount(value) amount = value; return true end
    function container:canAddFluid() return true end
    return container
end

Fluid = {
    Get = function(name)
        return { getFluidTypeString = function() return name end }
    end,
}

local destinationContainer = makeFluidContainer()
local syncCount = 0
local destination = {
    getFullType = function() return "Base.EmptyCan" end,
    getFluidContainer = function() return destinationContainer end,
    syncItemFields = function() syncCount = syncCount + 1 end,
}
PNC.Equipment.CreateItem = function(fullType)
    if fullType == "Base.EmptyCan" then
        return { getFluidContainer = function() return makeFluidContainer() end }
    end
    return {}
end

T.load("ProjectHoomans", "shared",
    "PNC/Core/Inventory/PNC_Inventory/PNC_Inventory_Model.lua")
T.load("ProjectHoomans", "shared",
    "PNC/Core/Inventory/PNC_Inventory/Equipment/PNC_Inventory_Hydration.lua")
T.load("ProjectHoomans", "shared",
    "PNC/Core/Inventory/PNC_Inventory/PNC_Inventory_Mutations.lua")
T.load("ProjectHoomans", "shared",
    "PNC/Core/Inventory/PNC_Inventory/PNC_Inventory_WaterContainers.lua")

local Inventory = PNC.Inventory
Inventory.SyncEquipmentFromInventory = function() end
Inventory.RebuildCaches = function() end
PNC.Registry = {
    MarkDirty = function() end,
    GetLiveZombie = function() return {
        getInventory = function() return {} end,
    } end,
}
PNC.SupplyInventoryInternal = {
    NativeCandidates = function() return {
        { item = destination, container = {} },
    } end,
}

local sourceAmount = 2
local sourceObject = {
    getFluidAmount = function() return sourceAmount end,
    setWaterAmount = function(_, value) sourceAmount = value end,
}
local source = { kind = "faucet", x = 10, y = 10, z = 0,
    key = "sink:10:10:0", object = sourceObject }
PNC.NearbyWaterService = {
    MAX_REFILL_LITERS = 4,
    IsInfiniteFaucet = function() return false end,
    IsCleanFaucet = function() return true end,
    ResolveFillSource = function() return source end,
    Consume = function(_, _, liters)
        sourceAmount = sourceAmount - liters
        return true, liters, sourceAmount
    end,
}
PNC.NearbyResourceLocator = { Invalidate = function() end }

local Events = require "PsychopatzCore/Events/PC_EventBus"
local EventTypes = require "PNC/Core/Events/PNC_EventDefinitions"
local refillEvent
local refillEventCount = 0
Events.subscribe(EventTypes.NPC_WATER_REFILLED, function(receivedRecord,
        fullType, amount, sourceKey)
    refillEventCount = refillEventCount + 1
    refillEvent = {
        record = receivedRecord, fullType = fullType, amount = amount,
        sourceKey = sourceKey,
    }
end, "tests.water_refill")

local record = {
    id = "npc_refill",
    ownerUsername = "alice",
    runtime = { inventory = { nextItemSerial = 0, opLog = {} } },
    inventory = {
        revision = 0, cachedWeight = 0, maxWeight = 10, rootMaxWeight = 10,
        equipped = { primary = nil, secondary = nil, bag = nil },
        worn = {}, attached = {},
        items = { can = { id = "can", type = "Base.EmptyCan", stack = 1,
            container = "root" } },
        containers = { root = { maxWeight = 10, items = { "can" } } },
        template = { generatorVersion = 3 },
    },
}
Inventory.EnsureRecordInventory(record)
local Service = T.load("ProjectHoomans", "server",
    "PNC/World/PNC_WaterContainerService.lua")

local ok, filled = Service.Refill(record, "can", source)
T.truthy(ok, "empty generic liquid container refills from a clean source")
T.equal(filled, 1, "refill is capped by destination capacity")
T.equal(sourceAmount, 1, "source water is debited exactly once")
T.equal(Inventory.ResolveItemState(record.inventory.items.can).fluidAmount, 1,
    "compact inventory receives the physical filled-fluid state")
T.equal(record.inventory.equipped.waterContainer, "can",
    "filled container remains in the one-container equipment slot")
T.equal(refillEvent.record, record,
    "successful refill emits the refilled NPC record")
T.equal(refillEvent.fullType, "Base.EmptyCan",
    "successful refill emits the filled container type")
T.equal(refillEvent.amount, 1,
    "successful refill emits the committed fill amount")
T.equal(refillEvent.sourceKey, source.key,
    "successful refill emits the source identity")
T.near(destinationContainer:getAmount(), 1, 0.000001,
    "successful refill mutates the physical native item")
T.truthy(syncCount >= 1, "successful refill synchronizes the native item")
T.equal(payloadSyncCount, 1,
    "successful refill pushes the committed compact inventory to the owner")
T.equal(payloadSyncRecord, record,
    "inventory payload refresh targets the refilled NPC record")

destinationContainer:adjustAmount(0.25)
record.inventory.items.can.itemState = {
    fluidAmount = 0.25,
    fluidCapacity = 1,
    fluidPrimaryType = "Water",
    fluids = {{ type = "Water", amount = 0.25 }},
}
sourceAmount = 2
ok, filled = Service.Refill(record, "can", source)
T.truthy(ok, "partially filled container refills without losing existing water: "
    .. tostring(filled))
T.equal(filled, 0.75, "partial refill only consumes free capacity")
T.equal(sourceAmount, 1.25, "partial refill debits only the free capacity")
T.equal(Inventory.ResolveItemState(record.inventory.items.can).fluidAmount, 1,
    "partial refill preserves the existing liquid amount")
T.near(destinationContainer:getAmount(), 1, 0.000001,
    "partial refill keeps physical and compact amounts synchronized")

-- A full container is a precise, non-mutating rejection.
destinationContainer:adjustAmount(1)
record.inventory.items.can.itemState = {
    fluidAmount = 1, fluidCapacity = 1, fluidPrimaryType = "Water",
    fluids = {{ type = "Water", amount = 1 }},
}
sourceAmount = 2
local revisionBeforeFull = record.inventory.revision
local eventsBeforeFull = refillEventCount
ok, reason = Service.Refill(record, "can", source)
T.falsy(ok, "a full container is rejected before source mutation")
T.equal(reason, "WATER_CONTAINER_FULL",
    "a full container returns the precise refill reason")
T.equal(sourceAmount, 2, "full-container rejection does not debit the source")
T.equal(destinationContainer:getAmount(), 1,
    "full-container rejection does not mutate the physical item")
T.equal(Inventory.ResolveItemState(record.inventory.items.can).fluidAmount, 1,
    "full-container rejection does not mutate compact inventory")
T.equal(record.inventory.revision, revisionBeforeFull,
    "full-container rejection does not advance inventory revision")
T.equal(refillEventCount, eventsBeforeFull,
    "full-container rejection emits no success journal event")
T.truthy(string.find(refillLogs[#refillLogs],
    "failureReason=WATER_CONTAINER_FULL", 1, true),
    "full-container failure log preserves the exact failure reason")
T.truthy(string.find(refillLogs[#refillLogs],
    "compactFreeCapacity=0", 1, true),
    "full-container failure log includes compact capacity state")

-- If source consumption fails after destination mutation, both sides roll
-- back and no journal event is emitted.
destinationContainer:adjustAmount(0.25)
record.inventory.items.can.itemState = {
    fluidAmount = 0.25, fluidCapacity = 1, fluidPrimaryType = "Water",
    fluids = {{ type = "Water", amount = 0.25 }},
}
sourceAmount = 2
local originalConsume = PNC.NearbyWaterService.Consume
PNC.NearbyWaterService.Consume = function(_, _, liters)
    sourceAmount = sourceAmount - liters
    return false, "WATER_FILL_SOURCE_NOT_MUTABLE", 0, {
        sourceMutationAPI = "test_partial_debit",
        sourceConsumedAmount = liters,
    }
end
local compactBeforeRollback = Inventory.ResolveItemState(
    record.inventory.items.can).fluidAmount
ok, reason = Service.Refill(record, "can", source)
PNC.NearbyWaterService.Consume = originalConsume
T.falsy(ok, "a failed source transaction is rejected")
T.equal(reason, "WATER_FILL_SOURCE_NOT_MUTABLE",
    "source failure reason propagates from the refill transaction")
T.equal(sourceAmount, 2, "failed source consumption rolls the source back")
T.near(destinationContainer:getAmount(), 0.25, 0.000001,
    "failed source consumption rolls the physical destination back")
T.equal(Inventory.ResolveItemState(record.inventory.items.can).fluidAmount,
    compactBeforeRollback,
    "failed source consumption rolls compact inventory back")
T.equal(refillEventCount, eventsBeforeFull,
    "failed source consumption emits no success journal event")
T.truthy(string.find(refillLogs[#refillLogs],
    "destinationPhysicalRollback=true", 1, true),
    "failed refill log records physical rollback")
T.truthy(string.find(refillLogs[#refillLogs],
    "destinationCompactRollback=true", 1, true),
    "failed refill log records compact rollback")
T.truthy(string.find(refillLogs[#refillLogs],
    "sourceRollback=true", 1, true),
    "failed refill log records source rollback")

T.finish("pnc_water_refill_smoke")
