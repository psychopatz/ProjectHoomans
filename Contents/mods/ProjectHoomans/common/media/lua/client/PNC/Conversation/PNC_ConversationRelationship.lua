PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local Relationship = PNC.Conversation.Relationship or {}
PNC.Conversation.Relationship = Relationship

Relationship.categories = {
    FirstMeet = true,
    Acquaintance = true,
    Member = true,
    Lover = true,
}

-- Kept on during development. Gameplay can disable this before opening a
-- conversation, then reveal it in a dialogue branch such as "What do you
-- think of me?" without changing the relationship data flow.
Relationship.presentationVisible = Relationship.presentationVisible ~= false

local aliases = {
    firstmeet = "FirstMeet",
    first_meet = "FirstMeet",
    stranger = "FirstMeet",
    acquaintance = "Acquaintance",
    acuaintance = "Acquaintance",
    known = "Acquaintance",
    friend = "Acquaintance",
    member = "Member",
    companion = "Member",
    factionmember = "Member",
    faction_member = "Member",
    lover = "Lover",
    partner = "Lover",
    spouse = "Lover",
}

function Relationship.Normalize(value)
    if Relationship.categories[tostring(value or "")] then
        return tostring(value)
    end
    local normalized = string.lower(tostring(value or ""))
    normalized = string.gsub(normalized, "[%s%-]", "_")
    return aliases[normalized] or "FirstMeet"
end

local function playerKey(player)
    if player and player.getUsername then
        return tostring(player:getUsername())
    end
    if player and player.getOnlineID then
        return tostring(player:getOnlineID())
    end
    return nil
end

function Relationship.Resolve(entry, player)
    local snapshot = entry and entry.snapshot or {}
    local record = entry and entry.record or {}
    local relation = entry and entry.relationship
        or snapshot.relationship
        or record.relationship
        or {}
    local value = entry and (
            entry.conversationRelationship
            or entry.relationshipCategory
        )
        or snapshot.conversationRelationship
        or snapshot.relationshipCategory
        or record.conversationRelationship
        or record.relationshipCategory
        or relation.category
        or relation.status
    if value ~= nil then return Relationship.Normalize(value) end
    if snapshot.recruited == true
        or record.recruited == true
        or snapshot.ownerUsername
        or record.ownerUsername
    then
        return "Member"
    end
    local presentation = snapshot.mapPresentation
        or record.mapPresentation
        or {}
    local knownBy = presentation.knownBy or {}
    local key = playerKey(player)
    if key and knownBy[key] == true then return "Acquaintance" end
    return Relationship.Normalize(value)
end

function Relationship.GetPresentation(npcID)
    local state = PNC.Network and PNC.Network.ClientState or {}
    return state.conversationRelationships
        and state.conversationRelationships[tostring(npcID or "")]
        or nil
end

function Relationship.ReceivePresentation(summary)
    if type(summary) ~= "table" or not summary.npcID then return false end
    local view = PsychopatzCore
        and PsychopatzCore.Conversation
        and PsychopatzCore.Conversation.instance or nil
    if view and view.spec
        and tostring(view.spec.npcID or "") == tostring(summary.npcID)
        and view.extensionParts
        and view.extensionParts.relationship
        and view.extensionParts.relationship.setRelationship
    then
        view.extensionParts.relationship:setRelationship(summary)
    end
    return true
end

function Relationship.RequestPresentation(npcID)
    if PNC.Client and PNC.Client.RequestConversationRelationship then
        return PNC.Client.RequestConversationRelationship(npcID)
    end
    return false, "presentation_unavailable"
end

function Relationship.IsPresentationVisible()
    return Relationship.presentationVisible ~= false
end

function Relationship.SetPresentationVisible(visible)
    Relationship.presentationVisible = visible == true
    local view = PsychopatzCore
        and PsychopatzCore.Conversation
        and PsychopatzCore.Conversation.instance or nil
    local panel = view and view.extensionParts
        and view.extensionParts.relationship or nil
    if panel and panel.setVisible then
        panel:setVisible(Relationship.IsPresentationVisible())
    end
end

function Relationship.ApplyDebugStanding(npcID, standingID)
    if not PNC.Client or not PNC.Client.CanUseDebug
        or not PNC.Client.CanUseDebug()
        or not PNC.Client.SendDebug
    then
        return false, "not_authorized"
    end
    return PNC.Client.SendDebug("conversation_relationship_standing", {
        observerNPCID = tostring(npcID or ""),
        standingID = tostring(standingID or ""),
    })
end

return Relationship
