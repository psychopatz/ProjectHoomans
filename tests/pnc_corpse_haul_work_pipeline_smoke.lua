local T = require "tests/support/test"

T.addPackagePaths()

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local clock, sequence = 1000, 0
local atHome = false
local deepCopy
deepCopy = function(value)
    if type(value) ~= "table" then return value end
    local output = {}
    for key, item in pairs(value) do output[key] = deepCopy(item) end
    return output
end

local corpse = {
    x = 40, y = 40, z = 0,
    data = { PNC_DeathMarkerID = "dead:one", PNC_CorpseHaulToken = "corpse:one" },
}
function corpse:getX() return self.x end
function corpse:getY() return self.y end
function corpse:getZ() return self.z end
function corpse:getModData() return self.data end
function corpse:transmitModData() self.transmitted = true end

local body = { x = 5, y = 5, z = 0, dragging = false }
function body:getX() return self.x end
function body:getY() return self.y end
function body:getZ() return self.z end
function body:isDraggingCorpse() return self.dragging end

local squares = {
    ["40:40:0"] = { corpses = { corpse } },
    ["60:60:0"] = { corpses = {} },
}
getCell = function()
    return { getGridSquare = function(_, x, y, z)
        return squares[tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z)]
    end }
end

package.preload["PsychopatzCore/World/PC_ZoneRegistry"] = function()
    return { get = function() return nil end }
end
package.preload["PsychopatzCore/World/PC_GridRegion"] = function()
    return {
        normalize = function(region) return region end,
        countTiles = function() return 1 end,
        validate = function(region) return true, nil, region end,
        isConnected = function() return true end,
        containsPoint = function() return true end,
    }
end

PNC = {
    Core = {
        Now = function() return clock end,
        DeepCopy = deepCopy,
        GenerateID = function(prefix)
            sequence = sequence + 1
            return tostring(prefix) .. ":" .. tostring(sequence)
        end,
        Distance = function(x1, y1, x2, y2)
            local dx, dy = x1 - x2, y1 - y2
            return math.sqrt(dx * dx + dy * dy)
        end,
    },
    Tasking = {
        Providers = {},
        Commands = {},
        Events = { Emit = function() end },
    },
    Registry = { Data = {} },
    OrderSystem = {
        SetOrder = function(record, order) record.orderSpec = order end,
    },
    HomeDutyService = {
        IsAtHome = function() return atHome end,
        IsReturningHome = function() return false end,
    },
    BodyLifecycle = {
        Internal = {
            forEachCorpse = function(square, callback)
                for _, item in ipairs(square and square.corpses or {}) do
                    callback(item)
                end
            end,
            stampCorpse = function() return true end,
        },
    },
    SettlementRepository = {
        State = { bases = {
            ["base:one"] = {
                id = "base:one", colonyId = "colony:one",
                factionId = "faction:one", corpseHaul = {
                    sourceRegion = { levels = { [0] = { rows = {
                        [40] = { 40, 40 },
                    } } } },
                    destinationRegion = { levels = { [0] = { rows = {
                        [60] = { 60, 60 },
                    } } } },
                    revision = 1,
                },
            },
        } },
        Load = function() end,
        MarkDirty = function() end,
        Save = function() end,
    },
}

PNC.BaseService = {
    Get = function(id)
        return tostring(id) == "base:one"
            and PNC.SettlementRepository.State.bases["base:one"] or nil
    end,
}
PNC.BaseValidationService = { CanUse = function() return true end }

PNC.Registry.Get = function(id) return PNC.Registry.Data[tostring(id)] end
PNC.Registry.ForEach = function(callback)
    for _, record in pairs(PNC.Registry.Data) do callback(record) end
end
PNC.Registry.GetLiveZombie = function(id)
    return tostring(id) == "npc:one" and body or nil
end

local record = {
    id = "npc:one", alive = true, x = 5, y = 5, z = 0, runtime = {},
    affiliation = { factionID = "faction:one", communityID = "colony:one",
        communityRole = "resident" },
}
PNC.Registry.Data[record.id] = record

local Definitions = T.load("ProjectHoomans", "shared",
    "PNC/Core/Production/PNC_WorkDefinitions.lua")
local Repository = T.load("ProjectHoomans", "server",
    "PNC/Production/PNC_WorkRepository.lua")
Repository.Import(nil)
local Work = T.load("ProjectHoomans", "server",
    "PNC/Production/PNC_WorkService.lua")

PNC.Tasking.Commands.RegisterProvider = function(domain, provider)
    PNC.Tasking.Providers[domain] = provider
    return true
end
local Leases = T.load("ProjectHoomans", "server",
    "PNC/Tasking/PNC_TaskLeaseService.lua")
local Provider = T.load("ProjectHoomans", "server",
    "PNC/Tasking/PNC_WorkTaskProvider.lua")
local CorpseService = T.load("ProjectHoomans", "server",
    "PNC/Tasking/PNC_CorpseHaulService.lua")

local saved, saveReason = CorpseService.SetConfiguration({}, {
    baseId = "base:one",
    sourceRegion = { levels = { [0] = { rows = {
        [40] = { 40, 40 },
    } } } },
    destinationRegion = { levels = { [0] = { rows = {
        [60] = { 60, 60 },
    } } } },
})
T.truthy(saved, "corpse source and destination regions can be configured")
T.equal(saveReason, "CORPSE_HAUL_ZONES_SAVED",
    "corpse region configuration returns a stable result")

CorpseService.Pump(1000)
local order = T.truthy(Work.Queries.List()[1],
    "corpse scan creates a durable work order")
T.equal(order.operation, "CORPSE_HAUL",
    "scanner queues the corpse operation in WorkService")
T.equal(order.payload.sourceX, 40, "queued source remains outside the home base")
T.equal(order.payload.dropX, 60, "queued destination remains outside the home base")

local candidates = Provider.GetCandidates(record.id)
T.equal(#candidates, 0, "away resident cannot receive home-only corpse work")

atHome = true
candidates = Provider.GetCandidates(record.id)
T.equal(#candidates, 1, "home resident receives generic work candidate")
T.equal(candidates[1].sourceDomain, "work",
    "corpse candidate uses the shared work provider")
T.equal(candidates[1].sourceRef, order.id,
    "candidate references the durable work order")
T.truthy(Provider.Validate(candidates[1]), "generic candidate validates")

local assignment = T.truthy(Provider.Assign(candidates[1]),
    "generic provider claims a corpse world-object target")
local claimed = Work.Queries.Get(order.id)
T.equal(claimed.workerId, record.id, "work order owns the NPC claim")
T.equal(claimed.stationId, "corpse:corpse:one",
    "world-object claim has a durable collision key")
T.equal(claimed.phase, "SOURCE_APPROACH",
    "corpse operation starts with its source phase")
T.truthy(record.orderSpec and record.orderSpec.kind == "production_work",
    "NPC receives the shared production order kind")
T.equal(record.orderSpec.operation, "CORPSE_HAUL",
    "shared order carries the corpse operation")

local lease = T.truthy(Leases.Create(candidates[1], assignment),
    "shared task lease is created")
PNC.Tasking.Commands.Complete = function() return true end
PNC.Tasking.Commands.CancelLease = function() return true end
T.truthy(Provider.Tick(lease), "shared work provider ticks corpse operation")
T.equal(CorpseService.GetTask(order.id).haulToken, "corpse:one",
    "operation handler creates runtime corpse state under work id")
T.equal(record.runtime.corpseHaulTaskId, order.id,
    "lifecycle marker follows the durable work order")
T.equal(corpse.data.PNC_CorpseHaulTaskId, order.id,
    "corpse marker follows the durable work order")

-- Drive the operation through the shared provider tick. The real grapple
-- action boundary is covered separately; this verifies that the operation
-- phases are still owned by WorkService rather than a second task domain.
CorpseService.SendAction = function(_, _, action)
    if action == "grab" then body.dragging = true end
    if action == "drop" then
        body.dragging = false
        corpse.x, corpse.y = 60, 60
        squares["60:60:0"].corpses = { corpse }
    end
    return true
end
body.x, body.y = 40, 40
T.truthy(Provider.Tick(lease), "source grapple phase is dispatched by work")
T.equal(Work.Queries.Get(order.id).phase, "GRAB_PENDING",
    "grab remains an operation phase on the durable order")
body.x, body.y = 60, 60
T.truthy(Provider.Tick(lease), "destination travel phase is dispatched by work")
T.truthy(Provider.Tick(lease), "destination grapple phase is dispatched by work")
T.equal(Work.Queries.Get(order.id).phase, "DROP_PENDING",
    "drop remains an operation phase on the durable order")
T.truthy(Provider.Tick(lease), "drop completion is dispatched by work")
T.truthy(Provider.Tick(lease), "completed corpse work is released by work")
T.equal(Work.Queries.Get(order.id).status, Definitions.STATUS.COMPLETED,
    "corpse completion uses the shared WorkService completion path")
T.falsy(record.runtime.workOrderId, "completed work releases the shared worker claim")
Leases.Release(lease.leaseId, "test_complete")

-- Cancellation also goes through the durable operation cleanup hook, including
-- the corpse marker that protects lifecycle processing during a grapple.
corpse.x, corpse.y = 40, 40
squares["40:40:0"].corpses = { corpse }
squares["60:60:0"].corpses = {}
CorpseService.Pump(4000)
local orderTwo
for _, candidate in ipairs(Work.Queries.List()) do
    if candidate.status == Definitions.STATUS.QUEUED then
        orderTwo = candidate
        break
    end
end
T.truthy(orderTwo, "a later corpse scan queues a replacement work order")
local candidatesTwo = Provider.GetCandidates(record.id)
local assignmentTwo = T.truthy(Provider.Assign(candidatesTwo[1]),
    "replacement corpse uses the generic work provider")
local leaseTwo = T.truthy(Leases.Create(candidatesTwo[1], assignmentTwo),
    "replacement corpse receives a shared lease")
body.x, body.y = 5, 5
T.truthy(Provider.Tick(leaseTwo), "replacement work records its physical state")
T.truthy(Work.Commands.Cancel(orderTwo.id, "test_cancel"),
    "corpse cancellation uses WorkService")
T.equal(Work.Queries.Get(orderTwo.id).status, Definitions.STATUS.CANCELLED,
    "cancelled corpse order is terminal in WorkService")
T.falsy(record.runtime.workOrderId, "cancellation releases the shared worker claim")
T.falsy(corpse.data.PNC_CorpseHaulTaskId,
    "cancellation clears the corpse lifecycle marker")

local cleared, clearReason = CorpseService.ClearConfiguration({}, {
    baseId = "base:one",
})
T.truthy(cleared, "corpse regions can be cleared")
T.equal(clearReason, "CORPSE_HAUL_ZONES_CLEARED",
    "corpse region clearing returns a stable result")

T.finish("pnc_corpse_haul_work_pipeline_smoke")
