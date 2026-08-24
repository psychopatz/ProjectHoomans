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

function Resolver.FindRandomHouse(options)
    options = type(options) == "table" and options or {}
    local candidates = {}
    local seen = {}
    local z = H.Finite(options.z) or 0
    local world = getWorld and getWorld() or nil
    local metaGrid = world
        and H.InvokeObject(world, "getMetaGrid") or nil
    local definitions = metaGrid
        and H.InvokeObject(metaGrid, "getBuildings") or nil
    for _, definition in ipairs(H.ListValues(definitions)) do
        H.AddCandidate(
            candidates,
            seen,
            definition,
            z,
            options
        )
    end
    if #candidates == 0 then
        H.AddLoadedBuildingCandidates(
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
        H.RandomCandidateIndex(#candidates, options)
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
        and H.SiteIsAvailable(origin)
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
                    if H.SiteIsAvailable(candidate) then
                        return candidate,
                            "nearby_building_found"
                    end
                end
            end
        end
    end
    if origin and origin.kind == "radius"
        and H.SiteIsAvailable(origin)
    then
        return origin, originReason
    end
    return nil, "no_available_loaded_site"
end

