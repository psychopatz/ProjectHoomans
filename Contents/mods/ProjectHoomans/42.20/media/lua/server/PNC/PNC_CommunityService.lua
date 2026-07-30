-- Server-authoritative persistent communities and NPC community membership.

if isClient and isClient() and (not isServer or not isServer()) then
    return
end

PNC = PNC or {}
PNC.Communities = PNC.Communities or {}

local Communities = PNC.Communities
local Core = PNC.Core
local Constants = PNC.CommunityConstants
local Types = PNC.CommunityTypes
local CommunityMath = PNC.CommunityMath
local FactionTypes = PNC.FactionTypes

Communities.Registry = Communities.Registry or Types.NewRegistry()
Communities.Loaded = Communities.Loaded or false
Communities.Dirty = Communities.Dirty or false
Communities.IDGenerator = Communities.IDGenerator
    or function()
        return Core.GenerateID("community")
    end

local function authority()
    return Core and Core.IsAuthority
        and Core.IsAuthority() == true
end

local function copy(value)
    return Core and Core.DeepCopy and Core.DeepCopy(value) or value
end

local function assignTable(target, source)
    for key, _ in pairs(target) do target[key] = nil end
    for key, value in pairs(source) do target[key] = value end
end

local function worldAge(value, fallback)
    return CommunityMath.Clamp(
        value,
        0,
        1000000000,
        fallback or 0
    )
end

local function currentWorldAgeHours()
    local gameTime = getGameTime and getGameTime() or nil
    if gameTime and gameTime.getWorldAgeHours then
        return worldAge(gameTime:getWorldAgeHours(), 0)
    end
    return 0
end

local function registryRecord(communityID)
    return Types.IsValidCommunityID(communityID)
        and Communities.Registry.byID[communityID] or nil
end

local function siteRecord(siteID)
    return Types.IsValidSiteID(siteID)
        and Communities.Registry.sitesByID[siteID] or nil
end

local function npcRecord(npcID, allowDead)
    local record = Types.IsValidNPCID(npcID)
        and PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(npcID) or nil
    if not record then return nil, "npc_not_found" end
    if not allowDead and record.alive == false then
        return nil, "npc_not_living"
    end
    return record
end

local function factionRecord(factionID)
    return PNC.Factions and PNC.Factions.Get
        and PNC.Factions.Get(factionID) or nil
end

local function factionHasPlayerMembers(factionID)
    local faction = factionRecord(factionID)
    for _, present in pairs(
        faction and faction.playerMemberKeys or {}
    ) do
        if present == true then return true end
    end
    return false
end

local function touchCommunity(community)
    community.revision = math.max(
        0,
        math.floor(tonumber(community.revision) or 0)
    ) + 1
end

local function touchSite(site)
    site.revision = math.max(
        0,
        math.floor(tonumber(site.revision) or 0)
    ) + 1
end

local function touchRegistry()
    Communities.Registry.revision = math.max(
        0,
        math.floor(
            tonumber(Communities.Registry.revision) or 0
        )
    ) + 1
    Communities.Dirty = true
end

local function commitAffiliation(record, affiliation)
    affiliation.revision = math.max(
        0,
        math.floor(tonumber(
            record.affiliation and record.affiliation.revision
        ) or 0)
    ) + 1
    record.affiliation = affiliation
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "community_affiliation")
    end
end

local function affiliationWithCommunity(
    record,
    communityID,
    communityRole,
    joinedAt
)
    local source = FactionTypes.NormalizeAffiliation(
        record.affiliation
    )
    source.communityID = communityID
    source.communityRole = communityRole or "resident"
    source.communityJoinedAt = communityID
        and worldAge(joinedAt, 0) or 0
    return FactionTypes.NormalizeAffiliation(source)
end

local function clearAffiliationCommunity(record)
    return affiliationWithCommunity(
        record,
        nil,
        "resident",
        0
    )
end

local function population(community)
    local count = 0
    for npcID, present in pairs(community.memberIDs or {}) do
        if present == true then
            local record = PNC.Registry and PNC.Registry.Get
                and PNC.Registry.Get(npcID) or nil
            if record and record.alive ~= false
                and record.affiliation
                and record.affiliation.communityID
                    == community.id
            then
                count = count + 1
            end
        end
    end
    return count
end

local function publicCommunity(community)
    if not community then return nil end
    local output = copy(community)
    output.currentPopulation = population(community)
    output.populationCapacity =
        community.capacity.population
    output.overcrowded = output.currentPopulation
        > output.populationCapacity
    output.site = community.siteID
        and copy(Communities.Registry.sitesByID[
            community.siteID
        ]) or nil
    return output
end

local function publicSite(site)
    return site and copy(site) or nil
end

local function releaseSiteOccupancy(community, at)
    local site = community and community.siteID
        and siteRecord(community.siteID) or nil
    if not site
        or site.occupantCommunityID ~= community.id
    then
        return false
    end
    site.occupantCommunityID = nil
    site.status = site.claimantKey
        and "claimed" or "vacant"
    site.vacatedAt = worldAge(at, 0)
    touchSite(site)
    return true
end

local function sortedMemberIDs(community)
    local ids = {}
    for npcID, present in pairs(community.memberIDs or {}) do
        if present == true then ids[#ids + 1] = npcID end
    end
    table.sort(ids)
    return ids
end

local function clearMembers(community)
    local changed = false
    for _, npcID in ipairs(sortedMemberIDs(community)) do
        local record = PNC.Registry.Get(npcID)
        if record and record.affiliation
            and record.affiliation.communityID == community.id
        then
            commitAffiliation(
                record,
                clearAffiliationCommunity(record)
            )
            changed = true
        end
    end
    if community.leaderNPCID ~= nil then changed = true end
    for _, _ in pairs(community.memberIDs or {}) do
        changed = true
        break
    end
    community.memberIDs = {}
    community.leaderNPCID = nil
    return changed
end

local function rebuildDerivedIndexes()
    local byFaction = {}
    local memberIDs = {}
    local changed = false
    for communityID, community in pairs(
        Communities.Registry.byID
    ) do
        byFaction[community.factionID] =
            byFaction[community.factionID] or {}
        byFaction[community.factionID][communityID] = true
        memberIDs[communityID] = {}
    end
    local occupiedBySite = {}
    for communityID, community in pairs(
        Communities.Registry.byID
    ) do
        if community.status == "active"
            and community.siteID
            and Communities.Registry.sitesByID[
                community.siteID
            ]
        then
            local current = occupiedBySite[community.siteID]
            if not current or communityID < current then
                occupiedBySite[community.siteID] = communityID
            end
        end
    end
    for siteID, site in pairs(
        Communities.Registry.sitesByID
    ) do
        local occupant = site.claimantKey
            and nil or occupiedBySite[siteID]
        local status = site.claimantKey
            and "claimed"
            or occupant and "occupied"
            or "vacant"
        if site.occupantCommunityID ~= occupant
            or site.status ~= status
        then
            site.occupantCommunityID = occupant
            site.status = status
            touchSite(site)
            changed = true
        end
    end
    for npcID, record in pairs(
        PNC.Registry and PNC.Registry.Data or {}
    ) do
        local communityID = record.affiliation
            and record.affiliation.communityID or nil
        local community = communityID
            and Communities.Registry.byID[communityID] or nil
        if community and record.alive ~= false
            and record.affiliation.factionID
                == community.factionID
            and community.status ~= "archived"
            and community.status ~= "destroyed"
        then
            memberIDs[communityID][npcID] = true
        end
    end
    if not Types.AreEqual(
        Communities.Registry.byFaction,
        byFaction
    ) then
        Communities.Registry.byFaction = byFaction
        changed = true
    end
    for communityID, community in pairs(
        Communities.Registry.byID
    ) do
        local expected = memberIDs[communityID] or {}
        if not Types.AreEqual(
            community.memberIDs,
            expected
        ) then
            community.memberIDs = expected
            touchCommunity(community)
            changed = true
        end
    end
    if changed then touchRegistry() end
    return changed
end

local function reconcileLeaders()
    local changed = false
    for _, community in pairs(
        Communities.Registry.byID
    ) do
        local leader = community.leaderNPCID
            and PNC.Registry.Get(community.leaderNPCID)
            or nil
        if community.leaderNPCID
            and (
                not leader
                or leader.alive == false
                or not leader.affiliation
                or leader.affiliation.communityID
                    ~= community.id
                or community.memberIDs[
                    community.leaderNPCID
                ] ~= true
                or community.status == "archived"
                or community.status == "destroyed"
            )
        then
            community.leaderNPCID = nil
            touchCommunity(community)
            changed = true
        end
    end
    if changed then touchRegistry() end
    return changed
end

local function reconcileNPCReferences()
    local changed = false
    for _, record in pairs(
        PNC.Registry and PNC.Registry.Data or {}
    ) do
        local affiliation =
            FactionTypes.NormalizeAffiliation(record.affiliation)
        local communityID = affiliation.communityID
        local community = communityID
            and Communities.Registry.byID[communityID] or nil
        local invalid = communityID ~= nil and (
            community == nil
            or record.alive == false
            or affiliation.factionID ~= community.factionID
            or community.status == "archived"
            or community.status == "destroyed"
        )
        if invalid then
            affiliation.communityID = nil
            affiliation.communityRole = "resident"
            affiliation.communityJoinedAt = 0
        end
        if not FactionTypes.AreEqual(
            record.affiliation,
            affiliation
        ) then
            commitAffiliation(record, affiliation)
            changed = true
        end
    end
    return changed
end

function Communities.Load()
    local raw
    local normalized
    if not authority() then return false, "not_authority" end
    if PNC.Registry and PNC.Registry.EnsureLoaded then
        PNC.Registry.EnsureLoaded()
    end
    if PNC.Factions and PNC.Factions.EnsureLoaded then
        PNC.Factions.EnsureLoaded()
    end
    raw = ModData and ModData.getOrCreate
        and ModData.getOrCreate(
            Constants.REGISTRY_MODDATA_KEY
        ) or {}
    normalized = Types.NormalizeRegistry(raw)
    Communities.Registry = normalized
    Communities.Loaded = true
    Communities.Dirty = not Types.AreEqual(raw, normalized)
    reconcileNPCReferences()
    rebuildDerivedIndexes()
    reconcileLeaders()
    return true, Communities.Dirty
end

function Communities.EnsureLoaded()
    if not Communities.Loaded then
        return Communities.Load()
    end
    return true
end

function Communities.Save()
    local target
    Communities.EnsureLoaded()
    if not Communities.Dirty then return false, "not_dirty" end
    target = ModData and ModData.getOrCreate
        and ModData.getOrCreate(
            Constants.REGISTRY_MODDATA_KEY
        ) or nil
    if not target then return false, "moddata_unavailable" end
    assignTable(target, Types.NormalizeRegistry(
        Communities.Registry
    ))
    Communities.Registry = Types.NormalizeRegistry(target)
    Communities.Dirty = false
    return true, "saved"
end

function Communities.GenerateID()
    Communities.EnsureLoaded()
    for _ = 1, Constants.ID_GENERATION_RETRIES do
        local candidate = Communities.IDGenerator()
        if Types.IsValidCommunityID(candidate)
            and not Communities.Registry.byID[candidate]
        then
            return candidate
        end
    end
    return nil, "id_generation_failed"
end

function Communities.Get(communityID)
    Communities.EnsureLoaded()
    local community = registryRecord(communityID)
    return publicCommunity(community),
        community and nil or "community_not_found"
end

function Communities.List()
    local output = {}
    Communities.EnsureLoaded()
    for _, community in pairs(Communities.Registry.byID) do
        output[#output + 1] = publicCommunity(community)
    end
    table.sort(output, function(left, right)
        if left.name ~= right.name then
            return left.name < right.name
        end
        return left.id < right.id
    end)
    return output
end

function Communities.GetForFaction(factionID)
    local output = {}
    Communities.EnsureLoaded()
    if not Types.IsValidFactionID(factionID) then
        return output, "invalid_faction_id"
    end
    for communityID, present in pairs(
        Communities.Registry.byFaction[factionID] or {}
    ) do
        if present == true
            and Communities.Registry.byID[communityID]
        then
            output[#output + 1] = publicCommunity(
                Communities.Registry.byID[communityID]
            )
        end
    end
    table.sort(output, function(left, right)
        return left.id < right.id
    end)
    return output
end

function Communities.BuildSiteID(siteSpec)
    local source = type(siteSpec) == "table"
        and siteSpec or {}
    local bounds = type(source.bounds) == "table"
        and source.bounds or {}
    local home = type(source.home) == "table"
        and source.home or source
    local kind = Constants.VALID_SITE_KINDS[source.kind]
        and source.kind or "radius"
    local function token(value)
        value = tonumber(value) or 0
        if value >= 0 then
            return tostring(math.floor(value * 10 + 0.5))
        end
        return tostring(math.ceil(value * 10 - 0.5))
    end
    return Constants.SITE_ID_PREFIX .. kind .. "_"
        .. token(bounds.minX or home.x) .. "_"
        .. token(bounds.minY or home.y) .. "_"
        .. token(bounds.maxX or home.x) .. "_"
        .. token(bounds.maxY or home.y) .. "_"
        .. token(home.z)
end

function Communities.GetSite(siteID)
    Communities.EnsureLoaded()
    local site = siteRecord(siteID)
    return publicSite(site),
        site and nil or "site_not_found"
end

function Communities.ListSites()
    Communities.EnsureLoaded()
    local output = {}
    for _, site in pairs(Communities.Registry.sitesByID) do
        output[#output + 1] = publicSite(site)
    end
    table.sort(output, function(left, right)
        return left.id < right.id
    end)
    return output
end

function Communities.ReserveSite(
    communityID,
    siteSpec,
    worldAgeHours
)
    if not authority() then return false, "not_authority" end
    Communities.EnsureLoaded()
    local community = registryRecord(communityID)
    if not community then
        return false, "community_not_found"
    end
    if community.status ~= "active" then
        return false, "community_not_active"
    end
    siteSpec = type(siteSpec) == "table"
        and copy(siteSpec) or {}
    siteSpec.id = Types.IsValidSiteID(siteSpec.id)
        and siteSpec.id
        or Communities.BuildSiteID(siteSpec)
    siteSpec.createdAt = worldAge(
        siteSpec.createdAt,
        worldAgeHours
    )
    local normalized = Types.NormalizeSite(
        siteSpec,
        siteSpec.id
    )
    if not normalized then return false, "invalid_site" end
    local existing = siteRecord(normalized.id)
    if existing and existing.claimantKey then
        return false, "site_claimed"
    end
    if existing and existing.occupantCommunityID
        and existing.occupantCommunityID ~= communityID
    then
        return false, "site_occupied"
    end
    if community.siteID
        and community.siteID ~= normalized.id
    then
        releaseSiteOccupancy(community, worldAgeHours)
    end
    local site = existing or normalized
    if not existing then
        site.revision = math.max(1, site.revision)
        Communities.Registry.sitesByID[site.id] = site
    end
    site.occupantCommunityID = communityID
    site.claimantKey = nil
    site.claimedAt = 0
    site.status = "occupied"
    if existing then touchSite(site) end
    community.siteID = site.id
    community.home = copy(site.home)
    touchCommunity(community)
    touchRegistry()
    return true, "site_reserved", publicSite(site)
end

function Communities.ReleaseSite(
    communityID,
    worldAgeHours
)
    if not authority() then return false, "not_authority" end
    Communities.EnsureLoaded()
    local community = registryRecord(communityID)
    if not community then
        return false, "community_not_found"
    end
    if not releaseSiteOccupancy(community, worldAgeHours) then
        return false, "site_not_occupied_by_community"
    end
    community.siteID = nil
    touchCommunity(community)
    touchRegistry()
    return true, "site_released",
        publicSite(siteRecord(community.siteID))
end

function Communities.ClaimSite(
    siteID,
    playerKey,
    worldAgeHours
)
    if not authority() then return false, "not_authority" end
    Communities.EnsureLoaded()
    local site = siteRecord(siteID)
    if not site then return false, "site_not_found" end
    if not PNC.EntityRef
        or not PNC.EntityRef.IsPlayer
        or not PNC.EntityRef.IsPlayer(playerKey)
    then
        return false, "invalid_player_key"
    end
    if site.occupantCommunityID then
        return false, "site_occupied"
    end
    if site.claimantKey then
        if site.claimantKey == playerKey then
            return false, "already_claimed_by_player"
        end
        return false, "site_claimed"
    end
    site.claimantKey = playerKey
    site.claimedAt = worldAge(worldAgeHours, 0)
    site.status = "claimed"
    touchSite(site)
    touchRegistry()
    return true, "site_claimed", publicSite(site)
end

function Communities.UnclaimSite(siteID, playerKey)
    if not authority() then return false, "not_authority" end
    Communities.EnsureLoaded()
    local site = siteRecord(siteID)
    if not site then return false, "site_not_found" end
    if not site.claimantKey then
        return false, "site_not_claimed"
    end
    if playerKey and site.claimantKey ~= playerKey then
        return false, "site_claimed_by_other_player"
    end
    site.claimantKey = nil
    site.claimedAt = 0
    site.status = "vacant"
    touchSite(site)
    touchRegistry()
    return true, "site_unclaimed", publicSite(site)
end

function Communities.GetNPCAffiliation(npcID)
    local record, reason = npcRecord(npcID, true)
    if not record then return nil, reason end
    local affiliation =
        FactionTypes.NormalizeAffiliation(record.affiliation)
    return {
        communityID = affiliation.communityID,
        communityRole = affiliation.communityRole,
        communityJoinedAt = affiliation.communityJoinedAt,
        affiliationRevision = affiliation.revision,
    }
end

function Communities.GetNPCCommunity(npcID)
    local affiliation, reason =
        Communities.GetNPCAffiliation(npcID)
    if not affiliation then return nil, reason end
    if not affiliation.communityID then
        return nil, "no_community"
    end
    return Communities.Get(affiliation.communityID)
end

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

function Communities.SetLeader(
    communityID,
    npcID,
    worldAgeHours
)
    local community
    local record
    if not authority() then return false, "not_authority" end
    Communities.EnsureLoaded()
    community = registryRecord(communityID)
    if not community then return false, "community_not_found" end
    if npcID == nil then
        if community.leaderNPCID == nil then
            return false, "unchanged"
        end
        local oldLeader = PNC.Registry.Get(
            community.leaderNPCID
        )
        if oldLeader and oldLeader.affiliation
            and oldLeader.affiliation.communityID
                == communityID
            and oldLeader.affiliation.communityRole
                == "leader"
        then
            commitAffiliation(
                oldLeader,
                affiliationWithCommunity(
                    oldLeader,
                    communityID,
                    "resident",
                    oldLeader.affiliation.communityJoinedAt
                )
            )
        end
        community.leaderNPCID = nil
        touchCommunity(community)
        touchRegistry()
        return true, "leader_cleared", publicCommunity(community)
    end
    record = npcRecord(npcID, false)
    if not record then return false, "npc_not_found" end
    if not record.affiliation
        or record.affiliation.communityID ~= communityID
        or community.memberIDs[npcID] ~= true
    then
        return false, "leader_not_member"
    end
    if community.leaderNPCID == npcID
        and record.affiliation.communityRole == "leader"
    then
        return false, "unchanged"
    end
    local oldLeader = community.leaderNPCID
        and PNC.Registry.Get(community.leaderNPCID)
        or nil
    if oldLeader and oldLeader.affiliation
        and oldLeader.affiliation.communityID == communityID
        and oldLeader.affiliation.communityRole == "leader"
    then
        commitAffiliation(
            oldLeader,
            affiliationWithCommunity(
                oldLeader,
                communityID,
                "resident",
                oldLeader.affiliation.communityJoinedAt
            )
        )
    end
    community.leaderNPCID = npcID
    if record.affiliation.communityRole ~= "leader" then
        commitAffiliation(
            record,
            affiliationWithCommunity(
                record,
                communityID,
                "leader",
                record.affiliation.communityJoinedAt
            )
        )
    end
    touchCommunity(community)
    touchRegistry()
    return true, "leader_set", publicCommunity(community)
end

local function setCommunityField(
    communityID,
    field,
    value
)
    local community = registryRecord(communityID)
    if not community then return false, "community_not_found" end
    if Types.AreEqual(community[field], value) then
        return false, "unchanged"
    end
    community[field] = value
    touchCommunity(community)
    touchRegistry()
    return true, "updated", publicCommunity(community)
end

function Communities.SetMode(communityID, mode, worldAgeHours)
    if not authority() then return false, "not_authority" end
    Communities.EnsureLoaded()
    if not Constants.VALID_MODES[mode] then
        return false, "invalid_mode"
    end
    if mode == "destroyed" then
        return Communities.Destroy(
            communityID,
            "mode_changed",
            worldAgeHours
        )
    end
    local community = registryRecord(communityID)
    if not community then return false, "community_not_found" end
    if community.status == "archived"
        or community.status == "destroyed"
    then
        return false, "community_retired"
    end
    local nextMode, nextStatus =
        Types.NormalizeStatus(community.status, mode)
    if nextMode == community.mode
        and nextStatus == community.status
    then
        return false, "unchanged"
    end
    community.mode = nextMode
    community.status = nextStatus
    if nextMode == "abandoned" then
        clearMembers(community)
    end
    touchCommunity(community)
    touchRegistry()
    return true, "mode_set", publicCommunity(community)
end

function Communities.SetStatus(
    communityID,
    status,
    worldAgeHours
)
    if not authority() then return false, "not_authority" end
    Communities.EnsureLoaded()
    if not Constants.VALID_STATUSES[status] then
        return false, "invalid_status"
    end
    if status == "archived" then
        return Communities.Archive(
            communityID,
            "status_changed",
            worldAgeHours
        )
    end
    if status == "destroyed" then
        return Communities.Destroy(
            communityID,
            "status_changed",
            worldAgeHours
        )
    end
    local community = registryRecord(communityID)
    if not community then return false, "community_not_found" end
    if community.status == "archived"
        or community.status == "destroyed"
    then
        return false, "community_retired"
    end
    local nextMode, nextStatus =
        Types.NormalizeStatus(status, community.mode)
    if nextMode == community.mode
        and nextStatus == community.status
    then
        return false, "unchanged"
    end
    community.mode = nextMode
    community.status = nextStatus
    touchCommunity(community)
    touchRegistry()
    return true, "status_set", publicCommunity(community)
end

function Communities.SetHome(communityID, homeSpec)
    if not authority() then return false, "not_authority" end
    Communities.EnsureLoaded()
    local community = registryRecord(communityID)
    if not community then return false, "community_not_found" end
    local home = Types.NormalizeHome(homeSpec, community.mode)
    if not home then return false, "invalid_home" end
    return setCommunityField(communityID, "home", home)
end

function Communities.SetCapacity(
    communityID,
    capacitySpec
)
    if not authority() then return false, "not_authority" end
    Communities.EnsureLoaded()
    local community = registryRecord(communityID)
    if not community then return false, "community_not_found" end
    return setCommunityField(
        communityID,
        "capacity",
        Types.NormalizeCapacity(
            capacitySpec,
            community.capacity
        )
    )
end

function Communities.SetSecurity(communityID, value)
    if not authority() then return false, "not_authority" end
    Communities.EnsureLoaded()
    local community = registryRecord(communityID)
    if not community then return false, "community_not_found" end
    if not CommunityMath.IsFinite(value) then
        return false, "invalid_security"
    end
    return setCommunityField(
        communityID,
        "security",
        CommunityMath.Clamp(
            value,
            Constants.SECURITY_MIN,
            Constants.SECURITY_MAX,
            community.security
        )
    )
end

function Communities.SetMorale(communityID, value)
    if not authority() then return false, "not_authority" end
    Communities.EnsureLoaded()
    local community = registryRecord(communityID)
    if not community then return false, "community_not_found" end
    if not CommunityMath.IsFinite(value) then
        return false, "invalid_morale"
    end
    return setCommunityField(
        communityID,
        "morale",
        CommunityMath.Clamp(
            value,
            Constants.MORALE_MIN,
            Constants.MORALE_MAX,
            community.morale
        )
    )
end

local function validateSupply(communityID, category, amount)
    local community = registryRecord(communityID)
    if not community then
        return nil, nil, "community_not_found"
    end
    if not Constants.VALID_SUPPLY_CATEGORIES[category] then
        return nil, nil, "invalid_supply_category"
    end
    if not CommunityMath.IsFinite(amount) then
        return nil, nil, "invalid_supply_amount"
    end
    amount = math.floor(tonumber(amount))
    if amount < 0 then
        return nil, nil, "invalid_supply_amount"
    end
    return community, amount
end

function Communities.GetSupply(communityID, category)
    Communities.EnsureLoaded()
    local community, _, reason =
        validateSupply(communityID, category, 0)
    if not community then return nil, reason end
    return community.supplies[category]
end

function Communities.SetSupply(
    communityID,
    category,
    amount
)
    if not authority() then return false, "not_authority" end
    Communities.EnsureLoaded()
    local community, normalized, reason =
        validateSupply(communityID, category, amount)
    if not community then return false, reason end
    normalized = math.floor(CommunityMath.Clamp(
        normalized,
        Constants.SUPPLY_MIN,
        Constants.SUPPLY_MAX,
        0
    ))
    if community.supplies[category] == normalized then
        return false, "unchanged"
    end
    community.supplies[category] = normalized
    touchCommunity(community)
    touchRegistry()
    return true, "supply_set", normalized
end

function Communities.AddSupply(
    communityID,
    category,
    amount
)
    if not authority() then return false, "not_authority" end
    Communities.EnsureLoaded()
    local community, normalized, reason =
        validateSupply(communityID, category, amount)
    if not community then return false, reason end
    return Communities.SetSupply(
        communityID,
        category,
        community.supplies[category] + normalized
    )
end

function Communities.RemoveSupply(
    communityID,
    category,
    amount
)
    if not authority() then return false, "not_authority" end
    Communities.EnsureLoaded()
    local community, normalized, reason =
        validateSupply(communityID, category, amount)
    if not community then return false, reason end
    if normalized > community.supplies[category] then
        return false, "insufficient_supply"
    end
    return Communities.SetSupply(
        communityID,
        category,
        community.supplies[category] - normalized
    )
end

local function retireCommunity(
    community,
    status,
    reason,
    at
)
    clearMembers(community)
    releaseSiteOccupancy(community, at)
    community.mode = status == "destroyed"
        and "destroyed" or "abandoned"
    community.status = status
    if status == "destroyed" then
        community.destroyedAt = at
        community.destroyReason = tostring(
            reason or "destroyed"
        )
    else
        community.archivedAt = at
        community.archiveReason = tostring(
            reason or "archived"
        )
    end
    touchCommunity(community)
    touchRegistry()
end

function Communities.Archive(
    communityID,
    reason,
    worldAgeHours
)
    if not authority() then return false, "not_authority" end
    Communities.EnsureLoaded()
    local community = registryRecord(communityID)
    if not community then return false, "community_not_found" end
    if community.status == "archived" then
        return false, "already_archived"
    end
    if community.status == "destroyed" then
        return false, "community_destroyed"
    end
    retireCommunity(
        community,
        "archived",
        reason,
        worldAge(worldAgeHours, community.createdAt)
    )
    return true, "archived", publicCommunity(community)
end

function Communities.Destroy(
    communityID,
    reason,
    worldAgeHours
)
    if not authority() then return false, "not_authority" end
    Communities.EnsureLoaded()
    local community = registryRecord(communityID)
    if not community then return false, "community_not_found" end
    if community.status == "destroyed" then
        return false, "already_destroyed"
    end
    retireCommunity(
        community,
        "destroyed",
        reason,
        worldAge(worldAgeHours, community.createdAt)
    )
    return true, "destroyed", publicCommunity(community)
end

-- Called immediately before a faction service replaces the affiliation.
-- It updates only the derived community index, avoiding a second NPC commit.
function Communities.OnFactionMembershipChanging(record)
    if not authority() or type(record) ~= "table" then
        return false, "invalid_record"
    end
    Communities.EnsureLoaded()
    local communityID = record.affiliation
        and record.affiliation.communityID or nil
    local community = communityID
        and registryRecord(communityID) or nil
    if not community then return false, "no_community" end
    community.memberIDs[record.id] = nil
    if community.leaderNPCID == record.id then
        community.leaderNPCID = nil
    end
    touchCommunity(community)
    touchRegistry()
    return true, "community_detached"
end

function Communities.OnFactionArchived(
    factionID,
    worldAgeHours
)
    local changed = false
    Communities.EnsureLoaded()
    local communities = Communities.GetForFaction(factionID)
    for _, community in ipairs(communities) do
        if community.status ~= "archived"
            and community.status ~= "destroyed"
        then
            Communities.Archive(
                community.id,
                "faction_archived",
                worldAgeHours
            )
            changed = true
        end
    end
    return changed
end

function Communities.OnFactionDestroyed(
    factionID,
    worldAgeHours
)
    local changed = false
    Communities.EnsureLoaded()
    local communities = Communities.GetForFaction(factionID)
    for _, community in ipairs(communities) do
        if community.status ~= "destroyed" then
            Communities.Destroy(
                community.id,
                "faction_destroyed",
                worldAgeHours
            )
            changed = true
        end
    end
    return changed
end

function Communities.OnNPCDeath(npcID)
    if not authority() then return false, "not_authority" end
    Communities.EnsureLoaded()
    local record = npcRecord(npcID, true)
    if not record then return false, "npc_not_found" end
    local communityID = record.affiliation
        and record.affiliation.communityID or nil
    if not communityID then return false, "no_community" end
    local community = registryRecord(communityID)
    if not community then
        commitAffiliation(record, clearAffiliationCommunity(record))
        return true, "invalid_reference_cleared"
    end
    community.memberIDs[npcID] = nil
    if community.leaderNPCID == npcID then
        community.leaderNPCID = nil
    end
    commitAffiliation(record, clearAffiliationCommunity(record))
    if community.status == "active"
        and population(community) <= 0
        and not factionHasPlayerMembers(
            community.factionID
        )
    then
        retireCommunity(
            community,
            "destroyed",
            "population_wiped_out",
            currentWorldAgeHours()
        )
        return true, "community_wiped_out"
    end
    touchCommunity(community)
    touchRegistry()
    return true, "death_reconciled"
end

function Communities.RebuildIndexes()
    Communities.EnsureLoaded()
    return rebuildDerivedIndexes()
end

function Communities.ValidateRegistry()
    Communities.EnsureLoaded()
    if PNC.CommunityValidation
        and PNC.CommunityValidation.ValidateRegistry
    then
        return PNC.CommunityValidation.ValidateRegistry()
    end
    return nil, "validator_unavailable"
end

Communities.IsInsideHomeArea =
    CommunityMath.IsInsideHomeArea
Communities.GetDistanceFromHome =
    CommunityMath.GetDistanceFromHome
Communities.NormalizeRegistry = Types.NormalizeRegistry
Communities.NormalizeCommunity = Types.NormalizeCommunity

local function onInitGlobalModData()
    Communities.Load()
end

local function onSave()
    Communities.Save()
end

if Events and Events.OnInitGlobalModData
    and not Communities.GlobalModDataHookRegistered
then
    Events.OnInitGlobalModData.Add(onInitGlobalModData)
    Communities.GlobalModDataHookRegistered = true
end

if Events and Events.OnSave
    and not Communities.SaveHookRegistered
then
    Events.OnSave.Add(onSave)
    Communities.SaveHookRegistered = true
end

return Communities
