local T = require "tests/support/test"
T.addPackagePaths()

local logs = {}
local traceEntries = {}
local setting
local enabled = false
local clock = 1000

local settings = {
    Register = function(definition)
        setting = definition
        definition.apply(enabled)
        return definition
    end,
    IsEnabled = function()
        return enabled
    end,
}

PsychopatzCore = {
    DebugSettings = settings,
    DebugTrace = {
        Record = function(definition)
            traceEntries[#traceEntries + 1] = definition
            return true
        end,
    },
}
PNC = {
    Core = {
        Now = function() return clock end,
        LogInfo = function(message) logs[#logs + 1] = message end,
    },
    Semantics = {},
}

local Diagnostics = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDiagnostics.lua"
)

T.equal(setting.id, "ProjectHoomans.SemanticDialogueAudit",
    "semantic audit registers a central debug setting")
T.falsy(Diagnostics.IsEnabled(), "semantic audit defaults off")
T.equal(Diagnostics.Record("disabled", { rawText = "not retained" }), false,
    "disabled semantic audit does not record")
T.equal(#logs, 0, "disabled semantic audit does not log")
T.equal(#traceEntries, 0, "disabled semantic audit does not trace")

enabled = true
setting.apply(true)
T.truthy(Diagnostics.IsEnabled(), "setting apply enables semantic audit")
T.truthy(Diagnostics.Record("nlu.parsed", {
    requestID = "request-one",
    rawText = string.rep("x", 400),
    route = "local",
    diagnostics = {
        fuzzyMatch = false,
        nested = { value = "kept" },
    },
    callback = function() end,
}, {
    requestID = "request-one",
}), "enabled semantic audit records")

T.equal(#traceEntries, 1, "enabled semantic audit writes one trace event")
T.equal(traceEntries[1].source, "ProjectHoomans.Semantics",
    "trace event uses the semantic source")
T.equal(traceEntries[1].event, "nlu.parsed",
    "trace event preserves the stage")
T.equal(traceEntries[1].requestID, "request-one",
    "trace event preserves correlation")
T.equal(#traceEntries[1].data.rawText, 256,
    "trace payload bounds raw text")
T.equal(traceEntries[1].data.callback, "[omitted:function]",
    "trace payload omits executable values")
T.equal(traceEntries[1].data.diagnostics.nested.value, "kept",
    "trace payload preserves bounded diagnostic context")
T.contains(logs[1], "semantic_audit event=nlu.parsed",
    "enabled semantic audit writes a compact console line")
T.contains(logs[1], "requestID=\"request-one\"",
    "console line preserves correlation")

Diagnostics.Record("progress", { planID = "plan-one", state = "TRAVEL" }, {
    requestID = "request-one",
    dedupeKey = "plan-one|TRAVEL",
    consoleIntervalMs = 100,
})
Diagnostics.Record("progress", { planID = "plan-one", state = "TRAVEL" }, {
    requestID = "request-one",
    dedupeKey = "plan-one|TRAVEL",
    consoleIntervalMs = 100,
})
T.equal(#traceEntries, 3,
    "console deduplication does not discard structured trace events")
T.equal(#logs, 2, "repeated progress is bounded in the console")

clock = 1200
Diagnostics.Record("progress", { planID = "plan-one", state = "TRAVEL" }, {
    requestID = "request-one",
    dedupeKey = "plan-one|TRAVEL",
    consoleIntervalMs = 100,
})
T.equal(#logs, 3, "progress logs again after the dedupe interval")

setting.apply(false)
T.falsy(Diagnostics.IsEnabled(), "setting apply disables semantic audit")
T.equal(Diagnostics.Record("disabled_again", {}), false,
    "disabled semantic audit returns to the cheap path")

T.finish("pnc_semantic_diagnostics_smoke")
