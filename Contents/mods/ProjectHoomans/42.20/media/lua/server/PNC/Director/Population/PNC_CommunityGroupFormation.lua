-- Slowly forms one supported scavenging party from existing community members.

if isClient and isClient() and (not isServer or not isServer()) then return end

PNC = PNC or {}
PNC.CommunityGroupFormation = PNC.CommunityGroupFormation or {}

local Formation = PNC.CommunityGroupFormation
local Config = PNC.DirectorConfig.Population
local Sectors = PNC.PopulationSectors
local Store = PNC.AbstractWorldStore

Formation.Cursor = Formation.Cursor or 1
Formation.Metrics = Formation.Metrics or { evaluated = 0, formed = 0 }

local function assignedMembers()
    local output = {}
    for _, group in ipairs(PNC.AbstractGroups.List()) do
        for _, npcID in ipairs(group.memberIds or {}) do output[npcID] = true end
    end
    return output
end

local function groupsForCommunity(communityID)
    local total = 0
    for _, group in ipairs(PNC.AbstractGroups.List()) do
        if group.homeCommunityId == communityID then total = total + 1 end
    end
    return total
end

local function locationFor(community)
    local siteID = community.siteID or community.site and community.site.id
    for _, location in ipairs(PNC.AbstractLocations.List()) do
        if location.sourceSite and location.sourceSite.id == siteID then return location end
    end
    if community.site then
        return PNC.AbstractLocations.RegisterSite(community.site, {
            type = "SETTLEMENT", tags = { SETTLEMENT = true, SAFE = true } })
    end
    return nil
end

function Formation.Try(community, now)
    if not community or community.status ~= "active" then return false, "COMMUNITY_INACTIVE" end
    if #PNC.AbstractGroups.List() >= Config.HARD_MAX_ABSTRACT_GROUPS then
        return false, "HARD_CAP_REACHED"
    end
    if groupsForCommunity(community.id) >= Config.HARD_MAX_GROUPS_PER_COMMUNITY then
        return false, "GROUP_BUDGET_HEALTHY"
    end
    local memberCount = 0
    for _ in pairs(community.memberIDs or {}) do memberCount = memberCount + 1 end
    if memberCount < Config.COMMUNITY_GROUP_MIN_POPULATION then
        return false, "INSUFFICIENT_COMMUNITY_POPULATION"
    end
    local used, eligible = assignedMembers(), {}
    for npcID in pairs(community.memberIDs or {}) do
        local record = PNC.Registry.Get(npcID)
        if record and record.alive ~= false and not used[npcID] then
            eligible[#eligible + 1] = npcID
        end
    end
    table.sort(eligible)
    if #eligible < Config.COMMUNITY_GROUP_SIZE then
        return false, "NO_ELIGIBLE_IDLE_MEMBERS"
    end
    local location = locationFor(community)
    if not location then return false, "LOCATION_NOT_FOUND" end
    local sectorID = Sectors.IDForPosition(location.x, location.y)
    if Sectors.CountAllGroups(sectorID) >= Config.HARD_MAX_GROUPS_PER_SECTOR then
        return false, "SECTOR_HARD_CAP_REACHED"
    end
    local generationID, serial = Sectors.NextGenerationID("COMMUNITY_GROUP")
    local members = {}
    for index = 1, Config.COMMUNITY_GROUP_SIZE do members[index] = eligible[index] end
    local generation = { source = "COMMUNITY_FORMATION",
        generationId = generationID,
        sectorId = sectorID,
        createdAt = now, seed = Sectors.GenerationSeed(
            "COMMUNITY_GROUP", sectorID, serial, community.id) }
    local group, reason = PNC.AbstractGroups.Create({
        id = "agroup_" .. generationID,
        factionId = community.factionID, homeCommunityId = community.id,
        groupType = "SCAVENGER", memberIds = members, leaderId = members[1],
        mission = "SCAVENGE", state = "IDLE",
        location = PNC.AbstractLocations.Ref(location),
        resources = { food = 12, water = 18, ammo = 8, medical = 2,
            materials = 0 }, generation = generation,
        diagnostics = { generation = generation,
            memberSignature = table.concat(members, "|") },
    })
    if not group then return false, string.upper(tostring(reason)) end
    Sectors.RegisterGroup(group)
    Sectors.SetProvenance(group.id, generation)
    Sectors.MarkCommitted(generationID)
    Sectors.AddHistory("COMMUNITY_GROUP_CREATED", { groupId = group.id,
        communityId = community.id, sectorId = generation.sectorId,
        generationId = generationID }, now)
    Formation.Metrics.formed = Formation.Metrics.formed + 1
    return true, "COMMUNITY_GROUP_CREATED", group
end

function Formation.Reconcile(now, budget)
    local communities = PNC.Communities.List()
    if #communities == 0 then return 0 end
    budget = math.max(1, math.floor(tonumber(budget) or 1))
    Formation.Cursor = math.max(1, math.min(#communities, Formation.Cursor))
    local processed = 0
    while processed < budget and processed < #communities do
        Formation.Try(communities[Formation.Cursor], now)
        Formation.Metrics.evaluated = Formation.Metrics.evaluated + 1
        Formation.Cursor = Formation.Cursor % #communities + 1
        processed = processed + 1
    end
    return processed
end

return Formation
