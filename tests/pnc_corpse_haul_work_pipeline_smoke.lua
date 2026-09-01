local T = require "tests/support/test"

T.addPackagePaths()

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local clock, sequence = 1000, 0
local atHome = false
local sentSync = {}
local manualLogs = {}
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
local untrackedCorpse = { x = 40, y = 40, z = 0, data = {} }
local player = { x = 5, y = 5, onlineID = 77 }
local grappleTarget = { onlineID = 501 }
function player:getX() return self.x end
function player:getY() return self.y end
function player:getOnlineID() return self.onlineID end
function grappleTarget:getOnlineID() return self.onlineID end
function corpse:getX() return self.x end
function corpse:getY() return self.y end
function corpse:getZ() return self.z end
function corpse:getModData() return self.data end
function corpse:transmitModData() self.transmitted = true end
function untrackedCorpse:getX() return self.x end
function untrackedCorpse:getY() return self.y end
function untrackedCorpse:getZ() return self.z end
function untrackedCorpse:getModData() return self.data end

local squares
local body = { x = 5, y = 5, z = 0, dragging = false }
function body:getX() return self.x end
function body:getY() return self.y end
function body:getZ() return self.z end
function body:isDraggingCorpse() return self.dragging end
function body:pickUpCorpse(targetCorpse)
    self.dragging, self.targetCorpse = true, targetCorpse
end
function body:getGrapplingTarget() return grappleTarget end
function body:setDoGrappleLetGo()
    self.dragging = false
    if self.targetCorpse then
        self.targetCorpse.x, self.targetCorpse.y = 60, 60
        squares["60:60:0"].corpses = { self.targetCorpse }
        squares["40:40:0"].corpses = {}
    end
end

squares = {
    ["40:40:0"] = { corpses = { corpse, untrackedCorpse } },
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
    Const = { CMD_CORPSE_HAUL_ACTION = "CorpseHaulAction" },
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
        ForEachPlayer = function(callback) callback(player) end,
        ResolvePlayerByOnlineID = function(id)
            return tonumber(id) == player.onlineID and player or nil
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
        },
    },
    Network = {
        Internal = {
            SendToPlayer = function(_, command, payload)
                sentSync[#sentSync + 1] = { command = command, args = payload }
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
isMultiplayer = function() return true end

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

CorpseService.Pump(1000)
local order = T.truthy(Work.Queries.List()[1],
    "corpse scan creates a durable work order")
T.equal(order.operation, "CORPSE_HAUL",
    "scanner queues the corpse operation in WorkService")
T.equal(order.payload.sourceX, 40, "queued source remains outside the home base")
T.equal(order.payload.dropX, 60, "queued destination remains outside the home base")

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
local physicalAssignment = {
    haulToken = order.payload.haulToken,
    sourceX = order.payload.sourceX, sourceY = order.payload.sourceY,
    sourceZ = order.payload.sourceZ, dropX = order.payload.dropX,
    dropY = order.payload.dropY, dropZ = order.payload.dropZ,
    destinationRegion = order.payload.destinationRegion,
}
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
    "durable corpse task is available to the action boundary")
T.equal(type(isMultiplayer), "function", "MP fixture exposes the session role")
T.equal(isMultiplayer(), true, "MP fixture identifies as multiplayer")
T.truthy(PNC.Network and PNC.Network.Internal
    and PNC.Network.Internal.SendToPlayer,
    "MP fixture exposes the corpse sync transport")
T.equal(type(PNC.Network.Internal.SendToPlayer), "function",
    "MP fixture exposes a callable corpse sync transport")
T.truthy(CorpseService.SendAction(lease, physicalAssignment, "grab"),
    "the server applies the native grapple directly")
T.truthy(body.dragging, "native grapple attaches the corpse")
T.equal(CorpseService.GetTask(order.id).visualSyncPending, false,
    "authoritative grapple completes its MP sync send")
T.equal(#sentSync, 1, "authoritative grapple emits one MP sync command")
T.equal(sentSync[1].args.action, "sync_grab",
    "authoritative grapple sends an MP visual synchronization command")
body.x, body.y = 60, 60
local dropped, dropReason = CorpseService.SendAction(lease, physicalAssignment,
    "drop")
T.truthy(dropped, "the server applies the native release directly: "
    .. tostring(dropReason))
T.falsy(body.dragging, "native release detaches the corpse")
T.equal(sentSync[2].args.action, "sync_drop",
    "authoritative release sends an MP visual synchronization command")

isMultiplayer = function() return false end
body.x, body.y, body.dragging, body.targetCorpse = 40, 40, false, nil
corpse.x, corpse.y = 40, 40
squares["40:40:0"].corpses = { corpse }
squares["60:60:0"].corpses = {}
T.truthy(CorpseService.SendAction(lease, physicalAssignment, "grab"),
    "the singleplayer server applies the native grapple directly")
body.x, body.y = 60, 60
T.truthy(CorpseService.SendAction(lease, physicalAssignment, "drop"),
    "the singleplayer server applies the native release directly")
T.equal(#sentSync, 2,
    "singleplayer performs the grapple without an MP sync command")

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
record.allowedJobs = nil
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

local cleared, clearReason = CorpseService.ClearConfiguration({}, {
    baseId = "base:one",
})
T.truthy(cleared, "corpse regions can be cleared")
T.equal(clearReason, "CORPSE_HAUL_ZONES_CLEARED",
    "corpse region clearing returns a stable result")

T.finish("pnc_corpse_haul_work_pipeline_smoke")
