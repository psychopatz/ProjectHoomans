local T = require "tests/support/test"

local ROOT =
    T.path("ProjectHoomans", "shared", "PNC/Core/")
local SERVER =
    T.path("ProjectHoomans", "server", "PNC/")

function isClient() return false end
function isServer() return true end

PNC = {}
T.load(ROOT .. "Base/PNC_Core.lua")
T.load(ROOT .. "Relationships/PNC_EntityRef.lua")
T.load(ROOT .. "Communities/PNC_CommunityConstants.lua")
T.load(ROOT .. "Communities/PNC_CommunityProfiles.lua")
T.load(ROOT .. "Communities/PNC_CommunityMath.lua")
T.load(ROOT .. "Communities/PNC_CommunityTypes.lua")

local function definition(minX, minY, maxX, maxY)
    return {
        getX = function() return minX end,
        getY = function() return minY end,
        getX2 = function() return maxX + 1 end,
        getY2 = function() return maxY + 1 end,
        containsRoom = function(_, roomName)
            return roomName == "bedroom"
                or roomName == "kitchen"
        end,
    }
end

local function building(def)
    return {
        getDef = function() return def end,
    }
end

local firstBuilding = building(definition(0, 0, 4, 4))
local secondBuilding = building(definition(9, 0, 13, 4))
local distantDefinition = definition(1000, 1200, 1008, 1208)

local function buildingAt(x, y)
    if x >= 0 and x <= 4 and y >= 0 and y <= 4 then
        return firstBuilding
    end
    if x >= 9 and x <= 13 and y >= 0 and y <= 4 then
        return secondBuilding
    end
    return nil
end

local cell = {}
function cell:getGridSquare(x, y, z)
    if z ~= 0 or x < -20 or x > 20
        or y < -20 or y > 20
    then
        return nil
    end
    local found = buildingAt(x, y)
    return {
        getBuilding = function() return found end,
        isFree = function() return true end,
    }
end
function getCell() return cell end

local metaDefinitions = {
    firstBuilding:getDef(),
    distantDefinition,
}
local metaList = {
    size = function() return #metaDefinitions end,
    get = function(_, index)
        return metaDefinitions[index + 1]
    end,
}
function getWorld()
    return {
        getMetaGrid = function()
            return {
                getBuildings = function()
                    return metaList
                end,
            }
        end,
    }
end

local occupiedID
PNC.Communities = {
    BuildSiteID = function(site)
        local bounds = site.bounds
        return "community_site_building_"
            .. tostring(bounds.minX) .. "_"
            .. tostring(bounds.minY) .. "_"
            .. tostring(bounds.maxX) .. "_"
            .. tostring(bounds.maxY)
    end,
    GetSite = function(siteID)
        if siteID == occupiedID then
            return { id = siteID, status = "occupied" }
        end
        return nil
    end,
}

T.load(SERVER .. "PNC_CommunitySiteResolver.lua")

local first = PNC.CommunitySiteResolver.DescribeAt(
    2,
    2,
    0,
    { createdAt = 10 }
)
T.equal(first.kind, "building", "building detected")
T.equal(first.bounds.minX, 0, "first min x")
T.equal(first.bounds.maxX, 4, "first max x")
T.equal(first.home.x, 2, "building center x")
T.equal(first.building, nil,
    "engine building is not retained")
occupiedID = first.id

local available, reason =
    PNC.CommunitySiteResolver.FindAvailableNear(
        2,
        2,
        0,
        {
            createdAt = 10,
            searchRadius = 16,
            searchStep = 1,
        }
    )
T.equal(reason, "nearby_building_found",
    "nearby allocation reason")
T.equal(available.kind, "building",
    "nearby building selected")
T.equal(available.bounds.minX, 9,
    "occupied building skipped")
T.equal(available.bounds.maxX, 13,
    "second building bounds")
T.truthy(available.id ~= occupiedID,
    "distinct stable site ID")

local randomHouse, randomReason =
    PNC.CommunitySiteResolver.FindRandomHouse({
        createdAt = 11,
        randomIndex = 1,
    })
T.equal(randomReason, "random_house_found",
    "random house allocation reason")
T.equal(randomHouse.bounds.minX, 1000,
    "occupied house skipped during world scan")
T.equal(
    PNC.CommunitySiteResolver.IsSiteLoaded(randomHouse),
    false,
    "unloaded meta-grid house remains primitive"
)

local points =
    PNC.CommunitySiteResolver.FindSpawnPoints(
        available,
        4
    )
T.equal(#points, 4, "four spawn points")
for _, point in ipairs(points) do
    T.truthy(
        point.x >= 9 and point.x <= 14
            and point.y >= 0 and point.y <= 5,
        "spawn point inside loaded building"
    )
end
T.finish("pnc_community_site_resolver_smoke")

T.finish("pnc_community_site_resolver_smoke")
