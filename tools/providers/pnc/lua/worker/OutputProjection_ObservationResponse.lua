-- Response and queued-message projection for an observation.

local Response = {}

local MAX_PLAN_TURNS = 4

local function initial(Values, response)
    return {
        templateID = response.templateID,
        renderTemplateID = response.renderTemplateID,
        sourcePoolID = response.sourcePoolID
            or response.plan and response.plan.sourcePoolID,
        fallback = response.fallback,
        text = response.fallback,
        key = response.templateID,
        semanticTemplateID = response.semanticTemplateID,
        args = Values.copy(response.args),
        dialogueAct = response.dialogueAct
            or response.plan and response.plan.dialogueAct,
        topic = response.topic or response.plan and response.plan.topic,
        groundedFactRefs = Values.copy(response.groundedFactRefs
            or response.plan and response.plan.groundedFactRefs),
        uncertainty = response.uncertainty
            or response.plan and response.plan.uncertainty,
        tone = response.tone or response.plan and response.plan.tone,
        personalityStyle = response.personalityStyle
            or response.plan and response.plan.personalityStyle,
        speechStyleContext = Values.copy(response.speechStyleContext),
        realization = Values.copy(response.realization),
        realizationFamily = response.realizationFamily,
        realizationVariant = response.realizationVariant,
        semanticVariantID = response.semanticVariantID,
        speechStyleVariant = response.speechStyleVariant,
        phraseFamilyID = response.phraseFamilyID,
        phraseID = response.phraseID,
        phrasePoolSize = response.phrasePoolSize,
        phraseAntiRepeatReason = response.phraseAntiRepeatReason,
        phraseSemanticTemplateID = response.phraseSemanticTemplateID,
        phraseSelection = Values.copy(response.phraseSelection),
        realizationFallbackReason = response.realizationFallbackReason,
        selectionID = response.selectionID,
        selectionSource = response.selectionSource,
        sourceFlowID = response.sourceFlowID,
        sourceBeatID = response.sourceBeatID,
        sourceBehaviorID = response.sourceBehaviorID,
        flowTransition = response.flowTransition,
        plan = Values.copy(response.plan),
        planTurnCount = type(response.plan) == "table"
            and math.min(#(response.plan.turns or {}), MAX_PLAN_TURNS) or 0,
        queued = {},
    }
end

local function queuedMessage(Values, payload, responseObservation, response)
    local text = payload.text or payload.fallback
    local fallback = payload.fallback or responseObservation.fallback
    local plan = payload.plan
    return {
        text = text,
        fallback = fallback,
        key = payload.key or payload.translationKey,
        semanticTemplateID = payload.semanticTemplateID
            or responseObservation.semanticTemplateID,
        args = Values.copy(payload.args),
        plan = Values.copy(plan),
        dialogueAct = plan and plan.dialogueAct,
        topic = plan and plan.topic,
        groundedFactRefs = Values.copy(plan and plan.groundedFactRefs),
        uncertainty = plan and plan.uncertainty,
        tone = plan and plan.tone,
        personalityStyle = plan and plan.personalityStyle,
        speechStyleContext = Values.copy(
            payload.speechStyleContext or response.speechStyleContext
        ),
        realization = Values.copy(payload.realization or response.realization),
        realizationFamily = payload.realizationFamily
            or response.realizationFamily,
        realizationVariant = payload.realizationVariant
            or response.realizationVariant,
        semanticVariantID = payload.semanticVariantID
            or response.semanticVariantID,
        speechStyleVariant = payload.speechStyleVariant
            or response.speechStyleVariant,
        phraseFamilyID = payload.phraseFamilyID or response.phraseFamilyID,
        phraseID = payload.phraseID or response.phraseID,
        phrasePoolSize = payload.phrasePoolSize or response.phrasePoolSize,
        phraseAntiRepeatReason = payload.phraseAntiRepeatReason
            or response.phraseAntiRepeatReason,
        phraseSemanticTemplateID = payload.phraseSemanticTemplateID
            or response.phraseSemanticTemplateID,
        phraseSelection = Values.copy(
            payload.phraseSelection or response.phraseSelection
        ),
        realizationFallbackReason = payload.realizationFallbackReason
            or response.realizationFallbackReason,
        translationKey = payload.translationKey,
        translationKeys = Values.copy(payload.translationKeys),
        planTurn = payload.planTurn,
        planTurnID = payload.planTurnID,
        planContinuation = payload.planContinuation,
        translated = text ~= nil
            and fallback ~= nil
            and text ~= fallback,
    }
end

local function applyFirstQueued(Values, responseObservation, queued, payload)
    responseObservation.text = queued.text
    responseObservation.fallback = queued.fallback
    responseObservation.key = queued.key
    responseObservation.semanticTemplateID = queued.semanticTemplateID
    responseObservation.translationKey = queued.translationKey
    responseObservation.translationKeys = queued.translationKeys
    -- Keep the semantic response identity canonical. The queued key is the
    -- presentation realization and remains available through response.key.
    responseObservation.templateID = payload.templateID
    responseObservation.plan = queued.plan
    responseObservation.planTurnCount = queued.plan
        and math.min(#(queued.plan.turns or {}), MAX_PLAN_TURNS) or 0
    responseObservation.domain = payload.domain
    responseObservation.planTurn = queued.planTurn
    responseObservation.planTurnID = queued.planTurnID
    responseObservation.planContinuation = queued.planContinuation
    responseObservation.translated = queued.translated
    responseObservation.dialogueAct = queued.dialogueAct
    responseObservation.topic = queued.topic
    responseObservation.groundedFactRefs = Values.copy(queued.groundedFactRefs)
    responseObservation.uncertainty = queued.uncertainty
    responseObservation.tone = queued.tone
    responseObservation.personalityStyle = queued.personalityStyle
    responseObservation.speechStyleContext = Values.copy(
        queued.speechStyleContext
    )
    responseObservation.realization = Values.copy(queued.realization)
    responseObservation.realizationFamily = queued.realizationFamily
    responseObservation.realizationVariant = queued.realizationVariant
    responseObservation.semanticVariantID = queued.semanticVariantID
    responseObservation.speechStyleVariant = queued.speechStyleVariant
    responseObservation.phraseFamilyID = queued.phraseFamilyID
    responseObservation.phraseID = queued.phraseID
    responseObservation.phrasePoolSize = queued.phrasePoolSize
    responseObservation.phraseAntiRepeatReason = queued.phraseAntiRepeatReason
    responseObservation.phraseSemanticTemplateID = queued.phraseSemanticTemplateID
    responseObservation.phraseSelection = Values.copy(queued.phraseSelection)
    responseObservation.realizationFallbackReason =
        queued.realizationFallbackReason
end

function Response.build(context, record, response)
    local Values = context.Values
    local responseObservation = initial(Values, response)
    for _, message in ipairs(record.messages or {}) do
        if type(message) == "table" and message.speaker == "npc" then
            local payload = type(message.payload) == "table"
                and message.payload or {}
            local queued = queuedMessage(
                Values, payload, responseObservation, response
            )
            if #responseObservation.queued < MAX_PLAN_TURNS then
                responseObservation.queued[#responseObservation.queued + 1] =
                    queued
            end
            if #responseObservation.queued == 1 then
                applyFirstQueued(
                    Values, responseObservation, queued, response
                )
            end
        end
    end
    responseObservation.queueCount = #responseObservation.queued
    responseObservation.composed = responseObservation.queueCount > 1
    return responseObservation
end

return Response
