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
    local output = {
        approval = tonumber(value.approval) or 0,
        respect = tonumber(value.respect) or 0,
        familiarity = tonumber(value.familiarity) or 0,
        state = value.state,
    }
    if PNC.RelationshipTypes
        and PNC.RelationshipTypes.NormalizeInteractionJournal
    then
        output.interactionRevision = tonumber(value.interactionRevision) or 0
        output.interactionJournal = PNC.RelationshipTypes
            .NormalizeInteractionJournal(value.interactionJournal)
    end
    return output
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
    local network = PNC.Network
    if not network or not network.SendToPlayer then return false end
    return network.SendToPlayer(player, command, payload)
end

local RECRUIT_REPLY_VARIANTS = {
    admire = {
        "recruitment.admire.1",
        "recruitment.admire.2",
        "recruitment.admire.3",
    },
    fear = {
        "recruitment.fear.1",
        "recruitment.fear.2",
        "recruitment.fear.3",
    },
    relationship = {
        "recruitment.reject.relationship.1",
        "recruitment.reject.relationship.2",
        "recruitment.reject.relationship.3",
        "recruitment.reject.relationship.4",
        "recruitment.reject.relationship.5",
        "recruitment.reject.relationship.6",
        "recruitment.reject.relationship.7",
        "recruitment.reject.relationship.8",
        "recruitment.reject.relationship.9",
        "recruitment.reject.relationship.10",
    },
    leader = {
        "recruitment.reject.leader.1",
        "recruitment.reject.leader.2",
    },
    cooldown = {
        "recruitment.reject.cooldown.1",
        "recruitment.reject.cooldown.2",
    },
    member = {
        "recruitment.reject.member.1",
        "recruitment.reject.member.2",
    },
    hostile = {
        "recruitment.reject.hostile.1",
        "recruitment.reject.hostile.2",
    },
    unavailable = {
        "recruitment.reject.unavailable.1",
        "recruitment.reject.unavailable.2",
    },
    general = {
        "recruitment.reject.general.1",
        "recruitment.reject.general.2",
        "recruitment.reject.general.3",
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

local function recruitReplyKey(npcID, reason, route, worldAgeHours, salt)
    local group
    if reason == "already_recruited"
        or reason == "npc_not_debug_recruitable"
    then
        group = "member"
    elseif reason == "hostile_audience" then
        group = "hostile"
    elseif reason == "npc_unavailable"
        or reason == "npc_not_found"
        or reason == "recruitment_service_unavailable"
    then
        group = "unavailable"
    elseif route == "admire" then
        group = "admire"
    elseif route == "fear" then
        group = "fear"
    elseif reason == "relationship_threshold" then
        group = "relationship"
    elseif reason == "leader_active" then
        group = "leader"
    elseif reason == "cooldown_active" then
        group = "cooldown"
    else
        group = "general"
    end
    local variants = RECRUIT_REPLY_VARIANTS[group]
    local index = stableVariantIndex(table.concat({
        tostring(npcID or ""), tostring(reason or ""), tostring(route or ""),
        tostring(math.floor(tonumber(worldAgeHours) or 0) / 24),
        tostring(salt or ""),
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
