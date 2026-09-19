-- Own conversation-local semantic state and router initialization.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local RouterLifecycle = {}

local State
local DialogueContextState
local DialogueRouter
local Policy
local Internal

function RouterLifecycle.Configure(
    state,
    dialogueContextState,
    dialogueRouter,
    policy,
    internal
)
    State = state
    DialogueContextState = dialogueContextState
    DialogueRouter = dialogueRouter
    Policy = policy
    Internal = internal
end

function RouterLifecycle.For(view)
    local session = view and view.session
    if not session then return nil, "conversation_unavailable" end

    local source = view.spec and view.spec.context or {}
    local initialTopic = source.conversationTopic
        or source.conversationBlockContext
        and source.conversationBlockContext.conversationTopic

    if not session.semanticDialogueState then
        local participants = {}
        local groupParticipants = source.semanticGroupParticipants
        if type(groupParticipants) == "table" then
            for index = 1, #groupParticipants do
                participants[#participants + 1] = groupParticipants[index]
            end
        elseif view.spec and view.spec.npcID then
            participants[#participants + 1] = view.spec.npcID
        end
        if session.characterUUID then
            participants[#participants + 1] = session.characterUUID
        end
        session.semanticDialogueState = State.New({
            participants = participants,
            currentTopic = initialTopic,
            maxEvents = 12,
            maxParticipants = math.max(8, #participants),
        })
    end

    if not session.semanticDialogueContext
        and DialogueContextState
        and type(DialogueContextState.New) == "function"
    then
        session.semanticDialogueContext = DialogueContextState.New({
            currentTopic = initialTopic,
            maxTurns = 12,
            maxMentions = 32,
            maxFocus = 8,
        })
    end

    if not session.semanticDialogueRouter then
        session.semanticDialogueRouter = DialogueRouter.New({
            state = session.semanticDialogueState,
            policy = Policy,
            parser = Internal.Parse,
            contextResolver = Internal.ResolveReferences,
            context = Internal.ShallowContext(view),
        })
    else
        if type(session.semanticDialogueRouter.SetParser) == "function" then
            session.semanticDialogueRouter:SetParser(Internal.Parse)
        else
            session.semanticDialogueRouter.parser = Internal.Parse
        end
        if type(session.semanticDialogueRouter.SetContextResolver) == "function" then
            session.semanticDialogueRouter:SetContextResolver(
                Internal.ResolveReferences
            )
        else
            session.semanticDialogueRouter.contextResolver =
                Internal.ResolveReferences
        end
        session.semanticDialogueRouter:SetContext(Internal.ShallowContext(view))
        session.semanticDialogueRouter:SetPolicy(Policy)
    end
    return session.semanticDialogueRouter
end

return RouterLifecycle
