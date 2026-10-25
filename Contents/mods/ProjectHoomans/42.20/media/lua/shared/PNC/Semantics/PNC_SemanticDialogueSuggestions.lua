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

local function isActiveHubDefinition(definition, activeHubID)
    if type(definition) ~= "table" or activeHubID == nil then return false end
    local extensions = type(definition.extensions) == "table"
        and definition.extensions or {}
    return extensions.route == "semantic_hub"
        and tostring(extensions.hubID or "") == activeHubID
end

local function isActiveHubCandidate(candidate, activeHubID)
    if type(candidate) ~= "table" or activeHubID == nil then return false end
    local frame = type(candidate.frame) == "table" and candidate.frame or {}
    local extensions = type(frame.extensions) == "table"
        and frame.extensions or {}
    return extensions.route == "semantic_hub"
        and tostring(extensions.hubID or "") == activeHubID
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
        groupID = definition.groupID,
        textKey = definition.utteranceKey,
        textFallback = definition.utteranceFallback,
        labelKey = definition.labelKey,
        target = copyValue(definition.target)
            or { kind = "conversation_actor", ref = "npc" },
        destination = copyValue(definition.destination),
        slots = {
            npcID = { kind = "conversation_actor", ref = "npc" },
        },
        requestRevision = revision,
    }
end

local function isCompanionOrderAction(action)
    action = normalized(action)
    return action == "FOLLOW"
        or action == "STAY"
        or action == "GO"
        or action == "CAMP"
        or action == "WAIT_AT"
end

local function companionAuthorityEligible(context)
    local authority = type(context) == "table"
        and context.actorAuthority or nil
    return type(authority) == "table"
        and authority.eligible == true
        and authority.companion == true
        and authority.owned == true
end

local function companionOrderStateEligible(context)
    if not companionAuthorityEligible(context) then return false end
    local state = type(context) == "table"
        and type(context.npcState) == "table" and context.npcState or {}
    local behavior = tostring(state.activeBehavior or "")
    if behavior == "hostile" or behavior == "combat"
        or behavior == "busy" or behavior == "dead"
    then
        return false
    end
    local health = tostring(state.healthState or "")
    return health ~= "dead" and health ~= "incapacitated"
end

local function companionUnavailableReason(context)
    if not companionAuthorityEligible(context) then return nil end
    local state = type(context) == "table"
        and type(context.npcState) == "table" and context.npcState or {}
    local behavior = string.lower(tostring(state.activeBehavior or ""))
    local health = string.lower(tostring(state.healthState or ""))
    if health == "dead" or behavior == "dead" then
        return {
            code = "companion_dead",
            key = "UI_PNC_Conversation_Suggestion_CompanionDead_Tooltip",
            fallback = "Unavailable because the companion is dead.",
        }
    end
    if health == "incapacitated" then
        return {
            code = "companion_incapacitated",
            key = "UI_PNC_Conversation_Suggestion_CompanionIncapacitated_Tooltip",
            fallback = "Unavailable because the companion is incapacitated.",
        }
    end
    if behavior == "hostile" or behavior == "combat"
        or behavior == "busy"
    then
        return {
            code = "companion_busy",
            key = "UI_PNC_Conversation_Suggestion_CompanionBusy_Tooltip",
            fallback = "Unavailable while the companion is busy or in combat.",
        }
    end
    return nil
end

local function companionOrderReason(action, context)
    local unavailable = companionUnavailableReason(context)
    if unavailable then return unavailable end
    local state = type(context) == "table"
        and type(context.npcState) == "table" and context.npcState or {}
    local orderKind = string.lower(tostring(state.orderKind or ""))
    action = normalized(action)
    if action == "FOLLOW" and orderKind == "follow" then
        return {
            code = "already_following",
            key = "UI_PNC_Conversation_Suggestion_AlreadyFollowing_Tooltip",
            fallback = "Already following you.",
        }
    end
    if action == "STAY" and orderKind ~= "follow" then
        if orderKind == "guard" or orderKind == "camp"
            or orderKind == "patrol"
        then
            return {
                code = "already_staying",
                key = "UI_PNC_Conversation_Suggestion_AlreadyStaying_Tooltip",
                fallback = "Already holding position.",
            }
        end
        return {
            code = "not_following",
            key = "UI_PNC_Conversation_Suggestion_NotFollowing_Tooltip",
            fallback = "Stay is available while the companion is following you.",
        }
    end
    return nil
end

local function campSiteCandidates(context)
    return type(context) == "table"
        and (context.campSiteCandidates
            or context.semanticCampSiteCandidates
            or (context.npcState and context.npcState.campSiteCandidates))
        or {}
end

local function campCandidateTarget(candidate)
    local target = type(candidate) == "table"
        and (candidate.target or candidate) or nil
    return type(target) == "table" and target or nil
end

local function campCandidateUsable(candidate)
    local target = campCandidateTarget(candidate)
    return target ~= nil
        and (target.campfireID ~= nil
            or target.siteID ~= nil
            or target.roomID ~= nil)
end

local function firstCampSiteCandidate(candidates)
    if type(candidates) ~= "table" then return nil end
    for index = 1, math.min(#candidates,
        Suggestions.MAX_CAMP_DESTINATIONS) do
        if campCandidateUsable(candidates[index]) then
            return candidates[index]
        end
    end
    return nil
end

local function campSiteCandidateCount(context)
    local candidates = campSiteCandidates(context)
    if type(candidates) ~= "table" then return 0 end
    local count = 0
    for index = 1, math.min(#candidates,
        Suggestions.MAX_CAMP_DESTINATIONS) do
        if campCandidateUsable(candidates[index]) then
            count = count + 1
        end
    end
    return count
end

local function navigationDetails(groupID, context)
    if groupID == Suggestions.COMPANION_ORDERS_GROUP_ID then
        return "companion_orders", "COMPANION_ORDERS"
    end
    if groupID == Suggestions.COMPANION_CAMP_GROUP_ID then
        if campSiteCandidateCount(context) > 0 then
            return "companion_camp", "COMPANION_CAMP"
        end
        return "companion_camp", "COMPANION_CAMP_EMPTY"
    end
    return "topic", "CONVERSATION_TOPIC"
end

local function addGroupNavigationCandidate(
    output,
    seen,
    context,
    revision,
    predicateTrace,
    groupID,
    parentGroupID,
    candidateID,
    labelKey,
    labelFallback,
    reason,
    availability
)
    if seen[candidateID] or #output >= Suggestions.MAX_CANDIDATES then
        return
    end
    local frame = Suggestions.BuildGroupFrame({
        id = groupID,
        labelKey = labelKey,
        label = resolvedText(labelKey, labelFallback),
        allowBack = true,
        parentGroupID = parentGroupID,
        navigationKind = navigationDetails(groupID, context),
        navigationSubject = select(2, navigationDetails(groupID, context)),
        utterance = labelFallback,
    }, revision)
    if not frame then return end
    local available = not availability
        or availability.allowed ~= false
    local status = available and "eligible"
        or "unavailable_" .. tostring(availability.status or "unavailable")
    local availabilityReason = availability and availability.reason or reason
    local source = sourceRecord("conversation_root", revision, reason)
    local candidate = {
        id = candidateID,
        topic = "movement",
        groupID = parentGroupID,
        rank = #output + 1,
        source = source,
        sources = { source },
        frame = frame,
        enabled = available,
        status = status,
        reasonCode = availability and availability.reasonCode or nil,
        reasonKey = availability and availability.reasonKey or nil,
        reasonFallback = availability and availability.reasonFallback or nil,
        display = {
            labelKey = labelKey,
            labelFallback = labelFallback,
            label = resolvedText(labelKey, labelFallback),
        },
        visibility = "player",
        eligibility = {
            status = available and "allowed" or "rejected",
            allowed = available,
            reason = availabilityReason,
            reasonCode = availability and availability.reasonCode or nil,
            reasonKey = availability and availability.reasonKey or nil,
            reasonFallback = availability
                and availability.reasonFallback or nil,
        },
    }
    candidate = normalizeCandidate(candidate, "conversation_root", #output + 1)
    output[#output + 1] = candidate
    seen[candidateID] = candidate
    if #predicateTrace < Predicates.MAX_TRACE then
        predicateTrace[#predicateTrace + 1] = {
            candidateID = candidateID,
            source = "conversation_root",
            path = "actorAuthority.eligible",
            status = "allowed",
            reason = reason,
        }
    end
end

local function appendCompanionOrderNavigation(
    output, seen, context, revision, predicateTrace
)
    if not companionAuthorityEligible(context) then return end
    addGroupNavigationCandidate(
        output,
        seen,
        context,
        revision,
        predicateTrace,
        Suggestions.COMPANION_ORDERS_GROUP_ID,
        Suggestions.ROOT_GROUP_ID,
        "companion.orders:open",
        "UI_PNC_Conversation_Suggestion_CompanionOrders_Label",
        "I need you to do something...",
        "companion_orders_hub"
    )
end

local function appendCompanionCampNavigation(
    output, seen, context, revision, predicateTrace
)
    if not companionAuthorityEligible(context) then return end
    local stateEligible = companionOrderStateEligible(context)
    local available = stateEligible and campSiteCandidateCount(context) > 0
    local availability
    if not available then
        local unavailable = companionUnavailableReason(context)
        availability = stateEligible and {
            allowed = false,
            status = "no_camp_site",
            reason = "no_camp_site",
            reasonCode = "no_camp_site",
            reasonKey =
                "UI_PNC_Conversation_Suggestion_NoCampSite_Tooltip",
            reasonFallback =
                "No valid camp location is currently available.",
        } or {
            allowed = false,
            status = unavailable and unavailable.code
                or "companion_unavailable",
            reason = unavailable and unavailable.code
                or "companion_unavailable",
            reasonCode = unavailable and unavailable.code
                or "companion_unavailable",
            reasonKey = unavailable and unavailable.key or
                "UI_PNC_Conversation_Suggestion_CompanionUnavailable_Tooltip",
            reasonFallback = unavailable and unavailable.fallback
                or "Unavailable because this companion cannot receive orders right now.",
        }
    end
    addGroupNavigationCandidate(
        output,
        seen,
        context,
        revision,
        predicateTrace,
        Suggestions.COMPANION_CAMP_GROUP_ID,
        Suggestions.COMPANION_ORDERS_GROUP_ID,
        "companion.orders:camp",
        "UI_PNC_Conversation_Suggestion_CompanionCamp_Label",
        "Let's camp...",
        "companion_camp_branch",
        availability
    )
end

local function campTargetForCandidate(candidate)
    local target = copyValue(campCandidateTarget(candidate))
    local campfire
    if type(target) ~= "table" then return nil, false end
    campfire = target.campfireID ~= nil or target.kind == "campfire"
    if campfire then
        target.kind = "camp_site"
        target.scope = target.scope or "campfire"
        target.siteScope = target.siteScope or target.scope
    end
    return target, campfire
end

local function campDisplayLabel(candidate, target, campfire)
    local label
    if campfire then return "campfire" end
    if CampSite and type(CampSite.DisplayLabel) == "function" then
        label = CampSite.DisplayLabel(target or candidate)
        if label and label ~= "" then return label end
    end
    return candidate and (candidate.label or candidate.roomName
        or candidate.roomType) or "room"
end

local function campDisplayText(candidate, target, campfire, automatic)
    local label
    local text
    if automatic then
        return resolvedText(CAMP_HERE_TEXT_KEY, "Let's camp here.")
    end
    if candidate and (candidate.utterance or candidate.displayText) then
        return candidate.utterance or candidate.displayText
    end
    label = campDisplayLabel(candidate, target, campfire)
    if campfire then
        return resolvedText(
            CAMP_CAMPFIRE_TEXT_KEY,
            "Let's camp by the campfire."
        )
    end
    text = resolvedText(
        CAMP_ROOM_TEXT_KEY,
        "Let's camp in the %1."
    )
    return string.gsub(text, "%%1", function()
        return tostring(label)
    end, 1)
end

local function appendCampCapabilityRow(
    rows, revision, context, candidate, stateEligible,
    disabledCode, disabledKey, disabledFallback, automatic
)
    local target
    local campfire
    local targetKey
    local candidateID
    local displayText
    local definition
    local frame
    local rowAvailable
    local rowStatus
    local rowReasonCode
    local rowReasonKey
    local rowReasonFallback
    if automatic then
        target = {
            kind = CampSite.KIND or "camp_site",
            scope = CampSite.SCOPES.HERE or "here",
            siteScope = CampSite.SCOPES.HERE or "here",
        }
        if campCandidateUsable(candidate) then
            local candidateTarget = campCandidateTarget(candidate)
            local hint = candidateTarget.clientHint or candidateTarget
            if type(hint) == "table" then
                target.clientHint = copyValue(hint)
            end
        end
        candidateID = "action.camp_here"
        targetKey = "auto"
    else
        target, campfire = campTargetForCandidate(candidate)
        if not target then return false end
        if campfire then
            targetKey = target.campfireID
        elseif target.siteID ~= nil and target.roomID ~= nil then
            targetKey = tostring(target.siteID) .. "|"
                .. tostring(target.roomID)
        else
            targetKey = target.roomID or target.siteID
        end
        candidateID = candidate.id
            or ("action.camp_site:" .. tostring(targetKey or "unknown"))
    end
    displayText = campDisplayText(candidate, target, campfire, automatic)
    rowAvailable = stateEligible and campCandidateUsable(candidate)
    if rowAvailable then
        rowStatus = "eligible"
        rowReasonCode = "valid_client_camp_site_hint"
    elseif automatic and not campCandidateUsable(candidate)
        and stateEligible
    then
        rowStatus = "unavailable_no_camp_site"
        rowReasonCode = "no_camp_site"
        rowReasonKey = "UI_PNC_Conversation_Suggestion_NoCampSite_Tooltip"
        rowReasonFallback = "No valid camp location is currently available."
    else
        rowStatus = "unavailable_companion"
        rowReasonCode = disabledCode
        rowReasonKey = disabledKey
        rowReasonFallback = disabledFallback
    end
    definition = {
        id = candidateID,
        topic = "movement",
        groupID = Suggestions.COMPANION_CAMP_GROUP_ID,
        labelFallback = displayText,
        utteranceFallback = displayText,
        target = target,
        slots = {
            npcID = { kind = "conversation_actor", ref = "npc" },
        },
    }
    frame = capabilityFrame("CAMP", definition, revision)
    if not frame then return false end
    rows[#rows + 1] = {
        id = candidateID,
        topic = "movement",
        groupID = Suggestions.COMPANION_CAMP_GROUP_ID,
        rank = #rows + 1,
        enabled = rowAvailable,
        status = rowStatus,
        reasonCode = rowReasonCode,
        reasonKey = rowReasonKey,
        reasonFallback = rowReasonFallback,
        frame = frame,
        semanticFrame = frame,
        source = {
            groupID = Suggestions.COMPANION_CAMP_GROUP_ID,
            kind = automatic and "automatic_camp_capability"
                or "permitted_capability",
        },
        text = displayText,
        display = {
            label = displayText,
            utterance = displayText,
            visibility = "player",
        },
        visibility = "player",
        eligibility = {
            status = rowAvailable and "allowed" or "rejected",
            allowed = rowAvailable,
            reasonCode = rowReasonCode,
            reason = rowReasonCode,
            reasonKey = rowReasonKey,
            reasonFallback = rowReasonFallback,
        },
        capability = {
            id = candidateID,
            action = "CAMP",
            source = automatic and "automatic_camp_site"
                or "production_camp_site",
            status = rowStatus,
            groupID = Suggestions.COMPANION_CAMP_GROUP_ID,
            selectionMode = automatic and "auto" or "specific",
            targetKey = targetKey,
        },
    }
    rows[#rows] = normalizeCandidate(
        rows[#rows], "permitted_capability", #rows
    )
    return true
end

local function appendCampSiteCapabilityRows(rows, revision, context, ir)
    local candidates = campSiteCandidates(context)
    if type(candidates) ~= "table" then return end
    local stateEligible = companionOrderStateEligible(context)
    local unavailable = not stateEligible
        and companionUnavailableReason(context) or nil
    local disabledCode = unavailable and unavailable.code
        or "companion_unavailable"
    local disabledKey = unavailable and unavailable.key
        or "UI_PNC_Conversation_Suggestion_CompanionUnavailable_Tooltip"
    local disabledFallback = unavailable and unavailable.fallback
        or "Unavailable because this companion cannot receive orders right now."

    local seen = {}
    local count = 0

    -- The generic action is intentionally first.  It carries the best
    -- observed primitive as a hint, while the target remains scope="here" so
    -- the normal camp resolver owns the final room/campfire choice.
    appendCampCapabilityRow(
        rows, revision, context, firstCampSiteCandidate(candidates),
        stateEligible,
        disabledCode, disabledKey, disabledFallback, true
    )

    for _, candidate in ipairs(candidates) do
        if count >= Suggestions.MAX_CAMP_DESTINATIONS then break end
        if campCandidateUsable(candidate) then
            local target, campfire = campTargetForCandidate(candidate)
            local targetKey
            if campfire then targetKey = target and target.campfireID
            elseif target and target.siteID ~= nil and target.roomID ~= nil then
                targetKey = tostring(target.siteID) .. "|"
                    .. tostring(target.roomID)
            else targetKey = target and (target.roomID or target.siteID) end
            local candidateID = candidate.id
                or ("action.camp_site:" .. tostring(targetKey or count + 1))
            local dedupeKey = tostring(candidateID) .. "|"
                .. tostring(targetKey or "")
            if targetKey ~= nil and not seen[dedupeKey] then
                seen[dedupeKey] = true
                appendCampCapabilityRow(
                    rows, revision, context, candidate, stateEligible,
                    disabledCode, disabledKey, disabledFallback, false
                )
                count = count + 1
            end
        end
    end
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
            local menuOnlyWhenDestination = definition.menuOnlyWhenDestination
            local hideWithoutDestination = menuOnlyWhenDestination == false
                and action == "WAIT_AT"
                and type(context.suggestionDestination) ~= "table"
            if not hideWithoutDestination then
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
                local hideIneligibleOrder = isCompanionOrderAction(action)
                    and eligibility.allowed ~= true
                    and definition.showWhenUnavailable ~= true
                if eligibility.status ~= "private"
                    and not hideIneligibleOrder
                then
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
                    local predicateReason = eligibility.reason
                    local reasonCode = predicateReason
                    local reasonKey
                    local reasonFallback
                    if definition.unavailableReasonCode
                        and definition.unavailableReasonPath
                    then
                        for _, traceRow in ipairs(eligibility.trace or {}) do
                            if traceRow.path
                                    == definition.unavailableReasonPath
                                and traceRow.status == "rejected"
                            then
                                reasonCode = definition.unavailableReasonCode
                                reasonKey = definition.unavailableReasonKey
                                reasonFallback =
                                    definition.unavailableReasonFallback
                                break
                            end
                        end
                    end
                    if eligibility.allowed ~= true
                        and isCompanionOrderAction(action)
                    then
                        local orderReason = companionOrderReason(
                            action, context
                        )
                        if orderReason then
                            reasonCode = orderReason.code
                            reasonKey = orderReason.key
                            reasonFallback = orderReason.fallback
                        end
                    end
                    local capability = {
                        id = definition.id,
                        action = action,
                        source = sourceRecord(
                            "permitted_capability", revision, status
                        ),
                        status = status,
                        enabled = status == "eligible"
                            or status == "selected_for_preflight",
                        reasonCode = reasonCode,
                        reasonKey = reasonKey,
                        reasonFallback = reasonFallback,
                        eligibility = {
                            status = eligibility.status,
                            reason = reasonCode,
                            predicateReason = predicateReason,
                            reasonCode = reasonCode,
                            reasonKey = reasonKey,
                            reasonFallback = reasonFallback,
                            trace = eligibility.trace,
                        },
                        binding = bindingView,
                        topic = definition.topic,
                        groupID = definition.groupID
                            or (isCompanionOrderAction(action)
                                and Suggestions.COMPANION_ORDERS_GROUP_ID
                                or "owned_actions"),
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
                    capability = normalizeCandidate(
                        capability, "permitted_capability", #rows + 1
                    )
                    rows[#rows + 1] = capability
                    allowed = allowed + 1
                end
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
    candidate = normalizeCandidate(candidate, kind, #output + 1)
    output[#output + 1] = candidate
    seen[definition.id] = candidate
end

local function addProviderCandidate(output, seen, candidate, revision)
    if type(candidate) ~= "table" then return end
    local id = tostring(candidate.id or "")
    if id == "" or candidate.visibility == "private" or seen[id] then
        return
    end
    if #output >= Suggestions.MAX_CANDIDATES then return end
    local frame = copyValue(candidate.frame) or {}
    local source = type(candidate.source) == "table"
        and candidate.source or {}
    frame.schemaVersion = Suggestions.VERSION
    frame.kind = "semantic_click_frame"
    frame.candidateID = id
    frame.requestRevision = revision
    candidate.frame = frame
    local providerID = tostring(
        candidate.providerID or source.providerID or "provider"
    )
    local sourceKind = tostring(source.kind or "provider")
    candidate.source = sourceRecord(
        sourceKind, revision, "provider_eligible"
    )
    candidate.source.providerID = providerID
    candidate.sources = { sourceRecord(
        sourceKind, revision, "provider_eligible"
    ) }
    candidate.sources[1].providerID = providerID
    frame.providerID = providerID
    local display = type(candidate.display) == "table"
        and candidate.display or {}
    display.label = resolvedText(display.labelKey, display.labelFallback)
    display.utterance = resolvedText(
        display.utteranceKey, display.utteranceFallback
    )
    candidate.display = display
    candidate.rank = #output + 1
    candidate.visibility = "player"
    output[#output + 1] = candidate
    seen[id] = candidate
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
            -- Branch offers are the active response surface. Preserve their
            -- exact predicate evidence when the bounded trace already holds
            -- lower-priority capability rows.
            while #predicateTrace >= Predicates.MAX_TRACE do
                table.remove(predicateTrace, 1)
            end
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
    candidate = normalizeCandidate(candidate, kind, #output + 1)
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
            destination = copyValue(source.destination),
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
    if Suggestions.IsNavigationFrame(frame) then
        return Suggestions.NavigationFrameToIR(frame, view)
    end
    -- A landing shortcut is already a typed semantic frame. Preserve its
    -- canonical topic/route when native Core submits it through a group
    -- host; flattening it to display text lets the native parser reinterpret
    -- "What's up?" as a generic navigation turn.
    if Suggestions.IsShortcutFrame(frame) then
        local value = Suggestions.ResolveFrameText(frame)
        if value == "" then return nil, "shortcut_frame_text_missing" end
        local extensions = copyValue(frame.extensions) or {}
        if extensions.topic == nil and frame.topic ~= nil then
            extensions.topic = frame.topic
        end
        return IR.New({
            kind = "semantic_suggestion_frame",
            rawText = value,
            normalizedText = normalizedText(value),
            intent = frame.intent or "QUESTION",
            speechAct = frame.speechAct or "QUESTION",
            subject = frame.subject or "CONVERSATION_TOPIC",
            target = {
                kind = "actor",
                id = view and view.spec and view.spec.npcID or nil,
                source = "conversation",
            },
            extensions = extensions,
            confidence = 1,
            provenance = {
                provider = "suggestion",
                parser = "semantic_click_frame",
                pattern = "semantic_shortcut",
                candidateID = frame.candidateID,
            },
        })
    end
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

    -- Generic registered providers resolve through the current bounded
    -- projection. This keeps click-time identity/revision checks on the
    -- existing lane instead of allowing a provider to become an action
    -- dispatcher or a second parser.
    local providerID = frame.providerID
    local extensions = type(frame.extensions) == "table"
        and frame.extensions or {}
    providerID = providerID or extensions.providerID
    if providerID ~= nil then
        local current = view and view.semanticSuggestions or nil
        for _, candidate in ipairs(
            type(current) == "table" and current.candidates or {}
        ) do
            if tostring(candidate.id or "") == tostring(frame.candidateID or "")
                and tostring(candidate.providerID or "") == tostring(providerID)
            then
                local source = type(candidate.frame) == "table"
                    and candidate.frame or nil
                if not source then return nil, "suggestion_provider_frame_missing" end
                local target = copyValue(source.target)
                return IR.New({
                    kind = "semantic_suggestion_frame",
                    rawText = Suggestions.ResolveFrameText(source),
                    normalizedText = normalizedText(
                        source.textFallback or source.utteranceFallback
                    ),
                    intent = source.intent,
                    speechAct = source.speechAct,
                    action = source.action,
                    subject = source.subject,
                    target = target,
                    destination = copyValue(source.destination),
                    slots = copyValue(source.slots) or {},
                    modifiers = copyValue(source.modifiers) or {},
                    socialContext = copyValue(source.socialContext) or {},
                    extensions = copyValue(source.extensions) or {},
                    confidence = 1,
                    provenance = {
                        provider = tostring(providerID),
                        parser = "semantic_click_frame",
                        pattern = source.pattern or "semantic_provider",
                        candidateID = frame.candidateID,
                    },
                })
            end
        end
        return nil, "suggestion_provider_candidate_unknown"
    end

    local definition = definitionFor(frame.candidateID)
    local action
    if not definition then
        action, definition = capabilityDefinitionFor(frame.candidateID)
    end
    if not definition then
        action, definition = projectedCapabilityFor(frame.candidateID, view)
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
    if isCapability and (target == nil
        or target.kind == "conversation_actor"
        or target.ref == "npc")
    then
        target = { kind = "actor", id = actorID, source = "conversation" }
        slots.npcID = actorID
    elseif isCapability then
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
        destination = copyValue(definition.destination),
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
    if Suggestions.IsNavigationFrame(frame) then
        if type(ir) ~= "table"
            or ir.intent ~= "NAVIGATE"
            or ir.provenance.parser ~= "semantic_navigation_frame"
        then
            return false, "navigation_frame_invalid"
        end
        return true, "navigation_frame_eligible", {
            status = "allowed",
            trace = {},
        }
    end
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

    local providerID = type(frame) == "table" and frame.providerID or nil
    local extensions = type(frame) == "table"
        and type(frame.extensions) == "table" and frame.extensions or {}
    providerID = providerID or extensions.providerID
    if providerID ~= nil then
        local registry = PNC.Semantics and PNC.Semantics.DialogueChoiceRegistry
        local provider = registry and type(registry.GetProvider) == "function"
            and registry.GetProvider(providerID) or nil
        if not provider or provider.enabled == false then
            return false, "suggestion_provider_unavailable", {
                status = "unknown",
                trace = {},
            }
        end
        return true, "provider_eligible", {
            status = "allowed",
            providerID = providerID,
            trace = {},
        }
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

local function appendConversationChoices(
    output, seen, context, revision, predicateTrace
)
    local block = type(context) == "table"
        and type(context.conversationBlock) == "table"
        and context.conversationBlock or nil
    if not block or type(block.choices) ~= "table" then return end
    for _, choice in ipairs(block.choices) do
        if type(choice) == "table" and tostring(choice.id or "") ~= "" then
            local candidateID = table.concat({
                "conversation.choice", tostring(block.blockID),
                tostring(block.nodeID), tostring(choice.id),
            }, ":")
            if not seen[candidateID] and #output < Suggestions.MAX_CANDIDATES then
                local text = tostring(choice.text or choice.id)
                local enabled = choice.enabled == true
                local status = enabled and "allowed" or "disabled"
                local reason = enabled and "production_choice_eligible"
                    or choice.lockedReasonKey or "production_choice_ineligible"
                predicateTrace[#predicateTrace + 1] = {
                    candidateID = candidateID,
                    source = "conversation_registry",
                    path = "conversationBlock.choices." .. tostring(choice.id),
                    status = enabled and "allowed" or "hidden",
                    reason = reason,
                }
                local frame = {
                    schemaVersion = Suggestions.VERSION,
                    kind = "semantic_click_frame",
                    candidateID = candidateID,
                    topic = canonicalTopic(block.topic) or "whats_up",
                    intent = "REQUEST",
                    speechAct = "REQUEST",
                    subject = "CONVERSATION_TOPIC",
                    extensions = {
                        route = "conversation_choice",
                        categoryID = block.categoryID,
                        blockID = block.blockID,
                        nodeID = block.nodeID,
                        choiceID = choice.id,
                    },
                    textKey = choice.textKey,
                    textFallback = text,
                    labelKey = choice.textKey,
                    requestRevision = revision,
                }
                local source = sourceRecord(
                    "conversation_registry", revision, reason
                )
                local candidate = {
                    id = candidateID,
                    topic = canonicalTopic(block.topic) or "whats_up",
                    groupID = "conversation_branch",
                    rank = #output + 1,
                    source = source,
                    sources = { source },
                    frame = frame,
                    enabled = enabled,
                    display = {
                        labelKey = choice.textKey,
                        labelFallback = text,
                        label = text,
                        utteranceKey = choice.textKey,
                        utteranceFallback = text,
                        utterance = text,
                    },
                    visibility = "player",
                    eligibility = {
                        status = enabled and "allowed" or "unavailable",
                        allowed = enabled,
                        reason = reason,
                    },
                }
                candidate = normalizeCandidate(
                    candidate, "conversation_registry", #output + 1
                )
                output[#output + 1] = candidate
                seen[candidateID] = candidate
            end
        end
    end
end

local function appendConversationRootChoices(
    output, seen, context, revision, predicateTrace
)
    local root = type(context) == "table"
        and type(context.conversationRoot) == "table"
        and context.conversationRoot or nil
    if not root or type(root.choices) ~= "table" then return end
    for _, choice in ipairs(root.choices) do
        local semantic = type(choice) == "table" and choice.semantic or nil
        local choiceID = type(choice) == "table"
            and tostring(choice.id or "") or ""
        if type(semantic) == "table" and choiceID ~= ""
            and (semantic.route == "conversation_category"
                or semantic.route == "conversation_root_choice")
            and not (
                choiceID == "show_debug_text"
                or choiceID == "view_dossier"
                or semantic.categoryID == "projecthoomans:set_territory"
                or semantic.categoryID == "projecthoomans:trade"
            )
            and #output < Suggestions.MAX_CANDIDATES
        then
            local candidateID = table.concat({
                "conversation.root", tostring(root.nodeID), choiceID,
            }, ":")
            if not seen[candidateID] then
                local topic = tostring(semantic.topic or "")
                -- Categories are a second-level context index. Direct root
                -- actions remain on the landing page. The authored choice
                -- still carries its original route, so the composer remains
                -- the owner when a category is selected.
                local directCategory = choiceID == "ceasefire"
                local groupID = semantic.route == "conversation_category"
                    and not directCategory
                    and Suggestions.CONTEXT_INDEX_GROUP_ID
                    or Suggestions.ROOT_GROUP_ID
                local text = boundedText(choice.text or choiceID, 160)
                local enabled = choice.enabled == true
                local reason = enabled and "production_root_choice_eligible"
                    or choice.tooltip or "production_root_choice_ineligible"
                if #predicateTrace < Predicates.MAX_TRACE then
                    predicateTrace[#predicateTrace + 1] = {
                        candidateID = candidateID,
                        source = "conversation_root",
                        path = "conversationRoot.choices." .. choiceID,
                        status = enabled and "allowed" or "hidden",
                        reason = reason,
                    }
                end
                local extensions = copyValue(semantic) or {}
                extensions.origin = "conversation_root"
                extensions.rootNodeID = root.nodeID
                extensions.rootChoiceID = choiceID
                local frame = {
                    schemaVersion = Suggestions.VERSION,
                    kind = "semantic_click_frame",
                    candidateID = candidateID,
                    topic = topic ~= "" and topic or nil,
                    intent = "REQUEST",
                    speechAct = "REQUEST",
                    subject = semantic.route == "conversation_category"
                        and "CONVERSATION_TOPIC" or "CONVERSATION_ACTION",
                    extensions = extensions,
                    textKey = choice.textKey,
                    textFallback = text,
                    labelKey = choice.textKey,
                    requestRevision = revision,
                }
                local source = sourceRecord(
                    "conversation_root", revision, reason
                )
                local candidate = {
                    id = candidateID,
                    topic = topic ~= "" and topic or nil,
                    groupID = groupID,
                    rank = #output + 1,
                    source = source,
                    sources = { source },
                    frame = frame,
                    enabled = enabled,
                    display = {
                        labelKey = choice.textKey,
                        labelFallback = text,
                        label = text,
                        utteranceKey = choice.textKey,
                        utteranceFallback = text,
                        utterance = text,
                    },
                    visibility = "player",
                    eligibility = {
                        status = enabled and "allowed" or "unavailable",
                        allowed = enabled,
                        reason = reason,
                    },
                }
                candidate = normalizeCandidate(
                    candidate, "conversation_root", #output + 1
                )
                output[#output + 1] = candidate
                seen[candidateID] = candidate
            end
        end
    end
end

local function hasConversationHistory(context)
    context = type(context) == "table" and context or {}
    local function isNonGreeting(topic)
        return topic ~= nil and tostring(topic) ~= "greeting"
    end
    if isNonGreeting(context.currentTopic)
        or isNonGreeting(context.previousTopic)
    then
        return true
    end
    local semantic = context.semanticDialogueContext
    if type(semantic) ~= "table" then return false end
    return isNonGreeting(semantic.currentTopic)
        or isNonGreeting(semantic.previousTopic)
        or #(semantic.priorTopics or {}) > 0
end

local function appendLandingShortcuts(
    output, seen, revision, predicateTrace
)
    local candidateID = "conversation.landing:whats_up"
    if seen[candidateID] or #output >= Suggestions.MAX_CANDIDATES then
        return
    end
    local labelKey = "UI_PNC_Conversation_Suggestion_WhatsUp_Label"
    local label = resolvedText(labelKey, "What's up?")
    local utterance = "What's up?"
    local frame = Suggestions.BuildShortcutFrame({
        candidateID = candidateID,
        topic = "whats_up",
        labelKey = labelKey,
        labelFallback = label,
        utterance = utterance,
        extensions = {
            route = "semantic_hub",
            hubID = "whats_up",
            canonicalConcept = "WHATS_UP",
            origin = "conversation_landing",
        },
    }, revision)
    if not frame then return end
    local source = sourceRecord(
        "conversation_root", revision, "conversation_landing_shortcut"
    )
    local candidate = {
        id = candidateID,
        topic = "whats_up",
        groupID = Suggestions.ROOT_GROUP_ID,
        rank = #output + 1,
        source = source,
        sources = { source },
        frame = frame,
        enabled = true,
        display = {
            labelKey = labelKey,
            labelFallback = label,
            label = label,
            utteranceFallback = utterance,
            utterance = utterance,
        },
        visibility = "player",
        eligibility = {
            status = "allowed",
            allowed = true,
            reason = "conversation_landing_shortcut",
        },
    }
    if #predicateTrace < Predicates.MAX_TRACE then
        predicateTrace[#predicateTrace + 1] = {
            candidateID = candidateID,
            source = "conversation_root",
            path = "conversationLanding.whatsUp",
            status = "allowed",
            reason = "conversation_landing_shortcut",
        }
    end
    candidate = normalizeCandidate(
        candidate, "conversation_root", #output + 1
    )
    output[#output + 1] = candidate
    seen[candidateID] = candidate
end

local function appendTalkAgainAbout(
    output, seen, context, revision, predicateTrace
)
    local candidateID = "conversation.landing:talk_again_about"
    if seen[candidateID]
        or not hasConversationHistory(context)
        or #output >= Suggestions.MAX_CANDIDATES
    then
        return
    end
    local labelKey =
        "UI_PNC_Conversation_Suggestion_TalkAgainAbout_Label"
    local label = resolvedText(labelKey, "Talk again about")
    local frame = Suggestions.BuildGroupFrame({
        id = Suggestions.CONTEXT_INDEX_GROUP_ID,
        label = label,
        labelKey = labelKey,
        allowBack = true,
    }, revision)
    if not frame then return end
    local source = sourceRecord(
        "conversation_root", revision, "conversation_context_index"
    )
    local candidate = {
        id = candidateID,
        groupID = Suggestions.ROOT_GROUP_ID,
        rank = #output + 1,
        source = source,
        sources = { source },
        frame = frame,
        enabled = true,
        display = {
            labelKey = labelKey,
            labelFallback = label,
            label = label,
        },
        visibility = "player",
        eligibility = {
            status = "allowed",
            allowed = true,
            reason = "conversation_context_history",
        },
    }
    candidate = normalizeCandidate(
        candidate, "conversation_root", #output + 1
    )
    output[#output + 1] = candidate
    if #predicateTrace < Predicates.MAX_TRACE then
        predicateTrace[#predicateTrace + 1] = {
            candidateID = candidateID,
            source = "conversation_root",
            path = "conversationLanding.contextIndex",
            status = "allowed",
            reason = "conversation_context_history",
        }
    end
    seen[candidateID] = output[#output]
end

local GROUP_LABELS = {
    whats_up = {
        key = "UI_PNC_Conversation_Suggestion_Group_WhatsUp_Label",
        fallback = "What's up",
    },
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
    companion_orders = {
        key = "UI_PNC_Conversation_Suggestion_CompanionOrders_Label",
        fallback = "I need you to do something...",
    },
    companion_camp = {
        key = "UI_PNC_Conversation_Suggestion_CompanionCamp_Label",
        fallback = "Let's camp...",
    },
}

local function groupPresentation(id, topic)
    if id == Suggestions.ROOT_GROUP_ID then
        return {
            id = id,
            label = resolvedText(
                "UI_PNC_Conversation_Suggestion_Group_Landing_Label",
                "Talk"
            ),
            labelKey = "UI_PNC_Conversation_Suggestion_Group_Landing_Label",
            allowBack = true,
        }
    end
    if id == Suggestions.CONTEXT_INDEX_GROUP_ID then
        return {
            id = id,
            label = resolvedText(
                "UI_PNC_Conversation_Suggestion_TalkAgainAbout_Label",
                "Talk again about"
            ),
            labelKey =
                "UI_PNC_Conversation_Suggestion_TalkAgainAbout_Label",
            allowBack = true,
        }
    end
    if id == "semantic_hub.whats_up" then
        local label = GROUP_LABELS.whats_up
        return {
            id = id,
            topic = "whats_up",
            label = resolvedText(label.key, label.fallback),
            labelKey = label.key,
        }
    end
    if id == Suggestions.COMPANION_ORDERS_GROUP_ID then
        local label = GROUP_LABELS.companion_orders
        return {
            id = id,
            topic = "movement",
            label = resolvedText(label.key, label.fallback),
            labelKey = label.key,
            allowBack = true,
        }
    end
    if id == Suggestions.COMPANION_CAMP_GROUP_ID then
        local label = GROUP_LABELS.companion_camp
        return {
            id = id,
            topic = "movement",
            label = resolvedText(label.key, label.fallback),
            labelKey = label.key,
            allowBack = true,
        }
    end
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
    if string.sub(tostring(id or ""), 1, 6) == "topic:" then
        local topicID = tostring(topic or string.sub(id, 7))
        local key = "category." .. topicID
        local categoryLabel = resolvedText(key, topicID)
        local text = PsychopatzCore and PsychopatzCore.Conversation
            and PsychopatzCore.Conversation.Text or nil
        if text and type(text.Resolve) == "function" then
            local ok, value = pcall(text.Resolve, {
                key = key,
                domain = "pnc.system.shared.categories",
                fallback = categoryLabel,
            })
            if ok and type(value) == "string" and value ~= "" then
                categoryLabel = value
            end
        end
        return {
            id = id,
            topic = topicID,
            label = categoryLabel,
            labelKey = key,
        }
    end
    if id == "conversation_actions" then
        return {
            id = id,
            label = resolvedText(
                "UI_PNC_Conversation_Suggestion_Group_Actions_Label",
                "Conversation actions"
            ),
            labelKey = "UI_PNC_Conversation_Suggestion_Group_Actions_Label",
        }
    end
    if id == "conversation_utilities" then
        return {
            id = id,
            label = resolvedText(
                "UI_PNC_Conversation_Suggestion_Group_Utilities_Label",
                "Conversation utilities"
            ),
            labelKey = "UI_PNC_Conversation_Suggestion_Group_Utilities_Label",
        }
    end
    return { id = id, label = id }
end

local function buildGroups(
    candidates, capabilities, currentTopic, revision, context
)
    local groups = {}
    local byID = {}
    local function ensure(id, topic)
        if not id then return nil end
        if not byID[id] then
            local group = groupPresentation(id, topic)
            group.candidates = {}
            group.capabilities = {}
            group.count = 0
            group.allowBack = true
            group.frame = Suggestions.BuildGroupFrame(group, revision)
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
            if candidate.allowBack == false
                or candidate.frame and candidate.frame.allowBack == false
                or candidate.frame and type(candidate.frame.extensions)
                    == "table"
                    and candidate.frame.extensions.allowBack == false
            then
                group.allowBack = false
            end
        end
    end
    for _, capability in ipairs(capabilities or {}) do
        local group = ensure(capability.groupID or "owned_actions", "movement")
        if group then
            group.capabilities[#group.capabilities + 1] = capability
            group.count = group.count + 1
            if capability.allowBack == false then group.allowBack = false end
        end
    end
    if byID[Suggestions.COMPANION_ORDERS_GROUP_ID] then
        -- The camp branch is a semantic navigation surface even before its
        -- dynamic site rows are projected. P12F fills it from live CampSite
        -- discovery; no room or Java object is retained here.
        ensure(Suggestions.COMPANION_CAMP_GROUP_ID, "movement")
    end
    context.semanticGroupParents = type(context.semanticGroupParents) == "table"
        and context.semanticGroupParents or {}
    context.semanticGroupParents[Suggestions.COMPANION_ORDERS_GROUP_ID] =
        Suggestions.ROOT_GROUP_ID
    context.semanticGroupParents[Suggestions.COMPANION_CAMP_GROUP_ID] =
        Suggestions.COMPANION_ORDERS_GROUP_ID
    local rootGroupID = byID[Suggestions.ROOT_GROUP_ID]
        and Suggestions.ROOT_GROUP_ID or nil
    -- The authored greeting is the opening lifecycle state, not a selected
    -- semantic topic. Keep the first Talk surface on the landing page.
    local semanticTopicActive = currentTopic
        and tostring(currentTopic) ~= "greeting"
    local requestedGroupID = context and context.activeSuggestionGroupID
    local requestedNonRootGroup = requestedGroupID
        and requestedGroupID ~= Suggestions.ROOT_GROUP_ID
    local currentGroupID = requestedNonRootGroup and byID[requestedGroupID]
        and requestedGroupID
        or not semanticTopicActive and rootGroupID
        or currentTopic == "whats_up"
        and byID["semantic_hub.whats_up"]
        and "semantic_hub.whats_up" or topicGroupID(currentTopic)
    if not byID[currentGroupID] then
        currentGroupID = byID.conversation_branch and "conversation_branch"
            or byID.active_flow and "active_flow"
            or byID.npc_response_plan and "npc_response_plan"
            or byID.owned_actions and "owned_actions"
            or groups[1] and groups[1].id
    end
    if rootGroupID then
        for index, group in ipairs(groups) do
            if group.id == rootGroupID and index ~= 1 then
                table.remove(groups, index)
                table.insert(groups, 1, group)
                break
            end
        end
    end
    -- Navigation is part of the shared projection, not a renderer-only
    -- convenience. Native Core and Semantic Lab must receive the same typed
    -- presentation frame and the same allowBack gate.
    for _, group in ipairs(groups) do
        group.navigation = {}
        if rootGroupID
            and group.id ~= rootGroupID
            and group.allowBack ~= false
            and Suggestions.BuildBackFrame
        then
            local frame = Suggestions.BuildBackFrame(revision, group.id, context)
            if frame then
                group.navigation[#group.navigation + 1] = {
                    id = frame.candidateID,
                    frame = frame,
                    display = {
                        label = frame.labelFallback,
                        labelFallback = frame.labelFallback,
                    },
                    source = {
                        kind = "semantic_back_navigation",
                        revision = revision,
                        fromGroupID = group.id,
                    },
                }
            end
        end
    end
    return groups, currentGroupID, rootGroupID
end

function Suggestions.IsConversationCategoryFrame(frame)
    if type(frame) ~= "table" or frame.kind ~= "semantic_click_frame" then
        return false
    end
    local extensions = type(frame.extensions) == "table"
        and frame.extensions or {}
    return extensions.route == "conversation_category"
        and string.sub(tostring(extensions.categoryID or ""), 1, 15)
            == "projecthoomans:"
        and tostring(extensions.topic or "") ~= ""
end

function Suggestions.IsConversationCategoryAvailable(frame, context)
    if not Suggestions.IsConversationCategoryFrame(frame) then
        return false, "conversation_category_frame_invalid"
    end
    local categoryID = frame.extensions.categoryID
    local preflight = type(context) == "table"
        and context.conversationCategoryPreflight or nil
    if type(preflight) == "table"
        and tostring(preflight.categoryID or categoryID) == categoryID
    then
        return preflight.visible == true,
            preflight.reason or "category_preflight"
    end
    for _, diagnostic in ipairs(
        type(context) == "table" and context.categoryDiagnostics or {}
    ) do
        if type(diagnostic) == "table"
            and tostring(diagnostic.id or "") == categoryID
        then
            return diagnostic.visible == true,
                diagnostic.reason or "category_diagnostic"
        end
    end
    return false, "category_preflight_unknown"
end

function Suggestions.BuildGroupFrame(group, revision)
    group = type(group) == "table" and group or {}
    local groupID = tostring(group.id or "")
    if groupID == "" then return nil end
    local utterance = group.utterance
        or group.textFallback
        or group.label
        or group.labelFallback
        or groupID
    return {
        schemaVersion = Suggestions.VERSION,
        kind = "semantic_group_click_frame",
        candidateID = "semantic.group:" .. groupID,
        groupID = groupID,
        parentGroupID = group.parentGroupID,
        topic = group.topic,
        labelKey = group.labelKey,
        labelFallback = group.label or groupID,
        textFallback = utterance,
        utteranceFallback = utterance,
        utterance = utterance,
        navigationExchange = true,
        navigationKind = group.navigationKind or "topic",
        navigationSubject = group.navigationSubject or "CONVERSATION_TOPIC",
        requestRevision = tonumber(revision) or 0,
    }
end

function Suggestions.BuildShortcutFrame(options, revision)
    options = type(options) == "table" and options or {}
    local candidateID = tostring(options.candidateID or "")
    local utterance = boundedText(
        options.utterance or options.textFallback or "", 160
    )
    if candidateID == "" or utterance == "" then return nil end
    local labelFallback = boundedText(
        options.labelFallback or utterance, 160
    )
    return {
        schemaVersion = Suggestions.VERSION,
        kind = "semantic_shortcut_frame",
        candidateID = candidateID,
        topic = options.topic,
        intent = options.intent or "QUESTION",
        speechAct = options.speechAct or "QUESTION",
        subject = options.subject or "CONVERSATION_TOPIC",
        textFallback = utterance,
        utteranceFallback = utterance,
        utterance = utterance,
        labelKey = options.labelKey,
        labelFallback = labelFallback,
        extensions = copyValue(options.extensions) or {},
        requestRevision = tonumber(revision) or 0,
        allowBack = options.allowBack,
    }
end

function Suggestions.IsShortcutFrame(frame)
    return type(frame) == "table"
        and frame.kind == "semantic_shortcut_frame"
        and tostring(frame.candidateID or "") ~= ""
        and tostring(frame.textFallback or frame.utterance or "") ~= ""
        and tonumber(frame.requestRevision) ~= nil
end

function Suggestions.BuildBackFrame(revision, fromGroupID, context)
    fromGroupID = tostring(fromGroupID or "")
    if fromGroupID == "" then return nil end
    context = type(context) == "table" and context or {}
    local parents = type(context.semanticGroupParents) == "table"
        and context.semanticGroupParents or {}
    local targetGroupID = tostring(
        parents[fromGroupID] or Suggestions.ROOT_GROUP_ID
    )
    local labelKey =
        "UI_PNC_Conversation_Suggestion_TalkSomethingElse_Label"
    local label = resolvedText(labelKey, "Let's talk something else")
    local seed = context.saveSeed
        or context.playerIdentitySeed
        or context.npcID
        or "semantic_navigation"
    local replies = {
        "Let's talk about something else.",
        "Maybe we should change the subject.",
        "There's something else I wanted to discuss.",
    }
    local reply = replies[Identity.Index(
        seed,
        table.concat({
            "semantic_back_reply",
            tostring(context.playerIdentitySeed or "player"),
            tostring(context.npcID or "npc"),
            fromGroupID,
        }, ":"),
        #replies
    )]
    return {
        schemaVersion = Suggestions.VERSION,
        kind = "semantic_back_click_frame",
        candidateID = "semantic.back_to_root:" .. fromGroupID,
        groupID = targetGroupID,
        fromGroupID = fromGroupID,
        utterance = reply,
        textFallback = reply,
        utteranceFallback = reply,
        playerReply = true,
        navigationReply = true,
        navigationExchange = true,
        navigationKind = "subject_change",
        navigationSubject = "CONVERSATION_TOPIC",
        labelKey = labelKey,
        labelFallback = label,
        requestRevision = tonumber(revision) or 0,
    }
end

function Suggestions.IsBackFrame(frame)
    return type(frame) == "table"
        and frame.kind == "semantic_back_click_frame"
        and tostring(frame.candidateID or "") ~= ""
        and tostring(frame.fromGroupID or "") ~= ""
        and tonumber(frame.requestRevision) ~= nil
end

function Suggestions.IsGroupFrame(frame)
    return type(frame) == "table"
        and frame.kind == "semantic_group_click_frame"
        and tostring(frame.groupID or "") ~= ""
        and tonumber(frame.requestRevision) ~= nil
end

function Suggestions.IsNavigationFrame(frame)
    return (Suggestions.IsBackFrame(frame)
            or Suggestions.IsGroupFrame(frame))
        and frame.navigationExchange ~= false
end

function Suggestions.NavigationFrameToIR(frame, view)
    if not Suggestions.IsNavigationFrame(frame) then
        return nil, "navigation_frame_invalid"
    end
    local actorID = view and view.spec and view.spec.npcID or nil
    local value = Suggestions.ResolveFrameText(frame)
    if value == "" then return nil, "navigation_frame_text_missing" end
    return IR.New({
        kind = "semantic_navigation_frame",
        rawText = value,
        normalizedText = normalizedText(value),
        intent = "NAVIGATE",
        speechAct = "NAVIGATE",
        subject = frame.navigationSubject or "CONVERSATION_TOPIC",
        target = {
            kind = "actor",
            id = actorID,
            source = "conversation",
        },
        slots = {
            npcID = actorID,
        },
        extensions = {
            topic = frame.topic or "conversation_navigation",
            navigationKind = frame.navigationKind or "topic",
            fromGroupID = frame.fromGroupID or frame.parentGroupID,
            toGroupID = frame.groupID,
            candidateID = frame.candidateID,
        },
        confidence = 1,
        provenance = {
            provider = "suggestion",
            parser = "semantic_navigation_frame",
            pattern = frame.navigationKind or "semantic_navigation",
            candidateID = frame.candidateID,
        },
    })
end

function Suggestions.IsConversationChoiceFrame(frame)
    if type(frame) ~= "table" or frame.kind ~= "semantic_click_frame" then
        return false
    end
    local extensions = type(frame.extensions) == "table"
        and frame.extensions or {}
    return extensions.route == "conversation_choice"
        and string.sub(tostring(extensions.categoryID or ""), 1, 15)
            == "projecthoomans:"
        and tostring(extensions.blockID or "") ~= ""
        and tostring(extensions.nodeID or "") ~= ""
        and tostring(extensions.choiceID or "") ~= ""
end

function Suggestions.IsConversationRootChoiceFrame(frame)
    if type(frame) ~= "table" or frame.kind ~= "semantic_click_frame" then
        return false
    end
    local extensions = type(frame.extensions) == "table"
        and frame.extensions or {}
    if extensions.origin ~= "conversation_root"
        or (extensions.route ~= "conversation_category"
            and extensions.route ~= "conversation_root_choice")
        or tostring(extensions.rootNodeID or "") == ""
    then
        return false
    end
    if extensions.route == "conversation_category" then
        return Suggestions.IsConversationCategoryFrame(frame)
            and tostring(extensions.rootChoiceID or "") ~= ""
    end
    return tostring(extensions.actionID or "") ~= ""
end

function Suggestions.Build(result, context, messages)
    if not DialogueRuntime.IsEnabled() then
        return {
            schemaVersion = Suggestions.VERSION,
            kind = "semantic_dialogue_suggestions",
            revision = 0,
            turnID = 0,
            candidates = {},
            sources = {},
            permittedCapabilities = {},
            groups = {},
            currentTopic = nil,
            currentGroupID = nil,
            rootGroupID = nil,
            allowBack = false,
            predicateTrace = {},
            trace = {{
                source = "semantic_runtime",
                status = "disabled",
                reason = "semantic_dialogue_disabled",
            }},
        }
    end
    result = type(result) == "table" and result or {}
    context = type(context) == "table" and context or {}
    local revision, turnID = revisionFor(result)
    local candidates = {}
    local seen = {}
    local trace = {}
    local ir = type(result.ir) == "table" and result.ir or {}
    local pendingIdentity = context.pendingIdentityExchange
        or context.semanticContextState
        and context.semanticContextState.pendingIdentityExchange
        or context.semanticDialogueContext
        and context.semanticDialogueContext.pendingIdentityExchange
    local activeHubID = semanticHubID(ir)
    local currentAction = normalized(ir.action)
    local capabilities, capabilitySource, predicateTrace = capabilityRows(
        revision, currentAction, context, ir
    )
    local actorConversationContext = context.actorConversationContext
    if type(actorConversationContext) ~= "table" then
        actorConversationContext = ActorConversationContext.Build(context)
    end

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
            rootGroupID = nil,
            allowBack = true,
            predicateTrace = {},
            trace = trace,
            choiceRegistry = ChoiceRegistry.Snapshot(),
            actorConversationContext = ActorConversationContext.PublicView(
                actorConversationContext
            ),
        }
    end

    local decision = type(result.decision) == "table"
        and result.decision or {}
    local flow = type(decision.flow) == "table" and decision.flow or {}
    local flowActive = flow.flowId ~= nil
        and (flow.committed == true or flow.matched == true)
    -- Keep the production landing choices in the projection even while a
    -- child topic/flow is active. They stay out of the selected child group,
    -- but this lets the shared Back frame return to a real landing surface
    -- instead of a synthetic empty page.
    appendConversationRootChoices(
        candidates, seen, context, revision, predicateTrace
    )
    appendLandingShortcuts(
        candidates, seen, revision, predicateTrace
    )
    appendTalkAgainAbout(
        candidates, seen, context, revision, predicateTrace
    )
    appendConversationChoices(
        candidates, seen, context, revision, predicateTrace
    )
    appendCompanionOrderNavigation(
        candidates, seen, context, revision, predicateTrace
    )
    appendCompanionCampNavigation(
        candidates, seen, context, revision, predicateTrace
    )
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

    -- All optional/domain providers use the generic registry lane. The
    -- registry filters raw legacy definitions, so static/capability choices
    -- still pass through their existing authoritative adapters above while
    -- canonical Dynamic Trading and contextual social candidates are
    -- discovered without provider-specific calls here.
    local providerTopic = topicFromIR(ir, nil)
        or canonicalTopic(context.currentTopic)
    local providerContext = context
    local currentContextTopic = tostring(context.currentTopic or "")
    local needsProviderContext = activeHubID ~= nil
        or providerTopic ~= nil
            and currentContextTopic ~= tostring(providerTopic)
    if needsProviderContext then
        -- Providers receive the current typed topic without mutating the
        -- read-only projection shared by the remaining suggestion sources.
        providerContext = {}
        for key, value in pairs(context) do
            providerContext[key] = value
        end
    end
    if providerTopic ~= nil
        and currentContextTopic ~= tostring(providerTopic)
    then
        providerContext.currentTopic = providerTopic
    end
    if activeHubID ~= nil then
        providerContext.activeHubID = activeHubID
    end
    local providerCandidates = ChoiceRegistry.Collect(
        providerContext, Suggestions.MAX_CANDIDATES
    )
    for _, candidate in ipairs(providerCandidates or {}) do
        if isActiveHubCandidate(candidate, activeHubID) then
            appendTrace(
                trace, "semantic_hub", "consumed", "hub_already_active",
                #candidates
            )
        else
            addProviderCandidate(candidates, seen, candidate, revision)
        end
    end
    if activeHubID ~= nil then
        appendTrace(
            trace, "semantic_hub", "active", "reviewed_hub_activation",
            #candidates
        )
    end

    local subject = normalized(ir.subject)
    local typedTopic = topicFromIR(ir, nil)
    local currentTopic = typedTopic or canonicalTopic(context.currentTopic)
    local typedReason = subject ~= "" and "interpreted_frame" or "no_subject"
    local typedSource = sourceRecord("typed_input", revision, typedReason)
    local typedEligible = result.accepted == true
        and subject ~= ""
        and ir.kind ~= "semantic_click_frame"
    if typedEligible and currentTopic then
        if subject == "WELLBEING" then
            addCandidate(
                candidates, seen, definitionFor("question.wellbeing_detail"),
                "typed_input", revision, "wellbeing_follow_up"
            )
        end
        local pendingIdentity = context.pendingIdentityExchange
            or context.semanticContextState
            and context.semanticContextState.pendingIdentityExchange
            or context.semanticDialogueContext
            and context.semanticDialogueContext.pendingIdentityExchange
        for _, definition in ipairs(DEFINITIONS) do
            if topicMatches(definition, currentTopic)
                and definition.hubOnly ~= true
                and not (pendingIdentity and subject == "IDENTITY")
            then
                if isActiveHubDefinition(definition, activeHubID) then
                    appendTrace(
                        trace, "typed_input", "consumed",
                        "semantic_hub_already_active", #candidates
                    )
                else
                    addCandidate(
                        candidates, seen, definition,
                        "typed_input", revision, "topic_branch"
                    )
                end
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
        if not (pendingIdentity and normalized(topic) == "IDENTITY") then
            addCandidate(
                candidates, seen, definition,
                "npc_response_plan", revision, "response_plan_topic"
            )
            appendTrace(
                trace, "npc_response_plan", "allowed", topic, #candidates
            )
        else
            appendTrace(
                trace,
                "npc_response_plan",
                "consumed",
                "identity_exchange_choices_active",
                #candidates
            )
        end
    else
        appendTrace(trace, "npc_response_plan", "skipped", "topic_unknown", #candidates)
    end

    local flowSource = sourceRecord(
        "active_flow", revision,
        flowActive and "active_flow" or "no_active_flow"
    )
    local flowTopic = responseTopic({ decision = { flow = flow } })
    if flowActive and flowTopic then
        if not (pendingIdentity and normalized(flowTopic) == "IDENTITY") then
            addCandidate(
                candidates, seen, definitionForSubject(flowTopic, false),
                "active_flow", revision, "active_flow_response_pool"
            )
            appendTrace(
                trace, "active_flow", "allowed", "active_flow", #candidates
            )
        else
            appendTrace(
                trace,
                "active_flow",
                "consumed",
                "identity_exchange_choices_active",
                #candidates
            )
        end
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

    local ranking, orderedCandidates = ChoiceRanking.Apply(
        candidates, capabilities, context, currentTopic
    )
    candidates = orderedCandidates
    local groups, currentGroupID, rootGroupID = buildGroups(
        candidates, capabilities, currentTopic, revision, context
    )
    local dynamicCampCapabilities = {}
    appendCampSiteCapabilityRows(
        dynamicCampCapabilities, revision, context, ir
    )
    local campGroup
    for _, group in ipairs(groups or {}) do
        if group.id == Suggestions.COMPANION_CAMP_GROUP_ID then
            campGroup = group
            break
        end
    end
    if campGroup then
        for _, capability in ipairs(dynamicCampCapabilities) do
            -- Keep dynamic destinations in the camp group and in the
            -- authoritative capability projection, but add them after
            -- ranking so they can never leak onto the landing surface.
            capabilities[#capabilities + 1] = capability
            campGroup.capabilities[#campGroup.capabilities + 1] = capability
            campGroup.count = campGroup.count + 1
        end
    end
    if isCompanionOrderAction(currentAction) then
        for _, group in ipairs(groups or {}) do
            if group.id == Suggestions.COMPANION_ORDERS_GROUP_ID then
                currentGroupID = group.id
                break
            end
        end
    end

    return {
        schemaVersion = Suggestions.VERSION,
        kind = "semantic_dialogue_suggestions",
        activeHub = activeHubID and {
            id = activeHubID,
            route = "semantic_hub",
        } or nil,
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
        rootGroupID = rootGroupID,
        allowBack = true,
        predicateTrace = predicateTrace,
        trace = trace,
        privacy = {
            playerVisible = true,
            privateFieldsInspected = false,
            unknownFieldsExposed = false,
        },
        choiceRegistry = ChoiceRegistry.Snapshot(),
        actorConversationContext = ActorConversationContext.PublicView(
            actorConversationContext
        ),
        ranking = ranking,
    }
end

return Suggestions
