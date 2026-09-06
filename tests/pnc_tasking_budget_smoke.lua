local T = require "tests/support/test"

-- Verifies that tasking stops after its time budget and resumes queued work
-- on the next scheduled pump.

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local clock = 0
local queue = {}
for index = 1, 5 do
    queue[#queue + 1] = { npcId = "npc:" .. tostring(index) }
end

local Tasking = {
    Commands = {},
    Providers = {},
    Executors = {},
    Internal = {
        SafeCall = function(_, callback, _, ...)
            return true, callback(...)
        end,
    },
    Events = { Emit = function() end },
    Inbox = {
        Count = function() return #queue end,
        Pop = function()
            local entry = table.remove(queue, 1)
            return entry
        end,
        Causes = function() return {} end,
    },
    Diagnostics = { counters = {
        eventProcesses = 0, executorFailures = 0, executorTicks = 0,
    } },
    TaskLeaseService = { Active = {}, Get = function() return nil end },
    NextPumpAt = 0,
    ExecutorCursor = 0,
    PUMP_INTERVAL_MS = 250,
    TIME_BUDGET_MS = 2,
    MAX_REEVALUATIONS_PER_PUMP = 8,
    MAX_EXECUTOR_TICKS_PER_PUMP = 16,
    ORPHAN_RECONCILE_INTERVAL_MS = 5000,
    NextOrphanReconcileAt = 0,
    Initialized = true,
}

PNC = {
    Core = { Now = function() return clock end },
    Tasking = Tasking,
    TaskLeaseService = Tasking.TaskLeaseService,
}

Tasking.Commands.Reevaluate = function()
    clock = clock + 1
    return true
end

T.load("ProjectHoomans", "server", "PNC/Tasking/Tasking/PNC_Tasking_Pump.lua")

local first = Tasking.Commands.Pump(0)
T.equal(first, 2, "first tasking pump respects its time budget")
T.equal(#queue, 3, "first tasking pump leaves queued work")

clock = 250
local second = Tasking.Commands.Pump(clock)
T.equal(second, 2, "second tasking pump resumes queued work")
T.equal(#queue, 1, "second tasking pump leaves only the final entry")

clock = 500
local third = Tasking.Commands.Pump(clock)
T.equal(third, 1, "third tasking pump drains the remaining entry")
T.equal(#queue, 0, "tasking queue is eventually drained")

T.finish("pnc_tasking_budget_smoke")
