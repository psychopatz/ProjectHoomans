PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Suggestions = PNC.Semantics.DialogueSuggestions
local Internal = Suggestions.Internal

local Predicates = Internal.Predicates
local resolvedText = Internal.resolvedText
local normalizeCandidate = Internal.normalizeCandidate
local sourceRecord = Internal.sourceRecord
local Content = PNC.Semantics.DialogueContentRegistry
    or require "PNC/Semantics/Generated/DialogueContent/Registry"
local UIRegistry = PNC.Semantics.ConversationUIRegistry
    or require "PNC/Semantics/Generated/ConversationUI/Registry"

local function landingChoiceNode()
    local children = UIRegistry.Children("conversation.landing")
    for index = 1, #children do
        local node = UIRegistry.Node(children[index].nodeID)
        if type(node) == "table" and node.kind == "landing_choice" then
            return node, Content.PlayerChoice(node.contentID)
        end
    end
    return nil, nil
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
    local node, content = landingChoiceNode()
    local destination = node and node.semanticDestination or {}
    local candidateID = destination.candidateID
    if not candidateID then return end
    if seen[candidateID] or #output >= Suggestions.MAX_CANDIDATES then
        return
    end
    local labelKey = content and content.choiceKey or ""
    local label = resolvedText(
        labelKey, content and content.choiceFallback or labelKey
    )
    local utterance = content and content.choiceFallback or labelKey
    local frame = Suggestions.BuildShortcutFrame({
        candidateID = candidateID,
        topic = destination.topic,
        labelKey = labelKey,
        labelFallback = label,
        utterance = utterance,
        extensions = {
            route = destination.route,
            hubID = destination.hubID,
            canonicalConcept = destination.canonicalConcept
                or content and content.canonicalConcept or "WHATS_UP",
            origin = "conversation_landing",
        },
    }, revision)
    if not frame then return end
    local source = sourceRecord(
        "conversation_root", revision, "conversation_landing_shortcut"
    )
    local candidate = {
        id = candidateID,
        topic = destination.topic,
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
            path = "conversationLanding." .. tostring(destination.topic or "choice"),
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
