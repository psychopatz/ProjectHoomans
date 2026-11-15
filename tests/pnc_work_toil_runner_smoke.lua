local T = require "tests/support/test"

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local now = 1000
local dirtyMarks = 0
local movedCalls, haltCalls, resetCalls = 0, 0, 0
local ensureCalls, collectCalls, workTicks = 0, 0, 0
local toolOwned = false
local inputsReady = false
local movementRecovery = { phase = "moving", active = true, watchable = true }

local body = {
    x = 0, y = 0, z = 0,
    getX = function(self) return self.x end,
    getY = function(self) return self.y end,
    getZ = function(self) return self.z end,
}

local record = {
    id = "npc:worker", x = 0, y = 0, z = 0, runtime = {},
    orderSpec = { kind = "production_work", operation = "FARMING", phase = "ENSURE_TOOLS" },
}

PNC = {
    Core = { Now = function() return now end },
    Registry = {
        Get = function(id) return id == "npc:worker" and record or nil end,
        GetLiveZombie = function(id) return id == "npc:worker" and body or nil end,
    },
    WorkRepository = { MarkDirty = function() dirtyMarks = dirtyMarks + 1 end },
    BehaviorCommon = {
        ClearCombatTarget = function() end,
        MoveRecord = function() movedCalls = movedCalls + 1 end,
        HaltMovement = function() haltCalls = haltCalls + 1 end,
    },
    PathService = {
        GetMovementRecoveryState = function() return movementRecovery end,
        Commands = {
            Reset = function() resetCalls = resetCalls + 1; return true end,
        },
    },
    WorkItemService = {
        OperationHasRequirements = function(op) return op == "FARMING" end,
        Ensure = function()
            ensureCalls = ensureCalls + 1
            return toolOwned, toolOwned and nil or "TOOL_MISSING"
        end,
        PrepareForWorker = function(order)
            order.waitingReason = "WAITING_FOR_WORK_ITEM"
            return true, "WAITING_FOR_WORK_ITEM"
        end,
    },
    WorkService = {
        Commands = {
            CollectInputs = function()
                collectCalls = collectCalls + 1
                if inputsReady then return true end
                return false, "INPUT_PENDING"
            end,
        },
    },
}

T.load("ProjectHoomans", "server", "PNC/Production/WorkService/PNC_WorkToilRunner.lua")
local Runner = PNC.WorkToilRunner

-- 1. ObserveLiveApproach backoff, stall recovery, exhausted stall, arrival
local pos = { x = 10, y = 10, z = 0, arriveDistance = 1.0 }
movementRecovery = { phase = "backoff", nativeBackoff = true, watchable = true }
local state = Runner.ObserveLiveApproach(record, body, "tile:10:10", pos, now)
T.equal(state, "backoff", "respects native backoff without firing extra stall reset")

now = now + 4000
movementRecovery = { phase = "moving", nativeBackoff = false, watchable = true }
state = Runner.ObserveLiveApproach(record, body, "tile:10:10", pos, now)
T.equal(state, "moving", "moving while within stall timeout")

now = now + 13000
state = Runner.ObserveLiveApproach(record, body, "tile:10:10", pos, now)
T.equal(state, "recovered", "first stall resets PathService")
T.equal(resetCalls, 1, "PathService Reset invoked once")

now = now + 16000
state = Runner.ObserveLiveApproach(record, body, "tile:10:10", pos, now)
T.equal(state, "recovered", "second stall resets PathService")
T.equal(resetCalls, 2, "PathService Reset invoked twice")

now = now + 16000
state = Runner.ObserveLiveApproach(record, body, "tile:10:10", pos, now)
T.equal(state, "stalled", "third stall reports stalled when maxRecoveries reached")

body.x, body.y = 9.5, 10
state = Runner.ObserveLiveApproach(record, body, "tile:10:10", pos, now)
T.equal(state, "arrived", "arrives inside envelope and clears watch")
T.equal(record.runtime.workApproachWatch.default, nil, "watch cleared on arrival")
T.truthy(haltCalls >= 1, "halts movement on arrival")

-- 2. Full 5-phase RunToilStep orchestration
local delivered = false
local order = {
    id = "wo:farm:1",
    operation = "FARMING",
    workerId = "npc:worker",
    executionMode = "LIVE",
    requiresInputs = true,
    x = 5, y = 5, z = 0,
    phase = Runner.PHASES.ENSURE_TOOLS,
}
local adapter = {
    workTarget = function(o)
        workTicks = workTicks + 1
        if workTicks < 2 then return "working", "PLOWING" end
        o.outputEffect = { id = "eff:1", state = "PENDING" }
        return "output_ready", "HARVESTED"
    end,
    deliverOutputs = function()
        delivered = true
        return true, "COMPLETED"
    end,
}

-- Tool missing triggers PrepareForWorker and pauses in ENSURE_TOOLS
local ok, reason = Runner.RunToilStep(order, nil, adapter)
T.falsy(ok, "pauses when tool missing")
T.equal(reason, "WAITING_FOR_WORK_ITEM", "queues/reports work item pickup wait")
T.equal(order.phase, Runner.PHASES.ENSURE_TOOLS, "stays in ENSURE_TOOLS")

-- Tool acquired -> moves to COLLECT_INPUTS -> waits until inputs ready
toolOwned = true
ok, reason = Runner.RunToilStep(order, nil, adapter)
T.falsy(ok, "pauses when inputs not yet collected")
T.equal(order.phase, Runner.PHASES.COLLECT_INPUTS, "advanced to COLLECT_INPUTS")
T.equal(collectCalls, 1, "CollectInputs attempted")

-- Inputs collected -> moves to APPROACH_TARGET -> walks toward (5,5)
inputsReady = true
body.x, body.y = 0, 0
ok, reason = Runner.RunToilStep(order, nil, adapter)
T.truthy(ok, "moves toward target during APPROACH_TARGET")
T.equal(order.phase, Runner.PHASES.APPROACH_TARGET, "advanced to APPROACH_TARGET")
T.equal(record.orderSpec.phase, Runner.PHASES.APPROACH_TARGET,
    "record.orderSpec.phase synced")

-- Arrive at target -> enters WORK_TARGET
body.x, body.y = 5, 5
ok, reason = Runner.RunToilStep(order, nil, adapter)
T.truthy(ok and reason == "PLOWING", "first WORK_TARGET tick reports working")
T.equal(order.phase, Runner.PHASES.WORK_TARGET, "advanced to WORK_TARGET")

-- Second WORK_TARGET tick finishes -> transitions to DELIVER_OUTPUTS and runs delivery
ok, reason = Runner.RunToilStep(order, nil, adapter)
T.truthy(ok and reason == "COMPLETED", "deliverOutputs completes toil pipeline")
T.truthy(delivered, "deliverOutputs invoked")

-- 3. Abstract mode skips physical movement directly to WORK_TARGET -> DELIVER_OUTPUTS
local abstractOrder = {
    id = "wo:farm:2",
    operation = "FARMING",
    workerId = "npc:worker",
    executionMode = "ABSTRACT",
    requiresInputs = false,
    x = 50, y = 50, z = 0,
    phase = Runner.PHASES.ENSURE_TOOLS,
}
delivered = false
workTicks = 1 -- next tick triggers output_ready immediately
ok, reason = Runner.RunToilStep(abstractOrder, nil, adapter)
T.truthy(ok and reason == "COMPLETED", "abstract toil reaches completion cleanly")
T.truthy(delivered, "abstract delivery runs on completion")

T.finish("pnc_work_toil_runner_smoke")
