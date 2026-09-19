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
ContextProjection.Configure(WorldContext, EntityResolver, Situation)
RouterLifecycle.Configure(
    State,
    DialogueContextState,
    DialogueRouter,
    Policy,
    Internal
)
pcall(require, "PNC/Semantics/PNC_SemanticDialogueFactSources")

Internal.Policy = Policy
Internal.LLMEnabled = ContextProjection.LLMEnabled
Internal.ProviderStatus = function()
    return ContextProjection.ProviderStatus(Internal.LLMEnabled)
end
Internal.ShallowContext = function(view)
    return ContextProjection.Build(view, Internal.ProviderStatus)
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
    local recordOptions = {
        timestamp = options.timestamp,
        speaker = options.speaker or "player",
        source = options.source or "player_input",
        mentions = options.mentions,
    }
    return context:RecordTurn(ir, recordOptions)
end

Internal.RouterFor = RouterLifecycle.For

return Input
