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

function H.Finite(value)
    return CommunityMath.IsFinite(value)
        and tonumber(value) or nil
end

function H.InvokeNumber(object, methodName)
    if not object or not object[methodName] then return nil end
    local ok
    local value
    ok, value = pcall(object[methodName], object)
    return ok and H.Finite(value) or nil
end

function H.InvokeBoolean(object, methodName)
    if not object or not object[methodName] then return nil end
    local ok
    local value
    ok, value = pcall(object[methodName], object)
    return ok and value == true or false
end

function H.InvokeObject(object, methodName)
    if not object or not object[methodName] then return nil end
    local ok
    local value
    ok, value = pcall(object[methodName], object)
    return ok and value or nil
end

function H.GetSquare(x, y, z)
    local cell = getCell and getCell() or nil
    if not cell or not cell.getGridSquare then return nil end
    return cell:getGridSquare(
        math.floor(tonumber(x) or 0),
        math.floor(tonumber(y) or 0),
        math.floor(tonumber(z) or 0)
    )
end

function H.DefinitionBounds(definition)
    if not definition then return nil end
    local minX = H.InvokeNumber(definition, "getX")
    local minY = H.InvokeNumber(definition, "getY")
    local maxX = H.InvokeNumber(definition, "getX2")
    local maxY = H.InvokeNumber(definition, "getY2")
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

function H.BuildingBounds(building)
    return H.DefinitionBounds(
        H.InvokeObject(building, "getDef")
    )
end

function H.RadiusForBounds(bounds, fallback)
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

