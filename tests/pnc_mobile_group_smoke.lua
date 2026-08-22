local T = require "tests/support/test"

local SHARED =
    T.path("ProjectHoomans", "shared", "PNC/Core/")
local SERVER =
    T.path("ProjectHoomans", "server", "PNC/")

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
T.load(SHARED .. "Base/PNC_Core.lua")
T.load(SHARED .. "Base/PNC_Constants.lua")
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

T.load(SERVER .. "PNC_FactionService.lua")
T.load(SERVER .. "PNC_CommunitySiteResolver.lua")

local siteOne = T.truthy(PNC.CommunityTypes.NormalizeSite({
    id = "community_site_building_a",
    kind = "building",
    home = { x = 100, y = 200, z = 0, radius = 10 },
    bounds = {
        minX = 92, minY = 192, maxX = 108, maxY = 208,
        minZ = 0, maxZ = 0,
    },
}, "community_site_building_a"))
local siteTwo = T.truthy(PNC.CommunityTypes.NormalizeSite({
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

T.load(SERVER .. "PNC_CommunityDirector.lua")
T.load(SERVER .. "PNC_MobileGroupDirector.lua")
PNC.Factions.Load()

PNC.Factions.IDGenerator = function() return "faction_mobile_looters" end
local ok, _, faction = PNC.Factions.Create({
    name = "Mobile Looters",
    archetypeID = "looter",
    createdAt = worldHour,
})
T.truthy(ok, "mobile looter faction created")

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
T.truthy(ok, "mobile looter group generated")
T.equal(generated.createdCount, 3, "mobile group population")
T.equal(generated.siteID, siteOne.id, "initial random staging house")
T.equal(PNC.Factions.Get(faction.id).mobile.pathMode, "random",
    "persistent random path mode")
T.equal(tableCount(PNC.Factions.Get(faction.id).memberIDs), 3,
    "members belong to faction only")
for _, npcID in ipairs(generated.npcIDs) do
    local record = PNC.Registry.Get(npcID)
    T.equal(record.affiliation.communityID, nil,
        "mobile member has no community affiliation")
    T.equal(record.orderSpec.kind, PNC.Const.ORDER_HOSTILE_ROAM,
        "random looter group roams rather than making a settlement")
end

local communityOK, communityReason =
    PNC.CommunityDirector.GenerateForFaction(faction.id, {})
T.equal(communityOK, false, "mobile faction cannot create a community")
T.equal(communityReason, "mobile_faction_cannot_create_community",
    "community rejection is explicit")

local changed = PNC.MobileGroupDirector.SetPathMode(
    faction.id, "player"
)
T.truthy(changed, "debug path mode changes mobile group")
T.equal(PNC.Factions.Get(faction.id).mobile.pathMode, "player",
    "player path mode is persisted")

local firstMember = PNC.Registry.Get(generated.npcIDs[1])
firstMember.presenceState = "live"
local moved, moveReason = PNC.MobileGroupDirector.RelocateFaction(
    faction.id, worldHour + 24, true
)
T.equal(moved, false, "live mobile group does not relocate")
T.equal(moveReason, "mobile_group_live",
    "relocation waits for abstract group")
firstMember.presenceState = "abstract"

worldHour = worldHour + 24
moved, _, generated = PNC.MobileGroupDirector.RelocateFaction(
    faction.id, worldHour, true
)
T.truthy(moved, "abstract mobile group relocates")
T.equal(generated.site.id, siteTwo.id, "group moves to next building")
T.equal(generated.relocationCount, 1, "relocation count increments")
T.equal(generated.nextMoveAt, worldHour + 24,
    "relocation schedules next abstract move")
for npcID, _ in pairs(PNC.Factions.Get(faction.id).memberIDs) do
    local record = PNC.Registry.Get(npcID)
    T.equal(record.anchorX, siteTwo.home.x,
        "member anchor updates with mobile staging site")
    T.equal(record.orderSpec.kind, PNC.Const.ORDER_HOSTILE_HUNT,
        "player mode looters hunt toward players")
end

local normalized = PNC.FactionTypes.NormalizeFaction(
    PNC.Factions.Get(faction.id), faction.id
)
T.equal(normalized.mobile.site.id, siteTwo.id,
    "mobile persistence normalizes staging site")
T.equal(deepEqual(
    normalized,
    PNC.FactionTypes.NormalizeFaction(normalized, faction.id)
), true, "mobile normalization is idempotent")

PNC.Factions.IDGenerator = function() return "faction_trading_caravan" end
local caravanOK, _, caravan = PNC.Factions.Create({
    name = "Frontier Trading Caravan",
    archetypeID = "trader",
    createdAt = worldHour,
})
T.truthy(caravanOK, "trading caravan faction created")
local caravanGenerated
caravanOK, _, caravanGenerated =
    PNC.MobileGroupDirector.GenerateForFaction(
        caravan.id,
        {
            groupSize = 3,
            presenceMode = "abstract",
            worldAgeHours = worldHour,
            mobilePathMode = "random",
        }
    )
T.truthy(caravanOK, "trading caravan group generated")
T.equal(caravanGenerated.createdCount, 3,
    "trading caravan population")
T.equal(PNC.Factions.Get(caravan.id).mobile.active, true,
    "trading caravan is mobile")
for _, npcID in ipairs(caravanGenerated.npcIDs) do
    local record = PNC.Registry.Get(npcID)
    T.equal(record.affiliation.communityID, nil,
        "trading caravan member has no settlement affiliation")
    T.equal(record.orderSpec.kind, PNC.Const.ORDER_ROAM,
        "trading caravan roams across the map")
end

T.load(SERVER .. "PNC_FactionDebug.lua")
local debugSnapshot = PNC.FactionDebug.BuildSnapshot(
    caravan.id,
    nil,
    nil,
    nil,
    nil
)
local labels = {}
for _, summary in ipairs(debugSnapshot.factions) do
    labels[summary.id] = summary.archetypeLabel
end
T.equal(labels[faction.id], "Mobile Looter Group",
    "inspector distinguishes mobile looters from settlements")
T.equal(labels[caravan.id], "Trading Caravan",
    "inspector identifies traders as mobile caravans")
T.finish("pnc_mobile_group_smoke")

T.finish("pnc_mobile_group_smoke")
