-- Context and router lifecycle for the hybrid semantic dialogue input.
-- This spoke owns conversation-local semantic state, not presentation or
-- gameplay effects.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Input = PNC.Semantics.DialogueInput or {}
PNC.Semantics.DialogueInput = Input

local Internal = Input.Internal or {}
Input.Internal = Internal

local Semantic = PsychopatzCore.Semantics
local DialogueRouter = Semantic.DialogueRouter
local State = Semantic.DialogueState
local DialogueContextState = PNC.Semantics.DialogueContextState
if type(DialogueContextState) ~= "table" then
    local loaded = require
        "PNC/Semantics/PNC_SemanticDialogueContextState"
    DialogueContextState = type(loaded) == "table" and loaded or nil
end
local Policy = PNC.Semantics.DialoguePolicy
local Topics = PNC.Semantics.TopicCatalog
if type(Topics) ~= "table" then
    local loaded = require "PNC/Semantics/PNC_SemanticTopicCatalog"
    Topics = type(loaded) == "table" and loaded or nil
end
local WorldContext = PNC.Semantics.WorldContext
if type(WorldContext) ~= "table" then
    local loaded = require "PNC/Semantics/PNC_SemanticWorldContext"
    WorldContext = type(loaded) == "table" and loaded or nil
end
local ReferenceResolver = PNC.Semantics.DialogueReferenceResolver
if type(ReferenceResolver) ~= "table" then
    local loaded = require
        "PNC/Semantics/PNC_SemanticDialogueReferenceResolver"
    ReferenceResolver = type(loaded) == "table" and loaded or nil
end
local EntityResolver = PNC.Semantics.EntityResolver
if type(EntityResolver) ~= "table" then
    local loaded = require "PNC/Semantics/PNC_SemanticEntityResolver"
    EntityResolver = type(loaded) == "table" and loaded or nil
end
local FactResolver = PNC.Semantics.DialogueFacts
if type(FactResolver) ~= "table" then
    local loaded = require "PNC/Semantics/PNC_SemanticDialogueFacts"
    FactResolver = type(loaded) == "table" and loaded or nil
end
local Situation = PNC.Semantics.DialogueSituation
if type(Situation) ~= "table" then
    local loaded = require "PNC/Semantics/PNC_SemanticDialogueSituation"
    Situation = type(loaded) == "table" and loaded or nil
end

local ContextProjection = require
    "PNC/Semantics/PNC_SemanticDialogueInput_ContextProjection"
local Requests = require "PNC/Semantics/PNC_SemanticDialogueInput_Requests"
local RouterLifecycle = require
    "PNC/Semantics/PNC_SemanticDialogueInput_RouterLifecycle"
local ActorConversationService = require
    "PNC/Semantics/PNC_SemanticActorConversationService"
ContextProjection.Configure(WorldContext, EntityResolver, Situation)
RouterLifecycle.Configure(
    State,
    DialogueContextState,
    DialogueRouter,
    Policy,
    Internal,
    ActorConversationService
)
pcall(require, "PNC/Semantics/PNC_SemanticDialogueFactSources")

Internal.Policy = Policy
Internal.LLMEnabled = ContextProjection.LLMEnabled
Internal.ProviderStatus = function()
    return ContextProjection.ProviderStatus(Internal.LLMEnabled)
end
Internal.ShallowContext = function(view)
    local output = ContextProjection.Build(view, Internal.ProviderStatus)
    local group = view and view.groupConversation or nil
    local session = group and type(group.PrimarySession) == "function"
        and group:PrimarySession() or view and view.session
    local lifecycle = PNC.Semantics and PNC.Semantics.GiftLifecycle or nil
    if lifecycle and type(lifecycle.PendingOfferConsent) == "function" then
        output.pendingGiftConsent = lifecycle.PendingOfferConsent(
            session,
            Internal.Now and Internal.Now() or nil,
            nil,
            group and group.id or nil
        )
    end
    return output
end
Internal.ClearPendingGiftConsent = function(view)
    local group = view and view.groupConversation or nil
    local session = group and type(group.PrimarySession) == "function"
        and group:PrimarySession() or view and view.session
    local lifecycle = PNC.Semantics and PNC.Semantics.GiftLifecycle or nil
    if lifecycle and type(lifecycle.ClearOfferConsent) == "function" then
        return lifecycle.ClearOfferConsent(session)
    end
    return false
end
Internal.RequestCognitionForIR = Requests.RequestCognitionForIR
Internal.PrepareIdentityRequest = Requests.PrepareIdentityRequest
Internal.DispatchIdentityRequest = Requests.DispatchIdentityRequest
Internal.RequestIdentityForIR = function(view, ir, context)
    return Requests.RequestIdentityForIR(view, ir, context, Internal)
end

function Internal.Parse(value, options)
    local parser = Semantic.Parser and Semantic.Parser.Parse
    if type(parser) ~= "function" then return nil, "parser_unavailable" end
    local ir, reason = parser(value, options)
    if ir and Topics and type(Topics.Annotate) == "function" then
        Topics.Annotate(ir, value)
    end
    return ir, reason
end

function Internal.ParseCandidates(value, options)
    local parser = Semantic.Parser and Semantic.Parser.ParseCandidates
    if type(parser) ~= "function" then
        return nil, "candidate_parser_unavailable"
    end
    local bundle, reason = parser(value, options)
    if type(bundle) ~= "table" then return bundle, reason end
    if Topics and type(Topics.Annotate) == "function" then
        local candidates = bundle.candidates
        local index
        local candidate
        for index = 1, #(type(candidates) == "table" and candidates or {}) do
            candidate = candidates[index]
            if candidate and candidate.ir then
                Topics.Annotate(candidate.ir, value)
            end
        end
        if bundle.selected and bundle.selected.ir then
            Topics.Annotate(bundle.selected.ir, value)
        end
    end
    return bundle, reason
end

-- Core owns the bounded clause split; this adapter keeps candidate parsing and
-- vocabulary ownership in the existing Hoomans/Core parser path.
function Internal.ParseTurn(value, options, view)
    local service = view and Internal.ActorConversationService
        and Internal.ActorConversationService(view) or nil
    if service and type(service.ParseTurn) == "function" then
        return service:ParseTurn(value, options)
    end
    local turn = Semantic.DialogueTurn
    if not turn or type(turn.Parse) ~= "function" then
        return nil, "dialogue_turn_unavailable"
    end
    return turn.Parse(value, Internal.ParseCandidates, options)
end

function Internal.ResolveReferences(ir, state, context, options)
    local output = ir
    if ReferenceResolver
        and type(ReferenceResolver.Resolve) == "function"
    then
        output = ReferenceResolver.Resolve(ir, state, context, options)
    end
    if FactResolver and type(FactResolver.Annotate) == "function" then
        output = FactResolver.Annotate(output, state, context, options)
    end
    return output
end

function Internal.Now()
    return getTimeInMillis and getTimeInMillis()
        or getTimestampMs and getTimestampMs() or 0
end

function Internal.Interactive(view)
    local session = view and view.session
    if not view or not session then return false end
    if session.closed == true or session.conversationMemoryClosed == true then
        return false
    end
    if view.closed == true or view.closing == true
        or view.editMode == true
    then
        return false
    end

    -- The semantic input is a live conversation channel, not a choice
    -- button.  A queued NPC line makes Session.busy true while it is being
    -- typed/released, but it must not prevent the player from sending the
    -- next turn.  Keep the legacy host callback as a fallback for custom
    -- conversation hosts that do not expose the view animation state.
    if view.headless == true then
        return view.lifecycleFinished ~= true
    end
    if view.animationInteractive ~= nil then
        return view.animationInteractive == true
    end
    return type(view.isConversationInteractive) == "function"
        and view:isConversationInteractive() == true
end

function Internal.RecordContextTurn(view, ir, options)
    local session = view and view.session
    local context = session and session.semanticDialogueContext or nil
    if not context or type(context.RecordTurn) ~= "function" then
        return false, "context_state_unavailable"
    end
    options = type(options) == "table" and options or {}
    local preserveCurrentTopic = false
    if ir.intent == "ACCEPT"
        or ir.intent == "ACKNOWLEDGE"
        or ir.intent == "AGREE"
        or ir.intent == "THANK"
    then
        preserveCurrentTopic = context.pendingFollowUp == nil
    end
    local recordOptions = {
        timestamp = options.timestamp,
        speaker = options.speaker or "player",
        source = options.source or "player_input",
        mentions = options.mentions,
        preserveCurrentTopic = preserveCurrentTopic,
    }
    return context:RecordTurn(ir, recordOptions)
end

Internal.RouterFor = RouterLifecycle.For
Internal.ActorConversationService = function(view)
    local session = view and view.session
    if not session then return nil end
    if session.semanticActorConversationService then
        return session.semanticActorConversationService
    end
    RouterLifecycle.For(view)
    return session.semanticActorConversationService
end

return Input
