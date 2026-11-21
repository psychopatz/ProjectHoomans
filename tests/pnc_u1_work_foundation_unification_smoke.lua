local T = require "tests/support/test"

T.addPackagePaths()

local clock = 1000
local idSeq = 0
local tickListeners = {}
local haltedMovements = {}
local releasedOutputs = {}
local cancelledInputs = {}
local releasedTools = {}

Events = {
    OnTick = {
        Add = function(fn)
            tickListeners[#tickListeners + 1] = fn
        end,
    },
}

PsychopatzCore = {
    RuntimeRole = {
        AllowsServerCode = function() return true end,
    },
    Events = {
        emit = function() end,
    },
}

local function shallowCopy(tbl)
    if type(tbl) ~= "table" then return tbl end
    local out = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            out[k] = shallowCopy(v)
        else
            out[k] = v
        end
    end
    return out
end

local liveZombie = { id = "body:npc-1" }
local records = {
    ["npc-1"] = {
        id = "npc-1",
        alive = true,
        x = 10,
        y = 10,
        z = 0,
        runtime = {
            workApproachWatch = { default = { key = "k" } },
            workApproachDiagnostic = { phase = "MOVE" },
        },
        affiliation = { communityID = "col-1", factionID = "fac-1", role = "worker" },
        jobs = { Farmer = true, Lumber = true, Fishing = true },
    },
}

PNC = {
    Const = {
        ORDER_LUMBER = "lumber",
    },
    Core = {
        Now = function() return clock end,
        GenerateID = function(prefix)
            idSeq = idSeq + 1
            return tostring(prefix or "id") .. "_" .. tostring(idSeq)
        end,
        DeepCopy = shallowCopy,
        Log = function() end,
        LogInfo = function() end,
        LogWarn = function() end,
    },
    EventTypes = {
        TASK_LEASE_CREATED = "TASK_LEASE_CREATED",
        TASK_LEASE_RELEASED = "TASK_LEASE_RELEASED",
        WORK_ORDER_QUEUED = "WORK_ORDER_QUEUED",
        WORK_ORDER_CANCELLED = "WORK_ORDER_CANCELLED",
        WORK_ORDER_COMPLETED = "WORK_ORDER_COMPLETED",
    },
    Registry = {
        Get = function(id) return records[tostring(id or "")] end,
        GetLiveZombie = function(id)
            return tostring(id) == "npc-1" and liveZombie or nil
        end,
        ForEach = function(cb)
            for _, rec in pairs(records) do cb(rec) end
        end,
    },
    BehaviorCommon = {
        HaltMovement = function(record, body, reason)
            haltedMovements[#haltedMovements + 1] = {
                npcId = record and record.id,
                body = body,
                reason = reason,
            }
            return true
        end,
    },
    WorkOutputService = {
        ReleaseOutputCapacity = function(order)
            releasedOutputs[#releasedOutputs + 1] = order and order.id
            return true
        end,
        FlushAbstractDelivery = function() return true, "COMPLETED" end,
        TickLiveDelivery = function() return true, true, "COMPLETED" end,
    },
    WorkInputService = {
        Cancel = function(order)
            cancelledInputs[#cancelledInputs + 1] = order and order.id
            return true
        end,
    },
    WorkItemService = {
        OperationHasRequirements = function() return false end,
        Release = function(record, op)
            releasedTools[#releasedTools + 1] = tostring(record.id) .. ":" .. tostring(op)
            return true
        end,
    },
    ColonyStorageService = {},
    SettlementRepository = {
        Load = function() end,
        State = { bases = {} },
        GetFacility = function() return nil end,
    },
    PZFarming = {},
    PlantingCatalog = {},
    Farming = { FARMER_JOB = "Farmer", FACILITY_ID = "farm_plot" },
    Fishing = { FISHING_JOB = "Fishing" },
    WorldEffectService = {
        Register = function() end,
        RegisterProvider = function() end,
    },
}

package.preload["PsychopatzCore/World/PC_GridRegion"] = function()
    return {
        validate = function(g) return true, nil, g end,
        bounds = function() return { minX = 0, maxX = 1, minY = 0, maxY = 1, minZ = 0 } end,
        containsPoint = function() return true end,
    }
end
package.preload["PsychopatzCore/World/PC_ZoneRegistry"] = function()
    return { register = function() end, unregister = function() end, get = function() return nil end }
end
package.preload["PsychopatzCore/Inventory/PsychopatzInventory"] = function()
    return {}
end
package.preload["PNC/Tasking/PNC_TaskExecutors"] = function() return {} end
package.preload["PNC/Needs/NeedFacilityTriggers/PNC_NeedFacilityTriggers"] = function() return {} end
package.preload["PNC/Core/Needs/PNC_WorkFatigueGate"] = function()
    return { Check = function() return true end }
end
package.preload["PNC/Core/Production/WorkDefinition/PNC_WorkPolicy"] = function()
    return {
        IsEnabled = function() return true end,
        GetPriority = function() return 2 end,
    }
end
package.preload["PNC/Production/WorldEffects/PNC_WorldEffectService"] = function()
    return PNC.WorldEffectService
end

T.load("ProjectHoomans", "shared", "PNC/Core/Production/WorkDefinition/PNC_WorkDefinitions.lua")
T.load("ProjectHoomans", "server", "PNC/Production/PNC_WorkRepository.lua")
PNC.WorkRepository.Import(nil)

local Claims = T.load("ProjectHoomans", "server", "PNC/Tasking/PNC_Tasking_Claims.lua")
local Leases = T.load("ProjectHoomans", "server", "PNC/Tasking/PNC_TaskLeaseService.lua")
local Tasking = T.load("ProjectHoomans", "server", "PNC/Tasking/PNC_Tasking.lua")
local Work = T.load("ProjectHoomans", "server", "PNC/Production/PNC_WorkService.lua")
local Runner = T.load("ProjectHoomans", "server", "PNC/Production/WorkService/PNC_WorkToilRunner.lua")

-- 1. PNC.Tasking.Claims contract
Claims.Reset()
local ok1, claim1 = Claims.Acquire("station:workbench:1", "npc-1", {
    leaseId = "lease-1",
    domain = "work",
    ttlMs = 500,
    at = 1000,
})
T.equal(ok1, true, "Claims.Acquire succeeds for initial owner")
T.equal(claim1.leaseId, "lease-1", "claim binds leaseId")

local okConflict, conflictReason = Claims.Acquire("station:workbench:1", "npc-2", {
    ttlMs = 500,
    at = 1100,
})
T.falsy(okConflict, "Claims.Acquire rejects competing owner")
T.equal(conflictReason, "RESOURCE_CLAIMED", "conflict returns RESOURCE_CLAIMED")

local okRenew = Claims.Renew("station:workbench:1", "npc-1", 1000, 1200)
T.equal(okRenew, true, "Claims.Renew extends TTL for matching owner")
T.equal(Claims.IsClaimed("station:workbench:1", "npc-2", 2199), true,
    "renewed claim remains active before expiry")

local okTakeover = Claims.Acquire("station:workbench:1", "npc-2", {
    ttlMs = 500,
    at = 2200,
})
T.equal(okTakeover, true, "expired claim allows takeover by new owner")
T.equal(Claims.ReleaseByOwner("npc-2", "cleanup"), 1,
    "ReleaseByOwner clears all owner claims")
T.equal(Claims.GetDiagnostics().activeCount, 0,
    "diagnostics tracks zero active claims after ReleaseByOwner")

-- 2. TaskLeaseService.Release + Tasking rollback automatically clear claims
Claims.Reset()
local rollbackCalls = 0
local testDomainProvider = {
    GetCandidates = function()
        return {
            {
                taskId = "task:claim:test",
                npcId = "npc-1",
                kind = "TEST",
                sourceDomain = "claim_test",
                sourceRef = "ref:1",
                precedence = "NORMAL_WORK",
                urgency = 0.5,
                capability = "work.test",
            },
        }
    end,
    Validate = function() return true end,
    Assign = function(intent)
        local okClaim = Claims.Acquire("resource:alpha", intent.npcId, { ttlMs = 5000, at = 3000 })
        T.equal(okClaim, true, "provider acquires claim during Assign")
        return {
            claimKeys = { "resource:alpha" },
            executionMode = "ABSTRACT",
        }
    end,
    Start = function()
        return true
    end,
    RollbackAssignment = function()
        rollbackCalls = rollbackCalls + 1
        return true
    end,
}
T.truthy(Tasking.Commands.RegisterProvider("claim_test", testDomainProvider),
    "registers claim_test Tasking provider")

local okAssign, createdLease = Tasking.Internal.Assign({
    taskId = "task:claim:test",
    npcId = "npc-1",
    kind = "TEST",
    sourceDomain = "claim_test",
    sourceRef = "ref:1",
    precedence = "NORMAL_WORK",
    urgency = 0.5,
    capability = "work.test",
})
T.equal(okAssign, true, "Tasking.Internal.Assign creates lease and attaches claimKeys")
T.equal(#Claims.ListByLease(createdLease.leaseId), 1,
    "claim is indexed under created TaskLease")

local releasedLease = Leases.Release(createdLease.leaseId, "test_complete")
T.truthy(releasedLease, "TaskLeaseService.Release succeeds")
T.equal(Claims.IsClaimed("resource:alpha", nil, 3100), false,
    "TaskLeaseService.Release automatically releases attached claims")

testDomainProvider.Start = function() return false, "SIMULATED_START_FAILURE" end
local okFailAssign, failReason = Tasking.Internal.Assign({
    taskId = "task:claim:fail",
    npcId = "npc-1",
    kind = "TEST",
    sourceDomain = "claim_test",
    sourceRef = "ref:2",
    precedence = "NORMAL_WORK",
    urgency = 0.5,
    capability = "work.test",
})
T.falsy(okFailAssign, "Assign fails when Start rejects")
T.equal(failReason, "SIMULATED_START_FAILURE", "Start failure propagates reason")
T.equal(Claims.IsClaimed("resource:alpha", nil, 3200), false,
    "Assign failure rolls back acquired claims")
T.truthy(rollbackCalls >= 1, "provider RollbackAssignment invoked")

-- 3 & 4 & 5. Four-chore WorkService unification & zero standalone polling loops
local farmingServiceStub = {
    Data = { zones = {} },
    Internal = {},
    HasActionableWork = function() return false end,
}
PNC.FarmingService = farmingServiceStub
PNC.Tasking.Providers.farming = { legacy = true }
T.load("ProjectHoomans", "server", "PNC/Farming/PNC_FarmingWorkAdapter.lua")
T.equal(PNC.Tasking.Providers.farming, nil,
    "FarmingWorkAdapter removes legacy farming Tasking provider when WorkService active")

PNC.FishingService = {
    Data = { jobs = {}, zones = {} },
    ValidateZone = function() return false end,
}
T.load("ProjectHoomans", "server", "PNC/Fishing/PNC_FishingWorkAdapter.lua")

local LumberService = T.load("ProjectHoomans", "server", "PNC/Lumber/PNC_LumberService.lua")
LumberService.Data = { zones = {}, zoneOrder = {}, trees = {}, jobs = {} }
LumberService.Loaded = true
T.load("ProjectHoomans", "server", "PNC/Lumber/PNC_LumberWorkAdapter.lua")

local tickHooksBeforeCorpse = #tickListeners
local CorpseService = T.load("ProjectHoomans", "server", "PNC/Tasking/PNC_CorpseHaulService.lua")
T.falsy(CorpseService.TickHookRegistered,
    "CorpseHaulService does not register standalone Events.OnTick when WorkService active")
T.equal(#tickListeners, tickHooksBeforeCorpse,
    "no Events.OnTick listener added by CorpseHaulService under WorkService")

T.equal(type(Work.ReconcileHandlers.FARMING), "function",
    "FARMING reconciler registered on WorkService")
T.equal(type(Work.ReconcileHandlers.FISHING), "function",
    "FISHING reconciler registered on WorkService")
T.equal(type(Work.ReconcileHandlers.LUMBER), "function",
    "LUMBER reconciler registered on WorkService")
T.equal(type(Work.ReconcileHandlers.CORPSE_HAUL), "function",
    "CORPSE_HAUL reconciler registered on WorkService")
T.equal(type(Work.TargetProviders.FARMING), "function",
    "Work.RegisterOperation bound FARMING TargetProvider")
T.equal(type(Work.TargetProviders.FISHING), "function",
    "Work.RegisterOperation bound FISHING TargetProvider")
T.equal(type(Work.TargetProviders.LUMBER), "function",
    "Work.RegisterOperation bound LUMBER TargetProvider")

local originalLumberReconcile = PNC.LumberWorkAdapter.Reconcile
local lumberReconcileCount = 0
PNC.LumberWorkAdapter.Reconcile = function()
    lumberReconcileCount = lumberReconcileCount + 1
    return 0
end
LumberService.Pump(10000)
T.equal(lumberReconcileCount, 0,
    "LumberService.Pump skips duplicate LumberWorkAdapter.Reconcile when WorkService owns reconciler")
PNC.LumberWorkAdapter.Reconcile = originalLumberReconcile

local corpsePumpCalls = 0
local originalCorpsePump = CorpseService.Pump
CorpseService.Pump = function(at)
    corpsePumpCalls = corpsePumpCalls + 1
    return originalCorpsePump(at)
end
Work.ReconcileHandlers.CORPSE_HAUL = function(at) return CorpseService.Pump(at) end
Work.NextPassAt = 0
Work.Tick(20000)
T.equal(corpsePumpCalls, 1,
    "WorkService.Tick drives CORPSE_HAUL reconciler deterministically")

-- 6. WorkToilRunner.AbortOrder & Live/Abstract parity
Claims.Reset()
local origReleaseOutput = PNC.WorkOutputService and PNC.WorkOutputService.ReleaseOutputCapacity
PNC.WorkOutputService = PNC.WorkOutputService or {}
PNC.WorkOutputService.ReleaseOutputCapacity = function(order, storage)
    releasedOutputs[#releasedOutputs + 1] = order and order.id
    if type(origReleaseOutput) == "function" then
        return origReleaseOutput(order, storage)
    end
    return true
end
PNC.WorkOutputService.FlushAbstractDelivery = function() return true, "COMPLETED" end
PNC.WorkOutputService.TickLiveDelivery = function() return true, true, "COMPLETED" end

local abortOrder = {
    id = "order:abort:1",
    operation = "FARMING",
    workerId = "npc-1",
    payload = { input = { staged = true } },
    outputEffect = { kind = "TEST" },
}
Claims.Acquire("work_station:plot:1", "order:abort:1", {
    leaseId = "lease:abort:1",
    domain = "work",
    ttlMs = 0,
})
local aborted, abortReason = Runner.AbortOrder(abortOrder, {
    leaseId = "lease:abort:1",
    npcId = "npc-1",
}, "unit_abort")
T.equal(aborted, true, "WorkToilRunner.AbortOrder returns true")
T.equal(abortReason, "unit_abort", "AbortOrder returns abort reason")
T.equal(Claims.IsClaimed("work_station:plot:1"), false,
    "AbortOrder releases order and lease claims")
T.equal(#releasedOutputs, 1, "AbortOrder releases output capacity")
T.equal(#cancelledInputs, 1, "AbortOrder cancels staged inputs")
T.equal(#releasedTools, 1, "AbortOrder releases held tools")
T.equal(records["npc-1"].runtime.workApproachWatch, nil,
    "AbortOrder clears workApproachWatch")
T.equal(#haltedMovements, 1, "AbortOrder halts live body movement")

local liveOrder = {
    id = "order:parity:live",
    operation = "LUMBER",
    workerId = "npc-1",
    executionMode = "LIVE",
    x = 10,
    y = 10,
    z = 0,
    outputEffect = { kind = "TEST" },
}
local abstractOrder = {
    id = "order:parity:abstract",
    operation = "LUMBER",
    workerId = "npc-absent",
    executionMode = "ABSTRACT",
    x = 10,
    y = 10,
    z = 0,
    outputEffect = { kind = "TEST" },
}
records["npc-absent"] = { id = "npc-absent", alive = true, x = 10, y = 10, z = 0, runtime = {} }
local parityAdapter = {
    workTarget = function() return "output_ready" end,
}
local okLive, resLive = Runner.RunToilStep(liveOrder, { npcId = "npc-1", executionMode = "LIVE" }, parityAdapter)
local okAbstract, resAbstract = Runner.RunToilStep(abstractOrder, { npcId = "npc-absent", executionMode = "ABSTRACT" }, parityAdapter)
T.equal(okLive, true, "Live RunToilStep completes cleanly")
T.equal(okAbstract, true, "Abstract RunToilStep completes cleanly")
T.equal(liveOrder.phase, Runner.PHASES.COMPLETED, "Live toil reaches COMPLETED")
T.equal(abstractOrder.phase, Runner.PHASES.COMPLETED, "Abstract toil reaches COMPLETED")
T.equal(resLive, resAbstract, "Live and Abstract execution return identical completion status")

-- 7. Static zero isFarmer gate verification
local farmingServiceSrc = T.read("ProjectHoomans", "server", "PNC/Farming/PNC_FarmingService.lua")
local farmingProviderSrc = T.read("ProjectHoomans", "server", "PNC/Farming/FarmingService/PNC_FarmingService_Provider.lua")
local farmingAdapterSrc = T.read("ProjectHoomans", "server", "PNC/Farming/PNC_FarmingWorkAdapter.lua")
T.falsy(farmingServiceSrc:find("isFarmer", 1, true), "PNC_FarmingService has zero isFarmer references")
T.falsy(farmingProviderSrc:find("isFarmer", 1, true), "PNC_FarmingService_Provider has zero isFarmer references")
T.falsy(farmingAdapterSrc:find("isFarmer", 1, true), "PNC_FarmingWorkAdapter has zero isFarmer references")

T.finish("pnc_u1_work_foundation_unification_smoke")
