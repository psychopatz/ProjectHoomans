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
    state.payload = payload
    state.conversationState.processed[args.requestID] = payload
    state.lease.processedConversationRequests =
        state.lease.processedConversationRequests or {}
    state.lease.processedConversationRequests[args.requestID] = payload
    return true
end

Internal.ChoiceHandleEffects = ChoiceEffects

return ChoiceEffects
