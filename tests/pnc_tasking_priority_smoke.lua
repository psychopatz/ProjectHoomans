local ROOT = "Contents/mods/ProjectHoomans/42.20/media/lua/server/"
PsychopatzCore = { RuntimeRole = { AllowsServerCode = function() return true end } }
PNC = {}
local Priority = dofile(ROOT .. "PNC/Tasking/PNC_TaskPriority.lua")

local bands = Priority.ORDER
for index = 1, #bands - 1 do
    assert(Priority.Compare({ precedence = bands[index], urgency = 0 },
        { precedence = bands[index + 1], urgency = 1 }) > 0,
        bands[index] .. " must outrank " .. bands[index + 1])
end
assert(Priority.Compare({ precedence = "CRITICAL_NEED", urgency = 0 },
    { precedence = "NORMAL_WORK", urgency = 1 }) > 0,
    "scores must not leak across precedence bands")
local allowed, reason = Priority.CanPreempt({ precedence = "NORMAL_WORK",
    urgency = 0.76, phase = "WORKING" }, { precedence = "NORMAL_WORK",
    urgency = 0.77 })
assert(not allowed and reason == "CURRENT_TASK_STICKY",
    "tiny same-band changes should remain sticky")
assert(Priority.CanPreempt({ precedence = "NORMAL_WORK", urgency = 1,
    phase = "WORKING" }, { precedence = "CRITICAL_NEED", urgency = 0 }))
allowed, reason = Priority.CanPreempt({ precedence = "NORMAL_WORK",
    urgency = 0, phase = "ATOMIC_COMMIT" }, { precedence = "HARD_EMERGENCY",
    urgency = 1 })
assert(not allowed and reason == "CURRENT_TASK_ATOMIC",
    "atomic commits must not be interrupted")
assert(not Priority.CanPreempt({ precedence = "CRITICAL_NEED", urgency = 0,
    phase = "WORKING" }, { precedence = "NORMAL_WORK", urgency = 1 }),
    "work must not interrupt critical self-care")

print("pnc_tasking_priority_smoke: ok")
