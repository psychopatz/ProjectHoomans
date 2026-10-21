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
local Predicates = PNC.Semantics.SuggestionPredicates
    or require "PNC/Semantics/PNC_SemanticDialogueSuggestionPredicates"
local IR = PsychopatzCore.Semantics and PsychopatzCore.Semantics.IR
    or require "PsychopatzCore/Semantics/PsychopatzSemanticIR"
local BranchOffers = PNC.Semantics.DialogueBranchOffers
    or require "PNC/Semantics/PNC_SemanticDialogueBranchOffers"

Suggestions.VERSION = 1
Suggestions.MAX_CANDIDATES = 5
Suggestions.MAX_TRACE = 12
Suggestions.MAX_SOURCES = 4

local TEXT_CACHE = {}

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

local PREDICATE_IR_FIELDS = {
    "intent", "speechAct", "action", "subject", "target", "reference",
    "identityClaim", "selfDirected", "stateType", "stateValue", "pattern",
    "normalizedText", "confidence",
}

local function predicateIR(value)
    local output = {}
    if type(value) ~= "table" then return output end
    for index = 1, #PREDICATE_IR_FIELDS do
        local key = PREDICATE_IR_FIELDS[index]
        if value[key] ~= nil then output[key] = copyValue(value[key]) end
    end
    return output
end

local function normalized(value)
    return string.upper(tostring(value or ""))
end

local function normalizedText(value)
    value = string.lower(tostring(value or ""))
    value = string.gsub(value, "[^%w]+", " ")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    return value
end

local function resolvedText(key, fallback)
    key = tostring(key or "")
    fallback = fallback or key
    local language = "EN"
    local manager = CustomTranslationManager
    if manager and type(manager.getLanguage) == "function" then
        local ok, value = pcall(manager.getLanguage)
        if ok and value then language = tostring(value) end
    end
    TEXT_CACHE[language] = TEXT_CACHE[language] or {}
    if TEXT_CACHE[language][key] ~= nil then
        return TEXT_CACHE[language][key]
    end
    local translation = PNC.Translation
    if translation and type(translation.GetKey) == "function" then
        local ok, value = pcall(translation.GetKey, key, fallback)
        if ok and type(value) == "string" and value ~= "" then
            TEXT_CACHE[language][key] = value
            return value
        end
    end
    local core = PsychopatzCore and PsychopatzCore.Translation or nil
    if core and type(core.GetKey) == "function" then
        local ok, value = pcall(core.GetKey, key, fallback)
        if ok and type(value) == "string" and value ~= "" then
            TEXT_CACHE[language][key] = value
            return value
        end
    end
    TEXT_CACHE[language][key] = fallback
    return fallback
end

-- These are semantic frames, not parser inputs.  patternID is retained as
-- provenance for the later click adapter; it is never used to reparse text.
local DEFINITIONS = {
    {
        id = "question.wellbeing",
        topic = "wellbeing",
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
        topic = "wellbeing",
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
        topic = "needs",
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
        topic = "medical",
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
        topic = "identity",
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
    {
        id = "question.time",
        topic = "time",
        order = 60,
        patternID = "pnc.question.time",
        labelKey = "UI_PNC_Conversation_Suggestion_Time_Label",
        labelFallback = "Ask about the time",
        utteranceKey = "UI_PNC_Conversation_Suggestion_Time_Utterance",
        utteranceFallback = "What time is it?",
        intent = "QUESTION",
        speechAct = "QUESTION",
        subject = "TIME",
        extensions = { topic = "time" },
    },
    {
        id = "question.date",
        topic = "date",
        order = 70,
        patternID = "pnc.question.date",
        labelKey = "UI_PNC_Conversation_Suggestion_Date_Label",
        labelFallback = "Ask about the date",
        utteranceKey = "UI_PNC_Conversation_Suggestion_Date_Utterance",
        utteranceFallback = "What's today's date?",
        intent = "QUESTION",
        speechAct = "QUESTION",
        subject = "DATE",
        extensions = { topic = "date" },
    },
    {
        id = "question.weather",
        topic = "weather",
        order = 80,
        patternID = "pnc.question.weather",
        labelKey = "UI_PNC_Conversation_Suggestion_Weather_Label",
        labelFallback = "Ask about the weather",
        utteranceKey = "UI_PNC_Conversation_Suggestion_Weather_Utterance",
        utteranceFallback = "How is the weather?",
        intent = "QUESTION",
        speechAct = "QUESTION",
        subject = "WEATHER",
        extensions = { topic = "weather" },
    },
}

local CAPABILITY_DEFINITIONS = {
    FOLLOW = {
        id = "action.follow",
        topic = "movement",
        requiresOwnedCompanion = true,
        labelKey = "UI_PNC_Conversation_Suggestion_Follow_Label",
        labelFallback = "Ask them to follow",
        utteranceKey = "UI_PNC_Conversation_Suggestion_Follow_Utterance",
        utteranceFallback = "Follow me.",
        constraints = {
            all = {
                {
                    path = "actorAuthority.owned",
                    op = "eq",
                    value = true,
                },
                {
                    path = "actorAuthority.companion",
                    op = "eq",
                    value = true,
                },
                {
                    path = "npcState.activeBehavior",
                    op = "not_in",
                    values = { "hostile", "combat", "busy", "dead" },
                },
                {
                    path = "npcState.followState.mode",
                    op = "not_in",
                    values = { "following", "follow" },
                },
                {
                    path = "npcState.healthState",
                    op = "not_in",
                    values = { "dead", "incapacitated" },
                },
            },
        },
    },
    STAY = {
        id = "action.stay",
        topic = "movement",
        requiresOwnedCompanion = true,
        labelKey = "UI_PNC_Conversation_Suggestion_Stay_Label",
        labelFallback = "Ask them to stay",
        utteranceKey = "UI_PNC_Conversation_Suggestion_Stay_Utterance",
        utteranceFallback = "Stay here.",
        constraints = {
            all = {
                {
                    path = "actorAuthority.owned",
                    op = "eq",
                    value = true,
                },
                {
                    path = "actorAuthority.companion",
                    op = "eq",
                    value = true,
                },
                {
                    path = "npcState.activeBehavior",
                    op = "not_in",
                    values = { "hostile", "combat", "busy", "dead" },
                },
                {
                    path = "npcState.followState.mode",
                    op = "not_in",
                    values = { "staying", "stay" },
                },
                {
                    path = "npcState.healthState",
                    op = "not_in",
                    values = { "dead", "incapacitated" },
                },
            },
        },
    },
    WAIT_AT = {
        id = "action.wait_at",
        topic = "movement",
        requiresOwnedCompanion = true,
        labelKey = "UI_PNC_Conversation_Suggestion_WaitAt_Label",
        labelFallback = "Ask them to wait there",
        utteranceKey = "UI_PNC_Conversation_Suggestion_WaitAt_Utterance",
        utteranceFallback = "Wait there.",
        constraints = {
            all = {
                {
                    path = "actorAuthority.owned",
                    op = "eq",
                    value = true,
                },
                {
                    path = "actorAuthority.companion",
                    op = "eq",
                    value = true,
                },
                {
                    path = "npcState.activeBehavior",
                    op = "not_in",
                    values = { "hostile", "combat", "busy", "dead" },
                },
                {
                    path = "npcState.healthState",
                    op = "not_in",
                    values = { "dead", "incapacitated" },
                },
                { path = "suggestion.destination", op = "exists" },
            },
        },
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
        if string.find(value, "weather", 1, true) then
            return "WEATHER"
        end
        if string.find(value, "date", 1, true)
            or string.find(value, "calendar", 1, true)
        then
            return "DATE"
        end
        if string.find(value, "time", 1, true) then
            return "TIME"
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
                if string.find(messageValue, "weather", 1, true) then
                    return "WEATHER"
                end
                if string.find(messageValue, "date", 1, true)
                    or string.find(messageValue, "calendar", 1, true)
                then
                    return "DATE"
                end
                if string.find(messageValue, "time", 1, true) then
                    return "TIME"
                end
            end
        end
    end
    return nil
end

local function canonicalTopic(value)
    value = string.lower(tostring(value or ""))
    if value == "npc_health_state" or value == "medical"
        or string.find(value, "health", 1, true)
        or string.find(value, "medical", 1, true)
    then
        return "medical"
    end
    if value == "wellbeing" or string.find(value, "wellbeing", 1, true) then
        return "wellbeing"
    end
    if value == "needs" or string.find(value, "need", 1, true) then
        return "needs"
    end
    if value == "identity" or string.find(value, "identity", 1, true) then
        return "identity"
    end
    if value == "weather" or string.find(value, "weather", 1, true) then
        return "weather"
    end
    if value == "date" or string.find(value, "date", 1, true)
        or string.find(value, "calendar", 1, true)
    then
        return "date"
    end
    if value == "time" or string.find(value, "time", 1, true) then
        return "time"
    end
    if value == "greeting" or string.find(value, "greet", 1, true) then
        return "greeting"
    end
    if value == "movement" then return "movement" end
    return nil
end

local function topicFromIR(ir, context)
    local extensions = type(ir) == "table" and ir.extensions or nil
    local topic = type(extensions) == "table" and extensions.topic or nil
    if type(topic) == "table" then topic = topic.id or topic.topic end
    local canonical = canonicalTopic(topic)
    if canonical then return canonical end
    canonical = canonicalTopic(ir and ir.subject)
    if canonical then return canonical end
    return canonicalTopic(context and context.currentTopic)
end

local RELATED_TOPICS = {
    wellbeing = { wellbeing = true, needs = true, medical = true },
    needs = { wellbeing = true, needs = true, medical = true },
    medical = { wellbeing = true, needs = true, medical = true },
    time = { time = true, date = true },
    date = { time = true, date = true },
    weather = { weather = true },
}

local function topicMatches(definition, topic)
    if not topic then return false end
    local related = RELATED_TOPICS[topic]
    if related then return related[definition.topic] == true end
    return definition.topic == topic
end

local function topicGroupID(topic)
    topic = canonicalTopic(topic)
    if topic == "date" then topic = "time" end
    if topic == "needs" or topic == "medical" then topic = "wellbeing" end
    return topic and "topic:" .. topic or nil
end

local function definitionFor(id)
    local index
    for index = 1, #DEFINITIONS do
        if DEFINITIONS[index].id == id then return DEFINITIONS[index] end
    end
    return nil
end

local function capabilityDefinitionFor(id)
    local action
    for action, definition in pairs(CAPABILITY_DEFINITIONS) do
        if definition.id == id then return action, definition end
    end
    return nil, nil
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
    if subject == "TIME" then return definitionFor("question.time") end
    if subject == "DATE" then return definitionFor("question.date") end
    if subject == "WEATHER" then return definitionFor("question.weather") end
    return nil
end

local function sourceRecord(kind, revision, reason)
    return {
        kind = kind,
        revision = revision,
        reason = reason,
    }
end

local function capabilityFrame(action, definition, revision)
    return {
        schemaVersion = Suggestions.VERSION,
        kind = "semantic_click_frame",
        candidateID = definition.id,
        topic = definition.topic,
        intent = "REQUEST",
        speechAct = "REQUEST",
        action = action,
        textKey = definition.utteranceKey,
        textFallback = definition.utteranceFallback,
        labelKey = definition.labelKey,
        target = { kind = "conversation_actor", ref = "npc" },
        slots = {
            npcID = { kind = "conversation_actor", ref = "npc" },
        },
        requestRevision = revision,
    }
end

local function capabilityRows(revision, currentAction, context, ir)
    local catalog = PNC.Semantics and PNC.Semantics.CapabilityCatalog
    if not catalog or type(catalog.ListActions) ~= "function" then
        return {}, sourceRecord(
            "permitted_capability", revision, "catalog_unavailable"
        ), {}
    end

    local rows = {}
    local allowed = 0
    local predicateTrace = {}
    local predicateContext = {}
    for key, value in pairs(type(context) == "table" and context or {}) do
        predicateContext[key] = value
    end
    predicateContext.ir = predicateIR(ir)
    predicateContext.suggestion = {
        destination = context.suggestionDestination,
    }
    for _, row in ipairs(catalog.ListActions()) do
        local action = normalized(row and row.id)
        local definition = CAPABILITY_DEFINITIONS[action]
        if definition and row.dispatchable == true then
            local eligibility = Predicates.Evaluate(
                definition.constraints, predicateContext
            )
            for _, traceRow in ipairs(eligibility.trace or {}) do
                if #predicateTrace < Predicates.MAX_TRACE then
                    predicateTrace[#predicateTrace + 1] = {
                        capability = action,
                        path = traceRow.path,
                        status = traceRow.status,
                        reason = traceRow.reason,
                    }
                end
            end
            local authorityEligible = not definition.requiresOwnedCompanion
                or type(context.actorAuthority) == "table"
                and context.actorAuthority.eligible == true
            if definition.requiresOwnedCompanion and not authorityEligible then
                if #predicateTrace < Predicates.MAX_TRACE then
                    predicateTrace[#predicateTrace + 1] = {
                        capability = action,
                        path = "actorAuthority",
                        status = "hidden",
                        reason = type(context.actorAuthority) == "table"
                            and (context.actorAuthority.status or "not_commandable")
                            or "authority_unknown",
                    }
                end
                -- A non-owned or unknown NPC is not an unavailable button.
                -- It is outside the player's discoverable command surface.
            end
            if not (definition.requiresOwnedCompanion and not authorityEligible) then
                local destinationPending = false
                for _, traceRow in ipairs(eligibility.trace or {}) do
                    if traceRow.path == "suggestion.destination"
                        and traceRow.status == "unknown"
                    then
                        destinationPending = true
                    end
                end
                if eligibility.status ~= "private" then
                    local binding = type(row.binding) == "table" and row.binding or {}
                    local bindingView = {
                        id = row.bindingID or binding.id,
                        owner = binding.owner or row.owner,
                        route = binding.route or row.route,
                        handlerID = binding.handlerID or row.handlerID,
                        targetScope = row.targetScope,
                        status = row.bindingStatus,
                    }
                    local status
                    if eligibility.allowed == true then
                        status = action == currentAction
                            and "selected_for_preflight" or "eligible"
                    elseif action == "WAIT_AT" and destinationPending
                    then
                        status = action == currentAction
                            and "selected_requires_destination"
                            or "requires_destination"
                    else
                        status = "unavailable_" .. tostring(eligibility.status)
                    end
                    rows[#rows + 1] = {
                        id = definition.id,
                        action = action,
                        source = sourceRecord(
                            "permitted_capability", revision, status
                        ),
                        status = status,
                        eligibility = {
                            status = eligibility.status,
                            reason = eligibility.reason,
                            trace = eligibility.trace,
                        },
                        binding = bindingView,
                        topic = definition.topic,
                        groupID = "owned_actions",
                        frame = capabilityFrame(action, definition, revision),
                        display = {
                            labelKey = definition.labelKey,
                            labelFallback = definition.labelFallback,
                            label = resolvedText(
                                definition.labelKey, definition.labelFallback
                            ),
                            utteranceKey = definition.utteranceKey,
                            utteranceFallback = definition.utteranceFallback,
                            utterance = resolvedText(
                                definition.utteranceKey,
                                definition.utteranceFallback
                            ),
                        },
                        visibility = "player",
                    }
                    allowed = allowed + 1
                end
            end
        end
    end
    return rows, sourceRecord(
        "permitted_capability", revision,
        allowed > 0 and "registered_dispatchable" or "none_registered"
    ), predicateTrace
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
        topic = definition.topic,
        patternID = definition.patternID,
        intent = definition.intent,
        speechAct = definition.speechAct,
        subject = definition.subject,
        target = definition.target,
        slots = copyValue(definition.slots) or {},
        modifiers = copyValue(definition.modifiers) or {},
        socialContext = copyValue(definition.socialContext) or {},
        extensions = copyValue(definition.extensions) or {},
        textKey = definition.utteranceKey,
        textFallback = definition.utteranceFallback,
        labelKey = definition.labelKey,
        requestRevision = revision,
    }
    candidate = {
        id = definition.id,
        topic = definition.topic,
        groupID = topicGroupID(definition.topic)
            or "topic:other",
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

local function predicateContextFor(context, ir, offer)
    local predicateContext = {}
    for key, value in pairs(type(context) == "table" and context or {}) do
        predicateContext[key] = value
    end
    predicateContext.ir = predicateIR(ir)
    predicateContext.suggestion = {
        candidateID = offer and offer.id or nil,
        destination = context and context.suggestionDestination or nil,
    }
    return predicateContext
end

local function branchOfferFrame(offer, revision, origin)
    local semantic = offer.frame or {}
    local frame = copyValue(semantic) or {}
    frame.schemaVersion = Suggestions.VERSION
    frame.kind = "semantic_click_frame"
    frame.candidateID = offer.id
    frame.textKey = offer.utteranceKey
    frame.textFallback = offer.utteranceFallback
    frame.labelKey = offer.labelKey
    frame.requestRevision = revision
    frame.origin = copyValue(origin) or {}
    return frame
end

local function addBranchOfferCandidate(
    output,
    seen,
    offer,
    kind,
    revision,
    reason,
    origin,
    context,
    ir,
    predicateTrace
)
    if type(offer) ~= "table" or offer.visibility == "private" then
        return nil, nil
    end
    local existing = seen[offer.id]
    if existing then
        if #existing.sources < Suggestions.MAX_SOURCES then
            existing.sources[#existing.sources + 1] = sourceRecord(
                kind, revision, reason
            )
        end
        return existing, nil
    end
    if #output >= Suggestions.MAX_CANDIDATES then return nil, nil end

    local eligibility = { status = "allowed", allowed = true, trace = {} }
    if type(offer.constraints) == "table" then
        eligibility = Predicates.Evaluate(
            offer.constraints,
            predicateContextFor(context, ir, offer)
        )
        for _, traceRow in ipairs(eligibility.trace or {}) do
            if #predicateTrace < Predicates.MAX_TRACE then
                predicateTrace[#predicateTrace + 1] = {
                    candidateID = offer.id,
                    source = kind,
                    path = traceRow.path,
                    status = traceRow.status,
                    reason = traceRow.reason,
                }
            end
        end
        if eligibility.status ~= "allowed" then
            return nil, eligibility
        end
    end

    local frame = branchOfferFrame(offer, revision, origin)
    local source = sourceRecord(kind, revision, reason)
    local candidate = {
        id = offer.id,
        topic = canonicalTopic(origin and origin.topic),
        groupID = "conversation_branch",
        rank = #output + 1,
        source = source,
        sources = { source },
        frame = frame,
        display = {
            labelKey = offer.labelKey,
            labelFallback = offer.labelFallback,
            label = resolvedText(offer.labelKey, offer.labelFallback),
            utteranceKey = offer.utteranceKey,
            utteranceFallback = offer.utteranceFallback,
            utterance = resolvedText(
                offer.utteranceKey, offer.utteranceFallback
            ),
        },
        visibility = "player",
        eligibility = eligibility,
        branch = copyValue(origin),
    }
    output[#output + 1] = candidate
    seen[offer.id] = candidate
    return candidate, eligibility
end

local function offersFromPlan(plan)
    if type(plan) ~= "table" or type(plan.turns) ~= "table" then
        return {}
    end
    local output = {}
    for turnIndex = 1, #plan.turns do
        local turn = plan.turns[turnIndex]
        for offerIndex = 1, #(turn.offers or {}) do
            output[#output + 1] = {
                offer = turn.offers[offerIndex],
                origin = {
                    kind = "response_plan",
                    sourcePoolID = plan.sourcePoolID,
                    turnID = turn.id,
                    turnIndex = turnIndex,
                    offerIndex = offerIndex,
                },
            }
        end
    end
    return output
end

local function offersFromMessages(messages)
    local output = {}
    for messageIndex = 1, #(type(messages) == "table" and messages or {}) do
        local message = messages[messageIndex]
        local payload = type(message) == "table"
            and type(message.payload) == "table" and message.payload or nil
        local plan = payload and payload.plan or nil
        for _, item in ipairs(offersFromPlan(plan)) do
            item.origin.messageIndex = messageIndex
            output[#output + 1] = item
        end
    end
    return output
end

function Suggestions.ResolveFrameText(frame)
    frame = type(frame) == "table" and frame or {}
    return resolvedText(
        frame.textKey,
        frame.textFallback or frame.utteranceFallback or frame.utterance
    )
end

local function sameBranchOrigin(frame, origin)
    local requested = type(frame.origin) == "table" and frame.origin or {}
    if requested.kind ~= nil and requested.kind ~= origin.kind then
        return false
    end
    for _, key in ipairs({ "flowID", "nodeID", "turnID", "sourcePoolID" }) do
        if requested[key] ~= nil
            and tostring(requested[key]) ~= tostring(origin[key] or "")
        then
            return false
        end
    end
    return true
end

local function branchOfferForFrame(frame, view)
    local result = view and view.lastSemanticDialogueResult or nil
    local decision = type(result) == "table"
        and type(result.decision) == "table" and result.decision or {}
    local flow = type(decision.flow) == "table" and decision.flow or {}
    local flowOrigin = {
        kind = "active_flow",
        flowID = flow.flowId,
        nodeID = flow.toNodeId or flow.nodeId,
    }
    for _, offer in ipairs(flow.branchOffers or {}) do
        if type(offer) == "table"
            and offer.id == frame.candidateID
            and sameBranchOrigin(frame, flowOrigin)
        then
            return offer, flowOrigin
        end
    end

    local response = type(decision.response) == "table"
        and decision.response or {}
    for _, item in ipairs(offersFromPlan(response.plan)) do
        if item.offer and item.offer.id == frame.candidateID
            and sameBranchOrigin(frame, item.origin)
        then
            return item.offer, item.origin
        end
    end

    -- A live view may only expose the most recent queued payload. Inspect
    -- that bounded payload as a compatibility fallback without reparsing.
    for _, item in ipairs(offersFromMessages(result and result.messages)) do
        if item.offer and item.offer.id == frame.candidateID
            and sameBranchOrigin(frame, item.origin)
        then
            return item.offer, item.origin
        end
    end
    return nil, nil
end

local function branchOfferIR(offer, origin, frame, view)
    local source = offer.frame or {}
    local actorID = view and view.spec and view.spec.npcID or nil
    local slots = {}
    if source.stateType ~= nil or source.stateValue ~= nil then
        slots.state = {
            type = source.stateType,
            value = source.stateValue,
        }
    end
    local socialContext = {}
    if source.selfDirected ~= nil then
        socialContext.selfDirected = source.selfDirected
    end
    if source.target ~= nil then socialContext.target = source.target end
    if source.identityClaim ~= nil then
        socialContext.identityClaim = source.identityClaim
    end
    local target = source.target and {
        kind = "conversation_actor",
        ref = source.target,
    } or nil
    local ir = IR.New({
        kind = "semantic_suggestion_frame",
        rawText = resolvedText(
            offer.utteranceKey, offer.utteranceFallback
        ),
        normalizedText = normalizedText(offer.utteranceFallback),
        intent = source.intent,
        speechAct = source.speechAct,
        action = source.action,
        subject = source.subject,
        target = target,
        slots = slots,
        socialContext = socialContext,
        confidence = 1,
        provenance = {
            provider = "suggestion",
            parser = "semantic_click_frame",
            pattern = source.pattern or "semantic_branch_offer",
            candidateID = frame.candidateID,
            origin = copyValue(origin),
            branchOfferID = offer.id,
            branchOfferConstraints = copyValue(offer.constraints),
        },
    })
    if actorID ~= nil and ir.target == nil and source.target == "SELF" then
        ir.target = { kind = "actor", id = actorID, source = "conversation" }
    end
    return ir
end

function Suggestions.FrameToIR(frame, view)
    if type(frame) ~= "table"
        or tonumber(frame.schemaVersion) ~= Suggestions.VERSION
        or frame.kind ~= "semantic_click_frame"
    then
        return nil, "suggestion_frame_invalid"
    end
    local branchOffer, branchOrigin = branchOfferForFrame(frame, view)
    if branchOffer then
        return branchOfferIR(branchOffer, branchOrigin, frame, view)
    end

    local definition = definitionFor(frame.candidateID)
    local action
    if not definition then
        action, definition = capabilityDefinitionFor(frame.candidateID)
    end
    if not definition then return nil, "suggestion_candidate_unknown" end

    local actorID = view and view.spec and view.spec.npcID or nil
    local isCapability = action ~= nil
    if isCapability and normalized(frame.action) ~= normalized(action) then
        return nil, "suggestion_action_mismatch"
    end
    if not isCapability and frame.action ~= nil then
        return nil, "suggestion_unexpected_action"
    end

    local rawText = resolvedText(
        definition.utteranceKey,
        definition.utteranceFallback
    )
    local slots = copyValue(definition.slots) or {}
    local target = copyValue(definition.target)
    if isCapability then
        target = { kind = "actor", id = actorID, source = "conversation" }
        slots.npcID = actorID
    end
    local ir = IR.New({
        kind = "semantic_suggestion_frame",
        rawText = rawText,
        normalizedText = normalizedText(definition.utteranceFallback),
        intent = isCapability and "REQUEST" or definition.intent,
        speechAct = isCapability and "REQUEST" or definition.speechAct,
        action = isCapability and action or nil,
        subject = isCapability and nil or definition.subject,
        target = target,
        slots = slots,
        modifiers = copyValue(definition.modifiers) or {},
        socialContext = copyValue(definition.socialContext) or {},
        extensions = copyValue(definition.extensions) or {},
        confidence = 1,
        provenance = {
            provider = "suggestion",
            parser = "semantic_click_frame",
            pattern = definition.patternID,
            candidateID = definition.id,
        },
    })
    return ir
end

function Suggestions.CheckFrame(frame, context, ir)
    local provenance = type(ir) == "table"
        and type(ir.provenance) == "table" and ir.provenance or {}
    if provenance.branchOfferID == frame.candidateID then
        local branchOffer = {
            id = provenance.branchOfferID,
            constraints = provenance.branchOfferConstraints,
        }
        local predicateContext = predicateContextFor(context, ir, branchOffer)
        if type(branchOffer.constraints) == "table" then
            local result = Predicates.Evaluate(
                branchOffer.constraints, predicateContext
            )
            if result.allowed ~= true then
                return false, "suggestion_click_ineligible_"
                    .. tostring(result.status), result
            end
            return true, "eligible", result
        end
        return true, "eligible", { status = "allowed", trace = {} }
    end

    local action, definition = capabilityDefinitionFor(
        type(frame) == "table" and frame.candidateID or nil
    )
    if not action or type(definition.constraints) ~= "table" then
        return true, "eligible", { status = "allowed", trace = {} }
    end
    local predicateContext = {}
    for key, value in pairs(type(context) == "table" and context or {}) do
        predicateContext[key] = value
    end
    predicateContext.ir = copyValue(ir) or {}
    predicateContext.suggestion = {
        destination = type(frame) == "table" and frame.destination or nil,
    }
    local result = Predicates.Evaluate(definition.constraints, predicateContext)
    if result.allowed ~= true then
        return false, "suggestion_click_ineligible_" .. tostring(result.status), result
    end
    return true, "eligible", result
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

local function appendBranchOffers(
    candidates,
    seen,
    offers,
    kind,
    revision,
    context,
    ir,
    predicateTrace,
    defaultOrigin
)
    for _, item in ipairs(offers or {}) do
        local offer = item.offer or item
        local origin = item.origin or copyValue(defaultOrigin)
            or { kind = kind }
        addBranchOfferCandidate(
            candidates,
            seen,
            offer,
            kind,
            revision,
            "branch_offer",
            origin,
            context,
            ir,
            predicateTrace
        )
    end
end

local GROUP_LABELS = {
    wellbeing = {
        key = "UI_PNC_Conversation_Suggestion_Group_Wellbeing_Label",
        fallback = "Wellbeing",
    },
    needs = {
        key = "UI_PNC_Conversation_Suggestion_Group_Needs_Label",
        fallback = "Needs",
    },
    medical = {
        key = "UI_PNC_Conversation_Suggestion_Group_Medical_Label",
        fallback = "Medical",
    },
    identity = {
        key = "UI_PNC_Conversation_Suggestion_Group_Identity_Label",
        fallback = "Identity",
    },
    time = {
        key = "UI_PNC_Conversation_Suggestion_Group_Time_Label",
        fallback = "Time and date",
    },
    date = {
        key = "UI_PNC_Conversation_Suggestion_Group_Time_Label",
        fallback = "Time and date",
    },
    weather = {
        key = "UI_PNC_Conversation_Suggestion_Group_Weather_Label",
        fallback = "Weather",
    },
    movement = {
        key = "UI_PNC_Conversation_Suggestion_Group_Movement_Label",
        fallback = "Owned companion actions",
    },
}

local function groupPresentation(id, topic)
    local label = GROUP_LABELS[topic]
    if label then
        return {
            id = id,
            topic = topic,
            label = resolvedText(label.key, label.fallback),
            labelKey = label.key,
        }
    end
    if id == "active_flow" then
        return {
            id = id,
            label = resolvedText(
                "UI_PNC_Conversation_Suggestion_Group_Flow_Label",
                "Current conversation branch"
            ),
            labelKey = "UI_PNC_Conversation_Suggestion_Group_Flow_Label",
        }
    end
    if id == "conversation_branch" then
        return {
            id = id,
            label = resolvedText(
                "UI_PNC_Conversation_Suggestion_Group_Flow_Label",
                "Current conversation branch"
            ),
            labelKey = "UI_PNC_Conversation_Suggestion_Group_Flow_Label",
        }
    end
    if id == "npc_response_plan" then
        return {
            id = id,
            label = resolvedText(
                "UI_PNC_Conversation_Suggestion_Group_Response_Label",
                "NPC reply"
            ),
            labelKey = "UI_PNC_Conversation_Suggestion_Group_Response_Label",
        }
    end
    return { id = id, label = id }
end

local function buildGroups(candidates, capabilities, currentTopic)
    local groups = {}
    local byID = {}
    local function ensure(id, topic)
        if not id then return nil end
        if not byID[id] then
            local group = groupPresentation(id, topic)
            group.candidates = {}
            group.capabilities = {}
            group.count = 0
            byID[id] = group
            groups[#groups + 1] = group
        end
        return byID[id]
    end
    for _, candidate in ipairs(candidates or {}) do
        local group = ensure(
            candidate.groupID or candidate.topic and "topic:" .. candidate.topic
                or candidate.source and candidate.source.kind,
            candidate.topic
        )
        if group then
            group.candidates[#group.candidates + 1] = candidate
            group.count = group.count + 1
        end
    end
    for _, capability in ipairs(capabilities or {}) do
        local group = ensure(capability.groupID or "owned_actions", "movement")
        if group then
            group.capabilities[#group.capabilities + 1] = capability
            group.count = group.count + 1
        end
    end
    local currentGroupID = topicGroupID(currentTopic)
    if not byID[currentGroupID] then
        currentGroupID = byID.conversation_branch and "conversation_branch"
            or byID.active_flow and "active_flow"
            or byID.npc_response_plan and "npc_response_plan"
            or byID.owned_actions and "owned_actions"
            or groups[1] and groups[1].id
    end
    return groups, currentGroupID
end

function Suggestions.Build(result, context, messages)
    result = type(result) == "table" and result or {}
    context = type(context) == "table" and context or {}
    local revision, turnID = revisionFor(result)
    local candidates = {}
    local seen = {}
    local trace = {}
    local ir = type(result.ir) == "table" and result.ir or {}
    local currentAction = normalized(ir.action)
    local capabilities, capabilitySource, predicateTrace = capabilityRows(
        revision, currentAction, context, ir
    )

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
            permittedCapabilities = {},
            groups = {},
            currentTopic = nil,
            currentGroupID = nil,
            predicateTrace = {},
            trace = trace,
        }
    end

    local decision = type(result.decision) == "table"
        and result.decision or {}
    local flow = type(decision.flow) == "table" and decision.flow or {}
    local flowActive = flow.flowId ~= nil
        and (flow.committed == true or flow.matched == true)
    if flowActive then
        appendBranchOffers(
            candidates,
            seen,
            flow.branchOffers,
            "active_flow",
            revision,
            context,
            ir,
            predicateTrace,
            {
                kind = "active_flow",
                flowID = flow.flowId,
                nodeID = flow.toNodeId or flow.nodeId,
            }
        )
    end
    local response = type(decision.response) == "table"
        and decision.response or {}
    appendBranchOffers(
        candidates,
        seen,
        offersFromPlan(response.plan),
        "npc_response_plan",
        revision,
        context,
        ir,
        predicateTrace
    )
    appendBranchOffers(
        candidates,
        seen,
        offersFromMessages(messages),
        "npc_response_plan",
        revision,
        context,
        ir,
        predicateTrace
    )

    local subject = normalized(ir.subject)
    local typedTopic = topicFromIR(ir, nil)
    local currentTopic = typedTopic or canonicalTopic(context.currentTopic)
    local typedReason = subject ~= "" and "interpreted_frame" or "no_subject"
    local typedSource = sourceRecord("typed_input", revision, typedReason)
    local typedEligible = result.accepted == true and subject ~= ""
    if typedEligible and currentTopic then
        if subject == "WELLBEING" then
            addCandidate(
                candidates, seen, definitionFor("question.wellbeing_detail"),
                "typed_input", revision, "wellbeing_follow_up"
            )
        end
        for _, definition in ipairs(DEFINITIONS) do
            if topicMatches(definition, currentTopic) then
                addCandidate(
                    candidates, seen, definition,
                    "typed_input", revision, "topic_branch"
                )
            end
        end
        appendTrace(trace, "typed_input", "allowed", typedReason, #candidates)
    else
        appendTrace(trace, "typed_input", "skipped", typedReason, #candidates)
    end

    local topic = responseTopic(result, messages)
    local responseTopicID = canonicalTopic(topic)
    if not typedTopic then currentTopic = responseTopicID or currentTopic end
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

    local flowSource = sourceRecord(
        "active_flow", revision,
        flowActive and "active_flow" or "no_active_flow"
    )
    local flowTopic = responseTopic({ decision = { flow = flow } })
    if flowActive and flowTopic then
        addCandidate(
            candidates, seen, definitionForSubject(flowTopic, false),
            "active_flow", revision, "active_flow_response_pool"
        )
        appendTrace(trace, "active_flow", "allowed", "active_flow", #candidates)
    else
        appendTrace(
            trace, "active_flow", "skipped",
            flow.flowId and "flow_topic_unknown" or "no_active_flow",
            #candidates
        )
    end

    if #capabilities > 0 then
        appendTrace(
            trace, "permitted_capability", "allowed",
            "registered_dispatchable", #candidates
        )
    else
        appendTrace(
            trace, "permitted_capability", "skipped",
            "none_registered", #candidates
        )
    end

    local groups, currentGroupID = buildGroups(
        candidates, capabilities, currentTopic
    )

    return {
        schemaVersion = Suggestions.VERSION,
        kind = "semantic_dialogue_suggestions",
        revision = revision,
        turnID = turnID,
        candidates = candidates,
        sources = {
            typedSource,
            planSource,
            flowSource,
            capabilitySource,
        },
        activeFlow = flowActive and {
            flowID = flow.flowId,
            nodeID = flow.toNodeId or flow.nodeId,
            revision = revision,
            responsePoolID = flow.responsePool,
        } or nil,
        permittedCapabilities = capabilities,
        groups = groups,
        currentTopic = currentTopic,
        currentGroupID = currentGroupID,
        predicateTrace = predicateTrace,
        trace = trace,
        privacy = {
            playerVisible = true,
            privateFieldsInspected = false,
            unknownFieldsExposed = false,
        },
    }
end

return Suggestions
