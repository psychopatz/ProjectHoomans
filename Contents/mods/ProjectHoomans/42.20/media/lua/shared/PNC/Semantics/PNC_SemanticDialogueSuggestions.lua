-- Versioned, non-executing semantic dialogue suggestions.
--
-- Suggestions are derived from the production semantic result and response
-- plan.  This module deliberately does not parse text, dispatch actions, or
-- mutate dialogue state.  A later click adapter may turn the typed frame
-- into an IR and send it through the existing DialogueInput boundary.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local DialogueRuntime = PNC.Semantics.SemanticDialogueRuntime
    or require "PNC/Semantics/PNC_SemanticDialogueRuntime"

local Suggestions = PNC.Semantics.DialogueSuggestions or {}
PNC.Semantics.DialogueSuggestions = Suggestions
local Predicates = PNC.Semantics.SuggestionPredicates
    or require "PNC/Semantics/PNC_SemanticDialogueSuggestionPredicates"
local IR = PsychopatzCore.Semantics and PsychopatzCore.Semantics.IR
    or require "PsychopatzCore/Semantics/PsychopatzSemanticIR"
local BranchOffers = PNC.Semantics.DialogueBranchOffers
    or require "PNC/Semantics/PNC_SemanticDialogueBranchOffers"
local ActorConversationContext = PNC.Semantics.ActorConversationContext
    or require "PNC/Semantics/PNC_ActorConversationContext"
local ChoiceRanking = PNC.Semantics.DialogueChoiceRanking
    or require "PNC/Semantics/SemanticDialogueSuggestions/PNC_SemanticDialogueSuggestions_Ranking"
local Identity = PNC.Identity
    or require "PNC/Core/Identity/PNC_Identity"
local CampSite = PNC.Semantics.CampSite
    or require "PNC/Semantics/PNC_SemanticCampSite"

Suggestions.VERSION = 1
Suggestions.ROOT_GROUP_ID = "conversation_landing"
Suggestions.CONTEXT_INDEX_GROUP_ID = "conversation_context_index"
Suggestions.COMPANION_ORDERS_GROUP_ID = "companion.orders"
Suggestions.COMPANION_CAMP_GROUP_ID = "companion.camp"
Suggestions.MAX_CAMP_DESTINATIONS = 6
-- The visual part keeps five rows per selected group. The projection itself
-- is bounded separately so a dynamic root can expose every safe topic through
-- the existing group selector without pretending that five is a global cap.
Suggestions.MAX_CANDIDATES = 24
Suggestions.MAX_TRACE = 12
Suggestions.MAX_SOURCES = 4

local CAMP_HERE_TEXT_KEY =
    "UI_PNC_Conversation_Suggestion_CompanionCampHere_Utterance"
local CAMP_CAMPFIRE_TEXT_KEY =
    "UI_PNC_Conversation_Suggestion_CompanionCampfire_Utterance"
local CAMP_ROOM_TEXT_KEY =
    "UI_PNC_Conversation_Suggestion_CompanionCampRoom_Utterance"

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
    -- Semantic click frames carry the executable meaning contract (intent,
    -- slots, provenance extensions, and presentation keys).  A twelve-field
    -- arbitrary pairs() cap could silently drop one of those fields and made
    -- valid provider frames depend on Lua table iteration order. Keep the
    -- copy bounded while leaving room for the complete frame contract.
    for key, item in pairs(value) do
        if count >= 32 then break end
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
local ChoiceRegistry = require "PNC/Semantics/SemanticDialogueSuggestions/PNC_SemanticDialogueSuggestions_Registry"
local StaticProvider = require "PNC/Semantics/SemanticDialogueSuggestions/PNC_SemanticDialogueSuggestions_StaticProvider"
local CapabilityProvider = require "PNC/Semantics/SemanticDialogueSuggestions/PNC_SemanticDialogueSuggestions_CapabilityProvider"
local SocialProvider = require "PNC/Semantics/SemanticDialogueSuggestions/PNC_SemanticDialogueSuggestions_SocialProvider"

ChoiceRegistry.RegisterProvider(StaticProvider)
ChoiceRegistry.RegisterProvider(CapabilityProvider)
ChoiceRegistry.RegisterProvider(SocialProvider)

local function registerSourceProvider(id, sourceKind, order)
    ChoiceRegistry.RegisterProvider({
        id = id,
        sourceKind = sourceKind,
        order = order,
        collect = function() return {} end,
    })
end

registerSourceProvider("projecthoomans.conversation_root", "conversation_root", 10)
registerSourceProvider("projecthoomans.conversation_registry", "conversation_registry", 20)
registerSourceProvider("projecthoomans.active_flow", "active_flow", 30)
registerSourceProvider("projecthoomans.response_plan", "npc_response_plan", 40)
registerSourceProvider("projecthoomans.flow_topic", "active_flow", 60)

local DEFINITIONS = StaticProvider.Definitions
local CAPABILITY_DEFINITIONS = CapabilityProvider.Definitions

local function normalizeCandidate(candidate, sourceKind, localOrder)
    local providerID = ChoiceRegistry.ProviderForSourceKind(sourceKind)
    if not providerID then return candidate end
    local normalizedCandidate = ChoiceRegistry.NormalizeCandidate(
        candidate, providerID, localOrder
    )
    return normalizedCandidate or candidate
end

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

local function definitionFor(id)
    return StaticProvider.Find(id)
end

local function capabilityDefinitionFor(id)
    local action
    for action, definition in pairs(CapabilityProvider.Definitions) do
        if definition.id == id then return action, definition end
    end
    return nil, nil
end

local function projectedCapabilityFor(id, view)
    local projection = view and view.semanticSuggestions or nil
    if type(projection) ~= "table" then return nil, nil end
    local function inspect(rows)
        for _, row in ipairs(rows or {}) do
            if type(row) == "table"
                and tostring(row.id or "") == tostring(id or "")
            then
                local frame = row.frame or row.semanticFrame
                local action = row.action
                    or row.capability and row.capability.action
                    or frame and frame.action
                if type(frame) == "table" and action ~= nil then
                    return normalized(action), {
                        id = id,
                        topic = frame.topic,
                        utteranceKey = frame.textKey,
                        utteranceFallback = frame.textFallback
                            or row.text,
                        target = copyValue(frame.target),
                        destination = copyValue(frame.destination),
                        slots = copyValue(frame.slots) or {},
                    }
                end
            end
        end
        return nil, nil
    end
    local action, definition = inspect(projection.permittedCapabilities)
    if action then return action, definition end
    for _, group in ipairs(projection.groups or {}) do
        action, definition = inspect(group.capabilities)
        if action then return action, definition end
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
local Internal = Suggestions.Internal or {}
Suggestions.Internal = Internal

Internal.DialogueRuntime = DialogueRuntime
Internal.Predicates = Predicates
Internal.IR = IR
Internal.BranchOffers = BranchOffers
Internal.ActorConversationContext = ActorConversationContext
Internal.ChoiceRanking = ChoiceRanking
Internal.Identity = Identity
Internal.CampSite = CampSite
Internal.ChoiceRegistry = ChoiceRegistry
Internal.StaticProvider = StaticProvider
Internal.CapabilityProvider = CapabilityProvider
Internal.SocialProvider = SocialProvider
Internal.DEFINITIONS = DEFINITIONS
Internal.CAPABILITY_DEFINITIONS = CAPABILITY_DEFINITIONS
Internal.CAMP_HERE_TEXT_KEY = CAMP_HERE_TEXT_KEY
Internal.CAMP_CAMPFIRE_TEXT_KEY = CAMP_CAMPFIRE_TEXT_KEY
Internal.CAMP_ROOM_TEXT_KEY = CAMP_ROOM_TEXT_KEY

Internal.boundedText = boundedText
Internal.copyValue = copyValue
Internal.predicateIR = predicateIR
Internal.normalized = normalized
Internal.normalizedText = normalizedText
Internal.resolvedText = resolvedText
Internal.normalizeCandidate = normalizeCandidate
Internal.revisionFor = revisionFor
Internal.privateResult = privateResult
Internal.responseTopic = responseTopic
Internal.canonicalTopic = canonicalTopic
Internal.topicFromIR = topicFromIR
Internal.semanticHubID = semanticHubID
Internal.topicMatches = topicMatches
Internal.topicGroupID = topicGroupID
Internal.definitionFor = definitionFor
Internal.capabilityDefinitionFor = capabilityDefinitionFor
Internal.projectedCapabilityFor = projectedCapabilityFor
Internal.definitionForSubject = definitionForSubject
Internal.sourceRecord = sourceRecord
Internal.isActiveHubDefinition = isActiveHubDefinition
Internal.isActiveHubCandidate = isActiveHubCandidate

require "PNC/Semantics/PNC_SemanticDialogueSuggestions_Capabilities"
require "PNC/Semantics/PNC_SemanticDialogueSuggestions_Branches"
require "PNC/Semantics/PNC_SemanticDialogueSuggestions_Frames"
require "PNC/Semantics/PNC_SemanticDialogueSuggestions_Projection"
require "PNC/Semantics/PNC_SemanticDialogueSuggestions_Build"

return Suggestions
