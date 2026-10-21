-- Versioned, non-executing semantic dialogue suggestions.
--
-- Suggestions are derived from the production semantic result and response
-- plan.  This module deliberately does not parse text, dispatch actions, or
-- mutate dialogue state.  A later click adapter may turn the typed frame
-- into an IR and send it through the existing DialogueInput boundary.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Suggestions = PNC.Semantics.DialogueSuggestions or {}
PNC.Semantics.DialogueSuggestions = Suggestions

Suggestions.VERSION = 1
Suggestions.MAX_CANDIDATES = 5
Suggestions.MAX_TRACE = 12
Suggestions.MAX_SOURCES = 4

local function boundedText(value, limit)
    value = tostring(value or "")
    limit = tonumber(limit) or 128
    if #value > limit then return string.sub(value, 1, limit) end
    return value
end

local function copyValue(value, depth)
    if type(value) ~= "table" then return value end
    depth = tonumber(depth) or 0
    if depth >= 4 then return nil end
    local output = {}
    local count = 0
    local key
    local item
    for key, item in pairs(value) do
        if count >= 12 then break end
        if type(key) == "string" or type(key) == "number" then
            if type(item) ~= "function" then
                output[key] = copyValue(item, depth + 1)
                count = count + 1
            end
        end
    end
    return output
end

local function normalized(value)
    return string.upper(tostring(value or ""))
end

local function resolvedText(key, fallback)
    local translation = PNC.Translation
    if translation and type(translation.GetKey) == "function" then
        local ok, value = pcall(translation.GetKey, key, fallback)
        if ok and type(value) == "string" and value ~= "" then
            return value
        end
    end
    local core = PsychopatzCore and PsychopatzCore.Translation or nil
    if core and type(core.GetKey) == "function" then
        local ok, value = pcall(core.GetKey, key, fallback)
        if ok and type(value) == "string" and value ~= "" then
            return value
        end
    end
    return fallback or key or ""
end

-- These are semantic frames, not parser inputs.  patternID is retained as
-- provenance for the later click adapter; it is never used to reparse text.
local DEFINITIONS = {
    {
        id = "question.wellbeing",
        order = 10,
        patternID = "pnc.question.wellbeing_feeling",
        labelKey = "UI_PNC_Conversation_Suggestion_Wellbeing_Label",
        labelFallback = "How are you feeling?",
        utteranceKey = "UI_PNC_Conversation_Suggestion_Wellbeing_Utterance",
        utteranceFallback = "How are you feeling?",
        intent = "QUESTION",
        speechAct = "QUESTION",
        subject = "WELLBEING",
    },
    {
        id = "question.wellbeing_detail",
        order = 20,
        patternID = "pnc.question.wellbeing_follow_up_what_is_wrong",
        labelKey = "UI_PNC_Conversation_Suggestion_WellbeingDetail_Label",
        labelFallback = "Can you tell me more?",
        utteranceKey = "UI_PNC_Conversation_Suggestion_WellbeingDetail_Utterance",
        utteranceFallback = "What's wrong?",
        intent = "QUESTION",
        speechAct = "QUESTION",
        subject = "WELLBEING",
        extensions = { dialogueFollowUp = "WELLBEING" },
        slots = { followUp = true },
    },
    {
        id = "question.needs",
        order = 30,
        patternID = "pnc.question.needs_offer_plain",
        labelKey = "UI_PNC_Conversation_Suggestion_Needs_Label",
        labelFallback = "Do you need anything?",
        utteranceKey = "UI_PNC_Conversation_Suggestion_Needs_Utterance",
        utteranceFallback = "Do you need anything?",
        intent = "QUESTION",
        speechAct = "QUESTION",
        subject = "NEEDS",
        extensions = {
            topic = "needs",
            dialogueFollowUp = "NEEDS_QUANTITY",
        },
    },
    {
        id = "question.health",
        order = 40,
        patternID = "pnc.question.health.are_you_hurt",
        labelKey = "UI_PNC_Conversation_Suggestion_Health_Label",
        labelFallback = "Are you hurt?",
        utteranceKey = "UI_PNC_Conversation_Suggestion_Health_Utterance",
        utteranceFallback = "Are you hurt?",
        intent = "QUESTION",
        speechAct = "QUESTION",
        subject = "NPC_HEALTH_STATE",
        target = "SELF",
        slots = { attribute = "health_state" },
        modifiers = { directed = true },
        socialContext = {
            directed = true,
            personalQuestion = true,
            target = "SELF",
        },
        extensions = { topic = "medical" },
    },
    {
        id = "question.identity",
        order = 50,
        patternID = "pnc.question.identity",
        labelKey = "UI_PNC_Conversation_Suggestion_Identity_Label",
        labelFallback = "Who are you?",
        utteranceKey = "UI_PNC_Conversation_Suggestion_Identity_Utterance",
        utteranceFallback = "Who are you?",
        intent = "QUESTION",
        speechAct = "QUESTION",
        subject = "IDENTITY",
    },
}

local function revisionFor(result)
    result = type(result) == "table" and result or {}
    local state = type(result.state) == "table" and result.state or {}
    local revision = tonumber(result.sequence or state.sequence) or 0
    return revision, "turn-" .. tostring(revision)
end

local function privateResult(result)
    local ir = result and result.ir or nil
    local decision = result and result.decision or nil
    local response = decision and decision.response or nil
    local plan = response and response.plan or nil
    local values = { result, ir, decision, response, plan }
    local index
    local value
    for index = 1, #values do
        value = values[index]
        if type(value) == "table" then
            if value.private == true or value.secret == true then return true end
            if normalized(value.visibility) == "PRIVATE"
                or normalized(value.privacy) == "PRIVATE"
                or normalized(value.visibility) == "SECRET"
                or normalized(value.privacy) == "SECRET"
            then
                return true
            end
        end
    end
    return false
end

local function responseTopic(result, messages)
    local decision = result and result.decision or {}
    local response = type(decision.response) == "table"
        and decision.response or {}
    local plan = type(response.plan) == "table" and response.plan or {}
    local flow = type(decision.flow) == "table" and decision.flow or {}
    local values = {
        response.topic,
        plan.topic,
        response.sourcePoolID,
        plan.sourcePoolID,
        flow.responsePool,
    }
    local index
    local value
    for index = 1, #values do
        value = tostring(values[index] or "")
        value = string.lower(value)
        if string.find(value, "wellbeing", 1, true) then
            return "WELLBEING"
        end
        if string.find(value, "needs", 1, true) then
            return "NEEDS"
        end
        if string.find(value, "identity", 1, true) then
            return "IDENTITY"
        end
        if string.find(value, "medical", 1, true)
            or string.find(value, "health", 1, true)
        then
            return "NPC_HEALTH_STATE"
        end
    end
    for index = 1, #(type(messages) == "table" and messages or {}) do
        local message = messages[index]
        local payload = type(message) == "table"
            and type(message.payload) == "table" and message.payload or nil
        local messagePlan = payload and type(payload.plan) == "table"
            and payload.plan or nil
        if messagePlan then
            local messageValues = {
                messagePlan.topic,
                messagePlan.sourcePoolID,
                payload.topic,
                payload.sourcePoolID,
            }
            local messageIndex
            local messageValue
            for messageIndex = 1, #messageValues do
                messageValue = string.lower(
                    tostring(messageValues[messageIndex] or "")
                )
                if string.find(messageValue, "wellbeing", 1, true) then
                    return "WELLBEING"
                end
                if string.find(messageValue, "needs", 1, true) then
                    return "NEEDS"
                end
                if string.find(messageValue, "identity", 1, true) then
                    return "IDENTITY"
                end
                if string.find(messageValue, "medical", 1, true)
                    or string.find(messageValue, "health", 1, true)
                then
                    return "NPC_HEALTH_STATE"
                end
            end
        end
    end
    return nil
end

local function definitionFor(id)
    local index
    for index = 1, #DEFINITIONS do
        if DEFINITIONS[index].id == id then return DEFINITIONS[index] end
    end
    return nil
end

local function definitionForSubject(subject, followUp)
    subject = normalized(subject)
    if followUp == true and subject == "WELLBEING" then
        return definitionFor("question.wellbeing_detail")
    end
    if subject == "WELLBEING" then return definitionFor("question.wellbeing") end
    if subject == "NEEDS" then return definitionFor("question.needs") end
    if subject == "IDENTITY" then return definitionFor("question.identity") end
    if subject == "NPC_HEALTH_STATE" then return definitionFor("question.health") end
    return nil
end

local function sourceRecord(kind, revision, reason)
    return {
        kind = kind,
        revision = revision,
        reason = reason,
    }
end

local function addCandidate(output, seen, definition, kind, revision, reason)
    if not definition then return end
    local candidate = seen[definition.id]
    if candidate then
        if #candidate.sources < Suggestions.MAX_SOURCES then
            candidate.sources[#candidate.sources + 1] =
                sourceRecord(kind, revision, reason)
        end
        return
    end
    if #output >= Suggestions.MAX_CANDIDATES then return end

    local frame = {
        schemaVersion = Suggestions.VERSION,
        kind = "semantic_click_frame",
        candidateID = definition.id,
        patternID = definition.patternID,
        intent = definition.intent,
        speechAct = definition.speechAct,
        subject = definition.subject,
        target = definition.target,
        slots = copyValue(definition.slots) or {},
        modifiers = copyValue(definition.modifiers) or {},
        socialContext = copyValue(definition.socialContext) or {},
        extensions = copyValue(definition.extensions) or {},
        requestRevision = revision,
    }
    candidate = {
        id = definition.id,
        rank = #output + 1,
        source = sourceRecord(kind, revision, reason),
        sources = { sourceRecord(kind, revision, reason) },
        frame = frame,
        display = {
            labelKey = definition.labelKey,
            labelFallback = definition.labelFallback,
            label = resolvedText(definition.labelKey, definition.labelFallback),
            utteranceKey = definition.utteranceKey,
            utteranceFallback = definition.utteranceFallback,
            utterance = resolvedText(
                definition.utteranceKey,
                definition.utteranceFallback
            ),
        },
        visibility = "player",
    }
    output[#output + 1] = candidate
    seen[definition.id] = candidate
end

local function appendTrace(trace, kind, status, reason, count)
    if #trace >= Suggestions.MAX_TRACE then return end
    trace[#trace + 1] = {
        source = kind,
        status = status,
        reason = reason,
        candidateCount = count,
    }
end

function Suggestions.Build(result, context, messages)
    result = type(result) == "table" and result or {}
    context = type(context) == "table" and context or {}
    local revision, turnID = revisionFor(result)
    local candidates = {}
    local seen = {}
    local trace = {}
    local ir = type(result.ir) == "table" and result.ir or {}

    if privateResult(result) then
        appendTrace(trace, "typed_input", "hidden", "private_or_secret", 0)
        appendTrace(trace, "npc_response_plan", "hidden", "private_or_secret", 0)
        return {
            schemaVersion = Suggestions.VERSION,
            kind = "semantic_dialogue_suggestions",
            revision = revision,
            turnID = turnID,
            candidates = {},
            sources = {},
            trace = trace,
        }
    end

    local subject = normalized(ir.subject)
    local typedReason = subject ~= "" and "interpreted_frame" or "no_subject"
    local typedSource = sourceRecord("typed_input", revision, typedReason)
    local typedEligible = result.accepted == true and subject ~= ""
    if typedEligible then
        if subject == "WELLBEING" then
            addCandidate(
                candidates, seen, definitionFor("question.wellbeing_detail"),
                "typed_input", revision, "wellbeing_follow_up"
            )
        end
        addCandidate(
            candidates, seen, definitionFor("question.wellbeing"),
            "typed_input", revision, "safe_question"
        )
        addCandidate(
            candidates, seen, definitionFor("question.needs"),
            "typed_input", revision, "safe_question"
        )
        addCandidate(
            candidates, seen, definitionFor("question.health"),
            "typed_input", revision, "safe_question"
        )
        addCandidate(
            candidates, seen, definitionFor("question.identity"),
            "typed_input", revision, "safe_question"
        )
        appendTrace(trace, "typed_input", "allowed", typedReason, #candidates)
    else
        appendTrace(trace, "typed_input", "skipped", typedReason, #candidates)
    end

    local topic = responseTopic(result, messages)
    local planSource = sourceRecord(
        "npc_response_plan", revision,
        topic and "known_safe_topic" or "topic_unknown"
    )
    if topic then
        local followUp = topic == "WELLBEING"
        local definition = definitionForSubject(topic, followUp)
        addCandidate(
            candidates, seen, definition,
            "npc_response_plan", revision, "response_plan_topic"
        )
        appendTrace(trace, "npc_response_plan", "allowed", topic, #candidates)
    else
        appendTrace(trace, "npc_response_plan", "skipped", "topic_unknown", #candidates)
    end

    return {
        schemaVersion = Suggestions.VERSION,
        kind = "semantic_dialogue_suggestions",
        revision = revision,
        turnID = turnID,
        candidates = candidates,
        sources = {
            typedSource,
            planSource,
        },
        trace = trace,
        privacy = {
            playerVisible = true,
            privateFieldsInspected = false,
            unknownFieldsExposed = false,
        },
    }
end

return Suggestions
