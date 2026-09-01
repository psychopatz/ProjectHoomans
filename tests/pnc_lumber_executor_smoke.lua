local T = require "tests/support/test"

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local jobs = {
    worker = {
        id = "job:worker", npcId = "worker", zoneId = "zone:1",
        active = true, revision = 3, createdAt = 10,
    },
}
local live = true
local started, cancelled, completed

PNC = {
    Const = { ORDER_LUMBER = "lumber" },
    LumberService = {
        GetJob = function(id) return jobs[tostring(id)] end,
        GetZone = function(id)
            return tostring(id) == "zone:1"
                and { enabled = true, workers = { worker = true } }
                or nil
        end,
        ValidateJob = function(npcId, jobId)
            return tostring(npcId) == "worker"
                and tostring(jobId) == "job:worker"
        end,
        StartJob = function(lease)
            started = true
            jobs.worker.leaseId = lease.leaseId
            return true
        end,
        TickJob = function() return true, false, "working" end,
        CancelJob = function() cancelled = true; return true end,
        RestoreOrder = function() end,
        ReleaseTree = function() end,
    },
    Registry = {
        GetLiveZombie = function() return live and {} or nil end,
    },
    Tasking = {
        Commands = {
            RegisterProvider = function(_, provider)
                -- Supports both colon-style and function-style test doubles.
                if type(_) == "table" then return true, provider end
                return true, _
            end,
        },
    },
    OrderSystem = {
        RegisterNormalizer = function() return true end,
    },
    JobSystem = { RegisterOrder = function() return true end },
    BehaviorRegistry = { Register = function() return true end },
}

-- The production call is dot-style; expose a capture that accepts it.
PNC.Tasking.Commands.RegisterProvider = function(domain, provider)
    PNC.LumberExecutorRegisteredDomain = domain
    PNC.LumberExecutorRegistered = provider
    return true, provider
end

local Executor = T.load("ProjectHoomans", "server",
    "PNC/Lumber/PNC_LumberExecutor.lua")
T.equal(PNC.LumberExecutorRegisteredDomain, "lumber",
    "lumber provider registration")
local candidates = Executor.GetCandidates("worker")
T.equal(#candidates, 1, "one lumber candidate")
T.equal(candidates[1].sourceRef, "job:worker", "candidate job reference")
T.truthy(Executor.Validate(candidates[1]), "candidate remains valid")
local assignment = Executor.Assign(candidates[1])
T.equal(assignment.executionMode, "LIVE", "live execution mode")
T.truthy(Executor.Start({ npcId = "worker", leaseId = "lease:1",
    sourceRef = "job:worker", executionMode = assignment.executionMode }),
    "provider start")
T.truthy(started, "service start called")
T.truthy(Executor.CanContinue({
    npcId = "worker", leaseId = "lease:1", sourceRef = "job:worker",
}), "provider can continue")
T.truthy(Executor.Tick({ npcId = "worker", leaseId = "lease:1" }),
    "provider tick")
T.truthy(Executor.Cancel({ npcId = "worker", leaseId = "lease:1" }, "test"),
    "provider cancel")
T.truthy(cancelled, "service cancel called")

live = false
assignment = Executor.Assign(candidates[1])
T.equal(assignment.executionMode, "ABSTRACT", "abstract execution mode")

T.finish("pnc_lumber_executor_smoke")
