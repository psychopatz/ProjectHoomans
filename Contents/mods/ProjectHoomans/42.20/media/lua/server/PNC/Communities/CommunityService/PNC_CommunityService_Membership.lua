if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Communities = PNC.Communities or {}
PNC.Communities.Internal = PNC.Communities.Internal or {}

local Communities = PNC.Communities
local Internal = Communities.Internal
local Core = PNC.Core
local Constants = PNC.CommunityConstants
local Types = PNC.CommunityTypes
local CommunityMath = PNC.CommunityMath
local FactionTypes = PNC.FactionTypes
local authority = Internal.authority
local copy = Internal.copy
local worldAge = Internal.worldAge
local registryRecord = Internal.registryRecord
local npcRecord = Internal.npcRecord
local factionRecord = Internal.factionRecord
local touchCommunity = Internal.touchCommunity
local touchRegistry = Internal.touchRegistry
local commitAffiliation = Internal.commitAffiliation
local affiliationWithCommunity = Internal.affiliationWithCommunity
local clearAffiliationCommunity = Internal.clearAffiliationCommunity
local population = Internal.population
local publicCommunity = Internal.publicCommunity

function Communities.Create(spec)
    local faction
    local id
    local defaults
    local community
    if not authority() then return false, "not_authority" end
    Communities.EnsureLoaded()
    spec = type(spec) == "table" and spec or {}
    if not Constants.VALID_MODES[spec.mode] then
        return false, "invalid_mode"
    end
    if spec.mode == "destroyed" then
        return false, "mode_not_creatable"
    end
    faction = factionRecord(spec.factionID)
    if not faction then return false, "faction_not_found" end
    if faction.status ~= "active" then
        return false, "faction_not_active"
    end
    id = Communities.GenerateID()
    if not id then return false, "id_generation_failed" end
    defaults = Types.BuildCreationDefaults(
        spec.mode,
        faction.archetypeID
    )
    community = Types.NewCommunity({
        id = id,
        factionID = faction.id,
        name = spec.name,
        renamePending = spec.renamePending == true,
        mode = spec.mode,
        status = (
            spec.mode == "settled"
            or spec.mode == "camped"
        ) and "active" or "inactive",
        createdAt = worldAge(spec.createdAt, 0),
        home = {
            x = spec.home and spec.home.x,
            y = spec.home and spec.home.y,
            z = spec.home and spec.home.z,
            radius = spec.home and spec.home.radius
                or defaults.radius,
        },
        capacity = spec.capacity or defaults.capacity,
        security = spec.security ~= nil
            and spec.security or defaults.security,
        morale = spec.morale ~= nil
            and spec.morale or defaults.morale,
        supplies = spec.supplies or defaults.supplies,
        revision = 1,
    })
    if not community then return false, "invalid_spec" end
    Communities.Registry.byID[id] = community
    Communities.Registry.byFaction[faction.id] =
        Communities.Registry.byFaction[faction.id] or {}
    Communities.Registry.byFaction[faction.id][id] = true
    touchRegistry()
    if PNC.ColonyStorageRepository
        and PNC.ColonyStorageRepository.GetPrimary
    then
        PNC.ColonyStorageRepository.GetPrimary(faction.id, community.id)
    end
    return true, "created", publicCommunity(community)
end

function Communities.AddNPC(communityID, npcID, options)
    local community
    local record
    local affiliation
    local role
    if not authority() then return false, "not_authority" end
    Communities.EnsureLoaded()
    options = type(options) == "table" and options or {}
    community = registryRecord(communityID)
    if not community then return false, "community_not_found" end
    if community.status ~= "active" then
        return false, "community_not_active"
    end
    record = npcRecord(npcID, false)
    if not record then return false, "npc_not_found" end
    affiliation =
        FactionTypes.NormalizeAffiliation(record.affiliation)
    if affiliation.factionID ~= community.factionID then
        return false, "faction_mismatch"
    end
    if affiliation.communityID
        and affiliation.communityID ~= communityID
    then
        return false, "npc_already_in_community"
    end
    role = options.communityRole or "resident"
    if not Constants.VALID_ROLES[role] then
        return false, "invalid_community_role"
    end
    if role == "leader"
        and community.leaderNPCID ~= npcID
    then
        return false, "leader_requires_set_leader"
    end
    if community.leaderNPCID == npcID
        and role ~= "leader"
    then
        return false, "leader_role_requires_replacement"
    end
    if options.strictCapacity == true
        and affiliation.communityID ~= communityID
        and population(community)
            >= community.capacity.population
    then
        return false, "population_capacity_reached"
    end
    local nextAffiliation = affiliationWithCommunity(
        record,
        communityID,
        role,
        affiliation.communityID
            and affiliation.communityJoinedAt
            or options.joinedAt
    )
    if FactionTypes.AreEqual(
        affiliation,
        nextAffiliation
    ) and community.memberIDs[npcID] == true then
        return false, "unchanged"
    end
    community.memberIDs[npcID] = true
    commitAffiliation(record, nextAffiliation)
    touchCommunity(community)
    touchRegistry()
    return true, "added", copy(nextAffiliation)
end

function Communities.RemoveNPC(
    communityID,
    npcID,
    reason,
    worldAgeHours
)
    local community
    local record
    local affiliation
    if not authority() then return false, "not_authority" end
    Communities.EnsureLoaded()
    community = registryRecord(communityID)
    if not community then return false, "community_not_found" end
    record = npcRecord(npcID, true)
    if not record then return false, "npc_not_found" end
    affiliation =
        FactionTypes.NormalizeAffiliation(record.affiliation)
    if affiliation.communityID ~= communityID then
        return false, "not_a_community_member"
    end
    community.memberIDs[npcID] = nil
    if community.leaderNPCID == npcID then
        community.leaderNPCID = nil
    end
    commitAffiliation(record, clearAffiliationCommunity(record))
    touchCommunity(community)
    touchRegistry()
    return true, reason or "removed",
        copy(record.affiliation)
end

function Communities.TransferNPC(
    npcID,
    destinationCommunityID,
    options
)
    local record
    local affiliation
    local source
    local destination
    local role
    if not authority() then return false, "not_authority" end
    Communities.EnsureLoaded()
    options = type(options) == "table" and options or {}
    record = npcRecord(npcID, false)
    if not record then return false, "npc_not_found" end
    affiliation =
        FactionTypes.NormalizeAffiliation(record.affiliation)
    destination = registryRecord(destinationCommunityID)
    if not destination then
        return false, "community_not_found"
    end
    if destination.status ~= "active" then
        return false, "community_not_active"
    end
    if affiliation.factionID ~= destination.factionID then
        return false, "faction_mismatch"
    end
    if affiliation.communityID == destinationCommunityID then
        return false, "already_a_member"
    end
    source = affiliation.communityID
        and registryRecord(affiliation.communityID) or nil
    if source and source.factionID ~= destination.factionID then
        return false, "cross_faction_transfer"
    end
    role = options.communityRole
        or affiliation.communityRole or "resident"
    if not Constants.VALID_ROLES[role] then
        return false, "invalid_community_role"
    end
    if role == "leader" then role = "resident" end
    if options.strictCapacity == true
        and population(destination)
            >= destination.capacity.population
    then
        return false, "population_capacity_reached"
    end
    if source then
        source.memberIDs[npcID] = nil
        if source.leaderNPCID == npcID then
            source.leaderNPCID = nil
        end
        touchCommunity(source)
    end
    destination.memberIDs[npcID] = true
    commitAffiliation(
        record,
        affiliationWithCommunity(
            record,
            destination.id,
            role,
            options.worldAgeHours
        )
    )
    touchCommunity(destination)
    touchRegistry()
    return true, "transferred", copy(record.affiliation)
end


return Communities
