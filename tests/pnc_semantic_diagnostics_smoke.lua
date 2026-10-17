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
    Semantics = {
        DialoguePolicy = {
            SelectCandidate = function() end,
            CommitFlow = function() end,
        },
    },
}
PNC.Translation = {
    Systems = {
        Conversation = {
            get = function() return "conversation" end,
            load = function() return true, { loaded = true } end,
        },
    },
}
CustomTranslationManager = {
    Systems = {
        ProjectHoomans = {
            Conversation = {
                manifestPath = "media/translation/manifests/Conversation.json",
                _manifestState = "loaded",
                _manifestPath = "media/translation/manifests/Conversation.json",
                _lastShardCount = 12,
            },
        },
    },
    registerSystem = function() end,
    forMod = function() end,
    getLanguage = function() return "EN" end,
}
PsychopatzCore.Semantics = {
    VERSION = 1,
    IR = { Validate = function() return true end },
    Parser = {
        Parse = function() end,
        ParseCandidates = function() end,
        CANDIDATE_VERSION = 1,
    },
    DialogueRouter = {
        VERSION = 1,
        New = function() end,
        Preview = function() end,
        ProcessIR = function() end,
        SetCandidateParser = function() end,
        SetCandidateSelector = function() end,
    },
}

local Diagnostics = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDiagnostics.lua"
)
local Handshake = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticCapabilityHandshake.lua"
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

local handshakeOK, handshake = Diagnostics.RecordCapabilityHandshake()
T.truthy(handshakeOK, "capability handshake accepts the matched contract")
T.truthy(handshake.ok, "capability handshake reports an OK contract")
T.truthy(handshake.parserCandidates,
    "capability handshake sees Core candidate parsing")
T.truthy(handshake.candidateSelection,
    "capability handshake sees Hoomans candidate selection")
T.truthy(handshake.flowCommit,
    "capability handshake sees Hoomans flow commit")
T.truthy(handshake.translation.manifestRead,
    "capability handshake sees the loaded Conversation manifest")
T.equal(traceEntries[#traceEntries].event,
    "semantic.capability_handshake",
    "capability handshake is emitted as a structured event")

Handshake.LastReport = nil
local parserCandidates = PsychopatzCore.Semantics.Parser.ParseCandidates
local manifestSource = CustomTranslationManager.Systems.ProjectHoomans.Conversation
PsychopatzCore.Semantics.Parser.ParseCandidates = nil
manifestSource.manifestPath = nil
manifestSource._manifestState = "error"
manifestSource._manifestPath = nil
local mismatchOK, mismatch = Diagnostics.RecordCapabilityHandshake()
T.falsy(mismatchOK, "capability mismatch is not reported as a pass")
local mismatchReasons = table.concat(mismatch.failures, ",")
T.contains(mismatchReasons, "parser_parse_candidates",
    "capability mismatch names the missing parser API")
T.contains(mismatchReasons, "conversation_manifest_registration",
    "capability mismatch names the missing manifest registration")
T.equal(traceEntries[#traceEntries].event,
    "semantic.capability_handshake",
    "capability mismatch remains visible as a structured event")
PsychopatzCore.Semantics.Parser.ParseCandidates = parserCandidates
manifestSource.manifestPath = "media/translation/manifests/Conversation.json"
manifestSource._manifestState = "loaded"
manifestSource._manifestPath = "media/translation/manifests/Conversation.json"

setting.apply(false)
T.falsy(Diagnostics.IsEnabled(), "setting apply disables semantic audit")
T.equal(Diagnostics.Record("disabled_again", {}), false,
    "disabled semantic audit returns to the cheap path")

T.finish("pnc_semantic_diagnostics_smoke")
