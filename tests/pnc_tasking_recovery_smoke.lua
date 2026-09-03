local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "server", "")
PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local now = 1000
local stopped = {}
local events = {}
PNC = {
    Core = { Now = function() return now end },
    Tasking = {
        Internal = {},
        Diagnostics = { counters = {} },
        Events = { Emit = function(name, event) events[#events + 1] = {
            name = name, event = event,
        } end },
        Providers = {},
    },
    TaskRequestDefinitions = {
        NON_INTERRUPTIBLE_PHASE = {
            ATOMIC_COMMIT = true, COMPLETING = true,
        },
    },
}

local Tasking = T.load(ROOT .. "PNC/Tasking/Tasking/PNC_Tasking_Recovery.lua")
local H = Tasking.Internal
H.SafeCall = function(_, callback, _, ...)
    local ok, first, second = pcall(callback, ...)
    if not ok then return false, nil, first end
    return true, first, second
end
H.StopLease = function(lease, reason)
    stopped[#stopped + 1] = { lease = lease, reason = reason }
    return true, {}
end

local healthy = {
    leaseId = "healthy", npcId = "one", sourceDomain = "work",
    phase = "WORKING", startedAt = 0, lastProgressAt = 1000,
}
local handled, state = H.RecoverStalledLease(healthy, 2000)
T.falsy(handled, "fresh work progress should not recover")
T.equal(state, "HEALTHY", "fresh work progress state")
T.equal(#stopped, 0, "fresh work progress should not stop the lease")

Tasking.Providers.work = {
    GetRecoveryState = function()
        return { lastProgressAt = 59000, phase = "WORKING" }
    end,
}
local providerFresh = {
    leaseId = "provider-fresh", npcId = "provider", sourceDomain = "work",
    phase = "WORKING", startedAt = 0, lastProgressAt = 0,
}
handled, state = H.RecoverStalledLease(providerFresh, 60001)
T.falsy(handled, "provider progress should refresh the watchdog")
T.equal(state, "HEALTHY", "provider progress state")
Tasking.Providers.work = nil

local travel = {
    leaseId = "travel", npcId = "traveler", sourceDomain = "work",
    phase = "TRAVEL", startedAt = 0, lastProgressAt = 0,
}
handled, state = H.RecoverStalledLease(travel, 60001)
T.falsy(handled, "travel remains owned by path recovery")
T.equal(state, "NOT_APPLICABLE", "travel watchdog boundary")

local stalled = {
    leaseId = "stalled", npcId = "two", sourceDomain = "work",
    phase = "WORKING", startedAt = 0, lastProgressAt = 0,
}
handled, state = H.RecoverStalledLease(stalled, 60001)
T.truthy(handled, "stalled work should release its lease")
T.equal(state, "RECOVERED", "stalled work recovery state")
T.equal(stopped[1].reason, "task_progress_timeout",
    "stall recovery reason")
T.equal(Tasking.Diagnostics.counters.stallRecoveries, 1,
    "stall recovery diagnostic")

local cleanupFailure = {
    leaseId = "cleanup", npcId = "three", sourceDomain = "work",
    phase = "WORKING", startedAt = 0, lastProgressAt = 0,
}
H.StopLease = function() return false, "cleanup_failed" end
handled, state = H.RecoverStalledLease(cleanupFailure, 60001)
T.falsy(handled, "failed cleanup should remain bounded")
T.equal(state, "RECOVERY_PENDING", "failed cleanup retry state")
handled, state = H.RecoverStalledLease(cleanupFailure, 60002)
T.falsy(handled, "retry backoff should suppress repeated cleanup")
T.equal(state, "RECOVERY_BACKOFF", "cleanup retry backoff")
handled, state = H.RecoverStalledLease(cleanupFailure, 65001)
T.falsy(handled, "exhausted cleanup should quarantine")
T.equal(state, "QUARANTINED", "cleanup quarantine state")
T.equal(Tasking.Diagnostics.counters.stallQuarantines, 1,
    "stall quarantine diagnostic")

local cancelling = {
    leaseId = "cancelling", npcId = "cancelled", sourceDomain = "work",
    phase = "WORKING", startedAt = 0, lastProgressAt = 0,
    cancellationRequested = true,
}
local stopCount = #stopped
handled, state = H.RecoverStalledLease(cancelling, 60001)
T.falsy(handled, "cancellation must outrank stall recovery")
T.equal(state, "CANCELLING", "cancellation recovery boundary")
T.equal(#stopped, stopCount, "cancellation must not be rewritten as a timeout")

Tasking.Providers.NeedFacility = {
    GetRecoveryState = function()
        return { lastProgressAt = 0, phase = "WORKING" }
    end,
}
H.StopLease = function(lease, reason)
    stopped[#stopped + 1] = { lease = lease, reason = reason }
    return true, {}
end
local needLease = {
    leaseId = "need", npcId = "four", sourceDomain = "NeedFacility",
    phase = "WORKING", startedAt = 0, lastProgressAt = 0,
}
handled, state = H.RecoverStalledLease(needLease, 60001)
T.truthy(handled, "NeedFacility effect stall should release its lease")
T.equal(state, "RECOVERED", "NeedFacility watchdog state")

Tasking.Providers.NeedFacility.GetRecoveryState = function()
    return {
        lastProgressAt = 60000,
        phase = "TRAVEL",
        watchable = true,
        timeoutMs = 1000,
        recoveryReason = "path_lane_missing",
    }
end
local needTravel = {
    leaseId = "need-travel", npcId = "five", sourceDomain = "NeedFacility",
    phase = "TRAVEL", startedAt = 0, lastProgressAt = 0,
}
handled, state = H.RecoverStalledLease(needTravel, 61001)
T.truthy(handled, "NeedFacility travel stall should use PathService recovery")
T.equal(state, "RECOVERED", "NeedFacility travel recovery state")
T.equal(stopped[#stopped].reason, "path_lane_missing",
    "travel recovery did not preserve the provider reason")

H.StopLease = function() return true, {} end
handled, state = H.RecoverExecutorFailure(needLease, 70000,
    "task_executor_failed")
T.truthy(handled, "executor failure should use the common cleanup boundary")
T.equal(state, "RECOVERED", "executor recovery state")
T.equal(Tasking.Diagnostics.counters.executorRecoveries, 1,
    "executor recovery diagnostic")

local entry = T.read(ROOT .. "PNC/Tasking/PNC_Tasking.lua")
local pump = T.read(ROOT .. "PNC/Tasking/Tasking/PNC_Tasking_Pump.lua")
local core = T.read(ROOT .. "PNC/Tasking/Tasking/PNC_Tasking_Core.lua")
local provider = T.read(ROOT .. "PNC/Tasking/PNC_WorkTaskProvider.lua")
local commands = T.read(ROOT
    .. "PNC/Production/WorkService/PNC_WorkService_Commands.lua")
local scheduler = T.read(ROOT
    .. "PNC/Production/WorkService/PNC_WorkService_Scheduler.lua")
local needProvider = T.read(ROOT
    .. "PNC/Needs/NeedFacilityTriggers/PNC_NeedFacilityTriggers_Provider.lua")
local facilityBehavior = T.read(T.path("ProjectHoomans", "shared", "")
    .. "PNC/Core/Facilities/PNC_FacilityJobs_Behavior.lua")
local facilityStart = T.read(ROOT
    .. "PNC/Settlement/FacilityJobs/FacilityJobs_Service/PNC_FacilityJobs_Service_Start.lua")
local provisionProcessing = T.read(ROOT
    .. "PNC/Provision/ProvisionScheduler/PNC_ProvisionScheduler_Processing.lua")
T.contains(entry, "PNC_Tasking_Recovery", "tasking recovery module load")
T.contains(core, "TASK_PROVIDER_RECOVERY_UNSUPPORTED",
    "watchdog providers require recovery snapshots")
T.contains(pump, "RecoverStalledLease", "pump stall watchdog")
T.contains(pump, "RecoverExecutorFailure", "pump executor recovery")
T.contains(provider, "RecordRecovery", "durable work recovery counter")
T.contains(provider, "recoveryQuarantined", "quarantined work exclusion")
T.contains(commands, "function Service.Commands.Quarantine",
    "durable work quarantine command")
T.contains(scheduler, "recoveryQuarantined",
    "scheduler quarantine guard")
T.contains(needProvider, "function Triggers.GetRecoveryState",
    "NeedFacility progress contract")
T.contains(needProvider, "return stopped == true",
    "NeedFacility cleanup result propagation")
T.contains(facilityBehavior, "function Jobs.RecordProgress",
    "facility effect progress owner")
T.contains(facilityStart, "lastProgressAt = activityStartedAt",
    "facility activity progress baseline")
T.contains(provisionProcessing, "provision_pickup_quarantined",
    "provision quarantine handoff")

local directProviders = {
    { path = ROOT .. "PNC/Farming/FarmingService/PNC_FarmingService_Provider.lua",
        name = "farming" },
    { path = ROOT .. "PNC/Fishing/PNC_FishingExecutor.lua",
        name = "fishing" },
    { path = ROOT .. "PNC/Lumber/PNC_LumberExecutor.lua",
        name = "lumber" },
    { path = ROOT .. "PNC/Scavenge/ScavengeExecutor/PNC_ScavengeExecutor_Provider.lua",
        name = "scavenge" },
}
for _, item in ipairs(directProviders) do
    T.contains(T.read(item.path), "GetRecoveryState",
        item.name .. " recovery contract")
end

local orderSystem = T.read(T.path("ProjectHoomans", "shared", "")
    .. "PNC/Core/Orders/PNC_OrderSystem.lua")
local behaviorSystem = T.read(T.path("ProjectHoomans", "shared", "")
    .. "PNC/Core/Behaviors/PNC_BehaviorSystem.lua")
local lumberExecutor = T.read(ROOT .. "PNC/Lumber/PNC_LumberExecutor.lua")
T.contains(orderSystem, "function OrderSystem.RecoverStalled",
    "direct orders share the bounded recovery boundary")
T.contains(orderSystem, "GetMovementRecoveryState",
    "direct order recovery observes PathService")
T.contains(behaviorSystem, "OrderSystem.RecoverStalled",
    "behavior tick runs direct order recovery")
T.contains(lumberExecutor, "LUMBER_WORK_AUTHORITY",
    "legacy lumber assignment is fenced from WorkService")
T.contains(lumberExecutor,
    "not (PNC.LumberWorkAdapter and PNC.WorkService)",
    "direct lumber provider is not registered beside WorkService")

T.finish("pnc_tasking_recovery_smoke")
