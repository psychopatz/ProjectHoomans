local T = require "tests/support/test"

local SHARED = T.path("ProjectHoomans", "shared", "PNC/Core/")
local SERVER = T.path("ProjectHoomans", "server", "PNC/")

local at = 48
local registry = {}
local locations = {}
local traversalStarts = 0
local scorerCalls = 0

function isServer() return true end
function isClient() return false end
function getGameTime()
    return { getWorldAgeHours = function() return at end }
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

local function copy(value)
    return PNC.Core.DeepCopy(value)
end

local function addLocation(id, site)
    local location = {
        id = id,
        type = "SETTLEMENT",
        x = site.home.x,
        y = site.home.y,
        z = site.home.z,
        tags = site.tags,
        sourceSite = site,
    }
    locations[id] = location
    return location
end

PNC.Communities = {
    ListSites = function()
        return {
            {
                id = "site_ai",
                home = { x = 400, y = 400, z = 0, radius = 12 },
                occupantCommunityID = "community_ai",
            },
            {
                id = "site_player",
                home = { x = 220, y = 220, z = 0, radius = 12 },
                occupantCommunityID = "community_player",
            },
            {
                id = "site_hostile",
                home = { x = 120, y = 120, z = 0, radius = 12 },
                occupantCommunityID = "community_hostile",
            },
        }
    end,
    Get = function(id)
        if id == "community_ai" then
            return { id = id, factionID = "faction_ai", status = "active" }
        end
        if id == "community_player" then
            return { id = id, factionID = "faction_player", status = "active" }
        end
        if id == "community_hostile" then
            return { id = id, factionID = "faction_hostile", status = "active" }
        end
        return nil
    end,
}

PNC.AbstractLocations = {
    RegisterSite = function(site)
        return addLocation("aloc_" .. site.id, site), "registered"
    end,
    Get = function(id) return locations[id] end,
}
PNC.SettlementRepository = { State = { bases = {} } }
PNC.BaseService = { BuildSnapshot = function(base)
    return { geometry = base.geometry }
end }

PNC.AbstractGroups = {
    FindByFactionID = function(id)
        return {
            id = "group_" .. id,
            location = { id = "aloc_origin", x = 100, y = 100, z = 0 },
            state = "ARRIVED",
            memberIds = {},
        }
    end,
    HasLiveMembers = function() return false end,
    SetState = function(group, state) group.state = state end,
}
PNC.AbstractGroupManagerInternal = { Touch = function() end }
PNC.AbstractTraversal = {
    Begin = function()
        traversalStarts = traversalStarts + 1
        return true, "travel_started"
    end,
}

local function updateMobile(id, patch)
    local faction = registry[id]
    for key, value in pairs(patch or {}) do
        faction.mobile[key] = copy(value)
    end
    return true, "updated", copy(faction.mobile)
end

PNC.Factions = {
    Registry = { byID = registry },
    Get = function(id) return registry[id] end,
    IsMobileGroup = function(faction)
        return faction and faction.mobile and faction.mobile.active == true
    end,
    UpdateMobileGroup = updateMobile,
}

PNC.MobileSettlementVisitService = {
    IsSettlementVisitEligible = function(faction, target)
        if target.communityID == "community_hostile" then
            return false, "hostile_settlement_relationship"
        end
        return true, "eligible"
    end,
}

registry.faction_caravan = {
    id = "faction_caravan",
    status = "active",
    archetypeID = "trader",
    playerMemberKeys = {},
    mobile = {
        active = true,
        pathMode = PNC.FactionConstants.MOBILE_PATH_RANDOM,
        controlMode = PNC.FactionConstants.MOBILE_CONTROL_STRATEGIC,
        mobilityIntent = PNC.FactionConstants.MOBILE_MOBILITY_INTENT_COMMERCIAL,
        activity = PNC.FactionConstants.MOBILE_ACTIVITY_STREET_ROAMING,
        site = { id = "site_origin", home = { x = 100, y = 100, z = 0 } },
        settlementHistory = {},
    },
}
registry.faction_ai = { id = "faction_ai", status = "active" }
registry.faction_player = {
    id = "faction_player",
    status = "active",
    playerMemberKeys = { player_one = true },
}
registry.faction_hostile = { id = "faction_hostile", status = "active" }

T.load(SERVER .. "Director/MobileGroupDirector/PNC_MobileGroupDirector_Core.lua")
T.load(SERVER .. "Director/MobileGroupDirector/PNC_MobileGroupDirector_DepartureTargets.lua")
T.load(SERVER .. "Director/MobileGroupDirector/PNC_MobileGroupDirector_Departures.lua")
T.load(SERVER .. "Director/PNC_CommercialMobilityService.lua")

local Service = PNC.CommercialMobilityService
local Constants = PNC.FactionConstants

T.truthy(Service.RegisterOpportunityScorer("test_opportunity", function(
    faction, target
)
    scorerCalls = scorerCalls + 1
    return target.communityID == "community_player" and 20 or 0
end), "bounded scorer registration succeeds")

local targets = PNC.MobileGroupDirectorInternal.ResolveSettlementDepartureTargets(
    registry.faction_caravan,
    { commercial = true }
)
local sawPlayer = false
for _, target in ipairs(targets) do
    if target.communityID == "community_player" then sawPlayer = true end
end
T.truthy(sawPlayer,
    "commercial candidates include an unbased player settlement")

local selected, selectedReason, candidates = Service.SelectDestination(
    registry.faction_caravan,
    at
)
T.truthy(selected, selectedReason)
T.equal(selected.communityID, "community_player",
    "Hoomans final choice includes bounded economic opportunity")
T.truthy(#candidates <= Constants.COMMERCIAL_DESTINATION_CANDIDATE_LIMIT,
    "commercial candidate list is bounded")
T.truthy(scorerCalls > 0, "external scorer receives bounded candidates")

local started, startReason = Service.StartCommercialTravel(
    registry.faction_caravan,
    selected,
    at
)
T.truthy(started, startReason)
T.equal(registry.faction_caravan.mobile.travel.purpose,
    Constants.MOBILE_TRAVEL_PURPOSE_SETTLEMENT_VISIT,
    "commercial mobility uses the generic temporary-visit purpose")
T.equal(registry.faction_caravan.mobile.travel.intent,
    Constants.MOBILE_SETTLEMENT_VISIT_INTENT_COMMERCIAL,
    "commercial mobility persists an extensible visit intent")
T.equal(traversalStarts, 1,
    "commercial mobility reuses abstract Hoomans traversal")

registry.faction_caravan.mobile.travel = nil
registry.faction_caravan.mobile.activity =
    Constants.MOBILE_ACTIVITY_STREET_ROAMING
registry.faction_caravan.mobile.settlementHistory = {
    {
        communityID = "community_player",
        locationID = "aloc_site_player",
        visitedAt = at,
        cooldownUntil = at + 24,
    },
}
local afterCooldown = Service.SelectDestination(
    registry.faction_caravan,
    at + 1
)
T.truthy(afterCooldown, "cooldown leaves another safe destination")
T.falsy(afterCooldown.communityID == "community_player",
    "recent settlement cooldown prevents immediate ping-pong")

registry.faction_caravan.mobile.settlementHistory = {}
registry.faction_caravan.mobile.travel = nil
registry.faction_caravan.mobile.activity =
    Constants.MOBILE_ACTIVITY_STREET_ROAMING
T.equal(Service.Pump(at + 2, 1), 1,
    "production pump respects its movement budget")

T.finish("pnc_commercial_mobility_smoke")
