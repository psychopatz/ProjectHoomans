if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local H = PNC and PNC.MobileGroupDirectorInternal
if not H then
    return
end

local Internal = H.Internal
local Deps = Internal and Internal.AmbientTargets
if not Deps then
    return
end

local Constants = PNC.FactionConstants
local Resolver = PNC.CommunitySiteResolver
local Core = PNC.Core
local beginDiagnosticTiming = Deps.beginDiagnosticTiming
local endDiagnosticTiming = Deps.endDiagnosticTiming
local finite = Deps.finite

local function chooseIndex(count)
    if count <= 1 then return 1 end
    if ZombRand then
        local ok, value = pcall(ZombRand, count)
        if ok and tonumber(value) then
            return (math.floor(value) % count) + 1
        end
    end
    return 1
end

local function targetFromSite(site)
    local points = Resolver.FindSpawnPoints(site, 1)
    local point = points[1] or site.home
    return {
        kind = "building",
        siteID = site.id,
        x = finite(point.x, site.home.x),
        y = finite(point.y, site.home.y),
        z = finite(point.z, site.home.z),
        radius = math.max(2, finite(site.home.radius, 8)),
        bounds = Core.DeepCopy(site.bounds),
    }
end

local function shelterTargetIsLocal(mobile, target)
    local home = mobile and mobile.site and mobile.site.home or nil
    local originX = home and tonumber(home.x) or nil
    local originY = home and tonumber(home.y) or nil
    local targetX = target and tonumber(target.x) or nil
    local targetY = target and tonumber(target.y) or nil
    if originX == nil or originY == nil
        or targetX == nil or targetY == nil
    then
        return false
    end
    local searchRadius = math.max(
        0,
        math.min(
            160,
            tonumber(Constants.MOBILE_AMBIENT_SHELTER_SEARCH_RADIUS) or 80
        )
    )
    local targetRadius = math.max(0, tonumber(target.radius) or 0)
    return Core.Distance(originX, originY, targetX, targetY)
        <= searchRadius + targetRadius
end

function H.FindShelterTarget(faction, at, ownershipSnapshot)
    local timingName, timingStart = beginDiagnosticTiming(
        "MobileAmbient.FindShelterTarget"
    )
    local mobile = faction and faction.mobile or {}
    local site = mobile.site or {}
    local snapshot = ownershipSnapshot or H.PlayerOwnershipSnapshot()
    local filter = H.ShelterFilter(snapshot)
    local home = site.home
    local originX = home and tonumber(home.x) or nil
    local originY = home and tonumber(home.y) or nil
    local originZ = home and tonumber(home.z) or 0
    if originX == nil or originY == nil then
        endDiagnosticTiming(timingName, timingStart, "missing_mobile_origin")
        return nil, "missing_mobile_origin"
    end
    local nearTimingName, nearTimingStart = beginDiagnosticTiming(
        "MobileAmbient.FindAvailableNear"
    )
    local selected, reason = Resolver.FindAvailableNear(
        originX,
        originY,
        originZ,
        {
            createdAt = at,
            searchRadius = Constants.MOBILE_AMBIENT_SHELTER_SEARCH_RADIUS,
            searchStep = 8,
            siteFilter = filter,
        }
    )
    endDiagnosticTiming(
        nearTimingName,
        nearTimingStart,
        selected and "selected" or reason
    )
    if not selected or not H.IsValidShelterSite(selected, snapshot) then
        endDiagnosticTiming(
            timingName,
            timingStart,
            reason or "no_valid_shelter"
        )
        return nil, reason or "no_valid_shelter"
    end
    endDiagnosticTiming(timingName, timingStart, "selected")
    return targetFromSite(selected), "shelter_selected"
end

local function invoke(object, method, ...)
    if not object or not object[method] then return nil end
    local ok, value = pcall(object[method], object, ...)
    return ok and value or nil
end

function H.FindRoadTarget(faction)
    local mobile = faction and faction.mobile or {}
    local origin = mobile.site and mobile.site.home or {}
    local world = getWorld and getWorld() or nil
    local metaGrid = invoke(world, "getMetaGrid")
    local list = ArrayList and ArrayList.new and ArrayList.new() or nil
    if not metaGrid or not list or not metaGrid.getZonesIntersecting then
        return nil, "nav_api_unavailable"
    end
    local timingName, timingStart = beginDiagnosticTiming(
        "MobileAmbient.FindRoadTarget"
    )
    local radius = Constants.MOBILE_AMBIENT_ROAD_SEARCH_RADIUS
    local x = math.floor(finite(origin.x, 0) - radius)
    local y = math.floor(finite(origin.y, 0) - radius)
    local width = math.floor(radius * 2)
    local z = math.floor(finite(origin.z, 0))
    local ok = pcall(
        metaGrid.getZonesIntersecting,
        metaGrid,
        x, y, z, width, width, list
    )
    if not ok then
        endDiagnosticTiming(timingName, timingStart, "nav_query_failed")
        return nil, "nav_query_failed"
    end
    local candidates = {}
    local count = list.size and list:size() or #list
    local index
    for index = 0, count - 1 do
        local zone = list.get and list:get(index) or list[index + 1]
        local zoneType = invoke(zone, "getType")
        local zoneX = finite(invoke(zone, "getX"), nil)
        local zoneY = finite(invoke(zone, "getY"), nil)
        local zoneWidth = finite(invoke(zone, "getWidth"), nil)
        local zoneHeight = finite(invoke(zone, "getHeight"), nil)
        if tostring(zoneType or "") == "Nav"
            and zoneX and zoneY and zoneWidth and zoneHeight
            and zoneWidth > 0 and zoneHeight > 0
        then
            candidates[#candidates + 1] = {
                minX = zoneX,
                minY = zoneY,
                maxX = zoneX + zoneWidth - 1,
                maxY = zoneY + zoneHeight - 1,
                z = z,
            }
        end
    end
    if #candidates == 0 then
        endDiagnosticTiming(timingName, timingStart, "no_nav_zone")
        return nil, "no_nav_zone"
    end
    local bounds = candidates[chooseIndex(#candidates)]
    local result = {
        kind = "nav",
        x = (bounds.minX + bounds.maxX) / 2,
        y = (bounds.minY + bounds.maxY) / 2,
        z = bounds.z,
        radius = math.max(4, math.min(
            80,
            math.sqrt(
                ((bounds.maxX - bounds.minX) / 2) ^ 2
                    + ((bounds.maxY - bounds.minY) / 2) ^ 2
            )
        )),
        bounds = bounds,
    }
    endDiagnosticTiming(timingName, timingStart, "nav_selected")
    return result, "nav_selected"
end

Internal.AmbientTargets.shelterTargetIsLocal = shelterTargetIsLocal

return H
