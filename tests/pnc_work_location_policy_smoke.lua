local T = require "tests/support/test"

T.addPackagePaths()

PNC = {
    Core = { Now = function() return 1000 end },
    WorkService = { Internal = {} },
}
local Work = T.load("ProjectHoomans", "server",
    "PNC/Production/WorkService/PNC_WorkService_WorkLocation.lua")
local Location = Work.Location

local corpsePolicy = Location.Normalize({
    operation = "CORPSE_HAUL",
    locationPolicy = { start = "HOME", execution = "REMOTE",
        returnHome = "HOME" },
})
T.equal(corpsePolicy.start, "HOME", "corpse starts at home")
T.equal(corpsePolicy.execution, "REMOTE", "corpse executes remotely")
T.equal(corpsePolicy.returnHome, "HOME", "corpse returns home")
local lumberPolicy = Location.Normalize({
    operation = "LUMBER",
    locationPolicy = { start = "ANYWHERE", execution = "REMOTE",
        returnHome = "STAY" },
})
T.equal(lumberPolicy.start, "ANYWHERE", "lumber may start away")
T.equal(lumberPolicy.execution, "REMOTE", "lumber executes remotely")
T.equal(lumberPolicy.returnHome, "STAY", "lumber does not auto-return")

local events = 0
PNC.HomeDutyService = {
    IsAtHome = function() return false end,
    IsReturningHome = function() return false end,
}
PNC.Registry = {
    MarkDirty = function() end,
}
PNC.Tasking = {
    Events = { Emit = function() events = events + 1 end },
}
local record = { id = "npc-1", runtime = {} }
local order = {
    id = "work:1", operation = "CORPSE_HAUL", workerId = "npc-1",
    baseId = "base-1",
    locationPolicy = corpsePolicy,
}
T.equal(Location.Classify(record, order), "AWAY_FOR_WORK",
    "remote work is not ordinary away state")
T.equal(Location.Observe(record, order, 1000), "AWAY_FOR_WORK",
    "remote state observation")
T.equal(events, 1, "location transition emits one event")
T.equal(record.runtime.workLocation.state, "AWAY_FOR_WORK",
    "location projection state")
T.truthy(Location.Clear(record, order.id), "location projection clears")

return T.finish("pnc_work_location_policy_smoke")
