local T = require "tests/support/test"

local SHARED =
    T.path("ProjectHoomans", "shared", "PNC/Core/")
local SERVER =
    T.path("ProjectHoomans", "server", "PNC/")

local function tableSize(value)
    local count = 0
    for _, _ in pairs(value or {}) do count = count + 1 end
    return count
end

local worldHour = 500
local globalData = {}

function isClient() return false end
function isServer() return true end
function getTimeInMillis() return worldHour * 3600000 end
function ZombRand() return 13 end
function getCell() return nil end
function getGameTime()
    return {
        getWorldAgeHours = function() return worldHour end,
    }
end

Events = {
    OnInitGlobalModData = { Add = function() end },
    OnSave = { Add = function() end },
}
ModData = {
    getOrCreate = function(key)
        globalData[key] = globalData[key] or {}
        return globalData[key]
    end,
}

PNC = {}
T.load(SHARED .. "Base/PNC_Core.lua")
PNC.Const = {
    PRESENCE_ABSTRACT = "abstract",
    PRESENCE_LIVE = "live",
    ORDER_ROAM = "roam",
    ROAM_MODE_AREA = "area",
}
T.load(SHARED .. "Relationships/PNC_EntityRef.lua")
T.load(SHARED .. "Factions/PNC_FactionConstants.lua")
T.load(SHARED .. "Factions/PNC_FactionArchetypes.lua")
T.load(SHARED .. "Factions/PNC_FactionNameGenerator.lua")
T.load(SHARED .. "Factions/PNC_FactionEmblems.lua")
T.load(SHARED .. "Factions/PNC_FactionDiplomacyMath.lua")
T.load(SHARED .. "Factions/PNC_FactionIncidentDefinitions.lua")
T.load(SHARED .. "Communities/PNC_CommunityConstants.lua")
T.load(SHARED .. "Communities/PNC_CommunityProfiles.lua")
T.load(SHARED .. "Communities/PNC_CommunityMath.lua")
T.load(SHARED .. "Communities/PNC_CommunityTypes.lua")
T.load(SHARED .. "Factions/PNC_FactionTypes.lua")

PNC.Registry = { Data = {} }
function PNC.Registry.Get(id)
    return PNC.Registry.Data[tostring(id)]
end
function PNC.Registry.EnsureLoaded() return true end
function PNC.Registry.MarkDirty(record)
    record.recordRevision =
        (tonumber(record.recordRevision) or 0) + 1
    return true
end

T.load(SERVER .. "Factions/PNC_FactionService.lua")
T.load(SERVER .. "Communities/PNC_CommunityService.lua")
T.load(SERVER .. "Communities/PNC_CommunitySiteResolver.lua")

local npcSequence = 0
PNC.Presence = {
    Abstract = function(record)
        record.presenceState = "abstract"
        return true
    end,
}
PNC.API = {}
function PNC.API.Spawn(spec)
    npcSequence = npcSequence + 1
    local id = "npc_director_" .. tostring(npcSequence)
    local record = {
        id = id,
        name = "Director NPC " .. tostring(npcSequence),
        alive = true,
        faction = spec.faction,
        recruited = false,
        ownerUsername = nil,
        ownerOnlineID = nil,
        x = spec.x,
        y = spec.y,
        z = spec.z,
        presenceState = "abstract",
        presenceRevision = 0,
        recordRevision = 0,
        affiliation = PNC.FactionTypes.NewAffiliation(),
        runtime = {},
        spawnRequestedLive = spec.forceLive == true,
    }
    PNC.Registry.Data[id] = record
    local added = PNC.Factions.AddNPC(
        spec.organizationalFactionID,
        id,
        {
            membershipStatus = spec.membershipStatus,
            role = spec.factionRole,
            joinedAt = spec.factionJoinedAt,
        }
    )
    if not added then
        PNC.Registry.Data[id] = nil
        return nil
    end
    return record
end
function PNC.API.Despawn(id)
    PNC.Registry.Data[id] = nil
    return true
end

T.load(SERVER .. "Communities/PNC_CommunityDirector.lua")
PNC.Factions.Load()
PNC.Communities.Load()

PNC.Factions.IDGenerator =
    function() return "faction_director" end
PNC.Communities.IDGenerator =
    function() return "community_director" end

local ok, _, faction = PNC.Factions.Create({
    name = "Unloaded Looter Group",
    archetypeID = "looter",
    createdAt = worldHour,
})
T.truthy(ok, "faction created")

local primitiveSite = {
    kind = "building",
    home = {
        x = 10000,
        y = 12000,
        z = 0,
        radius = 14,
    },
    bounds = {
        minX = 9994,
        minY = 11994,
        maxX = 10006,
        maxY = 12006,
        minZ = 0,
        maxZ = 0,
    },
}

local result
ok, _, result =
    PNC.CommunityDirector.GenerateForFaction(
        faction.id,
        {
            siteSpec = primitiveSite,
            groupSize = 4,
            presenceMode = "live",
            worldAgeHours = worldHour,
            debug = true,
        }
    )
T.truthy(ok, "unloaded group generated")
T.equal(result.createdCount, 4, "four generated")
T.equal(result.liveCount, 0, "unloaded live defers")
T.equal(result.abstractCount, 4,
    "unloaded group remains abstract")
T.equal(result.siteLoaded, false, "site unloaded")
T.truthy(PNC.CommunityTypes.IsValidSiteID(
    result.siteID
), "site ID generated from primitives")

local community = PNC.Communities.Get(
    result.communityID
)
T.equal(community.currentPopulation, 4,
    "community population")
T.equal(community.site.status, "occupied",
    "site occupied")
T.truthy(string.find(
    community.name,
    faction.name,
    1,
    true
), "community name retains faction identity")
T.equal(community.leaderNPCID, result.npcIDs[1],
    "community leader generated")
T.equal(PNC.Factions.Get(
    faction.id
).leaderNPCID, result.npcIDs[1],
    "faction leader generated")

for _, npcID in ipairs(result.npcIDs) do
    local record = PNC.Registry.Get(npcID)
    T.equal(record.presenceState, "abstract",
        "persistent abstract record")
    T.equal(record.spawnRequestedLive, false,
        "unloaded site never force-materializes")
    T.equal(record.affiliation.factionID, faction.id,
        "faction membership")
    T.equal(record.affiliation.communityID,
        community.id, "community membership")
    T.equal(record.faction, "neutral",
        "legacy combat classification preserved")
end
T.equal(
    PNC.Registry.Get(result.npcIDs[2]).affiliation.role,
    "raider",
    "looter group receives archetype role"
)
T.equal(
    PNC.Registry.Get(result.npcIDs[3]).affiliation.role,
    "enforcer",
    "looter group receives second archetype role"
)

-- A second generation reuses the existing community and site.
local second
ok, _, second =
    PNC.CommunityDirector.GenerateForFaction(
        faction.id,
        {
            siteSpec = primitiveSite,
            groupSize = 2,
            presenceMode = "abstract",
            worldAgeHours = worldHour + 1,
        }
    )
T.truthy(ok, "existing community group generated")
T.equal(second.communityID, community.id,
    "existing community reused")
T.equal(second.siteID, result.siteID,
    "existing site reused")
T.equal(PNC.Communities.Get(
    community.id
).currentPopulation, 6,
    "population expands")

-- The final death retires the community and releases the building record.
local allIDs = {}
for id, _ in pairs(PNC.Registry.Data) do
    allIDs[#allIDs + 1] = id
end
table.sort(allIDs)
for _, npcID in ipairs(allIDs) do
    local record = PNC.Registry.Get(npcID)
    record.alive = false
    T.truthy(PNC.Communities.OnNPCDeath(npcID),
        "death reconciles")
end
T.equal(PNC.Communities.Get(
    community.id
).status, "destroyed", "group wiped")
T.equal(PNC.Communities.GetSite(
    result.siteID
).status, "vacant", "site released")
T.equal(tableSize(
    PNC.Communities.Get(community.id).memberIDs
), 0, "retired membership cleared")
T.finish("pnc_community_director_smoke")

T.finish("pnc_community_director_smoke")
