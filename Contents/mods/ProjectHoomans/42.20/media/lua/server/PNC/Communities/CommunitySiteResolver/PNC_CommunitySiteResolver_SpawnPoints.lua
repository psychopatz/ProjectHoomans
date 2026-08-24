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

function H.PointIsUsable(site, x, y, z)
    local square = H.GetSquare(x, y, z)
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
                    and H.PointIsUsable(site, x, y, z)
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

