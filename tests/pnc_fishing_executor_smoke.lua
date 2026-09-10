local T = require "tests/support/test"

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local jobs = {
    npc = { id = "fishing:job", zoneId = "fishing:zone", active = true,
        revision = 1, createdAt = 10 },
}
local record = { id = "npc", alive = true, x = 1, y = 1, z = 0 }
local cancelled
local camped = false

PNC = {
    Const = { ORDER_FISHING = "fishing" },
    FishingService = {
        GetJob = function(id) return jobs[tostring(id)] end,
        GetZone = function() return { id = "fishing:zone", enabled = true } end,
        ValidateZone = function() return true end,
        IsNearby = function() return true end,
        ValidateJob = function() return true end,
        StartJob = function() return true end,
        TickJob = function() return false, false, "fishing_npc_tired" end,
        CancelJob = function() cancelled = true; return true end,
    },
    Registry = {
        Get = function() return record end,
        GetLiveZombie = function() return nil end,
    },
    HomeDutyService = {
        IsCamped = function() return camped end,
    },
    Tasking = {
        Commands = {
            RegisterProvider = function(domain, provider)
                PNC.FishingRegisteredDomain = domain
                PNC.FishingRegistered = provider
                return true, provider
            end,
            CancelLease = function(_, reason)
                PNC.FishingCancelReason = reason
                return true
            end,
        },
    },
}

local Executor = T.load("ProjectHoomans", "server",
    "PNC/Fishing/PNC_FishingExecutor.lua")
T.equal(PNC.FishingRegisteredDomain, "fishing", "provider registration")
local candidates = Executor.GetCandidates("npc")
T.equal(#candidates, 1, "nearby fishing candidate")
T.truthy(Executor.Validate(candidates[1]), "fishing candidate validates")
jobs.npc.leaseId = "lease:1"
camped = true
T.equal(#Executor.GetCandidates("npc"), 0,
    "camped NPC has no fishing candidate")
T.falsy(Executor.Validate(candidates[1]),
    "camped fishing candidate does not validate")
local _, campReason = Executor.Assign(candidates[1])
T.equal(campReason, "NPC_CAMPED", "camped fishing assignment is rejected")
T.falsy(Executor.CanContinue({ npcId = "npc", sourceRef = jobs.npc.id,
    leaseId = "lease:1" }), "camped fishing lease cannot continue")
camped = false
local assignment = Executor.Assign(candidates[1])
T.equal(assignment.executionMode, "ABSTRACT", "abstract assignment")
T.truthy(Executor.Start({ npcId = "npc", leaseId = "lease:1" }),
    "fishing start")
jobs.npc.phase, jobs.npc.lastProgressAt = "WORKING", 100
local recovery = Executor.GetRecoveryState({ npcId = "npc",
    lastProgressAt = 0 })
T.truthy(recovery.watchable, "fishing exposes active work recovery")
T.equal(recovery.lastProgressAt, 100,
    "fishing recovery uses service progress")
jobs.npc.phase = "WAITING"
recovery = Executor.GetRecoveryState({ npcId = "npc" })
T.falsy(recovery.watchable, "fishing waiting state is not treated as a stall")
T.falsy(Executor.Tick({ npcId = "npc", leaseId = "lease:1" }),
    "terminal fishing tick")
T.equal(PNC.FishingCancelReason, "fishing_npc_tired", "tick cancellation")
T.truthy(Executor.Cancel({ npcId = "npc" }, "test"), "fishing cancel")
T.truthy(cancelled, "service cancellation")

T.finish("pnc_fishing_executor_smoke")
