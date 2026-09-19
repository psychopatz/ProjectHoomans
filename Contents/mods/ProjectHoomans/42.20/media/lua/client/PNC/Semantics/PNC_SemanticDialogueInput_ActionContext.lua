-- Build the shared client-side dispatch context for semantic actions.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local ActionContext = PNC.Semantics.DialogueInputActionContext or {}
PNC.Semantics.DialogueInputActionContext = ActionContext

local function isBroadcastCamp(group, result, value)
    local decision = result and result.decision or nil
    local intent = decision and decision.actionIntent or nil
    local action = decision and decision.action
        or result and result.ir and result.ir.action
        or type(intent) == "table" and intent.action
        or ""
    local addressed
    if not group or string.upper(tostring(action)) ~= "CAMP" then
        return false
    end
    if type(group.AddressedIDs) ~= "function" then return true end
    local ok
    ok, addressed = pcall(group.AddressedIDs, group, result, value)
    if not ok or type(addressed) ~= "table" then return true end
    for _ in pairs(addressed) do return false end
    return true
end

function ActionContext.Build(view, result, value)
    local spec = view and view.spec or {}
    local session = view and view.session
    local group = view and view.groupConversation
    local actorID = session and session.characterUUID
    local recipientID = spec.npcID
    local lifecycle = spec.context
        and spec.context.conversationLifecycleState or nil
    local origin
    local groupCamp = isBroadcastCamp(group, result, value)
    local targets
    local selectionOrigin = spec.context and spec.context.player
        or getSpecificPlayer and getSpecificPlayer(0) or nil
    local registry = PNC.Registry
    if registry and type(registry.GetLiveZombie) == "function"
        and recipientID
    then
        local ok, body = pcall(registry.GetLiveZombie, recipientID)
        if ok then origin = body end
    end
    origin = origin or spec.context and spec.context.player
        or getSpecificPlayer and getSpecificPlayer(0) or nil
    if groupCamp and type(group.participantIDs) == "table" then
        targets = {}
        for index = 1, #group.participantIDs do
            targets[index] = group.participantIDs[index]
        end
    end
    return {
        npcID = spec.npcID,
        targetID = spec.npcID,
        actor = actorID and { id = actorID } or nil,
        recipient = recipientID and { id = recipientID } or nil,
        dialogueID = session and session.conversationID,
        conversationID = session and session.conversationID,
        requestID = view and view.semanticRequestID or result.sequence,
        scope = groupCamp and "group" or "single",
        targets = targets,
        groupID = group and group.id,
        groupTurnID = group and group.activeTurn
            and group.activeTurn.id or nil,
        groupScope = group and "nearby" or "single",
        rawText = value,
        normalizedText = result.ir and result.ir.normalizedText,
        confidence = result.ir and result.ir.confidence,
        provenance = result.ir and result.ir.provenance,
        conversationToken = lifecycle and lifecycle.token or nil,
        worldOrigin = origin,
        selectionOrigin = selectionOrigin,
    }
end

return ActionContext
