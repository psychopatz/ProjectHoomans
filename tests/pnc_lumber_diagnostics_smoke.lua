local T = require "tests/support/test"

local setting
local logs = 0
local traces = 0

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
    DebugSettings = {
        Register = function(spec) setting = spec end,
        IsEnabled = function() return false end,
    },
    DebugTrace = {
        Record = function() traces = traces + 1 end,
    },
}

PNC = {
    Core = {
        Now = function() return 1000 end,
        LogInfo = function() logs = logs + 1 end,
    },
    LumberService = {},
}

local Diagnostics = T.load("ProjectHoomans", "server",
    "PNC/Lumber/LumberService/PNC_LumberService_Diagnostics.lua")
T.equal(setting.id, "ProjectHoomans.LumberAudit",
    "lumber audit setting is registered centrally")
T.falsy(Diagnostics.IsEnabled(), "lumber audit defaults disabled")
T.equal(setting.defaultEnabled, false, "lumber audit is opt-in")
T.equal(setting.runtimeMutable, true, "lumber audit is runtime mutable")

setting.apply(true)
T.truthy(Diagnostics.IsEnabled(), "lumber audit can be enabled")
local record = { id = "npc:1", runtime = {} }
local job = { id = "job:1", phase = "CHOPPING", targetKey = "tree:1" }
T.truthy(Diagnostics.RecordTransition(record, job, nil, "abstract_chopping", {
    treeLoaded = true,
}), "first transition is recorded")
T.equal(logs, 1, "lumber transition logs once")
T.equal(traces, 1, "lumber transition enters the debug trace")
T.falsy(Diagnostics.RecordTransition(record, job, nil, "abstract_chopping", {
    treeLoaded = true,
}), "unchanged transition is deduplicated")
T.equal(logs, 1, "duplicate transition does not spam logs")

setting.apply(false)
T.falsy(Diagnostics.IsEnabled(), "lumber audit can be disabled")

T.finish("pnc_lumber_diagnostics_smoke")
