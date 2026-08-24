if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Validation = PNC.BaseValidationService
local H = Validation.Internal
local GridRegion = require "PsychopatzCore/World/PC_GridRegion"
local Zones = require "PsychopatzCore/World/PC_ZoneRegistry"
local Definitions = PNC.SettlementDefinitions

function H.RectangleRegion(minX, minY, maxX, maxY, minZ, maxZ)
    local region = { levels = {} }
    local z
    for z = math.floor(tonumber(minZ) or 0),
        math.floor(tonumber(maxZ) or tonumber(minZ) or 0)
    do
        local rows = {}
        local y
        for y = math.floor(tonumber(minY) or 0),
            math.floor(tonumber(maxY) or tonumber(minY) or 0)
        do
            rows[y] = {
                math.floor(tonumber(minX) or 0),
                math.floor(tonumber(maxX) or tonumber(minX) or 0),
            }
        end
        region.levels[z] = { rows = rows }
    end
    return GridRegion.normalize(region)
end

function H.ConflictsWithRegisteredBase(footprint, options)
    local exported = Zones.export and Zones.export() or { byID = {} }
    for zoneID, zone in pairs(exported.byID or {}) do
        if zone.ownerType == "projecthoomans.base"
            and GridRegion.intersects(footprint, zone.geometry)
        then
            local base = PNC.SettlementRepository
                and PNC.SettlementRepository.GetBase
                and PNC.SettlementRepository.GetBase(zone.ownerId) or nil
            local sameFaction = base and tostring(base.factionId)
                == tostring(options.factionId or "")
            return sameFaction and "PLAYER_ZONE_OCCUPIED"
                or "NPC_BASE_OCCUPIED", zoneID
        end
    end
    return nil
end

function H.ConflictsWithCommunity(footprint, options)
    local communities = PNC.Communities and PNC.Communities.List
        and PNC.Communities.List() or {}
    for _, community in ipairs(communities) do
        if community.status == "active"
            and tostring(community.id) ~= tostring(options.colonyId or "")
        then
            local site = community.site
            local home = site and site.home or community.home
            local bounds = site and site.bounds or nil
            local region
            if bounds then
                region = H.RectangleRegion(bounds.minX, bounds.minY,
                    bounds.maxX, bounds.maxY, bounds.minZ, bounds.maxZ)
            elseif home and tonumber(home.x) and tonumber(home.y) then
                local radius = math.max(1, math.floor(tonumber(home.radius) or 1))
                region = H.RectangleRegion(home.x - radius, home.y - radius,
                    home.x + radius, home.y + radius, home.z, home.z)
            end
            if region and GridRegion.intersects(footprint, region) then
                return "NPC_BASE_OCCUPIED", community.id
            end
        end
    end
    return nil
end

function H.SafehouseValue(safehouse, method)
    if not safehouse or not safehouse[method] then return nil end
    local ok, value = pcall(safehouse[method], safehouse)
    return ok and tonumber(value) or nil
end

function H.ConflictsWithSafehouse(footprint)
    if not SafeHouse or not SafeHouse.getSafehouseList then return nil end
    local ok, list = pcall(SafeHouse.getSafehouseList)
    if not ok or not list then return nil end
    local count = list.size and list:size() or #list
    local index
    for index = 0, count - 1 do
        local safehouse = list.get and list:get(index) or list[index + 1]
        local x = H.SafehouseValue(safehouse, "getX")
        local y = H.SafehouseValue(safehouse, "getY")
        local width = H.SafehouseValue(safehouse, "getW")
        local height = H.SafehouseValue(safehouse, "getH")
        if x and y and width and height then
            local region = H.RectangleRegion(x, y, x + width - 1,
                y + height - 1, 0, 0)
            if GridRegion.intersects(footprint, region) then
                return "PLAYER_ZONE_OCCUPIED", tostring(index)
            end
        end
    end
    return nil
end

function Validation.CanCreate(region, options)
    options = type(options) == "table" and options or {}
    local footprint = Validation.ProjectFootprint(region)
    local count = GridRegion.countTiles(footprint)
    if count <= 0 then return H.Result(false, "EMPTY_REGION") end
    if not GridRegion.isConnected(footprint, 4) then
        return H.Result(false, "BASE_DISCONNECTED")
    end
    if count > Definitions.STARTING_TERRITORY then
        return H.Result(false, "BASE_CAPACITY_EXCEEDED", { claimed = count,
            capacity = Definitions.STARTING_TERRITORY })
    end
    local reason, conflictId = H.ConflictsWithRegisteredBase(footprint, options)
    if not reason then
        reason, conflictId = H.ConflictsWithSafehouse(footprint)
    end
    if not reason then
        reason, conflictId = H.ConflictsWithCommunity(footprint, options)
    end
    if reason then
        return H.Result(false, reason, { conflictId = conflictId })
    end
    return H.Result(true, nil, { footprint = footprint, claimed = count })
end
