PNC = PNC or {}
PNC.FactionTypes = PNC.FactionTypes or {}
PNC.FactionTypes.Internal = PNC.FactionTypes.Internal or {}

local Types = PNC.FactionTypes
local Internal = Types.Internal
local Constants = PNC.FactionConstants
local Archetypes = PNC.FactionArchetypes
local Emblems = PNC.FactionEmblems

function Types.NormalizeFaction(value, factionID)
    local source = type(value) == "table" and value or {}
    local id = Types.IsValidFactionID(factionID)
        and factionID
        or Types.IsValidFactionID(source.id) and source.id
        or nil
    local name = Internal.SafeString(source.name, Constants.NAME_MAX_LENGTH)
    local archetypeID = Archetypes.Exists(source.archetypeID)
        and source.archetypeID or nil
    if not id or not name or not archetypeID then return nil end
    local output = {
        id = id,
        name = name,
        archetypeID = archetypeID,
        status = Constants.VALID_FACTION_STATUSES[source.status]
            and source.status or "active",
        createdAt = Internal.Timestamp(source.createdAt, 0),
        archivedAt = Internal.Timestamp(source.archivedAt, 0),
        leaderNPCID = Types.IsValidNPCID(source.leaderNPCID)
            and source.leaderNPCID or nil,
        ownerPlayerKey = Internal.IsValidPlayerKey(source.ownerPlayerKey)
            and source.ownerPlayerKey or nil,
        memberIDs = Internal.NormalizeIDSet(
            source.memberIDs,
            Types.IsValidNPCID
        ),
        playerMemberKeys = Internal.NormalizeIDSet(
            source.playerMemberKeys,
            Internal.IsValidPlayerKey
        ),
        policy = Types.NormalizePolicy(
            source.policy,
            archetypeID,
            id
        ),
        provision = PNC.ProvisionPolicy and PNC.ProvisionPolicy.Normalize
            and PNC.ProvisionPolicy.Normalize(source.provision) or nil,
        emblem = Emblems.Normalize(
            source.emblem,
            archetypeID,
            tostring(id) .. ":" .. tostring(name)
        ),
        playerPacifications =
            Types.NormalizePlayerPacifications(
                source.playerPacifications
            ),
        relations = {},
        tags = Internal.NormalizeTags(source.tags),
        mobile = Types.NormalizeMobileGroup(source.mobile),
        -- Group Needs are one aggregate state for a mobile faction, never a
        -- per-member resource table. The Needs module validates the values.
        needs = PNC.NeedsUtils and PNC.NeedsUtils.NormalizeState
            and Types.NormalizeMobileGroup(source.mobile)
            and PNC.NeedsUtils.NormalizeState(source.needs, 0)
            or nil,
        revision = Internal.Revision(source.revision),
    }
    for targetFactionID, rawRelation in pairs(
        type(source.relations) == "table"
            and source.relations or {}
    ) do
        local relation = Types.NormalizeRelation(
            rawRelation,
            id,
            targetFactionID
        )
        if relation then
            output.relations[targetFactionID] = relation
        end
    end
    return output
end

function Types.NewFaction(spec)
    return Types.NormalizeFaction(spec, spec and spec.id)
end
