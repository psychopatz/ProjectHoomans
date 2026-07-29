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

return Relationship
