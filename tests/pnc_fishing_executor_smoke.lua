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
local assignment = Executor.Assign(candidates[1])
T.equal(assignment.executionMode, "ABSTRACT", "abstract assignment")
T.truthy(Executor.Start({ npcId = "npc", leaseId = "lease:1" }),
    "fishing start")
T.falsy(Executor.Tick({ npcId = "npc", leaseId = "lease:1" }),
    "terminal fishing tick")
T.equal(PNC.FishingCancelReason, "fishing_npc_tired", "tick cancellation")
T.truthy(Executor.Cancel({ npcId = "npc" }, "test"), "fishing cancel")
T.truthy(cancelled, "service cancellation")

T.finish("pnc_fishing_executor_smoke")
