-- Transient engine-to-primitive community site discovery.
--
-- Building and square objects are inspected only during this call. Returned
-- values contain serialization-safe coordinates and identifiers exclusively.

if isClient and isClient() and (not isServer or not isServer()) then
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

local function getSquare(x, y, z)
    local cell = getCell and getCell() or nil
    if not cell or not cell.getGridSquare then return nil end
    return cell:getGridSquare(
        math.floor(tonumber(x) or 0),
        math.floor(tonumber(y) or 0),
        math.floor(tonumber(z) or 0)
    )
end

local function buildingBounds(building)
    local definition
    local ok
    if building and building.getDef then
        ok, definition = pcall(
            building.getDef,
            building
        )
        if not ok then definition = nil end
    end
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
