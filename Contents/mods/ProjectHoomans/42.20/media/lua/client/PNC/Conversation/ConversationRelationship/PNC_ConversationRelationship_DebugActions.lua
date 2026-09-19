-- Route explicit relationship debug actions to client adapters.
local Relationship = PNC.Conversation.Relationship

function Relationship.ApplyDebugStanding(npcID, standingID)
    if not PNC.Client or not PNC.Client.CanUseDebug
        or not PNC.Client.CanUseDebug()
        or not PNC.Client.SendDebug
    then
        return false, "not_authorized"
    end
    return PNC.Client.SendDebug("relationship_debug_baseline", {
        observerNPCID = tostring(npcID or ""),
        targetKind = "current_player",
        standingID = tostring(standingID or ""),
    })
end

function Relationship.TriggerDebugEvent(npcID, eventType)
    if not PNC.Client or not PNC.Client.CanUseDebug
        or not PNC.Client.CanUseDebug()
        or not PNC.Client.SendDebug
    then
        return false, "not_authorized"
    end
    return PNC.Client.SendDebug("social_trigger_event", {
        observerNPCID = tostring(npcID or ""),
        targetKind = "current_player",
        eventType = tostring(eventType or ""),
    })
end

function Relationship.OpenLaboratory(npcID)
    if PNC.RelationshipDebugUI and PNC.RelationshipDebugUI.Open then
        return PNC.RelationshipDebugUI.Open(npcID)
    end
    return nil
end

