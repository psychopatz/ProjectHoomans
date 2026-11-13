-- Queue inventory answers through the conversation's existing delivery path.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local InventoryPresentation = {}

function InventoryPresentation.QueueResult(view, payload, response, requestID)
    local session = view and view.session
    if not session or type(session.queueMessage) ~= "function" then
        return false, "conversation_queue_unavailable"
    end
    local group = view and view.groupConversation
    local outputSession = group
        and type(group.PrimarySession) == "function"
        and group:PrimarySession() or session
    if not outputSession
        or type(outputSession.queueMessage) ~= "function"
    then
        return false, "conversation_queue_unavailable"
    end
    local speakerID
    local speakerName
    if group and type(group.SpeakerFor) == "function" then
        speakerID, speakerName = group:SpeakerFor(view)
    end
    outputSession:queueMessage("npc", response, {
        speakerID = speakerID,
        speakerName = speakerName,
        npcID = speakerID or view.spec and view.spec.npcID,
        participants = group and group.participantIDs or nil,
        source = {
            kind = "semantic",
            channel = "inventory_query_response",
            requestID = requestID,
            status = payload.status,
            reason = payload.reason,
            groupID = group and group.id,
            groupTurnID = group and group.activeTurn
                and group.activeTurn.id or nil,
        },
        provenance = {
            provider = "server_inventory_projection",
            parser = "marketsense_item_selector",
            requestID = requestID,
            groupID = group and group.id,
            groupTurnID = group and group.activeTurn
                and group.activeTurn.id or nil,
        },
    })
    return true
end

return InventoryPresentation
