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


Internal.authority = authority
Internal.copy = copy
Internal.assignTable = assignTable
Internal.worldAge = worldAge
Internal.currentWorldAgeHours = currentWorldAgeHours
Internal.registryRecord = registryRecord
Internal.siteRecord = siteRecord
Internal.npcRecord = npcRecord
Internal.factionRecord = factionRecord
Internal.factionHasPlayerMembers = factionHasPlayerMembers
Internal.touchCommunity = touchCommunity
Internal.touchSite = touchSite
Internal.touchRegistry = touchRegistry
Internal.commitAffiliation = commitAffiliation
Internal.affiliationWithCommunity = affiliationWithCommunity
Internal.clearAffiliationCommunity = clearAffiliationCommunity
Internal.population = population
Internal.publicCommunity = publicCommunity
Internal.publicSite = publicSite
Internal.releaseSiteOccupancy = releaseSiteOccupancy
Internal.sortedMemberIDs = sortedMemberIDs
Internal.clearMembers = clearMembers

return Communities
