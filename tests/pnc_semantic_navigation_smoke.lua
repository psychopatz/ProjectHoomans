local T = require "tests/support/test"
T.addPackagePaths()

PsychopatzCore = {}
PNC = {}

local Semantic = T.load(
    "PsychopatzCore",
    "common",
    "PsychopatzCore/Semantics/PsychopatzSemantic.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialoguePolicy.lua"
)
local Policy = PNC.Semantics.DialoguePolicy
local IR = Semantic.IR

local navigation = IR.New({
    kind = "semantic_navigation_frame",
    rawText = "Let's talk about something else.",
    normalizedText = "lets talk about something else",
    intent = "NAVIGATE",
    speechAct = "NAVIGATE",
    subject = "CONVERSATION_TOPIC",
    extensions = {
        topic = "conversation_navigation",
        navigationKind = "subject_change",
    },
    confidence = 1,
    provenance = {
        provider = "suggestion",
        parser = "semantic_navigation_frame",
        pattern = "subject_change",
    },
})

local decision = Policy.Decide(navigation, nil, {
    llmEnabled = false,
    npcID = "mara-navigation",
})

T.equal(decision.branch, "SEMANTIC_NAVIGATION_RECEIVED",
    "navigation frames use the semantic navigation branch")
T.equal(decision.response.templateID,
    "semantic.navigation.subject_change",
    "subject-change navigation selects a semantic response")
T.equal(decision.response.fallback,
    "All right. What did you want to talk about?",
    "subject-change navigation has visible acknowledgement copy")

T.finish("pnc_semantic_navigation_smoke")
