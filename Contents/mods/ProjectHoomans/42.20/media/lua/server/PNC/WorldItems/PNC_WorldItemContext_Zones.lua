-- Zone & safehouse protection checks for world-item interaction.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local CoreZones = require "PsychopatzCore/World/PC_ZoneRegistry"

PNC = PNC or {}
PNC.WorldItemContext = PNC.WorldItemContext or {}

local Context = PNC.WorldItemContext
Context.Zones = Context.Zones or {}
local Zones = Context.Zones

local CACHE_TTL_MS = 2000
local RESTRICTED_OWNER_TYPES = {
    ["projecthoomans.base"] = true,
    ["projecthoomans.settlement"] = true,
}
local RESTRICTED_ZONE_TYPES = {
    base = true,
    player_base = true,
    safehouse = true,
    settlement = true,
    stockpile = true,
    colony = true,
}

Zones._cache = Zones._cache or {
    safehouses = {},
    communities = {},
    refreshedAt = -1,
}

local function nowMs()
    return PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
end

local function readNum(obj, method)
    if not obj or type(obj[method]) ~= "function" then return nil end
    local ok, value = pcall(obj[method], obj)
    if not ok then return nil end
    local num = tonumber(value)
    if num == nil or num ~= num or num == math.huge or num == -math.huge then
        return nil
    end
    return num
end

local function loadSafehouses()
    local output = {}
    if not SafeHouse or not SafeHouse.getSafehouseList then return output end
    local ok, list = pcall(SafeHouse.getSafehouseList)
    if not ok or not list then return output end
    local count = list.size and list:size() or #list
    for index = 0, count - 1 do
        local safehouse = list.get and list:get(index) or list[index + 1]
        local sx = readNum(safehouse, "getX")
        local sy = readNum(safehouse, "getY")
        local sw = readNum(safehouse, "getW")
        local sh = readNum(safehouse, "getH")
        if sx and sy and sw and sh and sw > 0 and sh > 0 then
            output[#output + 1] = {
                minX = sx,
                minY = sy,
                maxX = sx + sw - 1,
                maxY = sy + sh - 1,
            }
        end
    end
    return output
end

local function loadCommunityBounds()
    local output = {}
    local list = PNC.Communities and PNC.Communities.List
        and PNC.Communities.List() or nil
    if type(list) ~= "table" then return output end
    for index = 1, #list do
        local community = list[index]
        if community and community.status == "active" then
            local site = community.site
            local bounds = site and site.bounds or nil
            local home = site and site.home or community.home
            if bounds and tonumber(bounds.minX) and tonumber(bounds.maxX) then
                output[#output + 1] = {
                    minX = math.floor(tonumber(bounds.minX)),
                    minY = math.floor(tonumber(bounds.minY)),
                    maxX = math.floor(tonumber(bounds.maxX)),
                    maxY = math.floor(tonumber(bounds.maxY)),
                    minZ = math.floor(tonumber(bounds.minZ) or 0),
                    maxZ = math.floor(tonumber(bounds.maxZ) or 0),
                }
            elseif home and tonumber(home.x) and tonumber(home.y) then
                local radius = math.max(1, math.floor(tonumber(home.radius) or 1))
                local hx = math.floor(tonumber(home.x))
                local hy = math.floor(tonumber(home.y))
                local hz = math.floor(tonumber(home.z) or 0)
                output[#output + 1] = {
                    minX = hx - radius,
                    minY = hy - radius,
                    maxX = hx + radius,
                    maxY = hy + radius,
                    minZ = hz,
                    maxZ = hz,
                }
            end
        end
    end
    return output
end

local function ensureCache(now)
    local cache = Zones._cache
    if cache.refreshedAt >= 0 and (now - cache.refreshedAt) < CACHE_TTL_MS then
        return cache
    end
    cache.safehouses = loadSafehouses()
    cache.communities = loadCommunityBounds()
    cache.refreshedAt = now
    return cache
end

function Zones.InvalidateCache()
    Zones._cache.refreshedAt = -1
    Zones._cache.safehouses = {}
    Zones._cache.communities = {}
end

local function isCoreZoneRestricted(zone)
    if type(zone) ~= "table" then return false end
    if RESTRICTED_OWNER_TYPES[tostring(zone.ownerType or "")] then
        return true
    end
    if RESTRICTED_ZONE_TYPES[tostring(zone.type or "")] then
        return true
    end
    return false
end

function Zones.IsRestrictedSquare(x, y, z, options, square)
    if type(options) == "table"
        and (options.allowRestrictedZones == true or options.allowTheft == true)
    then
        return false, nil
    end
    x = math.floor(tonumber(x) or 0)
    y = math.floor(tonumber(y) or 0)
    z = math.floor(tonumber(z) or 0)

    if square and SafeHouse and SafeHouse.getSafeHouse then
        local ok, sh = pcall(SafeHouse.getSafeHouse, square)
        if ok and sh ~= nil then
            return true, "safehouse"
        end
    end

    local cache = ensureCache(nowMs())
    local safehouses = cache.safehouses
    for index = 1, #safehouses do
        local box = safehouses[index]
        if x >= box.minX and x <= box.maxX and y >= box.minY and y <= box.maxY then
            return true, "safehouse"
        end
    end

    if CoreZones and CoreZones.queryPoint then
        local hits = CoreZones.queryPoint(x, y, z)
        if type(hits) == "table" then
            for index = 1, #hits do
                if isCoreZoneRestricted(hits[index]) then
                    return true, "player_base_zone"
                end
            end
        end
    end

    local communities = cache.communities
    for index = 1, #communities do
        local box = communities[index]
        if x >= box.minX and x <= box.maxX and y >= box.minY and y <= box.maxY
            and z >= (box.minZ or z) and z <= (box.maxZ or z)
        then
            return true, "settlement_zone"
        end
    end

    return false, nil
end

Context.IsRestrictedSquare = Zones.IsRestrictedSquare

return Zones
