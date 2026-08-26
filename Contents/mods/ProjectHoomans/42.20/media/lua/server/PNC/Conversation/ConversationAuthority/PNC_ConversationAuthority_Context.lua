-- Shared relationship, reply, and audience helpers.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.Conversation.Authority = PNC.Conversation.Authority or {}
PNC.Conversation.Authority.Internal =
    PNC.Conversation.Authority.Internal or {}

local Internal = PNC.Conversation.Authority.Internal

local function personalRelationshipQueries()
    local relationships = PNC.Relationships
    local personal = relationships and relationships.Personal
    return personal and personal.Queries or relationships
end

local function personalRelationshipCommands()
    local relationships = PNC.Relationships
    local personal = relationships and relationships.Personal
    return personal and personal.Commands or relationships
end

local function relationshipCopy(value)
    value = type(value) == "table" and value or {}
    return {
        approval = tonumber(value.approval) or 0,
        respect = tonumber(value.respect) or 0,
        familiarity = tonumber(value.familiarity) or 0,
        state = value.state,
    }
end

local function relationshipDelta(before, after)
    before = relationshipCopy(before)
    after = relationshipCopy(after)
    return {
        approval = after.approval - before.approval,
        respect = after.respect - before.respect,
        familiarity = after.familiarity - before.familiarity,
    }
end

local function worldAgeHours()
    local time = getGameTime and getGameTime() or nil
    return time and time.getWorldAgeHours
        and math.max(0, tonumber(time:getWorldAgeHours()) or 0) or 0
end

local function send(player, command, payload)
    local internal = PNC.Network and PNC.Network.Internal
    if not internal or not internal.SendToPlayer then return false end
    return internal.SendToPlayer(player, command, payload)
end

local RECRUIT_REPLY_VARIANTS = {
    admire = {
        "response.recruit.admire.1",
        "response.recruit.admire.2",
        "response.recruit.admire.3",
    },
    fear = {
        "response.recruit.fear.1",
        "response.recruit.fear.2",
        "response.recruit.fear.3",
    },
    relationship = {
        "response.recruit.reject.relationship.1",
        "response.recruit.reject.relationship.2",
        "response.recruit.reject.relationship.3",
    },
    leader = {
        "response.recruit.reject.leader.1",
        "response.recruit.reject.leader.2",
    },
    cooldown = {
        "response.recruit.reject.cooldown.1",
        "response.recruit.reject.cooldown.2",
    },
    general = {
        "response.recruit.reject.general.1",
        "response.recruit.reject.general.2",
        "response.recruit.reject.general.3",
    },
}

local function stableVariantIndex(value, count)
    local hash = 7
    value = tostring(value or "")
    for index = 1, #value do
        hash = (hash * 31 + string.byte(value, index)) % 2147483647
    end
    return (hash % count) + 1
end

local function recruitReplyKey(npcID, reason, route, worldAgeHours)
    local group = route == "admire" and "admire"
        or route == "fear" and "fear"
        or reason == "relationship_threshold" and "relationship"
        or reason == "leader_active" and "leader"
        or reason == "cooldown_active" and "cooldown"
        or "general"
    local variants = RECRUIT_REPLY_VARIANTS[group]
    local index = stableVariantIndex(table.concat({
        tostring(npcID or ""), tostring(reason or ""), tostring(route or ""),
        tostring(math.floor(tonumber(worldAgeHours) or 0) / 24),
    }, ":"), #variants)
    return variants[index]
end

local function relationshipCategory(record, relationship)
    local explicit = record and (
        record.conversationRelationship or record.relationshipCategory
    )
    local verifier = PNC.Identity and PNC.Identity.Verifier or nil
    local ownership = verifier
        and verifier.BuildOwnershipSummary
        and verifier.BuildOwnershipSummary(record)
        or nil
    local recruited = ownership
        and (ownership.recruited or ownership.colonyOwned)
        or record and (record.recruited == true
            or record.ownerUsername ~= nil)
    if explicit == "Lover" then return explicit end
    if recruited then
        return "Member"
    end
    if explicit == "Member" or explicit == "Acquaintance"
        or explicit == "FirstMeet"
    then
        return explicit
    end
    if relationship and relationship.exists ~= false then return "Acquaintance" end
    return "FirstMeet"
end

local function audienceMap(record, category)
    local hostile = type(record and record.hostility) == "table"
        and record.hostility.attackPlayers == true
    return {
        hostile = hostile,
        neutral = not hostile and category ~= "Member" and category ~= "Lover",
        member = not hostile and category == "Member",
        special = not hostile and category == "Lover",
        shared = true,
    }
end

Internal.PersonalRelationshipQueries = personalRelationshipQueries
Internal.PersonalRelationshipCommands = personalRelationshipCommands
Internal.RelationshipCopy = relationshipCopy
Internal.RelationshipDelta = relationshipDelta
Internal.WorldAgeHours = worldAgeHours
Internal.Send = send
Internal.RecruitReplyKey = recruitReplyKey
Internal.RelationshipCategory = relationshipCategory
Internal.AudienceMap = audienceMap

return Internal
