local T = require "tests/support/test"
T.addPackagePaths()

PNC = {}

local ConversationRegistry = require
    "PNC/Semantics/Generated/Conversation/Registry"
local Catalog = require "PNC/Semantics/PNC_SemanticInteractionCatalog"
local Behaviors = Catalog.Behaviors
local Beats = Catalog.Beats

T.equal(#Behaviors.List(), 30,
    "generated Conversation source registers thirty reusable behaviors")
T.equal(#Beats.List(), 3,
    "generated Conversation source registers three initial beats")

local warn = Behaviors.Get("behavior.warn")
T.truthy(warn, "warn behavior is registered")
local canonicalWarn
for index = 1, #(ConversationRegistry.BEHAVIORS or {}) do
    if ConversationRegistry.BEHAVIORS[index].id == "behavior.warn" then
        canonicalWarn = ConversationRegistry.BEHAVIORS[index]
        break
    end
end
T.truthy(warn == canonicalWarn,
    "interaction catalog returns the canonical generated behavior object")
T.equal(warn.act, "WARN",
    "warn behavior preserves its semantic behavior act")
T.equal(warn.mode, "beat",
    "warn behavior remains beat-bound")
T.equal(warn.outputs.speech.dialogueAct, "BOUNDARY_WARNING",
    "warn speech output preserves its dialogue act")
T.equal(warn.outputs.speech.contentTemplateID,
    "semantic.social.hostile_boundary",
    "warn behavior references ordinary Dialogue Content")
T.falsy(warn.labelKey,
    "structural behavior definitions do not own localized labels")

local argument = Beats.Get("beat.argument_escalation")
T.truthy(argument, "argument escalation beat is registered")
T.equal(#argument.candidates, 4,
    "argument escalation exposes bounded behavior candidates")
T.equal(argument.candidates[1].behavior, "behavior.warn",
    "argument beat references reusable behavior ids")
T.falsy(argument.labelKey,
    "structural beat definitions do not own localized labels")

local badBehavior, behaviorReason = Behaviors.Validate({
    id = "behavior.bad",
    act = "BAD",
    mode = "beat",
    stimuli = { "HUMAN_UTTERANCE" },
    requiredCapabilities = { "speech" },
    outputs = {
        speech = {
            dialogueAct = "BAD",
            contentTemplateID = "semantic.social.hostile_boundary",
        },
    },
    baseRelevance = 2,
})
T.falsy(badBehavior, "out-of-range behavior relevance is rejected")
T.equal(behaviorReason, "behavior_relevance_invalid",
    "behavior validation reports the precise invalid relevance")

local badBeat, beatReason = Beats.Validate({
    id = "beat.bad",
    stimuli = { "HUMAN_UTTERANCE" },
    entry = {
        path = "stimulus.semantic.intent", op = "eq", value = "INSULT",
    },
    maintain = { path = "scene.ended", op = "falsy" },
    exit = { path = "scene.ended", op = "truthy" },
    candidates = {
        { behavior = "behavior.missing", relevance = 0.5 },
    },
    maxTurns = 1,
    cooldownTurns = 0,
    labelKey = "UI_Bad_Beat",
})
T.falsy(badBeat, "beat cannot reference an unknown behavior")
T.equal(beatReason, "beat_behavior_unknown:behavior.missing",
    "beat validation reports its missing behavior reference")

local draft = {
    id = "beat.lab_test",
    owner = "SemanticLab",
    version = 1,
    stimuli = { "HUMAN_UTTERANCE" },
    entry = {
        path = "stimulus.semantic.intent", op = "eq", value = "INSULT",
    },
    maintain = { path = "scene.ended", op = "falsy" },
    exit = { path = "scene.ended", op = "truthy" },
    candidates = {
        { behavior = "behavior.warn", relevance = 0.8 },
    },
    maxTurns = 2,
    cooldownTurns = 0,
    labelKey = "UI_Lab_Test_Beat",
}
local validDraft, normalized = Beats.Validate(draft)
T.truthy(validDraft, "harness-style beat draft validates through production registry")
T.equal(normalized.candidates[1].behavior, "behavior.warn",
    "validated draft retains production behavior reference")
local registeredDraft, registered = Beats.RegisterDraft(draft)
T.truthy(registeredDraft, "valid beat draft can register worker-locally")
T.truthy(Beats.Get("beat.lab_test") == registered,
    "registered draft is available from the production registry")

T.finish("pnc_semantic_interaction_registry_smoke")
