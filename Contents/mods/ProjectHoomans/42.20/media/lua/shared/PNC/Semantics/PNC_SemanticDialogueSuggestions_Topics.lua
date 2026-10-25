-- Topic normalization and authored category frames for semantic suggestions.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Suggestions = PNC.Semantics.DialogueSuggestions
local Internal = Suggestions.Internal

local normalized = Internal.normalized
local resolvedText = Internal.resolvedText

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
    if value == "whats_up" or string.find(value, "whats_up", 1, true) then
        return "whats_up"
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

local function semanticHubID(ir)
    if type(ir) ~= "table"
        or normalized(ir.subject) ~= "CONVERSATION_TOPIC"
    then
        return nil
    end
    local extensions = type(ir.extensions) == "table"
        and ir.extensions or {}
    if extensions.route ~= "semantic_hub" then return nil end
    local hubID = string.lower(tostring(extensions.hubID or ""))
    if hubID == "" or #hubID > 48
        or string.find(hubID, "[^%w_%.%-]") ~= nil
    then
        return nil
    end
    return hubID
end

-- A recognized authored category is a presentation boundary, not another
-- conversational suggestion.  Keep this conversion beside the suggestion
-- contract so typed input and the existing semantic-click surface share one
-- canonical frame without making the parser execute conversation effects.
function Suggestions.IsConversationCategoryIR(ir)
    if type(ir) ~= "table"
        or normalized(ir.subject) ~= "CONVERSATION_TOPIC"
    then
        return false
    end
    local extensions = type(ir.extensions) == "table"
        and ir.extensions or {}
    return extensions.route == "conversation_category"
        and string.sub(tostring(extensions.categoryID or ""), 1, 15)
            == "projecthoomans:"
        and tostring(extensions.topic or "") ~= ""
end

function Suggestions.BuildConversationCategoryFrame(ir, revision)
    if not Suggestions.IsConversationCategoryIR(ir) then return nil end
    local source = ir.extensions or {}
    local topic = canonicalTopic(source.topic) or tostring(source.topic)
    local categoryID = tostring(source.categoryID or "")
    if topic == "" or categoryID == "" then return nil end
    return {
        schemaVersion = Suggestions.VERSION,
        kind = "semantic_click_frame",
        candidateID = "conversation.typed:" .. categoryID .. ":"
            .. tostring(tonumber(revision) or 0),
        topic = topic,
        intent = "QUESTION",
        speechAct = "QUESTION",
        subject = "CONVERSATION_TOPIC",
        textKey = "category." .. topic,
        textFallback = resolvedText("category." .. topic, "What's up?"),
        labelKey = "category." .. topic,
        requestRevision = tonumber(revision) or 0,
        extensions = {
            route = "conversation_category",
            categoryID = categoryID,
            topic = topic,
        },
    }
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

Internal.responseTopic = responseTopic
Internal.canonicalTopic = canonicalTopic
Internal.topicFromIR = topicFromIR
Internal.semanticHubID = semanticHubID
Internal.topicMatches = topicMatches
Internal.topicGroupID = topicGroupID

return Suggestions

