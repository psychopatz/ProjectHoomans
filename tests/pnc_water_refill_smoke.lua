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
PNC.PerformanceScalingDiagnostics = {
    InventoryAuditEnabled = true,
    LogInventoryAudit = function(event, fields)
        local output = { "inventory_audit", "event=" .. tostring(event) }
        for _, field in ipairs(fields or {}) do
            output[#output + 1] = tostring(field)
        end
        refillLogs[#refillLogs + 1] = table.concat(output, " ")
    end,
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

local admissionOK, admissionReason = Service.CanRefill(record, "can")
T.truthy(admissionOK, "an empty live liquid container passes refill admission")
T.equal(admissionReason, "WATER_CONTAINER_REFILLABLE",
    "refill admission reports the accepted reason")
T.truthy(string.find(refillLogs[#refillLogs],
    "event=refill_admission", 1, true),
    "refill admission emits a dedicated inventory audit event")

local missingRecord = {
    id = "npc_missing_refill_container",
    runtime = { inventory = { nextItemSerial = 0, opLog = {} } },
    inventory = {
        revision = 0, cachedWeight = 0, maxWeight = 10, rootMaxWeight = 10,
        equipped = { primary = nil, secondary = nil, bag = nil },
        worn = {}, attached = {}, items = {},
        containers = { root = { maxWeight = 10, items = {} } },
        template = { generatorVersion = 3 },
    },
}
Inventory.EnsureRecordInventory(missingRecord)
local missingAdmissionOK, missingAdmissionReason =
    Service.CanRefill(missingRecord, "missing")
T.falsy(missingAdmissionOK,
    "missing liquid containers fail refill admission without crashing")
T.equal(missingAdmissionReason, "WATER_CONTAINER_NOT_REFILLABLE",
    "missing liquid containers preserve the precise admission reason")

local logsBeforeDisabledAdmission = #refillLogs
PNC.PerformanceScalingDiagnostics.InventoryAuditEnabled = false
local disabledAdmissionOK = Service.CanRefill(record, "can")
T.truthy(disabledAdmissionOK,
    "refill admission still works while inventory audit is disabled")
T.equal(#refillLogs, logsBeforeDisabledAdmission,
    "disabled inventory audit adds no refill admission log")
PNC.PerformanceScalingDiagnostics.InventoryAuditEnabled = true

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

-- If the compact entry is stale, reconcile it from the authoritative native
-- item before returning the full-container rejection.
record.inventory.items.can.itemState = {
    fluidAmount = 0, fluidCapacity = 1, fluidPrimaryType = "Water",
    fluids = {},
}
local revisionBeforeReconcile = record.inventory.revision
local reconcileOK, reconcileReason = Service.Refill(record, "can", source)
T.falsy(reconcileOK, "physical full bottle still rejects refill")
T.equal(reconcileReason, "WATER_CONTAINER_FULL",
    "physical full rejection keeps its reason")
T.equal(record.inventory.items.can.itemState.fluidAmount, 1,
    "physical full state repairs compact amount")
T.equal(Inventory.ResolveItemState(record.inventory.items.can).fluidAmount, 1,
    "physical full state is visible through the effective compact state")
T.truthy(Inventory.DescribeLiquidContainer(record.inventory.items.can).canDrink,
    "reconciled physical full state is eligible for drinking")
T.truthy(record.inventory.revision > revisionBeforeReconcile,
    "compact reconciliation advances inventory revision")

local NeedFacilityEffects = T.load("ProjectHoomans", "server",
    "PNC/Needs/NeedFacilityTriggers/PNC_NeedFacilityEffects.lua")
record.runtime.facilityActivity = {
    capability = "water_refill",
    resourceKind = "water_refill",
    resource = source,
    resourceKey = source.key,
    activityItemID = "can",
    manual = false,
}

-- A successful facility refill is also the NPC's drink action. The logical
-- need update and its journal event must happen once, after the physical
-- transaction commits.
destinationContainer:adjustAmount(0)
record.inventory.items.can.itemState = {
    fluidAmount = 0, fluidCapacity = 1, fluidPrimaryType = nil,
    fluids = {},
}
sourceAmount = 2
local thirst = 0.60
local thirstSetCount = 0
local autoDrinkEvent
local autoDrinkEventCount = 0
PNC.IndividualNeeds = {
    Get = function(_, needType)
        return needType == "thirst" and thirst or nil
    end,
    Set = function(_, needType, value)
        if needType ~= "thirst" then return nil, "invalid_need" end
        thirst = tonumber(value) or 0
        thirstSetCount = thirstSetCount + 1
        return thirst
    end,
}
Events.subscribe(EventTypes.NPC_WATER_REFILL_DRANK, function(receivedRecord,
        fullType, thirstBefore, amount, sourceKey)
    autoDrinkEventCount = autoDrinkEventCount + 1
    autoDrinkEvent = {
        record = receivedRecord, fullType = fullType,
        thirstBefore = thirstBefore, amount = amount, sourceKey = sourceKey,
    }
end, "tests.water_refill_drink")
local successfulEffectState = {
    effectReadyAt = 0,
    effectAttempted = false,
    activityItemID = "can",
    activityItemFullType = "Base.EmptyCan",
    resource = source,
    resourceKey = source.key,
}
local successfulEffectOK, successfulEffectComplete, successfulEffectReason,
    successfulEffectAmount =
    NeedFacilityEffects.Tick(record, successfulEffectState, {
        needEffect = "water_refill",
        effectDelayMs = 0,
    }, 0, 1)
T.truthy(successfulEffectOK, "successful refill effect reports success")
T.truthy(successfulEffectComplete, "successful refill effect completes once")
T.equal(successfulEffectReason, "WATER_REFILL_COMPLETE",
    "successful refill effect preserves the completion reason")
T.equal(successfulEffectAmount, 1,
    "successful refill effect reports committed liters")
T.equal(thirst, 0, "successful refill clears the NPC thirst need")
T.equal(thirstSetCount, 1, "successful refill clears thirst exactly once")
T.equal(autoDrinkEventCount, 1,
    "successful refill emits one combined refill-drink event")
T.equal(autoDrinkEvent.record, record,
    "combined refill-drink event targets the refilled NPC")
T.equal(autoDrinkEvent.fullType, "Base.EmptyCan",
    "combined refill-drink event stores the container type")
T.equal(autoDrinkEvent.thirstBefore, 0.60,
    "combined refill-drink event stores thirst before clearing")
T.equal(autoDrinkEvent.amount, 1,
    "combined refill-drink event stores the committed fill amount")
T.equal(autoDrinkEvent.sourceKey, source.key,
    "combined refill-drink event stores the source identity")
T.equal(sourceAmount, 1,
    "successful refill effect debits the source once")
local repeatOK, repeatComplete = NeedFacilityEffects.Tick(record,
    successfulEffectState, { needEffect = "water_refill", effectDelayMs = 0 },
    0, 2)
T.truthy(repeatOK, "completed refill effect remains safely acknowledged")
T.falsy(repeatComplete, "completed refill effect is not applied twice")
T.equal(thirstSetCount, 1,
    "completed refill effect does not clear thirst a second time")
T.equal(autoDrinkEventCount, 1,
    "completed refill effect does not journal a second drink")

-- The later full-container rejection remains a physical failure and must not
-- clear thirst or emit the combined drink event.
local effectOK, effectComplete, effectReason = NeedFacilityEffects.Tick(record, {
    effectReadyAt = 0,
    effectAttempted = false,
}, {
    needEffect = "water_refill",
    effectDelayMs = 0,
}, 0, 1)
T.falsy(effectOK, "effect boundary reports failed refill")
T.truthy(effectComplete, "failed refill requests scene completion")
T.equal(effectReason, "WATER_CONTAINER_FULL",
    "effect boundary preserves transaction failure reason")
T.equal(thirstSetCount, 1,
    "failed refill does not clear the NPC thirst need")
T.equal(autoDrinkEventCount, 1,
    "failed refill does not emit the combined drink event")

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
local eventsBeforeRollback = refillEventCount
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
T.equal(refillEventCount, eventsBeforeRollback,
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
