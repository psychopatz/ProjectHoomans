-- Context-reference question responses.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Response = PNC.Semantics.LocalResponse
local Internal = Response and Response.Internal or {}
Response.Internal = Internal
local copyArgs = Internal.CopyArgs
local catalogResponse = Internal.CatalogResponse
local factFor = Internal.FactFor
local Facts = PNC.Semantics.DialogueFacts
if type(Facts) ~= "table" then
    local loaded = require "PNC/Semantics/PNC_SemanticDialogueFacts"
    Facts = type(loaded) == "table" and loaded or nil
end
local Semantic = PsychopatzCore and PsychopatzCore.Semantics or nil
local IR = Semantic and Semantic.IR or nil
local resolveMedicalBiteStatus = Internal.ResolveMedicalBiteStatus
local resolveResidenceQuestion = Internal.ResolveResidenceQuestion
local resolveHealthStateQuestion = Internal.ResolveHealthStateQuestion
local resolveKnowledgeQuestion = Internal.ResolveKnowledgeQuestion
local resolveBackstoryQuestion = Internal.ResolveBackstoryQuestion

local function contextReferenceResponse(
    templateID,
    fallback,
    topic,
    uncertainty,
    factRefs
)
    return {
        templateID = templateID,
        fallback = fallback,
        dialogueAct = "FACT_ANSWER",
        topic = topic or "CONVERSATION",
        groundedFactRefs = factRefs or {},
        uncertainty = uncertainty or "unknown",
        tone = "direct",
        selectionSource = "conversation_reference",
    }
end

local function recentReferenceAnswer(context)
    local responseTurn = type(Internal.RecentAnswer) == "function"
        and Internal.RecentAnswer(context, 4) or nil
    if type(responseTurn) ~= "table"
        or responseTurn.branch ~= "QUESTION_RECEIVED"
    then
        return nil
    end
    return responseTurn
end

local function recentBackstoryAnswer(context, responseTurn)
    if type(responseTurn) == "table"
        and responseTurn.subject == "NPC_BACKSTORY"
    then
        return responseTurn
    end
    local dialogue = context and (
        context.semanticDialogueContext or context.semanticContextState
    ) or nil
    local turns = type(dialogue) == "table" and dialogue.recentTurns or nil
    if type(turns) ~= "table" and type(dialogue) == "table"
        and type(dialogue.RecentTurns) == "function"
    then
        turns = dialogue:RecentTurns(6, true)
    end
    for index = 1, math.min(type(turns) == "table" and #turns or 0, 6) do
        local turn = turns[index]
        if type(turn) == "table"
            and turn.speaker == "npc"
            and turn.speechAct == "ANSWER"
            and turn.branch == "QUESTION_RECEIVED"
            and turn.subject == "NPC_BACKSTORY"
        then
            return turn
        end
    end
    return nil
end

local function derivedQuestion(ir, subject, state, context)
    if not IR or type(IR.Clone) ~= "function" then return nil end
    if not Facts or type(Facts.Annotate) ~= "function" then return nil end
    local output = IR.Clone(ir)
    output.subject = subject
    output.extensions = type(output.extensions) == "table"
        and output.extensions or {}
    output.extensions.facts = nil
    output.diagnostics = type(output.diagnostics) == "table"
        and output.diagnostics or {}
    Facts.Annotate(output, state, context)
    return output
end

local function adoptDerivedFact(ir, derived)
    local fact = derived and derived.extensions
        and derived.extensions.facts and derived.extensions.facts[derived.subject]
    if type(fact) ~= "table" then return nil end
    ir.extensions = type(ir.extensions) == "table" and ir.extensions or {}
    ir.extensions.facts = type(ir.extensions.facts) == "table"
        and ir.extensions.facts or {}
    ir.extensions.facts["CONTEXT_REFERENCE"] = fact
    ir.diagnostics = type(ir.diagnostics) == "table"
        and ir.diagnostics or {}
    ir.diagnostics.factSubject = derived.subject
    ir.diagnostics.factStatus = fact.status
    ir.diagnostics.factProvider = fact.provider
    ir.diagnostics.factReason = fact.reason
    ir.provenance = type(ir.provenance) == "table" and ir.provenance or {}
    ir.provenance.factResolver = fact.provider or "none"
    return fact
end

local function resolveContextReferenceQuestion(ir, state, context)
    local target = ir and ir.target
    local answer = recentBackstoryAnswer(
        context, recentReferenceAnswer(context)
    )
    -- The resolver has already selected a concrete concept for a resolved
    -- pronoun. Keep that authoritative concept when the serialized context
    -- does not expose the preceding answer turn to this provider.
    local subject = answer and answer.subject
        or target and target.concept or nil
    local extensions = type(ir.extensions) == "table" and ir.extensions or {}
    local questionKind = extensions.contextQuestion
    local backstoryFollowUp = subject == "NPC_BACKSTORY"
        and (questionKind == "BACKSTORY_LOCATION"
            or questionKind == "BACKSTORY_MISS")

    if questionKind == "CAUSE" then
        local causeTopic = answer and answer.topic
            or subject
            or "CONVERSATION"
        local response = contextReferenceResponse(
            "semantic.conversation.context_reference.cause_unknown",
            answer
                and "I can confirm what happened, but I don't know why it is that way."
                or "I don't know why that is; I can't confirm the cause.",
            causeTopic,
            "unknown"
        )
        response.referenceSubject = subject
        response.causeResolution = "unavailable"
        return response
    end

    if type(target) ~= "table"
        or ((target.unresolved == true or target.resolvedReference == nil)
            and not backstoryFollowUp)
    then
        return contextReferenceResponse(
            "semantic.conversation.context_reference.unknown",
            "I'm not sure what you're referring to.",
            "CONVERSATION",
            "unknown"
        )
    end

    if questionKind == "SAFETY" then
        local response = contextReferenceResponse(
            "semantic.conversation.context_reference.location_safety_unknown",
            "I don't have reliable information about whether it's safe there.",
            "RESIDENCE",
            "unknown"
        )
        response.referenceSubject = subject
        return response
    end

    if questionKind == "DESCRIPTION"
        and subject ~= "NPC_KNOWLEDGE"
    then
        local response = contextReferenceResponse(
            "semantic.conversation.context_reference.description_unknown",
            "I don't know enough about that place to describe it.",
            answer and answer.topic or "CONVERSATION",
            "unknown"
        )
        response.referenceSubject = subject
        return response
    end

    if questionKind == "MEDICAL_PAIN"
        and subject ~= "NPC_HEALTH_STATE"
        and subject ~= "NPC_BITE_STATUS"
    then
        local response = contextReferenceResponse(
            "semantic.conversation.context_reference.medical_unknown",
            "I can't confirm anything about that pain right now.",
            "MEDICAL",
            "unknown"
        )
        response.referenceSubject = subject
        return response
    end

    if subject == "NPC_BITE_STATUS" or subject == "NPC_HEALTH_STATE" then
        local derived = derivedQuestion(
            ir,
            questionKind == "MEDICAL_PAIN" and "NPC_HEALTH_STATE"
                or subject,
            state,
            context
        )
        local fact = adoptDerivedFact(ir, derived)
        local response
        if derived and derived.subject == "NPC_BITE_STATUS" then
            response = resolveMedicalBiteStatus(derived, state, context)
        elseif derived then
            response = resolveHealthStateQuestion(derived, state, context)
        end
        if response then
            response.selectionSource = "conversation_reference"
            response.referenceResolution = "dialogue_context"
            response.referenceSubject = subject
            return response
        end
        local fallback = contextReferenceResponse(
            "semantic.conversation.context_reference.medical_unknown",
            "I can't confirm anything about my health right now.",
            "MEDICAL",
            fact and fact.status == "known" and "known" or "unknown"
        )
        fallback.referenceSubject = subject
        return fallback
    end

    if subject == "NPC_RESIDENCE" then
        local derived = derivedQuestion(ir, subject, state, context)
        local fact = adoptDerivedFact(ir, derived)
        local response = derived
            and resolveResidenceQuestion(derived, state, context) or nil
        if response then
            response.selectionSource = "conversation_reference"
            response.referenceResolution = "dialogue_context"
            response.referenceSubject = subject
            return response
        end
        local fallback = contextReferenceResponse(
            "semantic.conversation.context_reference.unknown",
            "I don't have enough confirmed information about that place.",
            "RESIDENCE",
            fact and fact.status == "known" and "known" or "unknown"
        )
        fallback.referenceSubject = subject
        return fallback
    end

    if subject == "NPC_KNOWLEDGE" then
        local derived = derivedQuestion(ir, subject, state, context)
        local fact = adoptDerivedFact(ir, derived)
        local response = derived
            and resolveKnowledgeQuestion(derived, state, context) or nil
        if response then
            response.selectionSource = "conversation_reference"
            response.referenceResolution = "dialogue_context"
            response.referenceSubject = subject
            return response
        end
        local fallback = contextReferenceResponse(
            "semantic.conversation.context_reference.unknown",
            "I don't have enough reliable information about that.",
            "KNOWLEDGE",
            fact and fact.status == "known" and "known" or "unknown"
        )
        fallback.referenceSubject = subject
        return fallback
    end

    if subject == "NPC_BACKSTORY" then
        if questionKind == "BACKSTORY_LOCATION"
            or questionKind == "BACKSTORY_MISS"
        then
            local poolID = questionKind == "BACKSTORY_LOCATION"
                and "semantic.question.backstory.follow_up.location"
                or "semantic.question.backstory.follow_up.miss"
            local response = catalogResponse(
                poolID, ir, state, context
            )
            if response then
                response.selectionSource = "conversation_reference"
                response.referenceResolution = "dialogue_context"
                response.referenceSubject = subject
                response.topic = "NPC_BACKSTORY"
                return response
            end
        end
        local dialogue = context and (
            context.semanticContextState or context.semanticDialogueContext
        ) or nil
        local kind = dialogue and dialogue.lastBackstoryKind or nil
        if kind then
            local derived = derivedQuestion(
                ir, "NPC_BACKSTORY", state, context
            )
            if derived then
                derived.slots = { backstoryKind = kind }
                derived.extensions.facts = nil
                Facts.Annotate(derived, state, context)
                local response = resolveBackstoryQuestion(
                    derived, state, context
                )
                if response then
                    response.selectionSource = "conversation_reference"
                    response.referenceResolution = "dialogue_context"
                    response.referenceSubject = subject
                    return response
                end
            end
        end
        return contextReferenceResponse(
            "semantic.conversation.context_reference.backstory_unknown",
            "I'm not sure which part of my past you mean.",
            "NPC_BACKSTORY",
            "unknown"
        )
    end

    return contextReferenceResponse(
        "semantic.conversation.context_reference.unknown",
        "I'm not sure what you're referring to.",
        answer and answer.topic or "CONVERSATION",
        "unknown"
    )
end

Internal.ResolveContextReferenceQuestion = resolveContextReferenceQuestion

return Response
