local T = require "tests/support/test"

local SHARED = T.path("ProjectHoomans", "shared", "PNC/Core/")
local SERVER = T.path("ProjectHoomans", "server", "PNC/")

function isClient() return false end
function isServer() return true end
function getGameTime()
    return { getWorldAgeHours = function() return 48 end }
end

PNC = {}
T.load(SHARED .. "Base/PNC_Core.lua")
T.load(SHARED .. "Base/PNC_Constants.lua")
T.load(SHARED .. "Relationships/PNC_EntityRef.lua")
T.load(SHARED .. "Factions/PNC_FactionConstants.lua")
T.load(SHARED .. "Communities/PNC_CommunityConstants.lua")
T.load(SHARED .. "Communities/PNC_CommunityMath.lua")
T.load(SHARED .. "Communities/PNC_CommunityTypes.lua")
T.load(SHARED .. "Director/PNC_DirectorConfig.lua")

local registry = {}
local locations = {}
local groups = {}
local updates = 0
local traversalStarts = 0

local function copy(value)
    return PNC.Core.DeepCopy(value)
end

local function faction(id)
    return registry[id]
end

PNC.Factions = {
    Registry = { byID = registry },
    Get = faction,
    IsMobileGroup = function(value)
        return value and value.mobile and value.mobile.active == true
    end,
    UpdateMobileGroup = function(id, patch)
        local value = registry[id]
        for key, item in pairs(patch or {}) do
            value.mobile[key] = copy(item)
        end
        updates = updates + 1
        return true, "updated", copy(value.mobile)
    end,
}

PNC.Communities = {
    ListSites = function()
        return {
            {
                id = "community_site_ai",
                home = { x = 500, y = 500, z = 0, radius = 12 },
                bounds = {
                    minX = 490, minY = 490, maxX = 510, maxY = 510,
                    minZ = 0, maxZ = 0,
                },
                occupantCommunityID = "community_ai",
            },
            {
                id = "community_site_player",
                home = { x = 200, y = 200, z = 0, radius = 12 },
                bounds = {
                    minX = 190, minY = 190, maxX = 210, maxY = 210,
                    minZ = 0, maxZ = 0,
                },
                occupantCommunityID = "community_player",
            },
        }
    end,
    Get = function(id)
        return id == "community_ai"
            and { id = id, factionID = "faction_ai" }
            or id == "community_player"
                and { id = id, factionID = "faction_player" }
            or nil
    end,
}

PNC.AbstractLocations = {
    RegisterSite = function(site)
        local location = {
            id = "aloc_" .. site.id,
            type = "SETTLEMENT",
            x = site.home.x,
            y = site.home.y,
            z = site.home.z,
        }
        locations[location.id] = location
        return location, "registered"
    end,
    Get = function(id) return locations[id] end,
}
PNC.SettlementRepository = {
    State = { bases = {} },
}
PNC.BaseService = {
    BuildSnapshot = function(base)
        return { geometry = base.geometry }
    end,
}

groups = {
    faction_looters = {
        id = "agroup_faction_looters",
        location = { id = "aloc_mobile_origin" },
        state = "TRAVELING",
        targetLocation = { id = "aloc_old_road_sample" },
    },
}
PNC.AbstractGroups = {
    FindByFactionID = function(id) return groups[id] end,
    HasLiveMembers = function() return false end,
}
PNC.AbstractGroupManagerInternal = {
    Touch = function() end,
}
PNC.AbstractTraversal = {
    Begin = function()
        traversalStarts = traversalStarts + 1
        return true, "travel_started"
    end,
}

registry.faction_looters = {
    id = "faction_looters",
    status = "active",
    archetypeID = "looter",
    mobile = {
        active = true,
        controlMode = PNC.FactionConstants.MOBILE_CONTROL_AMBIENT,
        activity = PNC.FactionConstants.MOBILE_ACTIVITY_STREET_ROAMING,
        ambient = {
            objective = PNC.FactionConstants.MOBILE_AMBIENT_ROAD,
        },
        site = {
            id = "community_site_origin",
            home = { x = 100, y = 100, z = 0, radius = 12 },
        },
        lastDepartureAt = -1,
    },
}
registry.faction_ai = {
    id = "faction_ai",
    playerMemberKeys = {},
}
registry.faction_player = {
    id = "faction_player",
    playerMemberKeys = { player_one = true },
}

T.load(SERVER .. "Director/MobileGroupDirector/PNC_MobileGroupDirector_Core.lua")
T.load(SERVER ..
    "Director/MobileGroupDirector/PNC_MobileGroupDirector_DepartureTargets.lua")
T.load(SERVER ..
    "Director/MobileGroupDirector/PNC_MobileGroupDirector_Departures.lua")

local Director = PNC.MobileGroupDirector
local H = PNC.MobileGroupDirectorInternal
Director.DailyDepartureRoll = function() return 0 end

T.equal(H.NextDailyDepartureAt(5), 6,
    "daily departure starts at daytime after a nighttime initialization")
T.equal(H.NextDailyDepartureAt(6), 6,
    "daily departure can run immediately at daytime initialization")
T.equal(H.NextDailyDepartureAt(20), 30,
    "daily departure rolls forward to the next daytime window")

local targetWithoutPlayerBase = T.truthy(
    H.ResolveSettlementDepartureTarget(registry.faction_looters),
    "hostile group receives an AI settlement target"
)
T.equal(targetWithoutPlayerBase.kind, "ai_settlement",
    "hostile group cannot target a player colony before a base exists")
T.equal(targetWithoutPlayerBase.siteID, "community_site_ai",
    "unbased player community is not reclassified as an AI settlement")

PNC.SettlementRepository.State.bases.base_player = {
    id = "base_player",
    factionId = "faction_player",
    baseZoneId = "base_zone_player",
    geometry = {
        minX = 700, minY = 700, maxX = 720, maxY = 720,
        minZ = 0, maxZ = 0,
    },
}
T.equal(H.PlayerBaseCount(), 1,
    "player base gate recognizes a registered player base")

local target = T.truthy(
    H.ResolveSettlementDepartureTarget(registry.faction_looters),
    "hostile group receives a settlement target after player base creation"
)
T.equal(target.kind, "player_colony",
    "hostile group prefers a player colony once a base exists")
T.equal(target.siteID, "community_site_player",
    "player settlement target carries its site identity")

registry.faction_trader = {
    id = "faction_trader",
    status = "active",
    archetypeID = "trader",
    mobile = {
        active = true,
        controlMode = PNC.FactionConstants.MOBILE_CONTROL_AMBIENT,
        activity = PNC.FactionConstants.MOBILE_ACTIVITY_STREET_ROAMING,
        ambient = {
            objective = PNC.FactionConstants.MOBILE_AMBIENT_ROAD,
        },
        site = {
            id = "community_site_origin",
            home = { x = 100, y = 100, z = 0, radius = 12 },
        },
        lastDepartureAt = -1,
    },
}
local peacefulTarget = T.truthy(
    H.ResolveSettlementDepartureTarget(registry.faction_trader),
    "peaceful group receives a settlement target"
)
T.equal(peacefulTarget.kind, "ai_settlement",
    "peaceful group prefers an AI settlement")
registry.faction_trader.mobile.lastDepartureAt = 48

local started, reason = Director.StartSettlementTravel(
    "faction_looters",
    target,
    48
)
T.truthy(started, reason)
T.equal(registry.faction_looters.mobile.activity,
    PNC.FactionConstants.MOBILE_ACTIVITY_TRAVELING_TO_SETTLEMENT,
    "departure persists the explicit travel activity")
T.equal(registry.faction_looters.mobile.travel.destination.kind,
    "player_colony",
    "departure persists the selected settlement kind")
T.equal(registry.faction_looters.mobile.lastDepartureAt, 48,
    "departure persists the daily attempt timestamp")
T.equal(groups.faction_looters.state, "ARRIVED",
    "departure supersedes an in-flight ambient road leg")
T.equal(groups.faction_looters.targetLocation, nil,
    "old ambient road target is cleared before settlement travel")
T.equal(traversalStarts, 1,
    "abstract group starts the existing traversal")

local before = updates
local moved = Director.PumpDepartures(48, 1)
T.equal(moved, 0, "a traveling group cannot depart twice in one day")
T.equal(updates, before, "same-day pump does not rewrite traveling state")

registry.faction_trader.mobile.lastDepartureAt = -1
registry.faction_trader_two = {
    id = "faction_trader_two",
    status = "active",
    archetypeID = "trader",
    mobile = {
        active = true,
        controlMode = PNC.FactionConstants.MOBILE_CONTROL_AMBIENT,
        activity = PNC.FactionConstants.MOBILE_ACTIVITY_STREET_ROAMING,
        ambient = {
            objective = PNC.FactionConstants.MOBILE_AMBIENT_ROAD,
        },
        site = {
            id = "community_site_origin",
            home = { x = 100, y = 100, z = 0, radius = 12 },
        },
        lastDepartureAt = -1,
    },
}
local budgetMoved = Director.PumpDepartures(72, 1)
T.equal(budgetMoved, 1, "daily departure budget caps movement")
T.equal(registry.faction_trader_two.mobile.lastDepartureAt, -1,
    "budget overflow keeps the next group's daily chance available")

T.finish("pnc_mobile_departure_smoke")
