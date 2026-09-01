local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "server" },
})

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local clock = 1000
local ids = 0
local records = {}
local squares = {}
local corpse = {
    x = 2, y = 2, z = 0,
    data = { PNC_DeathMarkerID = "npc:dead",
        PNC_CorpseToken = "corpse:one" },
}
function corpse:getX() return self.x end
function corpse:getY() return self.y end
function corpse:getZ() return self.z end
function corpse:getModData() return self.data end
function corpse:transmitModData() self.transmitted = true end

local body = { x = 2, y = 3, z = 0, dragging = false }
function body:getX() return self.x end
function body:getY() return self.y end
function body:getZ() return self.z end
function body:isDraggingCorpse() return self.dragging end
function body:pickUpCorpse()
    self.dragging = true
    self.grappleTarget = { getOnlineID = function() return 501 end }
end
function body:getGrapplingTarget() return self.grappleTarget end
function body:setDoGrappleLetGo() self.dragging = false end

local function key(x, y, z)
    return tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z)
end

local sourceSquare = { corpses = { corpse } }
local dropSquare = { corpses = {} }
squares[key(2, 2, 0)] = sourceSquare
squares[key(30, 10, 0)] = dropSquare
squares[key(31, 10, 0)] = dropSquare

getCell = function()
    return {
        getGridSquare = function(_, x, y, z)
            return squares[key(x, y, z)]
        end,
    }
end

package.preload["PsychopatzCore/World/PC_ZoneRegistry"] = function()
    return {
        get = function(id)
            return id == "zone:base" and {
                geometry = { levels = {
                    [0] = { rows = { [2] = { 2, 2 } } },
                } },
            } or nil
        end,
    }
end

package.preload["PsychopatzCore/World/PC_GridRegion"] = function()
    return {
        containsPoint = function(_, x, y, z)
            return z == 0 and x >= 30 and x <= 31 and y == 10
        end,
    }
end

PNC = {
    Const = { ORDER_CORPSE_HAUL = "corpse_haul" },
    Core = {
        Now = function() return clock end,
        GenerateID = function(prefix)
            ids = ids + 1
            return tostring(prefix) .. ":" .. tostring(ids)
        end,
        DeepCopy = function(value)
            if type(value) ~= "table" then return value end
            local copy = {}
            for field, item in pairs(value) do copy[field] = item end
            return copy
        end,
        Distance = function(x1, y1, x2, y2)
            local dx, dy = x1 - x2, y1 - y2
            return math.sqrt(dx * dx + dy * dy)
        end,
    },
    Registry = {
        Get = function(id) return records[tostring(id)] end,
        GetLiveZombie = function(id)
            return tostring(id) == "npc:worker" and body or nil
        end,
        GetDeathMarker = function(id)
            return tostring(id) == "npc:dead" and {
                id = "npc:dead", alive = false,
            } or nil
        end,
        MarkDirty = function() end,
    },
    BodyLifecycle = {
        Internal = {
            forEachCorpse = function(square, callback)
                for _, item in ipairs(square and square.corpses or {}) do
                    callback(item)
                end
            end,
            stampCorpse = function() return true end,
            transmitCorpseState = function() end,
        },
    },
    HomeDutyService = {
        GetBase = function()
            return {
                id = "base:one", baseZoneId = "zone:base",
                facilityIds = { ["facility:stockpile"] = true },
            }
        end,
    },
    SettlementRepository = {
        GetFacility = function(id)
            return id == "facility:stockpile" and {
                id = "facility:stockpile", definitionId = "stockpile",
                constructionState = "BUILT",
                componentIds = { ["component:region"] = true },
            } or nil
        end,
        GetComponent = function(id)
            return id == "component:region" and {
                role = "storage.stockpile",
                region = { levels = {
                    [0] = { rows = { [10] = { 30, 31 } } },
                } },
            } or nil
        end,
    },
    StockpileAccessService = {
        GetFacilityRegion = function(id)
            return id == "facility:stockpile" and {
                levels = { [0] = { rows = { [10] = { 30, 31 } } } },
            } or nil
        end,
        ContainsFacilityRegionTile = function(id, x, y, z)
            return id == "facility:stockpile" and z == 0
                and y == 10 and x >= 30 and x <= 31
        end,
    },
    PathService = {
        Internal = { isSquareWalkable = function() return true end },
    },
    OrderSystem = {
        SetOrder = function(record, order) record.orderSpec = order end,
    },
    TaskLeaseService = {
        Active = {},
        SetPhase = function() return true end,
    },
    Tasking = {
        Commands = { Complete = function() return true end },
        Events = { Emit = function() end },
    },
}

records["npc:worker"] = {
    id = "npc:worker", alive = true, x = 2, y = 3, z = 0,
    affiliation = { communityRole = "worker" },
    runtime = {}, orderSpec = { kind = "guard" },
}

local Service = T.load("ProjectHoomans", "server",
    "PNC/Tasking/PNC_CorpseHaulService.lua")
local assignment = Service.FindAssignment(records["npc:worker"])
T.truthy(assignment, "worker receives a corpse assignment")
T.equal(assignment.dropX, 30, "drop is selected in the external stockpile region")
T.equal(assignment.dropY, 10, "external stockpile row is preserved")
T.truthy(Service.IsEligibleCorpse(corpse), "managed corpse is eligible")
T.truthy(Service.Reserve(assignment, "npc:worker"),
    "corpse and drop reservations are atomic")
T.falsy(Service.FindAssignment(records["npc:worker"]),
    "reserved corpse is not offered twice")

local lease = {
    leaseId = "lease:one", npcId = "npc:worker", taskId = assignment.taskId,
    revision = 1,
}
T.truthy(Service.Start(lease, assignment), "haul starts only with live corpse")
T.equal(corpse.data.PNC_CorpseHaulTaskId, assignment.taskId,
    "source corpse is tagged before grappling")
T.truthy(Service.IsRecordProtected(records["npc:worker"]),
    "lifecycle protection follows the active haul")

Service.Cancel(lease, "test_cancel")
T.falsy(Service.GetTask(assignment.taskId), "cancel releases task reservation")
T.falsy(records["npc:worker"].runtime.corpseHaulTaskId,
    "cancel clears record lifecycle protection")
T.falsy(corpse.data.PNC_CorpseHaulTaskId,
    "cancel clears the source corpse task tag")
T.equal(records["npc:worker"].orderSpec.kind, "guard",
    "cancel restores the previous order")

-- Dedicated-MP request path: the client supplies only the task identity;
-- the server resolves the reserved corpse and invokes the vanilla grapple
-- method on the authoritative NPC.
PNC.Core.IsClientOnly = function() return true end
PNC.Core.ResolvePlayerByOnlineID = function(id)
    return tonumber(id) == 77 and {
        getOnlineID = function() return 77 end,
    } or nil
end
PNC.Network = {
    Internal = {
        SendToPlayer = function(_, command, payload)
            body.lastSyncCommand = command
            body.lastSyncPayload = payload
            return true
        end,
    },
}
PNC.TaskLeaseService.Active = { "lease:two" }
PNC.TaskLeaseService.Get = function(id)
    return id == "lease:two" and lease or nil
end

local leaseTwo = {
    leaseId = "lease:two", npcId = "npc:worker", taskId = assignment.taskId,
    revision = 2,
}
PNC.TaskLeaseService.Get = function(id)
    return id == "lease:two" and leaseTwo or nil
end
T.truthy(Service.Reserve(assignment, "npc:worker"),
    "server can reserve the corpse again for the MP request case")
T.truthy(Service.Start(leaseTwo, assignment),
    "MP request case starts from the same authoritative assignment")
local task = Service.GetTask(assignment.taskId)
task.executorOnlineID = 77
task.phase = "GRAB_PENDING"
T.truthy(Service.HandleClientAck(
    { getOnlineID = function() return 77 end },
    { taskId = assignment.taskId, npcId = "npc:worker", event = "grab_request" }),
    "authorized MP grab request is accepted")
T.truthy(body.dragging, "MP grab request uses the vanilla grapple API")
T.equal(body.lastSyncPayload.action, "sync_grab",
    "server sends a visual grapple sync after the authoritative grab")
T.equal(body.lastSyncPayload.grappleTargetOnlineID, 501,
    "visual sync identifies the server-created grapple target")
Service.Cancel(leaseTwo, "test_mp_cancel")
clock = clock + 6000
Service.Pump()

T.finish("pnc_corpse_haul_service_smoke")
