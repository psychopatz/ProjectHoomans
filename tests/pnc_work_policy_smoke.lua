local T = require "tests/support/test"

PNC = {
    Core = {
        DeepCopy = function(value)
            if type(value) ~= "table" then return value end
            local output = {}
            for key, item in pairs(value) do
                output[key] = PNC.Core.DeepCopy(item)
            end
            return output
        end,
    },
    WorkDefinitions = {
        COLONY_JOBS = { "Constructor", "MedicalCare" },
    },
}

local Policy = T.load("ProjectHoomans", "shared",
    "PNC/Core/Production/WorkDefinition/PNC_WorkPolicy.lua")

T.equal(Policy.GetPriority({}, "Constructor"), 3,
    "missing policy did not preserve the default priority")
T.equal(Policy.GetPriority({ allowedJobs = { Constructor = false } },
    "Constructor"), 0, "legacy disabled boolean was not migrated")
T.equal(Policy.GetPriority({ allowedJobs = { Constructor = true } },
    "Constructor"), 3, "legacy enabled boolean did not migrate")
T.equal(Policy.GetPriority({ jobPriorities = { Constructor = 1 } },
    "Constructor"), 1, "numeric priority was not read")
T.equal(Policy.NormalizePriority(99), 4, "priority was not clamped")
T.equal(Policy.NormalizePriority(-2), 0, "disabled priority was not clamped")

local record = { allowedJobs = { Constructor = true } }
T.equal(Policy.SetPriority(record, "Constructor", 1), 1,
    "priority mutation failed")
T.equal(record.jobPriorities.Constructor, 1,
    "canonical priority was not written")
T.truthy(record.allowedJobs.Constructor,
    "legacy enabled compatibility value was not written")
T.equal(Policy.SetPriority(record, "Constructor", 0), 0,
    "priority disable mutation failed")
T.falsy(record.allowedJobs.Constructor,
    "legacy compatibility value was not disabled")
T.falsy(Policy.HasAnyEnabled(record, { "Constructor" }),
    "all disabled jobs were reported as enabled")

local Priority = T.load("ProjectHoomans", "server",
    "PNC/Tasking/PNC_TaskPriority.lua")
T.truthy(Priority.Compare({ precedence = "NORMAL_WORK", urgency = 0.5,
    workPriority = 1, createdAt = 2, taskId = "first" }, {
    precedence = "NORMAL_WORK", urgency = 0.5,
    workPriority = 4, createdAt = 1, taskId = "second" }) > 0,
    "priority 1 did not outrank priority 4")

T.finish("pnc_work_policy_smoke")
