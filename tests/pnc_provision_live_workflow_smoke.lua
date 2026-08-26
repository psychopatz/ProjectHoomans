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
PNC.ColonyStorageService.ReserveProductionMaterials = function()
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
local queued, reason, details = Scheduler.QueueLivePickup(record, storage, {
    purpose = "PROVISION", resourceKind = "FOOD", priority = 80,
}, {
    { descriptor = { fullType = "Base.Apple" }, quantity = 1 },
}, state)
T.equal(queued, false, "live provision waits for stockpile pickup")
T.equal(reason, "provision_pickup_queued", "live provision queue reason")
T.truthy(details and details.workOrderId, "live provision work order id")
T.equal(state.phase, "TRAVEL_TO_STOCKPILE", "live provision phase")

local order = Work.Queries.Get(details.workOrderId)
T.equal(order.operation, "PROVISION_PICKUP", "provision work operation")
T.equal(order.requiresHome, true,
    "provision pickup is a home-bound work order")
T.equal(order.autoReturnHome, false,
    "provision pickup does not silently send an away worker home")
T.truthy(Work.Internal.requiresHome({ operation = "PROVISION_PICKUP" }),
    "legacy provision orders remain home-bound")
T.equal(order.status, Definitions.STATUS.QUEUED, "provision order queued")
returningHome = true
T.falsy(Work.Internal.workerAvailable(record, order),
    "provision does not reacquire a worker already returning home")
returningHome = false
Work.Tick(now + 1)
order = Work.Queries.Get(order.id)
T.equal(order.status, Definitions.STATUS.WAITING_FOR_WORKER,
    "away provision waits for a home worker")
T.equal(order.blockedReason, "NO_HOME_WORKER",
    "away provision reports the home vicinity requirement")
T.equal(homeRequests, 0,
    "away provision does not redirect the NPC home")
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
T.equal(homeRequests, 0,
    "provision scheduler did not redirect an away worker home")
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
T.equal(released, 0, "completed provision did not release a used reservation")

T.finish("pnc_provision_live_workflow_smoke")
