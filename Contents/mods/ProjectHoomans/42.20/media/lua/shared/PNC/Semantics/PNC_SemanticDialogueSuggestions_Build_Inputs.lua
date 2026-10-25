-- Suggestion-build input normalization and privacy projections.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Suggestions = PNC.Semantics.DialogueSuggestions
local Internal = Suggestions.Internal
local ActorConversationContext = Internal.ActorConversationContext
local ChoiceRegistry = Internal.ChoiceRegistry
local normalized = Internal.normalized
local semanticHubID = Internal.semanticHubID
local revisionFor = Internal.revisionFor
local privateResult = Internal.privateResult

function Internal.DisabledSuggestionProjection()
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

function Internal.PrepareSuggestionBuild(result, context, messages)
    result = type(result) == "table" and result or {}
    context = type(context) == "table" and context or {}
    local revision, turnID = revisionFor(result)
    local ir = type(result.ir) == "table" and result.ir or {}
    local actorConversationContext = context.actorConversationContext
    if type(actorConversationContext) ~= "table" then
        actorConversationContext = ActorConversationContext.Build(context)
    end

    local state = {
        result = result,
        context = context,
        messages = messages,
        revision = revision,
        turnID = turnID,
        ir = ir,
        candidates = {},
        seen = {},
        trace = {},
        actorConversationContext = actorConversationContext,
        pendingIdentity = context.pendingIdentityExchange
            or context.semanticContextState
            and context.semanticContextState.pendingIdentityExchange
            or context.semanticDialogueContext
            and context.semanticDialogueContext.pendingIdentityExchange,
        activeHubID = semanticHubID(ir),
        currentAction = normalized(ir.action),
    }

    if privateResult(result) then
        state.private = true
    end
    return state
end

function Internal.PrivateSuggestionProjection(state)
    return {
        schemaVersion = Suggestions.VERSION,
        kind = "semantic_dialogue_suggestions",
        revision = state.revision,
        turnID = state.turnID,
        candidates = {},
        sources = {},
        permittedCapabilities = {},
        groups = {},
        currentTopic = nil,
        currentGroupID = nil,
        rootGroupID = nil,
        allowBack = true,
        predicateTrace = {},
        trace = state.trace,
        choiceRegistry = ChoiceRegistry.Snapshot(),
        actorConversationContext = ActorConversationContext.PublicView(
            state.actorConversationContext
        ),
    }
end

return Suggestions
