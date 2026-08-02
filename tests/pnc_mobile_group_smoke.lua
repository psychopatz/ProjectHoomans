local SHARED =
    "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/"
local SERVER =
    "Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/"

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. ": expected="
            .. tostring(expected) .. " actual=" .. tostring(actual))
    end
end

local function truthy(value, label)
    equal(value == true, true, label)
end

local function tableCount(value)
    local count = 0
    for _, _ in pairs(value or {}) do count = count + 1 end
    return count
end

local function deepEqual(left, right)
    if type(left) ~= type(right) then return false end
    if type(left) ~= "table" then return left == right end
    for key, value in pairs(left) do
        if not deepEqual(value, right[key]) then return false end
    end
    for key, _ in pairs(right) do
        if left[key] == nil then return false end
    end
    return true
end

local worldHour = 100
local globalData = {}
local sequence = 0

function isClient() return false end
function isServer() return true end
function getTimeInMillis() return worldHour * 3600000 end
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
dofile(SHARED .. "Base/PNC_Constants.lua")
dofile(SHARED .. "Relationships/PNC_EntityRef.lua")
dofile(SHARED .. "Factions/PNC_FactionConstants.lua")
dofile(SHARED .. "Factions/PNC_FactionArchetypes.lua")
dofile(SHARED .. "Factions/PNC_FactionNameGenerator.lua")
dofile(SHARED .. "Factions/PNC_FactionEmblems.lua")
dofile(SHARED .. "Factions/PNC_FactionDiplomacyMath.lua")
dofile(SHARED .. "Factions/PNC_FactionIncidentDefinitions.lua")
dofile(SHARED .. "Communities/PNC_CommunityConstants.lua")
dofile(SHARED .. "Communities/PNC_CommunityProfiles.lua")
dofile(SHARED .. "Communities/PNC_CommunityMath.lua")
dofile(SHARED .. "Communities/PNC_CommunityTypes.lua")
dofile(SHARED .. "Factions/PNC_FactionTypes.lua")

PNC.Registry = { Data = {} }
function PNC.Registry.Get(id) return PNC.Registry.Data[tostring(id)] end
function PNC.Registry.GetLiveZombie() return nil end
function PNC.Registry.EnsureLoaded() return true end
function PNC.Registry.MarkDirty(record)
    record.recordRevision = (tonumber(record.recordRevision) or 0) + 1
    return true
end

PNC.OrderSystem = {
    SetOrder = function(record, order)
        record.orderSpec = PNC.Core.DeepCopy(order)
    end,
}
PNC.Network = { BroadcastRecord = function() end }
PNC.Presence = {
    Abstract = function(record)
        record.presenceState = "abstract"
        return true
    end,
}
PNC.API = {}
function PNC.API.Spawn(spec)
    sequence = sequence + 1
    local id = "npc_mobile_" .. tostring(sequence)
    local record = {
        id = id,
        alive = true,
        faction = spec.faction,
        x = spec.x,
        y = spec.y,
        z = spec.z,
        anchorX = spec.anchorX,
        anchorY = spec.anchorY,
        anchorZ = spec.anchorZ,
        presenceState = "abstract",
        presenceRevision = 0,
        recordRevision = 0,
        affiliation = PNC.FactionTypes.NewAffiliation(),
        runtime = {},
        orderSpec = PNC.Core.DeepCopy(spec.orderSpec),
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

dofile(SERVER .. "PNC_FactionService.lua")
dofile(SERVER .. "PNC_CommunitySiteResolver.lua")

local siteOne = assert(PNC.CommunityTypes.NormalizeSite({
    id = "community_site_building_a",
    kind = "building",
    home = { x = 100, y = 200, z = 0, radius = 10 },
    bounds = {
        minX = 92, minY = 192, maxX = 108, maxY = 208,
        minZ = 0, maxZ = 0,
    },
}, "community_site_building_a"))
local siteTwo = assert(PNC.CommunityTypes.NormalizeSite({
    id = "community_site_building_b",
    kind = "building",
    home = { x = 500, y = 700, z = 0, radius = 10 },
    bounds = {
        minX = 492, minY = 692, maxX = 508, maxY = 708,
        minZ = 0, maxZ = 0,
    },
}, "community_site_building_b"))
PNC.CommunitySiteResolver.FindRandomHouse = function(options)
    if (tonumber(options and options.randomIndex) or 0) >= 2 then
        return PNC.Core.DeepCopy(siteTwo), "deterministic_second_house"
    end
    return PNC.Core.DeepCopy(siteOne), "deterministic_first_house"
end
PNC.CommunitySiteResolver.FindSpawnPoints = function(site, count)
    local points = {}
    for index = 1, count do
        points[index] = {
            x = site.home.x + index,
            y = site.home.y,
            z = site.home.z,
        }
    end
    return points
end
PNC.CommunitySiteResolver.IsSiteLoaded = function() return false end

dofile(SERVER .. "PNC_CommunityDirector.lua")
dofile(SERVER .. "PNC_MobileGroupDirector.lua")
PNC.Factions.Load()

PNC.Factions.IDGenerator = function() return "faction_mobile_looters" end
local ok, _, faction = PNC.Factions.Create({
    name = "Mobile Looters",
    archetypeID = "looter",
    createdAt = worldHour,
})
truthy(ok, "mobile looter faction created")

local generated
ok, _, generated = PNC.MobileGroupDirector.GenerateForFaction(
    faction.id,
    {
        groupSize = 3,
        presenceMode = "abstract",
        worldAgeHours = worldHour,
        mobilePathMode = "random",
    }
)
truthy(ok, "mobile looter group generated")
equal(generated.createdCount, 3, "mobile group population")
equal(generated.siteID, siteOne.id, "initial random staging house")
equal(PNC.Factions.Get(faction.id).mobile.pathMode, "random",
    "persistent random path mode")
equal(tableCount(PNC.Factions.Get(faction.id).memberIDs), 3,
    "members belong to faction only")
for _, npcID in ipairs(generated.npcIDs) do
    local record = PNC.Registry.Get(npcID)
    equal(record.affiliation.communityID, nil,
        "mobile member has no community affiliation")
    equal(record.orderSpec.kind, PNC.Const.ORDER_HOSTILE_ROAM,
        "random looter group roams rather than making a settlement")
end

local communityOK, communityReason =
    PNC.CommunityDirector.GenerateForFaction(faction.id, {})
equal(communityOK, false, "mobile faction cannot create a community")
equal(communityReason, "mobile_faction_cannot_create_community",
    "community rejection is explicit")

local changed = PNC.MobileGroupDirector.SetPathMode(
    faction.id, "player"
)
truthy(changed, "debug path mode changes mobile group")
equal(PNC.Factions.Get(faction.id).mobile.pathMode, "player",
    "player path mode is persisted")

local firstMember = PNC.Registry.Get(generated.npcIDs[1])
firstMember.presenceState = "live"
local moved, moveReason = PNC.MobileGroupDirector.RelocateFaction(
    faction.id, worldHour + 24, true
)
equal(moved, false, "live mobile group does not relocate")
equal(moveReason, "mobile_group_live",
    "relocation waits for abstract group")
firstMember.presenceState = "abstract"

worldHour = worldHour + 24
moved, _, generated = PNC.MobileGroupDirector.RelocateFaction(
    faction.id, worldHour, true
)
truthy(moved, "abstract mobile group relocates")
equal(generated.site.id, siteTwo.id, "group moves to next building")
equal(generated.relocationCount, 1, "relocation count increments")
equal(generated.nextMoveAt, worldHour + 24,
    "relocation schedules next abstract move")
for npcID, _ in pairs(PNC.Factions.Get(faction.id).memberIDs) do
    local record = PNC.Registry.Get(npcID)
    equal(record.anchorX, siteTwo.home.x,
        "member anchor updates with mobile staging site")
    equal(record.orderSpec.kind, PNC.Const.ORDER_HOSTILE_HUNT,
        "player mode looters hunt toward players")
end

local normalized = PNC.FactionTypes.NormalizeFaction(
    PNC.Factions.Get(faction.id), faction.id
)
equal(normalized.mobile.site.id, siteTwo.id,
    "mobile persistence normalizes staging site")
equal(deepEqual(
    normalized,
    PNC.FactionTypes.NormalizeFaction(normalized, faction.id)
), true, "mobile normalization is idempotent")

print("pnc_mobile_group_smoke: PASS")
