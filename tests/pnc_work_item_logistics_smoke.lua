local T = require "tests/support/test"

local queued = {}
local orders = {}
local nextOrder = 0
local Work = {
    Commands = {}, Queries = {}, CancellationHandlers = {},
    CompletionHandlers = {}, CompletionRecoveryHandlers = {},
}

function Work.Commands.Queue(spec)
    nextOrder = nextOrder + 1
    local order = {
        id = "work-item-order-" .. tostring(nextOrder),
        operation = spec.operation, status = "QUEUED",
        workerId = spec.requiredWorkerId, baseId = spec.baseId,
        payload = spec.payload, requiredWorkerId = spec.requiredWorkerId,
    }
    orders[order.id] = order
    queued[#queued + 1] = spec
    return order
end

function Work.Queries.Get(id) return orders[id] end
function Work.RegisterTargetProvider(operation, handler)
    Work.TargetProviders = Work.TargetProviders or {}
    Work.TargetProviders[operation] = handler
end
function Work.RegisterCollection(operation, handler)
    Work.CollectionHandlers = Work.CollectionHandlers or {}
    Work.CollectionHandlers[operation] = handler
end
function Work.RegisterCompletion(operation, handler)
    Work.CompletionHandlers[operation] = handler
end
function Work.RegisterCompletionRecovery(operation, handler)
    Work.CompletionRecoveryHandlers[operation] = handler
end

local record
PNC = {
    Core = {},
    Inventory = {},
    Equipment = {
        AcquirePrimaryLease = function(worker, _, itemID)
            worker.inventory.equipped.primary = itemID
            return true, "acquired"
        end,
        ReleasePrimaryLease = function(worker)
            worker.inventory.equipped.primary = "hammer"
            return true, "released"
        end,
    },
    WorkService = Work,
    StorageAccessPolicy = {
        Resolve = function() return { id = "stockpile-1" } end,
    },
    ColonyStorageService = {},
    Registry = {
        Get = function(id)
            return tostring(id) == tostring(record and record.id) and record
                or nil
        end,
    },
    StockpileAccessService = {},
}

T.load("ProjectHoomans", "shared",
    "PNC/Core/Production/WorkDefinition/PNC_WorkDefinitions_Constants.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Production/WorkItems/PNC_JobRequirements.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Production/WorkItems/PNC_WorkItemService.lua")

PNC.WorkItemService.RegisterValidator("lumber_tool", function(_, item)
    return string.find(string.lower(tostring(item.type or "")), "axe", 1, true)
        ~= nil and tonumber(item.cond or 1) > 0
end)

function PNC.ColonyStorageService.ReserveProductionMaterials()
    return {
        id = "reservation-1",
        requirements = {{ selectedType = "Base.Axe" }},
    }
end
function PNC.ColonyStorageService.CollectProductionReservation(_, _, _, _, worker)
    worker.inventory.items.axe = {
        id = "axe", type = "Base.Axe", cond = 10,
    }
    return true, {
        itemIds = { "axe" }, records = {{ id = "axe-record" }},
        fullType = "Base.Axe",
    }
end
function PNC.ColonyStorageService.ReturnCollectedProductionRecords()
    return true
end
function PNC.ColonyStorageService.ReleaseProductionReservation()
    return true
end

T.load("ProjectHoomans", "server",
    "PNC/Production/PNC_WorkItemService_Logistics.lua")

record = {
    id = "npc-1", baseId = "base-1", affiliation = {}, runtime = {},
    inventory = {
        revision = 1, equipped = { primary = "hammer" },
        items = { hammer = { id = "hammer", type = "Base.Hammer" } },
    },
}

local mainOrder = {
    id = "lumber-1", operation = "LUMBER", requiredWorkerId = record.id,
    baseId = "base-1", colonyId = "colony-1", factionId = "faction-1",
    priority = 90,
}
local ready, reason = PNC.WorkItemService.PrepareOrder(mainOrder)
T.equal(ready, false, "missing work item queues pickup")
T.equal(reason, "WAITING_FOR_WORK_ITEM", "pickup wait reason is explicit")
T.equal(#queued, 1, "one pickup transaction is queued")
T.equal(queued[1].operation, "WORK_ITEM_PICKUP", "pickup operation is shared")
T.equal(queued[1].payload.selectedType, "Base.Axe",
    "pickup preserves the selected candidate type")

local pickup = orders["work-item-order-1"]
local completed, completionReason = Work.CompletionHandlers.WORK_ITEM_PICKUP(
    pickup)
T.equal(completed, true, "pickup completion commits the held item")
T.equal(completionReason, nil, "pickup completion has no error")
T.equal(record.inventory.equipped.primary, "axe",
    "pickup equips the exact collected item")
T.equal(PNC.WorkItemService.GetLease(record, "LUMBER").sourceStorageID,
    "stockpile-1", "lease retains storage provenance")
T.equal(PNC.WorkItemService.PrepareOrder(mainOrder), true,
    "main work becomes ready after pickup")

local released, releaseReason = PNC.WorkItemService.Release(record, "LUMBER")
T.equal(released, true, "work release queues the return transaction")
T.equal(releaseReason, "released", "lease release reason is preserved")
T.equal(#queued, 2, "one return transaction is queued")
T.equal(queued[2].operation, "WORK_ITEM_RETURN", "return operation is shared")
T.equal(queued[2].payload.storageID, "stockpile-1",
    "return targets the original storage")
T.equal(queued[2].payload.itemIDs[1], "axe",
    "return carries the exact item identity")
T.equal(record.runtime.workItems.LUMBER, nil,
    "released work item runtime is cleared")

-- Chunk F1A: unassigned work orders (requiredWorkerId = nil) pass
-- workerAvailable / CanAssign when colony storage holds a valid tool,
-- queue WORK_ITEM_PICKUP upon assignment, and resume once collected.
T.addPackagePaths()

local storageCounts = {
    ["Base.Axe"] = 1,
    ["Base.FishingRod"] = 1,
    ["Base.Trowel"] = 1,
}
function PNC.ColonyStorageService.CountProductionAvailable(_, itemTypes)
    local total = 0
    for index = 1, #(itemTypes or {}) do
        total = total + (tonumber(storageCounts[itemTypes[index]]) or 0)
    end
    return total
end

local canLumber = PNC.WorkItemService.CanAcquireFromStorage(record, "LUMBER")
local canFishing = PNC.WorkItemService.CanAcquireFromStorage(record, "FISHING")
local canFarming = PNC.WorkItemService.CanAcquireFromStorage(record, "FARMING")
T.truthy(canLumber, "CanAcquireFromStorage passes for LUMBER when storage has axe")
T.truthy(canFishing, "CanAcquireFromStorage passes for FISHING when storage has rod")
T.truthy(canFarming, "CanAcquireFromStorage passes for FARMING when storage has trowel")

storageCounts["Base.Trowel"] = 0
local missingFarming, missingReason =
    PNC.WorkItemService.CanAcquireFromStorage(record, "FARMING")
T.falsy(missingFarming, "CanAcquireFromStorage fails when storage lacks tool")
T.equal(missingReason, "NO_WORK_ITEM_SUPPLY", "missing tool reports supply error")
storageCounts["Base.Trowel"] = 1

-- Wire real WorkService + WorkRepository to verify unassigned workerAvailable,
-- UsesFatigueGate, and automatic WORK_ITEM_PICKUP on assignment.
local clock = 5000
PNC.Core.Now = function() return clock end
PNC.Core.DeepCopy = function(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for k, v in pairs(value) do copy[k] = PNC.Core.DeepCopy(v) end
    return copy
end
PNC.OrderSystem = { SetOrder = function(npc, spec) npc.orderSpec = spec end }
PNC.WorkFatigueGate = {
    Check = function(npc)
        if tonumber(npc and npc.fatigue) and tonumber(npc.fatigue) >= 0.90 then
            return false, "WORKER_NEEDS_REST"
        end
        return true
    end,
}

local emptyWorker = {
    id = "npc-empty", baseId = "base-1", alive = true, fatigue = 0.2,
    affiliation = { factionID = "f1", communityID = "c1" },
    runtime = {},
    inventory = { revision = 1, equipped = {}, items = {} },
}
PNC.Registry = {
    Data = { [emptyWorker.id] = emptyWorker },
    Get = function(id) return PNC.Registry.Data[tostring(id)] end,
    ForEach = function(cb)
        for _, npc in pairs(PNC.Registry.Data) do cb(npc) end
    end,
    GetLiveZombie = function() return nil end,
}

T.load("ProjectHoomans", "shared",
    "PNC/Core/Production/WorkDefinition/PNC_WorkDefinitions.lua")
T.truthy(PNC.WorkDefinitions.UsesFatigueGate("LUMBER"),
    "UsesFatigueGate enabled for LUMBER")
T.truthy(PNC.WorkDefinitions.UsesFatigueGate("CORPSE_HAUL"),
    "UsesFatigueGate enabled for CORPSE_HAUL")
T.truthy(PNC.WorkDefinitions.UsesFatigueGate("FISHING"),
    "UsesFatigueGate enabled for FISHING")
T.truthy(PNC.WorkDefinitions.UsesFatigueGate("FARMING"),
    "UsesFatigueGate enabled for FARMING")
T.falsy(PNC.WorkDefinitions.UsesFatigueGate("CRAFT"),
    "UsesFatigueGate disabled for CRAFT")

local WorkRepository = T.load("ProjectHoomans", "server",
    "PNC/Production/PNC_WorkRepository.lua")
WorkRepository.Import(nil)
local RealWork = T.load("ProjectHoomans", "server",
    "PNC/Production/PNC_WorkService.lua")
RealWork.ClaimsByStation, RealWork.ClaimsByWorker = {}, {}
RealWork.RegisterTargetProvider("FARMING", function(order)
    return {
        ok = true,
        componentId = "farming:" .. tostring(order.id),
        target = { x = 12, y = 14, z = 0 },
    }
end)
RealWork.RegisterCompletion("FARMING", function() return true end)

-- Reload Logistics bound to RealWork so WORK_ITEM_PICKUP queues in RealWork.
package.loaded["PNC/Production/PNC_WorkItemService_Logistics"] = nil
T.load("ProjectHoomans", "server",
    "PNC/Production/PNC_WorkItemService_Logistics.lua")

PNC.WorkItemService.RegisterValidator("farming_tool", function(_, item)
    return tostring(item and item.type or "") == "Base.Trowel"
end)
function PNC.ColonyStorageService.ReserveProductionMaterials(_, reqs)
    local itemTypes = reqs and reqs[1] and reqs[1].itemTypes or {}
    return {
        id = "res-farm-1",
        requirements = {{ selectedType = itemTypes[2] or "Base.Trowel" }},
    }
end
function PNC.ColonyStorageService.CollectProductionReservation(_, _, _, _, worker)
    worker.inventory.items.trowel = {
        id = "trowel", type = "Base.Trowel", cond = 10,
    }
    return true, {
        itemIds = { "trowel" }, records = {{ id = "trowel-rec" }},
        fullType = "Base.Trowel",
    }
end

local farmOrder = RealWork.Commands.Queue({
    operation = "FARMING",
    colonyId = "c1", factionId = "f1", baseId = "base-1",
    requiredWorkerId = nil, requiredWork = 1, priority = 30,
})
T.truthy(farmOrder, "unassigned FARMING order queued")

emptyWorker.fatigue = 0.95
local fatiguedOk, fatiguedReason = RealWork.Queries.CanAssign(
    farmOrder.id, emptyWorker.id)
T.falsy(fatiguedOk, "fatigued worker rejected by UsesFatigueGate for FARMING")
T.equal(fatiguedReason, "WORKER_NEEDS_REST", "fatigue gate rejection reason")
emptyWorker.fatigue = 0.2

local canAssignEmpty, assignErr = RealWork.Queries.CanAssign(
    farmOrder.id, emptyWorker.id)
T.equal(canAssignEmpty, true,
    assignErr or "empty-inventory worker can claim unassigned FARMING order via storage")

local assignedNow, assignReason = RealWork.Commands.Assign(
    farmOrder.id, emptyWorker.id)
T.equal(assignedNow, false,
    "assigning unassigned order without tool defers to WORK_ITEM_PICKUP")
T.equal(assignReason, "WAITING_FOR_WORK_ITEM",
    "assignment reports WAITING_FOR_WORK_ITEM handoff")

local updatedFarmOrder = RealWork.Queries.Get(farmOrder.id)
T.equal(updatedFarmOrder.status, "WAITING_RESOURCE",
    "main order waits in WAITING_RESOURCE while tool pickup runs")
T.equal(updatedFarmOrder.requiredWorkerId, emptyWorker.id,
    "main order pins auto-assigned worker during pickup")
T.truthy(updatedFarmOrder.autoAssignedWorker,
    "main order marks autoAssignedWorker for safe fallback release")

local pickupOrderId = emptyWorker.runtime.workItemPickups.FARMING
    and emptyWorker.runtime.workItemPickups.FARMING.orderID
T.truthy(pickupOrderId, "WORK_ITEM_PICKUP order queued and tracked on worker")
local pickupOrder = WorkRepository.Get(pickupOrderId)
T.equal(pickupOrder.operation, "WORK_ITEM_PICKUP",
    "queued logistics order is WORK_ITEM_PICKUP")
T.equal(pickupOrder.requiredWorkerId, emptyWorker.id,
    "pickup order targets claiming worker")

local pickupAssigned = RealWork.Commands.Assign(pickupOrderId, emptyWorker.id)
T.equal(pickupAssigned, true, "worker claims queued WORK_ITEM_PICKUP")
local pickupDone = RealWork.Commands.AddProgress(
    pickupOrderId, emptyWorker.id, 1)
T.equal(pickupDone, true, "WORK_ITEM_PICKUP completes")

local wokenOrder = RealWork.Queries.Get(farmOrder.id)
T.equal(wokenOrder.status, "WAITING_FOR_WORKER",
    "main order wakes to WAITING_FOR_WORKER once tool is picked up")
local finalAssign = RealWork.Commands.Assign(farmOrder.id, emptyWorker.id)
T.equal(finalAssign, true,
    "worker now claims main FARMING order with acquired tool")
local farmDone = RealWork.Commands.AddProgress(
    farmOrder.id, emptyWorker.id, 1)
T.equal(farmDone, true, "main FARMING order completes")
local completedFarmOrder = RealWork.Queries.Get(farmOrder.id)
T.equal(completedFarmOrder.status, "COMPLETED",
    "completed FARMING order transitions to COMPLETED")
local hasReturnOrder = false
for _, candidate in pairs(WorkRepository.State.byId) do
    if candidate.operation == "WORK_ITEM_RETURN"
        and candidate.requiredWorkerId == emptyWorker.id
    then
        hasReturnOrder = true
    end
end
T.truthy(hasReturnOrder,
    "completing unassigned FARMING order queues WORK_ITEM_RETURN")

T.finish("pnc_work_item_logistics_smoke")
