PNC = PNC or {}
PNC.FactionTypes = PNC.FactionTypes or {}
PNC.FactionTypes.Internal = PNC.FactionTypes.Internal or {}

local Types = PNC.FactionTypes
local Internal = Types.Internal
local Constants = PNC.FactionConstants
local Archetypes = PNC.FactionArchetypes

local function normalizeFormerFaction(value)
    if type(value) ~= "table"
        or not Types.IsValidFactionID(value.factionID)
    then
        return nil
    end
    local joinedAt = Internal.Timestamp(value.joinedAt, 0)
    return {
        factionID = value.factionID,
        joinedAt = joinedAt,
        leftAt = math.max(
            joinedAt,
            Internal.Timestamp(value.leftAt, joinedAt)
        ),
        reason = Constants.VALID_LEAVE_REASONS[value.reason]
            and value.reason or "unknown",
    }
end

local function normalizeFormerFactions(value)
    local output = {}
    local seen = {}
    local entry
    for _, raw in pairs(type(value) == "table" and value or {}) do
        entry = normalizeFormerFaction(raw)
        if entry then
            local key = entry.factionID .. ":"
                .. tostring(entry.joinedAt) .. ":"
                .. tostring(entry.leftAt) .. ":"
                .. entry.reason
            if not seen[key] then
                seen[key] = true
                output[#output + 1] = entry
            end
        end
    end
    table.sort(output, function(left, right)
        if left.leftAt ~= right.leftAt then
            return left.leftAt < right.leftAt
        end
        if left.joinedAt ~= right.joinedAt then
            return left.joinedAt < right.joinedAt
        end
        if left.factionID ~= right.factionID then
            return left.factionID < right.factionID
        end
        return left.reason < right.reason
    end)
    while #output > Constants.FORMER_FACTION_LIMIT do
        table.remove(output, 1)
    end
    return output
end

function Types.NormalizeAffiliation(value, faction)
    local source = type(value) == "table" and value or {}
    local factionID = Types.IsValidFactionID(source.factionID)
        and source.factionID or nil
    if faction == false then factionID = nil end
    local archetypeID = faction and faction.archetypeID or nil
    local status = Types.IsValidMembershipStatus(
        source.membershipStatus
    ) and source.membershipStatus or nil
    local role = Types.IsValidFactionRole(source.role)
        and source.role or nil
    local rank = Types.IsValidFactionRank(source.rank)
        and source.rank or "member"
    local communityID = PNC.CommunityTypes
        and PNC.CommunityTypes.IsValidCommunityID
        and PNC.CommunityTypes.IsValidCommunityID(
            source.communityID
        )
        and source.communityID or nil
    local communityRole = PNC.CommunityConstants
        and PNC.CommunityConstants.VALID_ROLES[
            source.communityRole
        ] and source.communityRole or "resident"
    if not factionID then
        status = "unaffiliated"
        role = "civilian"
        rank = "member"
        communityID = nil
        communityRole = "resident"
    else
        status = status == "unaffiliated" and "member"
            or status or "member"
        if archetypeID and not Archetypes.IsRoleAllowed(
            archetypeID,
            role
        ) then
            role = Archetypes.GetDefaultRole(archetypeID)
        end
        role = role or "civilian"
    end
    return {
        schemaVersion = Constants.AFFILIATION_SCHEMA_VERSION,
        factionID = factionID,
        membershipStatus = status,
        role = role,
        rank = rank,
        joinedAt = factionID and Internal.Timestamp(source.joinedAt, 0) or 0,
        leftAt = factionID and 0 or Internal.Timestamp(source.leftAt, 0),
        communityID = communityID,
        communityRole = communityRole,
        communityJoinedAt = communityID
            and Internal.Timestamp(source.communityJoinedAt, 0) or 0,
        originArchetypeID =
            Archetypes.Exists(source.originArchetypeID)
                and source.originArchetypeID or nil,
        formerFactionIDs = normalizeFormerFactions(
            source.formerFactionIDs
        ),
        revision = Internal.Revision(source.revision),
    }
end

function Types.NewAffiliation(value)
    return Types.NormalizeAffiliation(value)
end

function Types.AppendFormerFaction(
    affiliation,
    factionID,
    leftAt,
    reason
)
    local normalized = Types.NormalizeAffiliation(affiliation)
    normalized.formerFactionIDs[
        #normalized.formerFactionIDs + 1
    ] = {
        factionID = factionID,
        joinedAt = normalized.joinedAt,
        leftAt = Internal.Timestamp(leftAt, normalized.joinedAt),
        reason = Constants.VALID_LEAVE_REASONS[reason]
            and reason or "unknown",
    }
    normalized.formerFactionIDs = normalizeFormerFactions(
        normalized.formerFactionIDs
    )
    return normalized
end
