if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.CommunitySiteResolver = PNC.CommunitySiteResolver or {}
PNC.CommunitySiteResolverInternal =
    PNC.CommunitySiteResolverInternal or {}

local Resolver = PNC.CommunitySiteResolver
local H = PNC.CommunitySiteResolverInternal
local Constants = PNC.CommunityConstants
local Types = PNC.CommunityTypes
local CommunityMath = PNC.CommunityMath

function Resolver.DescribeBuildingDefinition(
    definition,
    z,
    options
)
    options = type(options) == "table" and options or {}
    z = H.Finite(z) or 0
    local bounds = H.DefinitionBounds(definition)
    if not bounds then return nil, "invalid_building_definition" end
    local home = {
        x = (bounds.minX + bounds.maxX) / 2,
        y = (bounds.minY + bounds.maxY) / 2,
        z = z,
        radius = H.RadiusForBounds(bounds, 12),
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
    x = H.Finite(x)
    y = H.Finite(y)
    z = H.Finite(z) or 0
    if not x or not y then return nil, "invalid_position" end
    local square = H.GetSquare(x, y, z)
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
    local bounds = H.BuildingBounds(building)
    local kind = bounds and "building" or "radius"
    local home
    if bounds then
        home = {
            x = (bounds.minX + bounds.maxX) / 2,
            y = (bounds.minY + bounds.maxY) / 2,
            z = z,
            radius = H.RadiusForBounds(bounds, 12),
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
        and H.GetSquare(home.x, home.y, home.z) ~= nil
end

