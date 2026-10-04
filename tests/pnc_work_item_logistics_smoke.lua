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
T.load("ProjectHoomans", "shared", "PNC/Core/Jobs/PNC_JobRequirements.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Jobs/PNC_WorkItemService.lua")

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

T.finish("pnc_work_item_logistics_smoke")
