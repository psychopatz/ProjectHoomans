-- Server-side conversation choice effect transaction boundary.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.Conversation.Authority = PNC.Conversation.Authority or {}
local Authority = PNC.Conversation.Authority
local Internal = Authority.Internal
local Rules = PNC.Conversation.Rules
local History = PNC.Conversation.History
local ChoiceEffects = {}

local personalRelationshipQueries = Internal.PersonalRelationshipQueries
local relationshipCopy = Internal.RelationshipCopy
local relationshipDelta = Internal.RelationshipDelta
local InteractionLifecycle = PNC.Semantics
    and PNC.Semantics.InteractionLifecycle or nil
local InteractionPersistence = PNC.Conversation
    and PNC.Conversation.InteractionLifecyclePersistence or nil

local function recordLifecycleMeaning(state, context, block, choice, outcome)
    if not InteractionLifecycle
        or not InteractionPersistence
        or type(InteractionPersistence.Apply) ~= "function"
        or type(InteractionLifecycle.Envelope) ~= "table"
    then
        return
    end
    local playerUUID = context.playerEntityKey or context.characterUUID
        or context.playerUUID
    local eventRef = table.concat({
        "conversation",
        tostring(state.record.id),
        tostring(state.args.requestID),
        tostring(outcome.id),
    }, ":")
    local envelope = InteractionLifecycle.Envelope.Build({
        source = "semantic_choice",
        actorID = playerUUID,
        targetID = state.record.id,
        playerUUID = playerUUID,
        act = "CHOICE",
        topic = block.category or block.id,
        eventType = "conversation_choice",
        eventRef = eventRef,
        provenance = {
            beatID = "conversation:" .. tostring(block.id) .. ":"
                .. tostring(state.conversationState.nodeID),
            responsePlanID = outcome.id,
            flowID = block.id,
            poolID = choice.id,
        },
        worldHour = context.worldAgeHours,
    })
    local applied, applyReason = InteractionPersistence.Apply(envelope, {
        meaningful = true,
        beatID = "conversation:" .. tostring(block.id) .. ":"
            .. tostring(outcome.next or "closed"),
        resolveBeat = outcome.close == true,
        worldHour = context.worldAgeHours,
    })
    if not applied and PNC.Core and type(PNC.Core.LogWarn) == "function" then
        PNC.Core.LogWarn(
            "conversation lifecycle choice failed reason="
                .. tostring(applyReason or "unknown")
        )
        return
    end
    if outcome.close == true
        or type(InteractionPersistence.RecordNPCSpeech) ~= "function"
    then
        return
    end
    local speech, speechReason = InteractionPersistence.RecordNPCSpeech({
        npcID = state.record.id,
        targetID = playerUUID,
        playerUUID = playerUUID,
        act = "RESPOND",
        topic = block.category or block.id,
        beatID = "conversation:" .. tostring(block.id) .. ":"
            .. tostring(outcome.next or "closed"),
        responsePlanID = outcome.id,
        flowID = block.id,
        poolID = choice.id,
        eventRef = eventRef .. ":npc",
        worldHour = context.worldAgeHours,
        meaningful = true,
        expectedReplies = { "yes", "no", "tell_me_more" },
    })
    if not speech and PNC.Core and type(PNC.Core.LogWarn) == "function" then
        PNC.Core.LogWarn(
            "conversation lifecycle NPC provenance failed reason="
                .. tostring(speechReason or "unknown")
        )
    end
end

function ChoiceEffects.Commit(state)
    local args = state.args
    local block = state.block
    local choice = state.choice
    local outcome = state.outcome
    local context = state.context
    context.interaction = {
        kind = "conversation",
        source = "conversation",
        categoryID = block.category,
        blockID = block.id,
        nodeID = state.conversationState.nodeID,
        choiceID = choice.id,
        outcomeID = outcome.id,
        playerTextKey = choice.textKey,
        npcTextKey = outcome.responseKey,
        responseKey = outcome.responseKey,
        at = context.worldAgeHours,
        worldAgeHours = context.worldAgeHours,
        applied = true,
    }
    local relationshipBefore = relationshipCopy(context.relationship)
    local effectResults
    local ok, reason = Rules.ValidateEffects(outcome.effects, context)
    if ok then
        ok, reason, effectResults = Rules.ApplyEffects(
            outcome.effects,
            context
        )
    end
    if not ok then return false, reason end

    recordLifecycleMeaning(state, context, block, choice, outcome)

    local relationshipAfter = relationshipBefore
    local relationshipQueries = personalRelationshipQueries()
    if relationshipQueries and relationshipQueries.Get then
        relationshipAfter = relationshipCopy(relationshipQueries.Get(
            state.record.id,
            context.playerEntityKey
        ))
    end
    History.Commit(block.id, block["repeat"], context, outcome.id)
    History.Commit(
        state.subjectID,
        choice["repeat"],
        context,
        outcome.id
    )
    History.Commit(
        "category:" .. tostring(state.conversationState.categoryID),
        { scope = "pair" },
        context,
        outcome.id
    )
    state.conversationState.nodeID = outcome.next
    local payload = {
        requestID = args.requestID,
        success = true,
        npcID = state.record.id,
        blockID = block.id,
        nodeID = args.nodeID,
        choiceID = choice.id,
        outcomeID = outcome.id,
        responseKey = outcome.responseKey,
        npcReaction = outcome.npcReaction,
        nextNodeID = outcome.next,
        close = outcome.close == true,
        closeReason = outcome.close == true and table.concat({
            "authored_outcome",
            block.id,
            state.conversationState.nodeID,
            choice.id,
            outcome.id,
        }, ":") or nil,
        relationshipBefore = relationshipBefore,
        relationshipAfter = relationshipAfter,
        relationshipDelta = relationshipDelta(
            relationshipBefore,
            relationshipAfter
        ),
        effectResults = effectResults,
        registryFingerprint = PNC.Conversation.Registry.GetFingerprint(),
    }
    if InteractionPersistence
        and type(InteractionPersistence.Project) == "function"
    then
        local lifecycle = InteractionPersistence.Project(
            context.playerEntityKey or context.characterUUID,
            state.record.id
        )
        -- Send only the targeted player's bounded semantic capsule. No
        -- rendered line or other player's private context crosses the wire.
        payload.interactionLifecycle = lifecycle
            and lifecycle.thread or nil
    end
    state.payload = payload
    state.conversationState.processed[args.requestID] = payload
    state.lease.processedConversationRequests =
        state.lease.processedConversationRequests or {}
    state.lease.processedConversationRequests[args.requestID] = payload
    return true
end

Internal.ChoiceHandleEffects = ChoiceEffects

return ChoiceEffects
