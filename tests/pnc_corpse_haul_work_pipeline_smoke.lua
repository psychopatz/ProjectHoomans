local T = require "tests/support/test"

T.addPackagePaths()

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local clock, sequence = 1000, 0
local atHome = false
local manualLogs = {}
local actionStates = {}
local pathResets = 0
local sceneStops = 0
local deepCopy
deepCopy = function(value)
    if type(value) ~= "table" then return value end
    local output = {}
    for key, item in pairs(value) do output[key] = deepCopy(item) end
    return output
end

local corpse = {
    x = 40, y = 40, z = 0,
    data = {
        PNC_DeathMarkerID = "dead:one",
        PNC_CorpseToken = "lifecycle:one",
        PNC_CorpseHaulToken = "corpse:one",
    },
}
local untrackedCorpse = { x = 40, y = 40, z = 0, data = {} }
function corpse:getX() return self.x end
function corpse:getY() return self.y end
function corpse:getZ() return self.z end
function corpse:setX(value) self.x = value end
function corpse:setY(value) self.y = value end
function corpse:setZ(value) self.z = value end
function corpse:getModData() return self.data end
function corpse:transmitModData() self.transmitted = true end
function corpse:getSquare() return self.square end
function untrackedCorpse:getX() return self.x end
function untrackedCorpse:getY() return self.y end
function untrackedCorpse:getZ() return self.z end
function untrackedCorpse:getModData() return self.data end

local squares
local gridLookups = 0
local body = {
    x = 5, y = 5, z = 0,
}
function body:getX() return self.x end
function body:getY() return self.y end
function body:getZ() return self.z end
function body:getSquare()
    return squares[tostring(math.floor(self.x)) .. ":"
        .. tostring(math.floor(self.y)) .. ":0"]
end

squares = {
    ["40:40:0"] = { corpses = {}, canReachTo = function() return true end },
    ["60:60:0"] = { corpses = {}, canReachTo = function() return true end },
}
for _, square in pairs(squares) do
    function square:removeCorpse(item)
        for index = #self.corpses, 1, -1 do
            if self.corpses[index] == item then table.remove(self.corpses, index) end
        end
        item.square = nil
    end
    function square:addCorpse(item)
        self.corpses[#self.corpses + 1] = item
        item.square = self
    end
end
squares["40:40:0"].corpses = { corpse, untrackedCorpse }
corpse.square = squares["40:40:0"]
getCell = function()
    return { getGridSquare = function(_, x, y, z)
        gridLookups = gridLookups + 1
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
        Log = function(level, message)
            manualLogs[#manualLogs + 1] = {
                level = level, message = message,
            }
        end,
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
    PathService = {
        Commands = {
            Reset = function(record)
                pathResets = pathResets + 1
                if record and record.runtime then
                    record.runtime.pathing = nil
                    record.runtime.moveIntent = nil
                    record.runtime.localNavigation = nil
                end
            end,
        },
    },
    AnimationScenes = {
        Stop = function(record)
            sceneStops = sceneStops + 1
            if record and record.runtime then
                record.runtime.animationScene = nil
            end
            return true
        end,
    },
    HomeDutyService = {
        IsAtHome = function() return atHome end,
        IsReturningHome = function() return false end,
        GetBase = function() return nil end,
    },
    BodyLifecycle = {
        Internal = {
            forEachCorpse = function(square, callback)
                for _, item in ipairs(square and square.corpses or {}) do
                    callback(item)
                end
            end,
            stampCorpse = function() return true end,
            moveCorpse = function(item, destination, x, y, z)
                local source = item.square
                source:removeCorpse(item, false)
                item.x, item.y, item.z = x + 0.5, y + 0.5, z
                destination:addCorpse(item, false)
                return true
            end,
            followCorpse = function(item, x, y, z)
                local source = item.square
                local destination = squares[tostring(math.floor(x)) .. ":"
                    .. tostring(math.floor(y)) .. ":"
                    .. tostring(math.floor(z))]
                if not source or not destination then
                    return false, "CORPSE_FOLLOW_DESTINATION_UNAVAILABLE"
                end
                if source ~= destination then
                    source:removeCorpse(item, false)
                    destination:addCorpse(item, false)
                end
                item.x, item.y, item.z = x, y, z
                return true
            end,
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
PNC.WorkSequence = {
    Status = function(_, order)
        return actionStates[order.phase] or "pending"
    end,
    GetState = function() return nil end,
    Reset = function() end,
}

PNC.BaseService = {
    Get = function(id)
        return tostring(id) == "base:one"
            and PNC.SettlementRepository.State.bases["base:one"] or nil
    end,
    GetForColony = function(id)
        return tostring(id) == "colony:one"
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
-- Keep the pipeline deterministic while still exercising the visible-carry
-- phase; the low-level world-transfer smoke covers cross-tile membership.
CorpseService.CORPSE_CARRY_OFFSET = 0

local lifecycleOnlyCorpse = {
    data = { PNC_CorpseToken = "lifecycle:only" },
}
function lifecycleOnlyCorpse:getModData() return self.data end
T.falsy(CorpseService.GetCorpseToken(lifecycleOnlyCorpse, false),
    "persistent lifecycle identity is not treated as a haul reservation")
local generatedHaulToken = CorpseService.GetCorpseToken(
    lifecycleOnlyCorpse, true)
T.truthy(generatedHaulToken,
    "a haul reservation gets its own token when needed")
T.equal(lifecycleOnlyCorpse.data.PNC_CorpseHaulToken, generatedHaulToken,
    "haul reservation is stored in the haul-specific field")

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
local totalCorpses, eligibleCorpses = CorpseService.CountCorpsesInRegion(
    PNC.SettlementRepository.State.bases["base:one"].corpseHaul.sourceRegion)
T.equal(totalCorpses, 2, "source zone reports every corpse object")
T.equal(eligibleCorpses, 2,
    "ordinary human corpses are eligible without a Hoomans death marker")
T.falsy(untrackedCorpse.data.PNC_CorpseHaulToken,
    "corpse counting does not stamp haul tokens")
local cachedTotal, cachedEligible = CorpseService.GetSourceCorpseCounts(
    PNC.SettlementRepository.State.bases["base:one"])
local lookupsAfterCount = gridLookups
local cachedTotalAgain, cachedEligibleAgain = CorpseService.GetSourceCorpseCounts(
    PNC.SettlementRepository.State.bases["base:one"])
T.equal(cachedTotal, 2, "source count cache reports physical corpses")
T.equal(cachedEligible, 2, "source count cache reports eligible corpses")
T.equal(cachedTotalAgain, cachedTotal,
    "source count cache returns the same physical count")
T.equal(cachedEligibleAgain, cachedEligible,
    "source count cache returns the same eligible count")
T.equal(gridLookups, lookupsAfterCount,
    "source count cache avoids a second world scan")

CorpseService.Pump(1000)
local order = T.truthy(Work.Queries.List()[1],
    "corpse scan creates a durable work order")
T.equal(order.operation, "CORPSE_HAUL",
    "scanner queues the corpse operation in WorkService")
T.equal(order.payload.sourceX, 40, "queued source remains outside the home base")
T.equal(order.payload.dropX, 60, "queued destination remains outside the home base")
T.falsy(untrackedCorpse.data.PNC_CorpseHaulToken,
    "corpse discovery does not stamp unselected corpses")
CorpseService.Pump(3000)
local pendingCorpseOrders = 0
for _, queuedOrder in ipairs(Work.Queries.List()) do
    if queuedOrder.operation == "CORPSE_HAUL"
        and queuedOrder.status ~= Definitions.STATUS.COMPLETED
        and queuedOrder.status ~= Definitions.STATUS.CANCELLED
    then
        pendingCorpseOrders = pendingCorpseOrders + 1
    end
end
T.equal(pendingCorpseOrders, 1,
    "automatic corpse hauling keeps one pending order per base")

local candidates = Provider.GetCandidates(record.id)
T.equal(#candidates, 0, "away resident cannot receive home-only corpse work")
local awayManual, awayManualReason = CorpseService.RequestManual(record)
T.falsy(awayManual, "away resident cannot manually start corpse work")
T.equal(awayManualReason, "NPC_NOT_AT_HOME",
    "home authorization remains separate from corpse eligibility")

atHome = true
record.allowedJobs = { CorpseHaul = false }
local forced, forcedReason = CorpseService.RequestManual(record)
T.truthy(forced, "manual corpse command promotes the queued work order")
T.equal(forcedReason, "CORPSE_HAUL_ORDER_FORCED",
    "manual corpse command returns a stable result")
T.truthy(#manualLogs > 0 and string.find(
    manualLogs[#manualLogs].message,
    "reason=CORPSE_HAUL_ORDER_FORCED",
    1,
    true
), "manual corpse command logs its result reason")
T.equal(Work.Queries.Get(order.id).priority, 100,
    "manual corpse order uses forced priority")
T.equal(Work.Queries.Get(order.id).requiredWorkerId, record.id,
    "manual corpse order binds to the selected worker")
T.equal(Work.Queries.Get(order.id).manual, true,
    "manual corpse order is marked as manual")
candidates = Provider.GetCandidates(record.id)
T.equal(#candidates, 1, "home resident receives generic work candidate")
T.equal(candidates[1].precedence, "FORCED_ORDER",
    "manual corpse order uses the forced task precedence")
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

body.x, body.y = 40, 40
T.equal(lease.taskId, order.id, "lease points at the durable corpse task")
T.truthy(CorpseService.GetTask(lease.taskId),
    "durable corpse task is available to the sequence boundary")
body.x, body.y = 40, 40
T.truthy(Provider.Tick(lease), "source approach is dispatched by work")
T.equal(Work.Queries.Get(order.id).phase, "GRAB_PENDING",
    "grab animation remains an operation phase on the durable order")
actionStates.GRAB_PENDING = "completed"
T.truthy(Provider.Tick(lease), "grab animation completion is dispatched by work")
T.equal(Work.Queries.Get(order.id).phase, "CARRYING",
    "completed grab advances to visible corpse carry")
body.x, body.y = 60, 60
T.truthy(Provider.Tick(lease), "visible corpse carry is dispatched by work")
T.equal(Work.Queries.Get(order.id).phase, "DROP_PENDING",
    "drop animation remains an operation phase on the durable order")
actionStates.DROP_PENDING = "completed"
local destinationSquare = squares["60:60:0"]
squares["60:60:0"] = nil
T.truthy(Provider.Tick(lease),
    "drop waits instead of cancelling while the destination chunk is unloaded")
T.equal(Work.Queries.Get(order.id).blockedReason,
    "DESTINATION_CHUNK_LOADING",
    "unloaded destination records a retryable world reason")
squares["60:60:0"] = destinationSquare
T.truthy(Provider.Tick(lease), "drop animation completion moves the corpse")
T.equal(Work.Queries.Get(order.id).status, Definitions.STATUS.COMPLETED,
    "corpse completion uses the shared WorkService completion path")
T.equal(corpse.square, squares["60:60:0"],
    "completed corpse hauling moves the same world corpse to the dump zone")
T.equal(corpse.x, 60.5, "corpse transfer preserves the destination position")
T.equal(corpse.data.PNC_CorpseToken, "lifecycle:one",
    "corpse hauling preserves the lifecycle identity token")
T.falsy(corpse.data.PNC_CorpseHaulToken,
    "completed corpse hauling clears its temporary haul token")
T.falsy(record.runtime.workOrderId, "completed work releases the shared worker claim")
T.truthy(pathResets > 0,
    "completed corpse hauling resets the live movement lane")
T.falsy(record.runtime.followState,
    "completed corpse hauling clears stale follow ownership state")
Leases.Release(lease.leaseId, "test_complete")

-- Cancellation also goes through the durable operation cleanup hook, including
-- the corpse marker that protects lifecycle processing during the sequence.
record.allowedJobs = nil
corpse.x, corpse.y = 40, 40
squares["40:40:0"].corpses = { corpse }
squares["60:60:0"].corpses = {}
corpse.square = squares["40:40:0"]
CorpseService.Pump(5000)
T.falsy(Work.Queries.Get(order.id),
    "terminal corpse orders are pruned from the durable work repository")
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
record.runtime.animationScene = { id = "production.corpse_grab" }
record.runtime.workSequence = { sceneId = "production.corpse_grab" }
record.runtime.pathing = { phase = "active" }
record.runtime.moveIntent = { kind = "move" }
record.runtime.followState = { ownerMoving = true }
local resetsBeforeCancel = pathResets
local scenesBeforeCancel = sceneStops
T.truthy(Work.Commands.Cancel(orderTwo.id, "test_cancel"),
    "corpse cancellation uses WorkService")
T.equal(Work.Queries.Get(orderTwo.id).status, Definitions.STATUS.CANCELLED,
    "cancelled corpse order is terminal in WorkService")
T.falsy(record.runtime.workOrderId, "cancellation releases the shared worker claim")
T.falsy(corpse.data.PNC_CorpseHaulTaskId,
    "cancellation clears the corpse lifecycle marker")
T.truthy(pathResets > resetsBeforeCancel,
    "cancellation resets the live movement lane")
T.truthy(sceneStops > scenesBeforeCancel,
    "cancellation stops the active corpse interaction scene")
T.falsy(record.runtime.followState,
    "cancellation clears stale follow ownership state")
Leases.Release(leaseTwo.leaseId, "test_cancel")

-- A manual request must also be able to create the durable order directly
-- when the automatic scanner has not queued it yet.
corpse.x, corpse.y = 40, 40
squares["40:40:0"].corpses = { corpse }
squares["60:60:0"].corpses = {}
local created, createdReason, createdOrder = CorpseService.RequestManual(record)
T.truthy(created, "manual corpse command creates an order when none is queued")
T.equal(createdReason, "CORPSE_HAUL_ORDER_FORCED",
    "direct manual corpse order returns a stable result")
T.equal(createdOrder.priority, 100,
    "direct manual corpse order uses forced priority")
T.equal(createdOrder.requiredWorkerId, record.id,
    "direct manual corpse order binds to the selected worker")
T.equal(createdOrder.payload.sourceX, 40,
    "direct manual corpse order preserves the external source zone")

local createdCandidates = Provider.GetCandidates(record.id)
local createdAssignment = T.truthy(Provider.Assign(createdCandidates[1]),
    "manual corpse order can claim a worker before pause")
local createdLease = T.truthy(Leases.Create(
    createdCandidates[1],
    createdAssignment
), "paused corpse order receives a live lease")
body.x, body.y = 40, 40
T.truthy(Provider.Tick(createdLease),
    "paused-order setup records the active corpse operation")
actionStates.GRAB_PENDING = "completed"
T.truthy(Provider.Tick(createdLease),
    "paused-order setup enters visible corpse carry")
T.equal(Work.Queries.Get(createdOrder.id).phase, "CARRYING",
    "paused-order setup records the carry phase")
T.truthy(Provider.Tick(createdLease),
    "paused-order setup attaches the corpse to the worker projection")
record.runtime.animationScene = { id = "production.corpse_drop" }
record.runtime.workSequence = { sceneId = "production.corpse_drop" }
record.runtime.pathing = { phase = "active" }
record.runtime.moveIntent = { kind = "move" }
local resetsBeforePause = pathResets
local scenesBeforePause = sceneStops
T.truthy(Work.Commands.Pause(createdOrder.id, true),
    "pausing corpse work uses the operation cleanup boundary")
T.equal(Work.Queries.Get(createdOrder.id).status, Definitions.STATUS.PAUSED,
    "paused corpse order remains durable")
T.truthy(pathResets > resetsBeforePause,
    "pausing corpse work resets the live movement lane")
T.truthy(sceneStops > scenesBeforePause,
    "pausing corpse work stops the active interaction scene")
T.falsy(record.runtime.followState,
    "pausing corpse work clears stale follow ownership state")
T.equal(corpse.data.PNC_CorpseHaulToken,
    createdOrder.payload.haulToken,
    "pausing visible carry preserves the corpse reservation for reassignment")
T.equal(corpse.data.PNC_CorpseHaulTaskId,
    createdOrder.id,
    "pausing visible carry preserves the lifecycle protection marker")
Leases.Release(createdLease.leaseId, "test_pause")

local cleared, clearReason = CorpseService.ClearConfiguration({}, {
    baseId = "base:one",
})
T.truthy(cleared, "corpse regions can be cleared")
T.equal(clearReason, "CORPSE_HAUL_ZONES_CLEARED",
    "corpse region clearing returns a stable result")

T.finish("pnc_corpse_haul_work_pipeline_smoke")
