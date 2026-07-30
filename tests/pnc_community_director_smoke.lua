local SHARED =
    "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/"
local SERVER =
    "Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected="
            .. tostring(expected) .. " actual="
            .. tostring(actual))
    end
end

local function assertTrue(value, label)
    assertEqual(value == true, true, label)
end

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
dofile(SHARED .. "Base/PNC_Core.lua")
PNC.Const = {
    PRESENCE_ABSTRACT = "abstract",
    PRESENCE_LIVE = "live",
    ORDER_ROAM = "roam",
    ROAM_MODE_AREA = "area",
}
dofile(SHARED .. "Relationships/PNC_EntityRef.lua")
dofile(SHARED .. "Factions/PNC_FactionConstants.lua")
dofile(SHARED .. "Factions/PNC_FactionArchetypes.lua")
dofile(SHARED .. "Factions/PNC_FactionDiplomacyMath.lua")
dofile(SHARED .. "Factions/PNC_FactionIncidentDefinitions.lua")
dofile(SHARED .. "Communities/PNC_CommunityConstants.lua")
dofile(SHARED .. "Communities/PNC_CommunityProfiles.lua")
dofile(SHARED .. "Communities/PNC_CommunityMath.lua")
dofile(SHARED .. "Communities/PNC_CommunityTypes.lua")
dofile(SHARED .. "Factions/PNC_FactionTypes.lua")

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

dofile(SERVER .. "PNC_FactionService.lua")
dofile(SERVER .. "PNC_CommunityService.lua")
dofile(SERVER .. "PNC_CommunitySiteResolver.lua")

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

dofile(SERVER .. "PNC_CommunityDirector.lua")
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
assertTrue(ok, "faction created")

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
assertTrue(ok, "unloaded group generated")
assertEqual(result.createdCount, 4, "four generated")
assertEqual(result.liveCount, 0, "unloaded live defers")
assertEqual(result.abstractCount, 4,
    "unloaded group remains abstract")
assertEqual(result.siteLoaded, false, "site unloaded")
assertTrue(PNC.CommunityTypes.IsValidSiteID(
    result.siteID
), "site ID generated from primitives")

local community = PNC.Communities.Get(
    result.communityID
)
assertEqual(community.currentPopulation, 4,
    "community population")
assertEqual(community.site.status, "occupied",
    "site occupied")
assertEqual(community.leaderNPCID, result.npcIDs[1],
    "community leader generated")
assertEqual(PNC.Factions.Get(
    faction.id
).leaderNPCID, result.npcIDs[1],
    "faction leader generated")

for _, npcID in ipairs(result.npcIDs) do
    local record = PNC.Registry.Get(npcID)
    assertEqual(record.presenceState, "abstract",
        "persistent abstract record")
    assertEqual(record.spawnRequestedLive, false,
        "unloaded site never force-materializes")
    assertEqual(record.affiliation.factionID, faction.id,
        "faction membership")
    assertEqual(record.affiliation.communityID,
        community.id, "community membership")
    assertEqual(record.faction, "neutral",
        "legacy combat classification preserved")
end

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
assertTrue(ok, "existing community group generated")
assertEqual(second.communityID, community.id,
    "existing community reused")
assertEqual(second.siteID, result.siteID,
    "existing site reused")
assertEqual(PNC.Communities.Get(
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
    assertTrue(PNC.Communities.OnNPCDeath(npcID),
        "death reconciles")
end
assertEqual(PNC.Communities.Get(
    community.id
).status, "destroyed", "group wiped")
assertEqual(PNC.Communities.GetSite(
    result.siteID
).status, "vacant", "site released")
assertEqual(tableSize(
    PNC.Communities.Get(community.id).memberIDs
), 0, "retired membership cleared")

print("pnc_community_director_smoke: PASS")
