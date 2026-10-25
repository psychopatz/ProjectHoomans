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
Internal.sourceRecord = sourceRecord
Internal.isActiveHubDefinition = isActiveHubDefinition
Internal.isActiveHubCandidate = isActiveHubCandidate

return Suggestions

