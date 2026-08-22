local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "server", "")
PsychopatzCore = { RuntimeRole = { AllowsServerCode = function() return true end } }
PNC = {}
local Priority = T.load(ROOT .. "PNC/Tasking/PNC_TaskPriority.lua")

local bands = Priority.ORDER
for index = 1, #bands - 1 do
    T.truthy(Priority.Compare({ precedence = bands[index], urgency = 0 },
        { precedence = bands[index + 1], urgency = 1 }) > 0,
        bands[index] .. " must outrank " .. bands[index + 1])
end
T.truthy(Priority.Compare({ precedence = "CRITICAL_NEED", urgency = 0 },
    { precedence = "NORMAL_WORK", urgency = 1 }) > 0,
    "scores must not leak across precedence bands")
local allowed, reason = Priority.CanPreempt({ precedence = "NORMAL_WORK",
    urgency = 0.76, phase = "WORKING" }, { precedence = "NORMAL_WORK",
    urgency = 0.77 })
T.truthy(not allowed and reason == "CURRENT_TASK_STICKY",
    "tiny same-band changes should remain sticky")
T.truthy(Priority.CanPreempt({ precedence = "NORMAL_WORK", urgency = 1,
    phase = "WORKING" }, { precedence = "CRITICAL_NEED", urgency = 0 }))
allowed, reason = Priority.CanPreempt({ precedence = "NORMAL_WORK",
    urgency = 0, phase = "ATOMIC_COMMIT" }, { precedence = "HARD_EMERGENCY",
    urgency = 1 })
T.truthy(not allowed and reason == "CURRENT_TASK_ATOMIC",
    "atomic commits must not be interrupted")
T.truthy(not Priority.CanPreempt({ precedence = "CRITICAL_NEED", urgency = 0,
    phase = "WORKING" }, { precedence = "NORMAL_WORK", urgency = 1 }),
    "work must not interrupt critical self-care")
T.finish("pnc_tasking_priority_smoke")

T.finish("pnc_tasking_priority_smoke")
