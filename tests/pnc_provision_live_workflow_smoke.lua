local T = require "tests/support/test"

T.addPackagePaths()

local function deepCopy(value)
    if type(value) ~= "table" then return value end
    local output = {}
    for key, entry in pairs(value) do output[key] = deepCopy(entry) end
    return output
end

local now = 1000
local homeRequests = 0
local returningHome = false
local atHome = false
PNC = {
    Core = { Now = function() return now end, DeepCopy = deepCopy },
    Registry = { Data = {} },
    OrderSystem = { SetOrder = function(record, order)
        record.orderSpec = order
    end },
    BaseService = { GetForColony = function(id)
        return id == "colony:1" and { id = "base:1" } or nil
    end },
    StockpileAccessService = { FindNearest = function()
        return { id = "stockpile:1", x = 20, y = 21, z = 0 }
    end },
    ColonyStorageService = {},
    HomeDutyService = {
        IsAtHome = function() return atHome end,
        IsReturningHome = function() return returningHome end,
        SendHome = function()
            homeRequests = homeRequests + 1
            return true, "RETURNING_HOME"
        end,
    },
}

function PNC.Registry.Get(id) return PNC.Registry.Data[tostring(id)] end
function PNC.Registry.GetLiveZombie(id)
    return id == "live_provisioner" and {
        getX = function() return 3 end,
        getY = function() return 4 end,
        getZ = function() return 0 end,
    } or nil
end

PNC.Registry.Data.live_provisioner = {
    id = "live_provisioner", alive = true,
    affiliation = { factionID = "faction:1", communityID = "colony:1" },
    x = 3, y = 4, z = 0, runtime = {},
}

local Definitions = require "PNC/Core/Production/PNC_WorkDefinitions"
local Repository = require "PNC/Production/PNC_WorkRepository"
Repository.Import(nil)
local Work = require "PNC/Production/PNC_WorkService"
Work.ClaimsByStation, Work.ClaimsByWorker = {}, {}

local reservation = { id = "production:provision:1" }
local reserved = true
local collected = 0
local released = 0
local reservationCalls = 0
PNC.ColonyStorageService.ReserveProductionMaterials = function()
    reservationCalls = reservationCalls + 1
    reserved = true
    return reservation
end
PNC.ColonyStorageService.GetProductionReservation = function(id)
    return reserved and id == reservation.id and reservation or nil
end
PNC.ColonyStorageService.ReleaseProductionReservation = function(id)
    if id == reservation.id then reserved, released = false, released + 1 end
    return true
end
PNC.ColonyStorageService.CollectProductionReservation = function()
    reserved, collected = false, collected + 1
    return true, { itemIds = { "item:1" }, records = { { quantity = 1 } } }
end

local Scheduler = PNC.ProvisionScheduler or { Internal = {} }
PNC.ProvisionScheduler = Scheduler
T.load("ProjectHoomans", "server",
    "PNC/Provision/ProvisionScheduler/PNC_ProvisionScheduler_WorkBridge.lua")
T.truthy(Scheduler.BindWorkService(Work), "provision work bridge bound")

local record = PNC.Registry.Data.live_provisioner
local storage = {
    id = "storage:1", settlementId = "colony:1",
    ownerFactionId = "faction:1",
}
local state = {}
atHome = true
record.orderSpec = { kind = "follow" }
local blocked, blockedReason = Scheduler.QueueLivePickup(record, storage, {
    purpose = "PROVISION", resourceKind = "FOOD", priority = 80,
}, {
    { descriptor = { fullType = "Base.Apple" }, quantity = 1 },
}, {})
T.equal(blocked, nil, "following NPC cannot queue provision pickup")
T.equal(blockedReason, "provision_blocked_while_following",
    "following provision blocker")
T.equal(reservationCalls, 0,
    "following provision blocker runs before storage reservation")
record.orderSpec = nil
local queued, reason, details = Scheduler.QueueLivePickup(record, storage, {
    purpose = "PROVISION", resourceKind = "FOOD", priority = 80,
}, {
    { descriptor = { fullType = "Base.Apple" }, quantity = 1 },
}, state)
T.equal(queued, false, "live provision waits for stockpile pickup")
T.equal(reason, "provision_pickup_queued", "live provision queue reason")
T.truthy(details and details.workOrderId, "live provision work order id")
T.equal(state.phase, "TRAVEL_TO_STOCKPILE", "live provision phase")
atHome = false

local order = Work.Queries.Get(details.workOrderId)
T.equal(order.operation, "PROVISION_PICKUP", "provision work operation")
T.equal(order.locationPolicy.start, "HOME",
    "provision pickup starts at home")
T.equal(order.locationPolicy.execution, "HOME",
    "provision pickup executes at home")
T.equal(order.locationPolicy.returnHome, "HOME",
    "provision pickup returns an away worker home before retrying")
T.equal(order.status, Definitions.STATUS.QUEUED, "provision order queued")
-- Tasking owns the eventual claim once its provider is installed. WorkService
-- must still initiate the home handoff for a home-only order.
local taskingEvents = 0
PNC.Tasking = {
    Providers = { work = {} },
    Commands = {},
    Events = { Emit = function() taskingEvents = taskingEvents + 1 end },
}
returningHome = true
local workerAvailable, workerReason = Work.Internal.workerAvailable(record, order)
T.falsy(workerAvailable,
    "provision does not reacquire a worker already returning home")
T.equal(workerReason, "WORKER_RETURNING_HOME",
    "provision reports the worker return-home gate")
local assignmentDiagnostics = Work.Queries.BuildAssignmentDiagnostics(
    record.id)
T.equal(assignmentDiagnostics.totalOrders, 1,
    "assignment diagnostics count the durable order")
T.equal(assignmentDiagnostics.assignableOrders, 1,
    "assignment diagnostics count the waiting order")
T.equal(assignmentDiagnostics.eligibleOrders, 0,
    "assignment diagnostics reject the returning worker")
T.equal(assignmentDiagnostics.rejectionCounts.WORKER_RETURNING_HOME, 1,
    "assignment diagnostics retain the rejection reason")
returningHome = false
Work.Tick(now + 1)
order = Work.Queries.Get(order.id)
T.equal(order.status, Definitions.STATUS.WAITING_FOR_WORKER,
    "away provision waits for a home worker")
T.equal(order.blockedReason, "WORKER_RETURNING_HOME",
    "away provision reports the return-home handoff")
T.equal(homeRequests, 1,
    "away provision redirects the NPC home")
T.truthy(taskingEvents > 0,
    "home handoff wakes the tasking arbiter")
-- The remainder of this workflow exercises the legacy direct scheduler path;
-- the assertions above cover the task-provider handoff itself.
PNC.Tasking.Providers.work = nil
atHome = true
T.truthy(Work.Commands.Assign(order.id, record.id),
    "home worker claims the provision order")
atHome = false
Work.Tick(Work.NextPassAt + 1)
order = Work.Queries.Get(order.id)
T.equal(order.payload.reservationId, nil,
    "abandoned provision releases its storage reservation")
T.equal(homeRequests, 2,
    "abandoned provision redirects its worker home")
atHome = true
Work.Tick(Work.NextPassAt + 1)
order = Work.Queries.Get(order.id)
T.equal(order.status, Definitions.STATUS.TRAVEL_TO_STOCKPILE,
    "provision order starts at stockpile")
T.equal(record.orderSpec.phase, "COLLECT_INPUTS",
    "live provision targets stockpile first")
T.equal(record.orderSpec.x, 20, "stockpile x target")
T.equal(record.orderSpec.y, 21, "stockpile y target")

Work.Tick(now + 1)
T.equal(homeRequests, 2,
    "provision scheduler does not redirect a worker already at home")
T.equal(Work.Queries.Get(order.id).status,
    Definitions.STATUS.TRAVEL_TO_STOCKPILE,
    "provision scheduler preserved the stockpile travel phase")

T.truthy(Work.Commands.CollectInputs(order.id, record.id),
    "live provision collects at stockpile")
order = Work.Queries.Get(order.id)
T.equal(collected, 1, "provision storage transfer occurs at stockpile")
T.equal(order.status, Definitions.STATUS.TRAVEL_TO_STATION,
    "provision moves to completion phase after pickup")
T.equal(record.orderSpec.phase, "WORK_AT_STATION",
    "provision order leaves collection phase")

T.truthy(Work.Commands.AddProgress(order.id, record.id, 1),
    "live provision completes after pickup")
T.equal(Work.Queries.Get(order.id).status, Definitions.STATUS.COMPLETED,
    "provision order completed")
T.equal(released, 1, "abandoned provision released its reservation once")

T.finish("pnc_provision_live_workflow_smoke")
