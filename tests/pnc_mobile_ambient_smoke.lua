local T = require "tests/support/test"

local SHARED = T.path("ProjectHoomans", "shared", "PNC/Core/")
local SERVER = T.path("ProjectHoomans", "server", "PNC/")

local function site(id, minX, minY, maxX, maxY)
    return PNC.CommunityTypes.NormalizeSite({
        id = id,
        kind = "building",
        home = {
            x = (minX + maxX) / 2,
            y = (minY + maxY) / 2,
            z = 0,
            radius = 8,
        },
        bounds = {
            minX = minX, minY = minY,
            maxX = maxX, maxY = maxY,
            minZ = 0, maxZ = 0,
        },
    }, id)
end

function isClient() return false end
function isServer() return true end
function getGameTime()
    return { getWorldAgeHours = function() return 8 end }
end

Events = {
    OnInitGlobalModData = { Add = function() end },
    OnSave = { Add = function() end },
}

PNC = {}
T.load(SHARED .. "Base/PNC_Core.lua")
T.load(SHARED .. "Base/PNC_Constants.lua")
T.load(SHARED .. "Relationships/PNC_EntityRef.lua")
T.load(SHARED .. "Factions/PNC_FactionConstants.lua")
T.load(SHARED .. "Factions/PNC_FactionArchetypes.lua")
T.load(SHARED .. "Communities/PNC_CommunityConstants.lua")
T.load(SHARED .. "Communities/PNC_CommunityProfiles.lua")
T.load(SHARED .. "Communities/PNC_CommunityMath.lua")
T.load(SHARED .. "Communities/PNC_CommunityTypes.lua")
T.load(SHARED .. "Factions/PNC_FactionTypes.lua")

PNC.Registry = { Data = {} }
function PNC.Registry.Get(id) return PNC.Registry.Data[tostring(id)] end
function PNC.Registry.MarkDirty() return true end
PNC.OrderSystem = {
    SetOrder = function(record, order)
        record.orderSpec = PNC.Core.DeepCopy(order)
    end,
}
PNC.Factions = {
    Registry = { byID = {} },
    IsMobileGroup = function(faction)
        return faction and faction.mobile and faction.mobile.active == true
    end,
    Get = function(id)
        return PNC.Factions.Registry.byID[id]
    end,
}

T.load(SERVER .. "Communities/PNC_CommunitySiteResolver.lua")
T.load(SERVER .. "Director/PNC_MobileGroupDirector.lua")

local Zones = require "PsychopatzCore/World/PC_ZoneRegistry"
Zones.import({ byID = {} })
Zones.register({
    id = "base_zone_player",
    ownerType = "projecthoomans.base",
    ownerId = "base_player",
    type = "base",
    geometry = {
        levels = {
            [0] = { rows = {
                [100] = { 90, 110 },
                [101] = { 90, 110 },
            } },
        },
    },
})

local owned = site("community_site_owned", 95, 99, 105, 103)
local safe = site("community_site_safe", 300, 300, 310, 310)
local ambientFaction = {
    id = "faction_ambient",
    archetypeID = "trader",
    memberIDs = { npc_ambient = true },
    mobile = {
        active = true,
        controlMode = PNC.FactionConstants.MOBILE_CONTROL_AMBIENT,
        pathMode = PNC.FactionConstants.MOBILE_PATH_RANDOM,
        site = safe,
        ambient = {
            phase = PNC.FactionConstants.MOBILE_AMBIENT_DAY,
            objective = PNC.FactionConstants.MOBILE_AMBIENT_ROAD,
            target = {
                kind = "nav",
                x = 400, y = 400, z = 0, radius = 20,
                bounds = { minX = 390, minY = 390, maxX = 410, maxY = 410 },
            },
        },
    },
}
PNC.Factions.Registry.byID[ambientFaction.id] = ambientFaction
PNC.Registry.Data.npc_ambient = {
    id = "npc_ambient",
    alive = true,
    tacticalClass = "neutral",
    x = 300, y = 300, z = 0,
    anchorX = 300, anchorY = 300, anchorZ = 0,
    orderSpec = { kind = PNC.Const.ORDER_GUARD },
    runtime = {},
}

local H = PNC.MobileGroupDirectorInternal
PNC.CommunitySiteResolver.FindSpawnPoints = function(value)
    return { { x = value.home.x, y = value.home.y, z = value.home.z } }
end
PNC.CommunitySiteResolver.FindRandomHouse = function(options)
    T.truthy(type(options.siteFilter) == "function",
        "shelter selection installs a site filter")
    if options.siteFilter(owned) then return owned, "wrong_filter" end
    return safe, "safe_house"
end
PNC.CommunitySiteResolver.FindAvailableNear = function(_, _, _, options)
    return options.siteFilter(safe) and safe or nil, "nearby_safe_house"
end

T.equal(H.AmbientPhase(8), PNC.FactionConstants.MOBILE_AMBIENT_DAY,
    "morning selects the day phase")
T.equal(H.AmbientPhase(22), PNC.FactionConstants.MOBILE_AMBIENT_NIGHT,
    "night selects the shelter phase")
T.equal(H.IsValidShelterSite(owned), false,
    "building overlapping player territory is rejected")
T.equal(H.IsValidShelterSite({
    kind = "radius", home = safe.home, bounds = safe.bounds,
}), false, "radius sites cannot become shelters")
local shelterTarget = T.truthy(H.FindShelterTarget(ambientFaction, 22),
    "ambient shelter target is selected")
T.equal(shelterTarget.siteID, safe.id,
    "shelter selection skips player-owned building")

local strategic = {
    id = "faction_looters",
    archetypeID = "looter",
    mobile = {
        active = true,
        controlMode = PNC.FactionConstants.MOBILE_CONTROL_STRATEGIC,
        pathMode = PNC.FactionConstants.MOBILE_PATH_PLAYER,
        site = safe,
    },
}
PNC.Factions.Registry.byID[strategic.id] = strategic
PNC.BaseService = {
    GetForFaction = function(id)
        return id == "faction_player" and {
            id = "base_player",
            factionId = "faction_player",
            baseZoneId = "base_zone_player",
        } or nil
    end,
    BuildSnapshot = function()
        return { geometry = { bounds = {
            minX = 90, minY = 90, maxX = 110, maxY = 110, minZ = 0,
        } } }
    end,
}
PNC.Core.ForEachPlayer = function(callback)
    callback({})
end
PNC.Factions.GetPlayerFaction = function()
    return { id = "faction_player" }
end
local baseTarget = T.truthy(H.FindPlayerBaseTarget(strategic),
    "player base target is discovered")
T.equal(baseTarget.baseID, "base_player",
    "strategic target points at the registered player base")
strategic.mobile.strategicTarget = baseTarget
local strategicOrder = H.MobileOrder(
    strategic,
    strategic.mobile,
    strategic.mobile.site
)
T.equal(strategicOrder.kind, PNC.Const.ORDER_HOSTILE_HUNT,
    "strategic looters retain hostile hunt")
T.equal(strategicOrder.x, baseTarget.x,
    "hostile hunt anchor uses player base coordinates")

PNC.Factions.UpdateMobileGroup = function(id, patch)
    local faction = PNC.Factions.Registry.byID[id]
    for key, value in pairs(patch or {}) do
        faction.mobile[key] = PNC.Core.DeepCopy(value)
    end
    return true, "updated", faction.mobile
end
local controlOk = PNC.MobileGroupDirector.SetControlMode(
    strategic.id,
    PNC.FactionConstants.MOBILE_CONTROL_STRATEGIC
)
T.truthy(controlOk, "debug control mode keeps strategic ownership")
T.equal(strategic.mobile.pathMode,
    PNC.FactionConstants.MOBILE_PATH_PLAYER,
    "strategic control forces player path mode")
local shelterFaction, shelterRefresh = H.RefreshAmbient(
    ambientFaction,
    22
)
T.truthy(shelterFaction and shelterRefresh,
    "ambient controller changes objective at night")
T.equal(ambientFaction.mobile.ambient.objective,
    PNC.FactionConstants.MOBILE_AMBIENT_SHELTER,
    "night objective is shelter")
T.equal(PNC.Registry.Data.npc_ambient.orderSpec.roamMode,
    PNC.Const.ROAM_MODE_SHELTER,
    "night objective repairs members toward shelter")
H.FindRoadTarget = function()
    return {
        kind = "nav",
        x = 450, y = 450, z = 0, radius = 20,
        bounds = { minX = 440, minY = 440, maxX = 460, maxY = 460 },
    }, "test_nav"
end
local roadFaction, roadRefresh = H.RefreshAmbient(ambientFaction, 8)
T.truthy(roadFaction and roadRefresh,
    "ambient controller changes objective in the morning")
T.equal(ambientFaction.mobile.ambient.objective,
    PNC.FactionConstants.MOBILE_AMBIENT_ROAD,
    "morning objective is road")

PNC.Registry.Data.npc_ambient.orderSpec = { kind = PNC.Const.ORDER_GUARD }
local repaired = H.RepairMobileOrders(ambientFaction)
T.equal(repaired, 1, "ambient objective repairs a replaced member order")
T.equal(PNC.Registry.Data.npc_ambient.orderSpec.roamMode,
    PNC.Const.ROAM_MODE_ROAD,
    "repaired ambient order returns to Nav roaming")

T.finish("pnc_mobile_ambient_smoke")
