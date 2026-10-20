-- Pure response mapping for semantic questions. The shared resolver supplies
-- presentation-safe helpers; this module reads only the IR and world snapshot.
local PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Response = PNC.Semantics.LocalResponse
local Internal = Response and Response.Internal or {}
local copyArgs = Internal.CopyArgs
local catalogResponse = Internal.CatalogResponse
local clockText = Internal.ClockText
local dayText = Internal.DayText
local weatherText = Internal.WeatherText
local identityText = Internal.IdentityText
local targetText = Internal.TargetText
local factFor = Internal.FactFor
local locationText = Internal.LocationText
local Facts = PNC.Semantics.DialogueFacts
if type(Facts) ~= "table" then
    local loaded = require "PNC/Semantics/PNC_SemanticDialogueFacts"
    Facts = type(loaded) == "table" and loaded or nil
end
local Semantic = PsychopatzCore and PsychopatzCore.Semantics or nil
local IR = Semantic and Semantic.IR or nil

local function resolveNeeds(ir, state, context)
    if ir and ir.subject == "QUANTITY" then
        return catalogResponse(
            "semantic.question.needs.quantity", ir, state, context
        )
    end
    return catalogResponse(
        "semantic.question.needs.offer", ir, state, context
    )
end

local function resolveTime(world)
    local text = clockText(world)
    if not text then return nil end
    return {
        templateID = "semantic.question.time",
        fallback = text,
        args = copyArgs({
            hour = world.time and world.time.hour,
            minute = world.time and world.time.minute,
            gameDay = world.gameDay,
        }),
    }
end

local function resolveDate(world)
    local text = dayText(world)
    if not text then return nil end
    local calendar = world.calendar or {}
    return {
        templateID = "semantic.question.date",
        fallback = text,
        args = copyArgs({
            gameDay = world.gameDay,
            year = calendar.year,
            month = calendar.month,
            day = calendar.day,
        }),
    }
end

local function resolveWeather(world)
    local text = weatherText(world)
    return {
        templateID = "semantic.question.weather",
        fallback = text or "I can't tell what the weather's doing right now.",
        args = copyArgs({ weather = world and world.weather }),
    }
end

local function resolveIdentityQuestion(ir, state, context)
    local text
    if context and context.identityTrust == "untrustworthy" then
        local response = catalogResponse(
            "semantic.question.identity", ir, state, context
        )
        if response then return response end
        text = "I don't share my name with liars. What's yours, truthfully?"
    elseif context and context.identityState == "known"
        and context.identityClaimVerified == true
    then
        text = identityText(context) .. " What's your name?"
    else
        local response = catalogResponse(
            "semantic.question.identity", ir, state, context
        )
        if response then return response end
        text = "I'll tell you my name once we've established some trust."
            .. " What's your name?"
    end
    return {
        templateID = "semantic.question.identity",
        fallback = text,
        args = copyArgs({
            npcName = context and (context.npcFullName or context.npcName),
        }),
    }
end

local function resolveActivity(ir, state, context)
    return catalogResponse(
        "semantic.question.activity", ir, state, context, {
            activity = context and context.dialogueSituation
                and context.dialogueSituation.npc
                and context.dialogueSituation.npc.activity
                and context.dialogueSituation.npc.activity.id,
        }
    )
end

local function resolveWellbeing(ir, state, context)
    local extensions = type(ir.extensions) == "table" and ir.extensions or nil
    local followsWellbeingAnswer = Internal.FollowsWellbeingAnswer
    local situation = context and context.dialogueSituation
    local npc = situation and situation.npc or nil
    local needs = npc and npc.needs or nil
    local emotion = npc and npc.emotion or nil
    local healthState = npc and npc.healthState or nil
    local personality = context and context.npcPersonality
    local authoredStyle = type(personality) == "table"
        and personality.socialStyle or nil
    if extensions and extensions.dialogueFollowUp == "WELLBEING"
        and type(followsWellbeingAnswer) == "function"
        and followsWellbeingAnswer(context)
    then
        return catalogResponse(
            "semantic.question.wellbeing.follow_up", ir, state, context
        )
    end
    if type(healthState) == "string"
        and (healthState == "injured"
            or healthState == "wounded"
            or healthState == "critical")
        and (authoredStyle == "friendly"
            or authoredStyle == "protective"
            or authoredStyle == "withdrawn")
    then
        local grounded = catalogResponse(
            "semantic.question.wellbeing.grounded", ir, state, context
        )
        if grounded then return grounded end
    end
    local healthUnknown = type(healthState) ~= "string"
        or healthState == ""
        or healthState == "unknown"
    if healthUnknown
        and (type(needs) ~= "table" or needs.highest == nil)
        and (type(emotion) ~= "table" or emotion.highest == nil)
    then
        return catalogResponse(
            "semantic.question.wellbeing.unknown", ir, state, context
        )
    end
    return catalogResponse(
        "semantic.question.wellbeing", ir, state, context, {
            needType = context and context.dialogueSituation
                and context.dialogueSituation.npc
                and context.dialogueSituation.npc.needs
                and context.dialogueSituation.npc.needs.highest,
        }
    )
end

local function resolveMedicalBiteStatus(ir, state, context)
    local fact = factFor(ir)
    local poolID = "semantic.question.medical_bite.unknown"
    if fact and fact.status == "known" then
        if fact.value == true then
            poolID = "semantic.question.medical_bite.positive"
        elseif fact.value == false then
            poolID = "semantic.question.medical_bite.negative"
        end
    end
    return catalogResponse(poolID, ir, state, context, {
        factStatus = fact and fact.status or "unknown",
        factProvider = fact and fact.provider,
        factRef = fact and fact.factRef,
    })
end

local function factTopic(ir, fact)
    local target = ir and ir.target
    local slot = ir and ir.slots and ir.slots.topic
    local value = fact and fact.topic
        or type(target) == "table" and (target.text or target.value)
        or target
        or type(slot) == "table" and (slot.text or slot.value)
        or slot
    value = tostring(value or "")
    return value ~= "" and value or "that"
end

local function factResponse(templateID, fallback, poolID, fact, topic, refs)
    return {
        templateID = templateID,
        fallback = fallback,
        sourcePoolID = poolID,
        dialogueAct = "FACT_ANSWER",
        topic = topic,
        groundedFactRefs = refs or {},
        uncertainty = fact and fact.status == "known" and "known"
            or "unknown",
        tone = "direct",
        selectionSource = "fact_provider",
        referenceTopic = topic,
    }
end

local function resolveResidenceQuestion(ir, state, context)
    local fact = factFor(ir)
    local value = fact and fact.value
    local label = type(value) == "table" and value.label or nil
    if fact and fact.status == "known" and label then
        return {
            templateID = "semantic.question.residence.known",
            fallback = "I live at " .. tostring(label) .. ".",
            args = copyArgs({ location = label }),
            sourcePoolID = "semantic.question.residence",
            dialogueAct = "FACT_ANSWER",
            topic = "RESIDENCE",
            groundedFactRefs = { "npc.residence" },
            uncertainty = "known",
            tone = "direct",
            selectionSource = "fact_provider",
        }
    end
    return factResponse(
        "semantic.question.residence.unknown",
        "I don't have a confirmed home to tell you about.",
        "semantic.question.residence",
        fact,
        "RESIDENCE"
    )
end

local function resolveHealthStateQuestion(ir, state, context)
    local fact = factFor(ir)
    local value = tostring(fact and fact.value or "")
    local fallback
    local templateID
    if fact and fact.status == "known" then
        if value == "injured" or value == "wounded" or value == "critical" then
            templateID = "semantic.question.health_state.injured"
            fallback = "I'm hurt, but I'm managing."
        elseif value == "healthy" or value == "normal" then
            templateID = "semantic.question.health_state.healthy"
            fallback = "I'm doing okay."
        end
        if templateID then
            return factResponse(
                templateID,
                fallback,
                "semantic.question.health_state",
                fact,
                "MEDICAL",
                { "npc.healthState" }
            )
        end
    end
    return factResponse(
        "semantic.question.health_state.unknown",
        "I can't confirm my health status right now.",
        "semantic.question.health_state",
        fact,
        "MEDICAL"
    )
end

local function resolveKnowledgeQuestion(ir, state, context)
    local fact = factFor(ir)
    local topic = factTopic(ir, fact)
    if fact and fact.status == "known" and fact.value == true then
        local answer = tostring(fact.answer or "")
        local fallback = "I know about " .. topic .. "."
        if answer ~= "" then fallback = fallback .. " " .. answer end
        local response = factResponse(
            "semantic.question.knowledge.known",
            fallback,
            "semantic.question.knowledge",
            fact,
            "KNOWLEDGE",
            { "npc.knowledge.topic" }
        )
        response.args = copyArgs({
            topic = answer ~= ""
                and (topic .. ". " .. string.gsub(answer, "[%s%.!?]+$", ""))
                or topic,
        })
        response.referenceTopic = topic
        return response
    end
    local response = factResponse(
        "semantic.question.knowledge.unknown",
        "I don't have reliable information about " .. topic .. ".",
        "semantic.question.knowledge",
        fact,
        "KNOWLEDGE"
    )
    response.args = copyArgs({ topic = topic })
    return response
end

local function resolveBackstoryQuestion(ir, state, context)
    local fact = factFor(ir)
    local content = fact and (fact.content or fact.value) or nil
    local kind = fact and fact.kind
        or ir and ir.slots and ir.slots.backstoryKind or "backstory"
    local refs = fact and fact.factID and { fact.factID } or {}
    local response
    local knownFallback = "Before all this, I was "
        .. tostring(content or "someone else") .. "."
    if kind == "hometown" then
        knownFallback = "I grew up in " .. tostring(content or "there") .. "."
    elseif kind == "former_job" then
        knownFallback = "I worked as a "
            .. tostring(content or "something else") .. " before all this."
    elseif kind == "education" then
        knownFallback = "I studied " .. tostring(content or "that") .. "."
    elseif kind == "hobby" then
        knownFallback = "I used to enjoy " .. tostring(content or "that") .. "."
    elseif kind == "family_background" then
        knownFallback = "My family was " .. tostring(content or "like that") .. "."
    elseif kind == "fear" then
        knownFallback = "I have always been afraid of "
            .. tostring(content or "that") .. "."
    elseif kind == "tragedy" then
        knownFallback = "Something happened: "
            .. tostring(content or "I lost people") .. "."
    end
    if fact and fact.status == "known"
        and type(content) == "string" and content ~= ""
    then
        local extensions = ir and type(ir.extensions) == "table"
            and ir.extensions or {}
        local authoredPool = extensions.responsePoolID
        local responseArgs = {
            kind = kind,
            content = content,
        }
        -- A generated interaction may supply its reviewed response pool. Use
        -- it only after the fact provider has returned an authorized known
        -- value; refusal and suspected branches retain their safe catalog
        -- responses and cannot turn an authored template into disclosure.
        if type(authoredPool) == "string" and authoredPool ~= "" then
            response = catalogResponse(
                authoredPool, ir, state, context, responseArgs
            )
        end
        local generatedPool = "semantic.question.backstory.known." .. tostring(kind)
        if not response then response = catalogResponse(
            generatedPool, ir, state, context, responseArgs
        ) end
        if not response then
            response = catalogResponse(
                "semantic.question.backstory.known", ir, state, context,
                responseArgs
            )
        end
        if response then
            response.dialogueAct = "FACT_ANSWER"
            response.topic = "NPC_BACKSTORY"
            response.groundedFactRefs = refs
            response.uncertainty = "known"
            response.tone = "direct"
            response.selectionSource = "fact_provider_catalog"
            return response
        end
        response = factResponse(
            "semantic.question.backstory.known",
            knownFallback,
            "semantic.question.backstory",
            fact,
            "NPC_BACKSTORY",
            refs
        )
        response.args = copyArgs({ kind = kind, content = content })
        return response
    end
    if fact and fact.status == "suspected"
        and type(content) == "string" and content ~= ""
    then
        response = catalogResponse(
            "semantic.question.backstory.suspected", ir, state, context, {
                kind = kind,
                content = content,
            }
        )
        if response then
            response.dialogueAct = "FACT_ANSWER"
            response.topic = "NPC_BACKSTORY"
            response.groundedFactRefs = refs
            response.uncertainty = "suspected"
            response.tone = "direct"
            response.selectionSource = "fact_provider_catalog"
            return response
        end
        response = factResponse(
            "semantic.question.backstory.suspected",
            "I think it was " .. content .. ", but I could be mistaken.",
            "semantic.question.backstory",
            fact,
            "NPC_BACKSTORY",
            refs
        )
        response.uncertainty = "suspected"
        response.args = copyArgs({ kind = kind, content = content })
        return response
    end
    if fact and fact.status == "ambiguous" then
        response = catalogResponse(
            "semantic.question.backstory.ambiguous", ir, state, context
        )
        if response then
            response.dialogueAct = "FACT_ANSWER"
            response.topic = "NPC_BACKSTORY"
            response.uncertainty = "ambiguous"
            response.tone = "cautious"
            response.selectionSource = "fact_provider_catalog"
            return response
        end
        return factResponse(
            "semantic.question.backstory.ambiguous",
            "Which part of my past do you mean?",
            "semantic.question.backstory",
            fact,
            "NPC_BACKSTORY"
        )
    end
    response = catalogResponse(
        "semantic.question.backstory.refusal", ir, state, context
    )
    if response then
        response.dialogueAct = "FACT_ANSWER"
        response.topic = "NPC_BACKSTORY"
        response.uncertainty = "pending"
        response.tone = "guarded"
        response.selectionSource = "fact_provider_catalog"
        return response
    end
    return factResponse(
        "semantic.question.backstory.refusal",
        "I'm not ready to talk about that yet.",
        "semantic.question.backstory",
        fact,
        "NPC_BACKSTORY"
    )
end

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

local function continuationResponse(templateID, fallback, topic)
    return {
        templateID = templateID,
        fallback = fallback,
        dialogueAct = "CONVERSATION_CONTINUATION",
        topic = topic,
        uncertainty = "unknown",
        tone = "conversational",
        selectionSource = "conversation_context",
    }
end

local function resolveConversationContinuation(ir, state, context)
    local recentAnswer = type(Internal.RecentAnswer) == "function"
        and Internal.RecentAnswer(context, 4) or nil
    local subject = recentAnswer and recentAnswer.subject or nil
    local topic = recentAnswer and recentAnswer.topic or nil

    if subject == "WELLBEING" or topic == "wellbeing" then
        local response = catalogResponse(
            "semantic.question.wellbeing.follow_up", ir, state, context
        )
        if response then
            response.dialogueAct = "CONVERSATION_CONTINUATION"
            response.selectionSource = "conversation_context"
            return response
        end
    end
    if subject == "GOSSIP" or topic == "gossip" then
        local gossip = context and context.npcGossip
        local hasMemory = type(gossip) == "table"
            and type(gossip.statements) == "table"
            and #gossip.statements > 0
        return continuationResponse(
            hasMemory
                and "semantic.conversation.continuation.gossip_memory"
                or "semantic.conversation.continuation.gossip_unknown",
            hasMemory
                and "That's all I know about it for now."
                or "I don't have anything else to add right now.",
            "gossip"
        )
    end
    if subject == "NPC_RESIDENCE" or topic == "location"
        or topic == "residence"
    then
        return continuationResponse(
            "semantic.conversation.continuation.residence",
            "That's all I can confirm about where I live right now.",
            "RESIDENCE"
        )
    end
    if subject == "NPC_BITE_STATUS" or subject == "NPC_HEALTH_STATE"
        or topic == "medical"
    then
        local situation = context and context.dialogueSituation
        local npc = situation and situation.npc
        local healthState = npc and npc.healthState
        local healthKnown = type(healthState) == "string"
            and healthState ~= ""
            and healthState ~= "unknown"
        return continuationResponse(
            healthKnown
                and "semantic.conversation.continuation.medical_known"
                or "semantic.conversation.continuation.medical_unknown",
            healthKnown
                and "I don't have anything more to add about my health right now."
                or "I can't confirm anything more about my health right now.",
            "MEDICAL"
        )
    end
    if subject == "NPC_KNOWLEDGE" or topic == "knowledge" then
        return continuationResponse(
            "semantic.conversation.continuation.knowledge",
            "I don't have anything else reliable to add about that.",
            "KNOWLEDGE"
        )
    end
    return continuationResponse(
        "semantic.conversation.continuation.default",
        "I don't have anything else to add about that right now.",
        topic or "conversation"
    )
end

local function isCommittedRelation(value)
    if type(value) ~= "string" then return false end
    value = string.lower(value)
    value = string.gsub(value, "[%s%-]", "_")
    value = string.gsub(value, "[^%w_]", "")
    return value == "lover" or value == "partner" or value == "spouse"
end

local function hasKnownCurrentPartner(context)
    context = type(context) == "table" and context or {}
    local relationship = type(context.relationship) == "table"
        and context.relationship or {}
    local npcRecord = type(context.npcRecord) == "table"
        and context.npcRecord or {}
    local npcGeneration = type(npcRecord.generation) == "table"
        and npcRecord.generation or {}
    local entry = type(context.entry) == "table" and context.entry or {}
    local entryRecord = type(entry.record) == "table" and entry.record or {}
    local entryGeneration = type(entryRecord.generation) == "table"
        and entryRecord.generation or {}

    return isCommittedRelation(context.relationshipState)
        or isCommittedRelation(context.conversationRelationshipID)
        or isCommittedRelation(context.relationshipKind)
        or isCommittedRelation(context.conversationRelationship)
        or isCommittedRelation(relationship.category)
        or isCommittedRelation(relationship.status)
        or isCommittedRelation(relationship.relationshipKind)
        or isCommittedRelation(relationship.relationshipState)
        or isCommittedRelation(npcGeneration.relationshipKind)
        or isCommittedRelation(entryGeneration.relationshipKind)
end

local function followsRecentCompliment(context)
    local recentTurns = type(Internal.RecentTurns) == "function"
        and Internal.RecentTurns(context, 2) or {}
    if type(recentTurns) ~= "table" or #recentTurns < 2 then
        return false
    end

    local npcReply = recentTurns[1]
    local playerCompliment = recentTurns[2]
    return type(npcReply) == "table"
        and npcReply.speaker == "npc"
        and npcReply.speechAct == "COMPLIMENT_RESPONSE"
        and type(playerCompliment) == "table"
        and playerCompliment.speaker == "player"
        and (playerCompliment.intent == "COMPLIMENT"
            or playerCompliment.speechAct == "COMPLIMENT")
end

local function resolveRelationshipStatus(ir, state, context)
    local followsCompliment = followsRecentCompliment(context)
    if hasKnownCurrentPartner(context) then
        if followsCompliment then
            local response = catalogResponse(
                "semantic.question.relationship_status.committed_after_compliment",
                ir,
                state,
                context
            )
            if response then return response end
        end
        return catalogResponse(
            "semantic.question.relationship_status.committed",
            ir,
            state,
            context
        ) or {
            templateID = "semantic.question.relationship_status.committed",
            fallback = "I thought we were already together.",
        }
    end

    if followsCompliment then
        local response = catalogResponse(
            "semantic.question.relationship_status.unknown_after_compliment",
            ir,
            state,
            context
        )
        if response then return response end
    end

    -- A missing partner fact is not evidence that the NPC is single. Keep the
    -- deterministic answer open-ended until the character has an authored or
    -- authoritative relationship status.
    return catalogResponse(
        "semantic.question.relationship_status.unknown",
        ir,
        state,
        context
    ) or {
        templateID = "semantic.question.relationship_status.uncertain",
        fallback = "I haven't really thought about dating. Right now, I'm focused on surviving.",
    }
end

local function resolveLocationOrSeen(ir)
    local fact = factFor(ir)
    if fact and fact.status == "known" then
        if ir.subject == "LOCATION" then
            return {
                templateID = "semantic.question.location",
                fallback = locationText(ir, fact),
                args = copyArgs({
                    target = targetText(ir.target, fact),
                    location = fact.location,
                    freshness = fact.freshness,
                }),
            }
        end
        if fact.value == true then
            return {
                templateID = "semantic.question.seen_yes",
                fallback = "Yes, I saw " .. targetText(ir.target, fact) .. ".",
                args = copyArgs({ target = targetText(ir.target, fact) }),
            }
        end
        if fact.value == false then
            return {
                templateID = "semantic.question.seen_no",
                fallback = "No, I haven't seen " .. targetText(ir.target, fact) .. ".",
                args = copyArgs({ target = targetText(ir.target, fact) }),
            }
        end
    elseif fact and fact.status == "ambiguous" then
        return {
            templateID = "semantic.question.fact_clarification",
            fallback = "I'm not sure which person you mean.",
            args = copyArgs({ target = targetText(ir.target, fact) }),
        }
    elseif ir.subject == "LOCATION" then
        return {
            templateID = "semantic.question.location_unknown",
            fallback = "I don't know where " .. targetText(ir.target, fact)
                .. " is.",
            args = copyArgs({ target = targetText(ir.target, fact) }),
        }
    else
        return {
            templateID = "semantic.question.seen_unknown",
            fallback = "I don't know if I've seen "
                .. targetText(ir.target, fact) .. ".",
            args = copyArgs({ target = targetText(ir.target, fact) }),
        }
    end
end

return function(ir, state, context)
    if type(ir) ~= "table" then return nil end
    local world = type(context) == "table" and context.worldContext or nil
    if ir.extensions
        and ir.extensions.dialogueFollowUp == "CONVERSATION_CONTINUATION"
    then
        return resolveConversationContinuation(ir, state, context)
    end
    if ir.subject == "TIME" then return resolveTime(world) end
    if ir.subject == "DATE" then return resolveDate(world) end
    if ir.subject == "WEATHER" then return resolveWeather(world) end
    if ir.subject == "IDENTITY" then
        return resolveIdentityQuestion(ir, state, context)
    end
    if ir.subject == "RELATIONSHIP_STATUS" then
        return resolveRelationshipStatus(ir, state, context)
    end
    if ir.subject == "ACTIVITY" then
        return resolveActivity(ir, state, context)
    end
    if ir.subject == "WELLBEING" then
        return resolveWellbeing(ir, state, context)
    end
    if ir.subject == "WELLBEING_RECIPROCAL" then
        local wellbeing = IR and type(IR.Clone) == "function"
            and IR.Clone(ir) or nil
        if wellbeing then
            wellbeing.subject = "WELLBEING"
            return resolveWellbeing(wellbeing, state, context)
        end
        return resolveWellbeing(ir, state, context)
    end
    if ir.subject == "NPC_BITE_STATUS" then
        return resolveMedicalBiteStatus(ir, state, context)
    end
    if ir.subject == "NPC_RESIDENCE" then
        return resolveResidenceQuestion(ir, state, context)
    end
    if ir.subject == "NPC_HEALTH_STATE" then
        return resolveHealthStateQuestion(ir, state, context)
    end
    if ir.subject == "NPC_KNOWLEDGE" then
        return resolveKnowledgeQuestion(ir, state, context)
    end
    if ir.subject == "NPC_BACKSTORY" then
        return resolveBackstoryQuestion(ir, state, context)
    end
    if ir.subject == "CONTEXT_REFERENCE" then
        return resolveContextReferenceQuestion(ir, state, context)
    end
    if ir.subject == "NEEDS" or ir.subject == "QUANTITY" then
        return resolveNeeds(ir, state, context)
    end
    if ir.subject == "LOCATION" or ir.subject == "SEEN" then
        return resolveLocationOrSeen(ir)
    end
    return nil
end
