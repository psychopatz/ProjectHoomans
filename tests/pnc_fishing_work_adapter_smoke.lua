local T = require "tests/support/test"

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local nowMs = 1000
local records = {
    fisher = {
        id = "fisher",
        name = "Fisher",
        x = 10,
        y = 10,
        z = 0,
        affiliation = { communityID = "col-1" },
        runtime = {},
        inventory = { items = {} },
    },
}
local deposits = {}
local orders = {}
local registrations = {}
local releaseCalls = 0
local job = {
    id = "fish-job:1",
    npcId = "fisher",
    zoneId = "fish-zone:1",
    active = true,
    state = "READY",
    phase = "WAITING",
    spotId = "spot-1",
    spot = { id = "spot-1", standX = 12, standY = 12, standZ = 0 },
}
local zone = {
    id = "fish-zone:1",
    ownerId = "col-1",
    enabled = true,
    valid = true,
    bounds = { minX = 11, maxX = 14, minY = 11, maxY = 14, minZ = 0, maxZ = 0 },
    fishingSpots = { { id = "spot-1", standX = 12, standY = 12, standZ = 0 } },
}

local serial = 0
PNC = {
    Core = {
        Now = function() return nowMs end,
        GenerateID = function(prefix)
            serial = serial + 1
            return tostring(prefix) .. ":" .. tostring(serial)
        end,
    },
    Const = { WORK_LEASE_TTL_MS = 15000 },
    WorkDefinitions = {
        STATUS = {
            QUEUED = "QUEUED",
            CANCELLED = "CANCELLED",
            COMPLETED = "COMPLETED",
            FAILED = "FAILED",
            WORKING = "WORKING",
        },
    },
    Registry = {
        Get = function(id) return records[id] end,
    },
    BaseService = {
        GetForColony = function(cid)
            return { id = "base:1", colonyId = cid, factionId = "fac:1" }
        end,
    },
    ColonyStorageRepository = {
        ListForColony = function(cid)
            return cid == "col-1" and { { id = "storage-1", access = { x = 5, y = 5, z = 0 } } } or {}
        end,
        Get = function(id)
            return id == "storage-1" and { id = "storage-1", access = { x = 5, y = 5, z = 0 } } or nil
        end,
    },
    ColonyStorageService = {
        DepositProductionItems = function(storageId, items)
            deposits[#deposits + 1] = { storageId = storageId, items = items }
            return true, "ok"
        end,
    },
    ProductionContext = {
        ForWorker = function()
            return { storage = { id = "storage-1" }, access = { x = 5, y = 5, z = 0 } }
        end,
    },
    WorkItemService = {
        Release = function()
            releaseCalls = releaseCalls + 1
            return true
        end,
    },
    WorkService = {
        RegisterOperation = function(op, handlers)
            registrations[op] = handlers
            return true
        end,
        Commands = {
            Queue = function(spec)
                local id = spec.id or ("work:" .. tostring(#deposits + 1))
                orders[id] = {
                    id = id,
                    operation = spec.operation,
                    requiredWorkerId = spec.requiredWorkerId,
                    workerId = spec.requiredWorkerId,
                    priority = spec.priority,
                    precedence = spec.precedence,
                    requiredWork = spec.requiredWork,
                    payload = spec.payload,
                    status = "QUEUED",
                }
                return orders[id]
            end,
            Cancel = function(id)
                if orders[id] then orders[id].status = "CANCELLED" end
                return true
            end,
            AddProgress = function(id)
                if orders[id] then orders[id].status = "COMPLETED" end
                return true
            end,
        },
        Queries = {
            Get = function(id) return orders[id] end,
        },
    },
    WorkRepository = {},
    Tasking = {},
    FishingService = {
        Data = { zones = { ["fish-zone:1"] = zone }, jobs = { fisher = job } },
        SPOT_RETRY_COOLDOWN_MS = 5000,
        GetZone = function(id) return id == "fish-zone:1" and zone or nil end,
        GetJob = function(id) return id == "fisher" and job or nil end,
        ValidateZone = function(z) return z and z.enabled == true and z.valid == true end,
        AssignWorker = function(_, npcId) return true, records[npcId] and job end,
        StartJob = function(lease)
            job.leaseId = lease and lease.leaseId
            return true
        end,
        TickJob = function() return true, false, "working" end,
        IsNearby = function(record, _, _, spot, body)
            local x = body and body:getX() or record.x
            local y = body and body:getY() or record.y
            return math.abs(x - spot.standX) + math.abs(y - spot.standY) <= 1.5
        end,
        CancelJob = function() job.active = false return true end,
        Internal = {
            Now = function() return nowMs end,
            MarkDirty = function() end,
            UpdateFishingRuntime = function() end,
            ReserveFishingSpot = function(z, j) j.spot = z.fishingSpots[1] j.spotId = "spot-1" return j.spot end,
            ReleaseFishingSpot = function() end,
        },
    },
}

T.load("ProjectHoomans", "server", "PNC/Production/PNC_WorkOutputService.lua")
T.load("ProjectHoomans", "server", "PNC/Production/WorkToilRunner/PNC_WorkToilRunner_Approach.lua")
T.load("ProjectHoomans", "server", "PNC/Fishing/PNC_FishingWorkAdapter.lua")
T.load("ProjectHoomans", "server", "PNC/Fishing/PNC_FishingExecutor.lua")
T.load("ProjectHoomans", "server", "PNC/Fishing/PNC_FishingService_WorkOutput.lua")

local reg = registrations.FISHING
T.truthy(reg ~= nil, "FISHING registers on WorkService")
local cands = PNC.FishingExecutor.GetCandidates()
T.truthy(type(cands) == "table" and #cands == 0,
    "FishingExecutor defers candidates to FishingWorkAdapter")

local okZone, zoneOrder = PNC.FishingWorkAdapter.EnsureZoneOrder(zone)
T.truthy(okZone == true and zoneOrder ~= nil, "EnsureZoneOrder queues autonomous FISHING order")
T.equal(zoneOrder.id, "fishing-zone:fish-zone:1", "autonomous order id matches zone")
T.equal(zoneOrder.precedence, "NORMAL_WORK", "autonomous order uses NORMAL_WORK precedence")
T.equal(zoneOrder.priority, 50, "autonomous order uses priority 50")
T.truthy(zoneOrder.requiredWorkerId == nil, "autonomous order has no requiredWorkerId")

zoneOrder.workerId = "fisher"
local okManual, reusedOrder = PNC.FishingWorkAdapter.EnsureOrder(job)
T.truthy(okManual == true and reusedOrder == zoneOrder,
    "EnsureOrder reuses claimed autonomous zone order for assigned fisher")

local target = reg.TargetProvider(zoneOrder, records.fisher)
T.truthy(target ~= nil and target.ok == true, "TargetProvider resolves fishing target")
T.equal(target.targetKind, "fishing_zone", "targetKind matches fishing_zone")

T.truthy(reg.ExecutionHandler(zoneOrder, { npcId = "fisher", leaseId = "lease-1" }) == true,
    "ExecutionHandler ticks active fishing job")

-- Abstract catch routes through WorkOutputService.FlushAbstractDelivery into colony storage
local H = PNC.FishingService.Internal
local committed, out1, out2 = H.CommitCatchOutput(
    false, job, zone, records.fisher, nil, { type = "Base.Bass" }, 1,
    function(ok, comp, rsn) return ok, comp, rsn end,
    function() return true end,
    function() return true end
)
T.truthy(committed == true and out1 == nil and out2 == nil,
    "Abstract catch commits via WorkOutputService")
T.equal(#deposits, 1, "Abstract catch deposits into colony storage")
T.equal(deposits[1].items[1].fullType, "Base.Bass", "Deposited catch item matches spec")

-- Live catch captures inventory output and drives WorkToilRunner approach observation
records.fisher.x, records.fisher.y = 20, 20
local travelState, tOk, _, tReason = H.ObserveLiveTravel(
    job, zone, records.fisher, nil, nowMs,
    function(ok, comp, rsn) return ok, comp, rsn end,
    function(r, _, s) return math.abs(r.x - s.standX) + math.abs(r.y - s.standY) end
)
T.equal(travelState, "handled", "ObserveLiveTravel handles distant live worker")
T.truthy(tOk == true and tReason == "traveling", "Initial live travel returns traveling")

local doneOk = reg.CompletionHandler(zoneOrder)
T.truthy(doneOk == true and releaseCalls == 1 and job.active == false,
    "CompletionHandler releases WorkItemService tool and cancels job")
T.finish("pnc_fishing_work_adapter_smoke")
