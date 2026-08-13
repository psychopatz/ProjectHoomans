-- Transient engine-to-primitive community site discovery.
--
-- Building and square objects are inspected only during this call. Returned
-- values contain serialization-safe coordinates and identifiers exclusively.

if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then
    return
end

PNC = PNC or {}
PNC.CommunitySiteResolver =
    PNC.CommunitySiteResolver or {}

local Resolver = PNC.CommunitySiteResolver
local Constants = PNC.CommunityConstants
local Types = PNC.CommunityTypes
local CommunityMath = PNC.CommunityMath

local function finite(value)
    return CommunityMath.IsFinite(value)
        and tonumber(value) or nil
end

local function invokeNumber(object, methodName)
    if not object or not object[methodName] then return nil end
    local ok
    local value
    ok, value = pcall(object[methodName], object)
    return ok and finite(value) or nil
end

local function invokeBoolean(object, methodName)
    if not object or not object[methodName] then return nil end
    local ok
    local value
    ok, value = pcall(object[methodName], object)
    return ok and value == true or false
end

local function invokeObject(object, methodName)
    if not object or not object[methodName] then return nil end
    local ok
    local value
    ok, value = pcall(object[methodName], object)
    return ok and value or nil
end

local function getSquare(x, y, z)
    local cell = getCell and getCell() or nil
    if not cell or not cell.getGridSquare then return nil end
    return cell:getGridSquare(
        math.floor(tonumber(x) or 0),
        math.floor(tonumber(y) or 0),
        math.floor(tonumber(z) or 0)
    )
end

local function definitionBounds(definition)
    if not definition then return nil end
    local minX = invokeNumber(definition, "getX")
    local minY = invokeNumber(definition, "getY")
    local maxX = invokeNumber(definition, "getX2")
    local maxY = invokeNumber(definition, "getY2")
    if not minX or not minY or not maxX or not maxY then
        return nil
    end
    return {
        minX = minX,
        minY = minY,
        maxX = math.max(minX, maxX - 1),
        maxY = math.max(minY, maxY - 1),
    }
end

local function buildingBounds(building)
    return definitionBounds(
        invokeObject(building, "getDef")
    )
end

local function radiusForBounds(bounds, fallback)
    if not bounds then return fallback end
    local halfWidth = math.max(
        0.5,
        (bounds.maxX - bounds.minX + 1) / 2
    )
    local halfHeight = math.max(
        0.5,
        (bounds.maxY - bounds.minY + 1) / 2
    )
    return CommunityMath.Clamp(
        math.sqrt(
            halfWidth * halfWidth
                + halfHeight * halfHeight
        ) + 2,
        Constants.RADIUS_MIN,
        Constants.RADIUS_MAX,
        fallback
    )
end

function Resolver.DescribeBuildingDefinition(
    definition,
    z,
    options
)
    options = type(options) == "table" and options or {}
    z = finite(z) or 0
    local bounds = definitionBounds(definition)
    if not bounds then return nil, "invalid_building_definition" end
    local home = {
        x = (bounds.minX + bounds.maxX) / 2,
        y = (bounds.minY + bounds.maxY) / 2,
        z = z,
        radius = radiusForBounds(bounds, 12),
    }
    bounds.minZ = z
    bounds.maxZ = z
    local site = {
        kind = "building",
        home = home,
        bounds = bounds,
        createdAt = tonumber(options.createdAt) or 0,
    }
    site.id = PNC.Communities.BuildSiteID(site)
    return Types.NormalizeSite(site, site.id),
        "building_definition"
end

function Resolver.DescribeAt(x, y, z, options)
    options = type(options) == "table" and options or {}
    x = finite(x)
    y = finite(y)
    z = finite(z) or 0
    if not x or not y then return nil, "invalid_position" end
    local square = getSquare(x, y, z)
    if not square then
        if options.siteSpec then
            local normalized = Types.NormalizeSite(
                options.siteSpec,
                options.siteSpec.id
            )
            return normalized,
                normalized and "primitive_site" or "invalid_site"
        end
        return nil, "square_unloaded"
    end
    local building = square.getBuilding
        and square:getBuilding() or nil
    local bounds = buildingBounds(building)
    local kind = bounds and "building" or "radius"
    local home
    if bounds then
        home = {
            x = (bounds.minX + bounds.maxX) / 2,
            y = (bounds.minY + bounds.maxY) / 2,
            z = z,
            radius = radiusForBounds(bounds, 12),
        }
    else
        local radius = CommunityMath.Clamp(
            options.radius,
            Constants.RADIUS_MIN,
            Constants.RADIUS_MAX,
            12
        )
        home = { x = x, y = y, z = z, radius = radius }
        bounds = {
            minX = x - radius,
            minY = y - radius,
            maxX = x + radius,
            maxY = y + radius,
        }
    end
    bounds.minZ = z
    bounds.maxZ = z
    local site = {
        kind = kind,
        home = home,
        bounds = bounds,
        createdAt = tonumber(options.createdAt) or 0,
    }
    site.id = PNC.Communities.BuildSiteID(site)
    return Types.NormalizeSite(site, site.id),
        kind == "building" and "building_found"
            or "radius_fallback"
end

function Resolver.IsSiteLoaded(site)
    local home = type(site) == "table"
        and site.home or nil
    return home ~= nil
        and getSquare(home.x, home.y, home.z) ~= nil
end

local function siteIsAvailable(site)
    if not site then return false end
    local existing = PNC.Communities.GetSite(site.id)
    return existing == nil or existing.status == "vacant"
end

local function listValues(list)
    local output = {}
    if not list then return output end
    local size = invokeNumber(list, "size")
    if size == nil or not list.get then return output end
    size = math.floor(size)
    if size <= 0 then return output end
    local index
    for index = 0, size - 1 do
        local ok
        local value
        ok, value = pcall(list.get, list, index)
        if ok and value then output[#output + 1] = value end
    end
    return output
end

local function definitionContains(definition, roomName)
    if not definition or not definition.containsRoom then
        return false
    end
    local ok
    local result
    ok, result = pcall(
        definition.containsRoom,
        definition,
        roomName
    )
    return ok and result == true
end

local function definitionIsHouse(definition)
    local bedroom = definitionContains(
        definition,
        "bedroom"
    ) or definitionContains(
        definition,
        "bedroom2"
    )
    local kitchen = definitionContains(
        definition,
        "kitchen"
    ) or definitionContains(
        definition,
        "kitchen2"
    )
    local living = definitionContains(
        definition,
        "livingroom"
    ) or definitionContains(
        definition,
        "livingroom2"
    )
    return bedroom and (kitchen or living)
end

function Resolver.IsResidentialDefinition(definition)
    return definitionIsHouse(definition)
end

local function addCandidate(
    candidates,
    seen,
    definition,
    z,
    options,
    assumeHouse
)
    if assumeHouse ~= true
        and not definitionIsHouse(definition)
    then
        return
    end
    local site = Resolver.DescribeBuildingDefinition(
        definition,
        z,
        options
    )
    if site and not seen[site.id]
        and siteIsAvailable(site)
    then
        seen[site.id] = true
        candidates[#candidates + 1] = site
    end
end

local function addLoadedBuildingCandidates(
    candidates,
    seen,
    z,
    options
)
    local cell = getCell and getCell() or nil
    local buildings = cell
        and invokeObject(cell, "getBuildingList") or nil
    for _, building in ipairs(listValues(buildings)) do
        if invokeBoolean(building, "isResidential")
            and not invokeBoolean(building, "isToxic")
        then
            local definition =
                invokeObject(building, "getDef")
            addCandidate(
                candidates,
                seen,
                definition,
                z,
                options,
                true
            )
        end
    end
end

local function randomCandidateIndex(count, options)
    local requested = math.floor(
        tonumber(options.randomIndex) or 0
    )
    if requested >= 1 and requested <= count then
        return requested
    end
    if ZombRand then
        local ok
        local value
        ok, value = pcall(ZombRand, count)
        value = ok and tonumber(value) or nil
        if value then
            return (math.floor(value) % count) + 1
        end
    end
    return 1
end

function Resolver.FindRandomHouse(options)
    options = type(options) == "table" and options or {}
    local candidates = {}
    local seen = {}
    local z = finite(options.z) or 0
    local world = getWorld and getWorld() or nil
    local metaGrid = world
        and invokeObject(world, "getMetaGrid") or nil
    local definitions = metaGrid
        and invokeObject(metaGrid, "getBuildings") or nil
    for _, definition in ipairs(listValues(definitions)) do
        addCandidate(
            candidates,
            seen,
            definition,
            z,
            options
        )
    end
    if #candidates == 0 then
        addLoadedBuildingCandidates(
            candidates,
            seen,
            z,
            options
        )
    end
    table.sort(candidates, function(left, right)
        return left.id < right.id
    end)
    if #candidates == 0 then
        return nil, "no_available_house"
    end
    return candidates[
        randomCandidateIndex(#candidates, options)
    ], "random_house_found"
end

function Resolver.FindAvailableNear(x, y, z, options)
    options = type(options) == "table" and options or {}
    local origin, originReason = Resolver.DescribeAt(
        x,
        y,
        z,
        options
    )
    if origin and origin.kind == "building"
        and siteIsAvailable(origin)
    then
        return origin, originReason
    end
    local maximum = math.max(
        0,
        math.min(
            160,
            math.floor(tonumber(options.searchRadius) or 80)
        )
    )
    local step = math.max(
        1,
        math.min(
            8,
            math.floor(tonumber(options.searchStep) or 3)
        )
    )
    local centerX = math.floor(tonumber(x) or 0)
    local centerY = math.floor(tonumber(y) or 0)
    local seen = {}
    if origin then seen[origin.id] = true end
    local radius
    local offset
    local candidate
    for radius = step, maximum, step do
        for offset = -radius, radius, step do
            local points = {
                { centerX + offset, centerY - radius },
                { centerX + offset, centerY + radius },
                { centerX - radius, centerY + offset },
                { centerX + radius, centerY + offset },
            }
            for _, point in ipairs(points) do
                candidate = Resolver.DescribeAt(
                    point[1],
                    point[2],
                    z,
                    options
                )
                if candidate
                    and candidate.kind == "building"
                    and not seen[candidate.id]
                then
                    seen[candidate.id] = true
                    if siteIsAvailable(candidate) then
                        return candidate,
                            "nearby_building_found"
                    end
                end
            end
        end
    end
    if origin and origin.kind == "radius"
        and siteIsAvailable(origin)
    then
        return origin, originReason
    end
    return nil, "no_available_loaded_site"
end

local function pointIsUsable(site, x, y, z)
    local square = getSquare(x, y, z)
    if not square then return false end
    if square.isFree and not square:isFree(false) then
        return false
    end
    if site.kind == "building" and square.getBuilding
        and not square:getBuilding()
    then
        return false
    end
    return true
end

function Resolver.FindSpawnPoints(site, count)
    local output = {}
    site = type(site) == "table" and site or {}
    local home = site.home or {}
    local bounds = site.bounds or {}
    count = math.max(
        1,
        math.min(
            Constants.GROUP_SIZE_MAX,
            math.floor(tonumber(count)
                or Constants.GROUP_SIZE_DEFAULT)
        )
    )
    local minX = math.floor(
        tonumber(bounds.minX) or tonumber(home.x) or 0
    )
    local maxX = math.floor(
        tonumber(bounds.maxX) or tonumber(home.x) or 0
    )
    local minY = math.floor(
        tonumber(bounds.minY) or tonumber(home.y) or 0
    )
    local maxY = math.floor(
        tonumber(bounds.maxY) or tonumber(home.y) or 0
    )
    local z = math.floor(tonumber(home.z) or 0)
    local x
    local y
    if Resolver.IsSiteLoaded(site) then
        for y = minY, maxY do
            for x = minX, maxX do
                if #output < count
                    and pointIsUsable(site, x, y, z)
                then
                    output[#output + 1] = {
                        x = x + 0.5,
                        y = y + 0.5,
                        z = z,
                    }
                end
            end
        end
    end
    local offsets = {
        { 0, 0 }, { 1, 0 }, { -1, 0 },
        { 0, 1 }, { 0, -1 }, { 1, 1 },
        { -1, 1 }, { 1, -1 }, { -1, -1 },
        { 2, 0 }, { -2, 0 }, { 0, 2 },
        { 0, -2 },
    }
    local index = 1
    while #output < count do
        local offset = offsets[
            ((index - 1) % #offsets) + 1
        ]
        local ring = math.floor(
            (index - 1) / #offsets
        ) + 1
        output[#output + 1] = {
            x = (tonumber(home.x) or 0)
                + offset[1] * ring,
            y = (tonumber(home.y) or 0)
                + offset[2] * ring,
            z = z,
        }
        index = index + 1
    end
    return output
end

return Resolver
