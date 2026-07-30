-- Pure home-area and numeric helpers. No engine state is read here.

PNC = PNC or {}
PNC.CommunityMath = PNC.CommunityMath or {}

local CommunityMath = PNC.CommunityMath

function CommunityMath.IsFinite(value)
    value = tonumber(value)
    return value ~= nil
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
end

function CommunityMath.Clamp(value, minimum, maximum, fallback)
    if not CommunityMath.IsFinite(value) then
        value = fallback
    end
    value = tonumber(value) or tonumber(fallback) or 0
    if value < minimum then return minimum end
    if value > maximum then return maximum end
    return value
end

function CommunityMath.GetDistanceFromHome(community, x, y, z)
    local home = type(community) == "table"
        and community.home or nil
    if type(home) ~= "table"
        or not CommunityMath.IsFinite(x)
        or not CommunityMath.IsFinite(y)
        or not CommunityMath.IsFinite(z)
    then
        return nil
    end
    local dx = tonumber(x) - tonumber(home.x)
    local dy = tonumber(y) - tonumber(home.y)
    local dz = tonumber(z) - tonumber(home.z)
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function CommunityMath.IsInsideHomeArea(community, x, y, z)
    local distance = CommunityMath.GetDistanceFromHome(
        community,
        x,
        y,
        z
    )
    if distance == nil then return false end
    if math.floor(tonumber(z) or -1)
        ~= math.floor(tonumber(community.home.z) or -2)
    then
        return false
    end
    return distance <= (tonumber(community.home.radius) or 0)
end

return CommunityMath
