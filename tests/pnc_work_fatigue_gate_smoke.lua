local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
})

PNC = {
    Const = { WORK_FATIGUE_STOP = 0.90 },
    IndividualNeeds = {
        Get = function(record, needType)
            return needType == "fatigue" and record.fatigue or nil
        end,
    },
}

local Gate = T.load("ProjectHoomans", "shared",
    "PNC/Core/Needs/PNC_WorkFatigueGate.lua")

local ok, reason, details = Gate.Check({ fatigue = 0.89 })
T.truthy(ok, "worker below the fatigue stop threshold may work")
T.equal(reason, nil, "healthy worker has no fatigue gate reason")
T.near(details.threshold, 0.90, 0.0001,
    "fatigue gate uses the configured 0.90 threshold")

ok, reason, details = Gate.Check({ fatigue = 0.90 })
T.falsy(ok, "worker at the fatigue stop threshold must rest")
T.equal(reason, "WORKER_NEEDS_REST", "fatigue gate reason")
T.near(details.fatigue, 0.90, 0.0001, "fatigue value is reported")

ok, reason = Gate.Check({ needs = { fatigue = 0.95 } })
T.falsy(ok, "legacy needs records are also gated")
T.equal(reason, "WORKER_NEEDS_REST", "legacy fatigue gate reason")

ok, reason, details = Gate.Check({})
T.truthy(ok, "records without needs remain compatibility-safe")
T.equal(reason, nil, "unknown fatigue has no false blocker")
T.falsy(details.known, "unknown fatigue is reported as unknown")

-- The durable work provider must invalidate an already-held lumber/corpse
-- lease when the NPC crosses the same threshold during travel or execution.
local worker = { id = "worker", alive = true, fatigue = 0.95 }
local order = {
    id = "work:1", operation = "LUMBER", workerId = worker.id,
    status = "WORKING",
}
PNC.Registry = { Get = function() return worker end }
PNC.WorkDefinitions = {
    STATUS = {
        CANCELLED = "CANCELLED", COMPLETED = "COMPLETED",
        FAILED = "FAILED", BLOCKED = "BLOCKED",
    },
    JOB_BY_OPERATION = {},
}
PNC.WorkService = { Queries = { Get = function() return order end } }
PNC.WorkPolicy = {
    GetPriority = function() return 1 end,
    NormalizePriority = function(value) return value end,
}
local registered
PNC.Tasking = {
    Commands = {
        RegisterProvider = function(_, provider)
            registered = provider
            return true
        end,
    },
}
local Provider = T.load("ProjectHoomans", "server",
    "PNC/Tasking/PNC_WorkTaskProvider.lua")
local canContinue, continueReason = Provider.CanContinue({
    npcId = worker.id, sourceRef = order.id,
})
T.falsy(canContinue, "fatigued lumber lease cannot continue")
T.equal(continueReason, "WORKER_NEEDS_REST",
    "fatigued lumber lease reports the rest handoff")
T.equal(registered, Provider, "work provider remains registered")

order.operation = "CORPSE_HAUL"
canContinue, continueReason = Provider.CanContinue({
    npcId = worker.id, sourceRef = order.id,
})
T.falsy(canContinue, "fatigued corpse lease cannot continue")
T.equal(continueReason, "WORKER_NEEDS_REST",
    "fatigued corpse lease reports the rest handoff")

return T.finish("pnc_work_fatigue_gate_smoke")
