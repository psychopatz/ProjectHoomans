-- Semantic interaction-plan construction; no wording or gameplay authority.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local ValueBounds = require "PNC/Semantics/PNC_SemanticValueBounds"
local Plan = PNC.Semantics.InteractionPlan or {}
PNC.Semantics.InteractionPlan = Plan

Plan.VERSION = 1

function Plan.Build(beat, behavior, stimulus, state, pragmatic)
    if type(behavior) ~= "table" then return nil end
    stimulus = type(stimulus) == "table" and stimulus or {}
    local semantic = type(stimulus.semantic) == "table"
        and stimulus.semantic or {}
    pragmatic = type(pragmatic) == "table" and pragmatic or {}
    local outputs = ValueBounds.Copy(behavior.outputs) or {}
    local speech = type(outputs.speech) == "table" and outputs.speech or nil
    return {
        schemaVersion = Plan.VERSION,
        kind = "semantic_interaction_plan",
        behaviorID = behavior.id,
        behaviorAct = behavior.act,
        behaviorMode = behavior.mode,
        beatID = beat and beat.id or nil,
        topic = pragmatic.topic
            or semantic.topic
            or state and state.currentTopic
            or nil,
        subject = pragmatic.subject or semantic.subject,
        sourceStimulusType = stimulus.type,
        sourceActorID = stimulus.source and stimulus.source.actorID or nil,
        targetActorIDs = ValueBounds.Copy(stimulus.targets) or {},
        sourceIntent = semantic.intent,
        sourceSpeechAct = semantic.speechAct,
        groundedFactRefs = ValueBounds.Copy(pragmatic.groundedFactRefs) or {},
        groundedEventRefs = ValueBounds.Copy(pragmatic.groundedEventRefs) or {},
        continuation = ValueBounds.Copy(behavior.continuation),
        outputs = outputs,
        -- Compatibility aliases while ResponsePlan consumes speech output.
        dialogueAct = speech and speech.dialogueAct or nil,
        contentTemplateID = speech and speech.contentTemplateID or nil,
    }
end

return Plan
