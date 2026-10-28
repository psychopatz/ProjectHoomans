PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Suggestions = PNC.Semantics.DialogueSuggestions
local Internal = Suggestions.Internal

local Predicates = Internal.Predicates
local resolvedText = Internal.resolvedText
local normalizeCandidate = Internal.normalizeCandidate
local sourceRecord = Internal.sourceRecord
local Content = PNC.Semantics.ConversationRegistry
    or require "PNC/Semantics/Generated/Conversation/Registry"
local WhatsUpContent = Content.PlayerChoice
    and Content.PlayerChoice("conversation.landing:whats_up") or {}

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
    local labelKey = WhatsUpContent.choiceKey
        or "UI_PNC_Conversation_Suggestion_WhatsUp_Label"
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

Internal.appendLandingShortcuts = appendLandingShortcuts
Internal.appendTalkAgainAbout = appendTalkAgainAbout

return Suggestions
