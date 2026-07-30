local ROOT =
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

function isClient() return false end
function isServer() return true end

PNC = {}
dofile(ROOT .. "Base/PNC_Core.lua")
dofile(ROOT .. "Relationships/PNC_EntityRef.lua")
dofile(ROOT .. "Communities/PNC_CommunityConstants.lua")
dofile(ROOT .. "Communities/PNC_CommunityProfiles.lua")
dofile(ROOT .. "Communities/PNC_CommunityMath.lua")
dofile(ROOT .. "Communities/PNC_CommunityTypes.lua")

local function definition(minX, minY, maxX, maxY)
    return {
        getX = function() return minX end,
        getY = function() return minY end,
        getX2 = function() return maxX + 1 end,
        getY2 = function() return maxY + 1 end,
    }
end

local function building(def)
    return {
        getDef = function() return def end,
    }
end

local firstBuilding = building(definition(0, 0, 4, 4))
local secondBuilding = building(definition(9, 0, 13, 4))

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

dofile(SERVER .. "PNC_CommunitySiteResolver.lua")

local first = PNC.CommunitySiteResolver.DescribeAt(
    2,
    2,
    0,
    { createdAt = 10 }
)
assertEqual(first.kind, "building", "building detected")
assertEqual(first.bounds.minX, 0, "first min x")
assertEqual(first.bounds.maxX, 4, "first max x")
assertEqual(first.home.x, 2, "building center x")
assertEqual(first.building, nil,
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
assertEqual(reason, "nearby_building_found",
    "nearby allocation reason")
assertEqual(available.kind, "building",
    "nearby building selected")
assertEqual(available.bounds.minX, 9,
    "occupied building skipped")
assertEqual(available.bounds.maxX, 13,
    "second building bounds")
assertTrue(available.id ~= occupiedID,
    "distinct stable site ID")

local points =
    PNC.CommunitySiteResolver.FindSpawnPoints(
        available,
        4
    )
assertEqual(#points, 4, "four spawn points")
for _, point in ipairs(points) do
    assertTrue(
        point.x >= 9 and point.x <= 14
            and point.y >= 0 and point.y <= 5,
        "spawn point inside loaded building"
    )
end

print("pnc_community_site_resolver_smoke: PASS")
