-- Resolve conversation relationship categories and client summaries.
local Relationship = PNC.Conversation.Relationship

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
    local verifier = PNC.Identity and PNC.Identity.Verifier or nil
    local ownership = verifier
        and verifier.BuildOwnershipSummary
        and verifier.BuildOwnershipSummary(entry)
        or nil
    local recruited = ownership
        and (ownership.recruited or ownership.colonyOwned)
        or snapshot.recruited == true
        or record.recruited == true
        or snapshot.ownerUsername
        or record.ownerUsername
    if value ~= nil then
        local normalized = Relationship.Normalize(value)
        -- A stale relationship presentation must not turn an already-owned
        -- NPC back into a recruit candidate. Lovers retain their special
        -- relationship category, while all other owned NPCs are Members.
        return recruited and normalized ~= "Lover"
            and "Member" or normalized
    end
    if recruited then
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

