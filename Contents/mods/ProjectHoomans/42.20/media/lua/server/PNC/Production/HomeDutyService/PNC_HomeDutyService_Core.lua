if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.HomeDutyService
local H = Service.Internal
local Zones = require "PsychopatzCore/World/PC_ZoneRegistry"
local GridRegion = require "PsychopatzCore/World/PC_GridRegion"

function H.ColonyId(record)
    local affiliation = record and record.affiliation or {}
    return tostring(affiliation.communityID or "")
end

function H.BaseFor(record, baseId)
    if baseId and tostring(baseId) ~= "" then
        return PNC.BaseService and PNC.BaseService.Get(baseId) or nil
    end
    local order = record and record.orderSpec or nil
    local followKind = PNC.Const and PNC.Const.ORDER_FOLLOW or "follow"
    local orderBaseId = order and order.kind == "colony_home"
        and order.baseId or order and order.kind == followKind
        and type(order.homeAnchor) == "table"
        and order.homeAnchor.baseId or nil
    local travelAction = record and record.travel
        and record.travel.arrivalAction or nil
    if not orderBaseId and type(travelAction) == "table"
        and tostring(travelAction.type or "") == "colony_home"
    then
        orderBaseId = travelAction.baseId
    end
    local remembered = record and record.runtime
        and record.runtime.homeBaseId
        or orderBaseId
        or nil
    if remembered and tostring(remembered) ~= "" then
        local base = PNC.BaseService and PNC.BaseService.Get(remembered) or nil
        if base then return base end
    end
    local id = H.ColonyId(record)
    return id ~= "" and PNC.BaseService
        and PNC.BaseService.GetForColony(id) or nil
end

function Service.GetColonyId(record)
    local id = H.ColonyId(record)
    if id ~= "" then return id end
    local base = H.BaseFor(record)
    return base and tostring(base.colonyId or "") or ""
end

local function homeBounds(zone, geometry)
    if zone and type(zone.cachedBounds) == "table" then
        return zone.cachedBounds
    end
    if GridRegion and GridRegion.bounds and geometry then
        local bounds = GridRegion.bounds(geometry)
        if bounds then return bounds end
    end
    return type(geometry) == "table" and geometry or nil
end

local function worldCell(record)
    local body
    if record and PNC.Registry and PNC.Registry.GetLiveZombie then
        body = PNC.Registry.GetLiveZombie(record.id)
    end
    if body and body.getCell then
        local cell = body:getCell()
        if cell and cell.getGridSquare then return cell end
    end
    if getCell then
        local cell = getCell()
        if cell and cell.getGridSquare then return cell end
    end
    return nil
end

-- Return nil when the map square is not currently loaded. Abstract NPCs can
-- legitimately choose a home tile outside the loaded cell; a loaded blocked
-- square, however, must never become a durable home target.
local function homePointUsability(point, cell)
    local square
    local pathInternal
    if not cell then return nil end
    square = cell:getGridSquare(
        math.floor(tonumber(point and point.x) or 0),
        math.floor(tonumber(point and point.y) or 0),
        math.floor(tonumber(point and point.z) or 0)
    )
    if not square then return nil end
    pathInternal = PNC.PathService and PNC.PathService.Internal or nil
    if pathInternal and pathInternal.isSquareWalkable then
        return pathInternal.isSquareWalkable(
            point.x, point.y, point.z) == true
    end
    if square.isSolid and square:isSolid() == true then return false end
    if square.isSolidTrans and square:isSolidTrans() == true then
        return false
    end
    if square.isFree and square:isFree(false) ~= true then return false end
    return true
end

local function betterHomePoint(current, candidate)
    if not candidate then return false end
    if not current then return true end
    if candidate.score ~= current.score then
        return candidate.score < current.score
    end
    return candidate.z < current.z
        or (candidate.z == current.z and candidate.y < current.y)
        or (candidate.z == current.z and candidate.y == current.y
            and candidate.x < current.x)
end

local function normalizeHomeAnchor(source, defaultBaseId)
    if type(source) ~= "table" then return nil end
    local x, y = tonumber(source.x), tonumber(source.y)
    if not x or not y then return nil end
    local baseId = source.baseId or defaultBaseId
    return {
        baseId = baseId ~= nil and tostring(baseId) or nil,
        x = x,
        y = y,
        z = tonumber(source.z) or 0,
        radius = math.max(1, tonumber(source.radius) or 3),
        homeZoneId = source.homeZoneId ~= nil
            and tostring(source.homeZoneId) or nil,
        stockpileNodeId = source.stockpileNodeId ~= nil
            and tostring(source.stockpileNodeId) or nil,
    }
end

local function homeAnchorSource(record)
    local order = record and record.orderSpec or nil
    local followKind = PNC.Const and PNC.Const.ORDER_FOLLOW or "follow"
    if type(order) == "table"
        and tostring(order.kind or "") == "colony_home"
    then
        return order, false
    end
    if type(order) == "table"
        and tostring(order.kind or "") == tostring(followKind)
        and type(order.homeAnchor) == "table"
    then
        return order.homeAnchor, true
    end
    local action = record and record.travel
        and record.travel.arrivalAction or nil
    if type(action) == "table"
        and tostring(action.type or "") == "colony_home"
    then
        return action, true
    end
    return nil, false
end

local function nearestStockpileNode(record, base, origin)
    local service = PNC.StockpileAccessService
    if not service or not service.FindNearest or not base then
        return nil
    end
    return service.FindNearest(
        base.id,
        tonumber(origin and origin.x) or tonumber(record and record.x) or 0,
        tonumber(origin and origin.y) or tonumber(record and record.y) or 0,
        tonumber(origin and origin.z) or tonumber(record and record.z) or 0
    )
end

function H.HomeAnchorInZone(record, base)
    local order = record and record.orderSpec or nil
    local zone = base and base.baseZoneId and Zones.get(base.baseZoneId) or nil
    if not zone or not zone.geometry or type(order) ~= "table"
        or order.kind ~= "colony_home"
    then
        return false
    end
    local x, y = tonumber(order.x), tonumber(order.y)
    if not x or not y or not GridRegion.containsXY then return false end
    -- Orders written before the access-point anchor was persisted may still
    -- contain the old zone-center destination. Let the normal home command
    -- repair that legacy in-memory state when an explicit access node exists.
    if order.stockpileNodeId == nil
        and nearestStockpileNode(record, base) ~= nil
    then
        return false
    end
    return GridRegion.containsXY(zone.geometry, math.floor(x), math.floor(y))
end

function H.ZoneInteriorPoint(record, base)
    local zone = base and base.baseZoneId and Zones.get(base.baseZoneId) or nil
    local geometry = zone and zone.geometry or nil
    if not geometry then return nil end

    local bounds = homeBounds(zone, geometry) or {}
    local minX, maxX = tonumber(bounds.minX), tonumber(bounds.maxX)
    local minY, maxY = tonumber(bounds.minY), tonumber(bounds.maxY)
    local targetZ = tonumber(record and record.z)
        or tonumber(bounds.minZ) or tonumber(bounds.z) or 0
    local centerX = minX and maxX and (minX + maxX) / 2 or 0
    local centerY = minY and maxY and (minY + maxY) / 2 or 0
    local bestUsable
    local bestUnknown
    local levels = geometry.levels
    local cell = worldCell(record)

    -- Base zones are sparse span maps, so choose the valid tile closest to
    -- the zone's center instead of using the center of its bounding box.
    -- This keeps irregular or disconnected zones inside their real geometry.
    if type(levels) == "table" then
        for zKey, level in pairs(levels) do
            local z = tonumber(zKey) or tonumber(level and level.z) or targetZ
            local rows = type(level) == "table" and (level.rows or level) or nil
            for yKey, spans in pairs(rows or {}) do
                local y = tonumber(yKey)
                if y and type(spans) == "table" then
                    for index = 1, #spans, 2 do
                        local first = tonumber(spans[index])
                        local last = tonumber(spans[index + 1])
                        if first and last and first <= last then
                            local x = math.floor((first + last) / 2)
                            local dx, dy = x - centerX, y - centerY
                            local score = dx * dx + dy * dy
                                + math.abs(z - targetZ) * 1000000
                            local candidate = {
                                x = x, y = y, z = z, score = score,
                            }
                            local usability = homePointUsability(
                                candidate, cell)
                            if usability == true
                                and betterHomePoint(bestUsable, candidate)
                            then
                                bestUsable = candidate
                            elseif usability == nil
                                and betterHomePoint(bestUnknown, candidate)
                            then
                                bestUnknown = candidate
                            end
                        end
                    end
                end
            end
        end
    end

    local best = bestUsable or bestUnknown
    if best then
        return { x = best.x, y = best.y, z = best.z, radius = 3,
            homeZoneId = base.baseZoneId }
    end
    if type(levels) == "table" then
        return nil, "HOME_LOCATION_BLOCKED"
    end

    -- Keep a compatibility fallback for older test/save geometry that only
    -- exposed bounds. Production zones use the span-map branch above.
    if minX and maxX and minY and maxY then
        local x = math.floor((minX + maxX) / 2)
        local y = math.floor((minY + maxY) / 2)
        if not GridRegion.containsXY
            or GridRegion.containsXY(geometry, x, y)
        then
            return { x = x, y = y, z = targetZ, radius = 3,
                homeZoneId = base.baseZoneId }
        end
    end
    return nil
end

local function durableHomePoint(record, base)
    local source, preserved = homeAnchorSource(record)
    local x, y, z
    local inside
    local baseId
    if type(source) ~= "table" then return nil end
    baseId = source.baseId
    if baseId ~= nil
        and tostring(baseId) ~= tostring(base and base.id or "")
    then
        return nil
    end
    x, y = tonumber(source.x), tonumber(source.y)
    z = tonumber(source.z) or tonumber(record and record.z) or 0
    if not x or not y then return nil end
    local zone = base and base.baseZoneId and Zones.get(base.baseZoneId) or nil
    local geometry = zone and zone.geometry or nil
    if not geometry then return nil end
    if GridRegion.containsPoint then
        inside = GridRegion.containsPoint(geometry, x, y, z)
    elseif GridRegion.containsXY then
        inside = GridRegion.containsXY(geometry, math.floor(x), math.floor(y))
    end
    if inside ~= true then return nil end
    return {
        x = x,
        y = y,
        z = z,
        radius = math.max(1, tonumber(source.radius) or 3),
        homeZoneId = base.baseZoneId,
        stockpileNodeId = source.stockpileNodeId,
        preservedHomeAnchor = preserved == true,
    }
end

function H.HomePoint(record, base)
    local node
    local remembered
    local order = record and record.orderSpec or nil
    local followKind = PNC.Const and PNC.Const.ORDER_FOLLOW or "follow"
    local legacyFollow = type(order) == "table"
        and tostring(order.kind or "") == tostring(followKind)
        and type(order.homeAnchor) ~= "table"
    local stableOrigin
    if not base then return nil, "BASE_NOT_FOUND" end
    -- The arrival order is the durable home/facing anchor. Reusing it keeps
    -- load/reconciliation ticks from selecting a new geometric point and
    -- preserves an existing save without migration.
    remembered = durableHomePoint(record, base)
    if remembered
        and (remembered.preservedHomeAnchor == true
            or remembered.stockpileNodeId ~= nil)
    then
        return remembered
    end
    if legacyFollow and H.ZoneInteriorPoint then
        -- Older follow orders predate the durable anchor. Resolve those saves
        -- from the base-zone geometry, never from the NPC's remote position.
        stableOrigin = H.ZoneInteriorPoint(record, base)
    end
    node = nearestStockpileNode(record, base, stableOrigin)
    if remembered and node == nil then return remembered end
    if node and tonumber(node.x) and tonumber(node.y) then
        -- A stockpile access node is an explicit walkable/facing point. It
        -- is preferable to a bounding-box center, which may be an interior
        -- tile with no usable approach or may vary as zone geometry changes.
        return {
            x = tonumber(node.x),
            y = tonumber(node.y),
            z = tonumber(node.z) or 0,
            radius = math.max(1, tonumber(node.radius) or 2),
            homeZoneId = base.baseZoneId,
            stockpileNodeId = node.id,
        }
    end
    if remembered then return remembered end
    local zonePoint, zoneReason = H.ZoneInteriorPoint(record, base)
    if zonePoint then
        -- Keep the ID for existing recovery/debug consumers, but never use
        -- the stockpile's coordinates as the NPC's home/idle destination.
        zonePoint.stockpileNodeId = node and node.id or nil
        return zonePoint
    end
    if zoneReason then return nil, zoneReason end
    local snapshot = PNC.BaseService and PNC.BaseService.BuildSnapshot
        and PNC.BaseService.BuildSnapshot(base) or nil
    local bounds = snapshot and snapshot.geometry
        and snapshot.geometry.bounds or nil
    if not bounds then return nil, "HOME_LOCATION_MISSING" end
    return {
        x = math.floor(((tonumber(bounds.minX) or 0)
            + (tonumber(bounds.maxX) or 0)) / 2),
        y = math.floor(((tonumber(bounds.minY) or 0)
            + (tonumber(bounds.maxY) or 0)) / 2),
        z = tonumber(bounds.z) or tonumber(record and record.z) or 0,
        radius = 3,
    }
end

function Service.EnsureHomeAnchor(record, baseId, reason)
    if not record or record.alive == false then
        return false, "NPC_MISSING"
    end
    local base = H.BaseFor(record, baseId)
    if not base then return false, "BASE_NOT_FOUND" end
    -- The durable return journey remains authoritative until its arrival
    -- action runs, even if the live body has already crossed into the base
    -- zone. This also repairs a stale colony_home order before AtHome freezes
    -- the movement lane.
    if Service.IsReturningHome(record, base.id) and Service.SendHome then
        return Service.SendHome(record, base.id, reason, {
            forceDestination = true,
        })
    end
    local atHome = Service.IsAtHome(record, base.id)
    if atHome and H.HomeAnchorInZone(record, base) then
        -- The current position and the durable anchor are already valid. Do
        -- not rebuild the zone point on every idle behavior tick.
        return true, "AT_HOME"
    end
    -- A return journey that failed leaves a bounded cooldown behind so this
    -- idle behavior tick does not create a fresh doomed journey every tick.
    local retryAt = tonumber(record.runtime and record.runtime.homeRetryAt)
    if retryAt and (PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0)
        < retryAt
    then
        return false, "HOME_RETRY_COOLDOWN"
    end

    -- This covers both NPCs outside the base and old saves whose durable
    -- colony_home anchor still points at an edge stockpile. The command's
    -- optional force flag makes the latter walk to the new zone anchor even
    -- though its current tile is technically inside the zone.
    if Service.SendHome then
        return Service.SendHome(record, base.id, reason, {
            forceDestination = true,
        })
    end
    return false, "HOME_ROUTING_UNAVAILABLE"
end

function H.SetAtHome(record, base, point)
    if Service.IsFollowing and Service.IsFollowing(record) then
        return false, "FOLLOWING_PLAYER"
    end
    record.runtime = record.runtime or {}
    record.runtime.homeState = "AT_HOME"
    record.runtime.homeBaseId = base.id
    record.runtime.homeJourneyId = nil
    local order = {
        kind = "colony_home", baseId = base.id,
        x = point.x, y = point.y, z = point.z,
        radius = point.radius,
        stockpileNodeId = point.stockpileNodeId,
    }
    if PNC.OrderSystem and PNC.OrderSystem.SetOrder then
        PNC.OrderSystem.SetOrder(record, order)
    else
        record.orderSpec = order
    end
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "home_state")
    end
    return true, "AT_HOME"
end

function H.SetFollowing(record, username, onlineID)
    local source = homeAnchorSource(record)
    local runtime = record and record.runtime or nil
    local homeAnchor = normalizeHomeAnchor(
        source,
        runtime and runtime.homeBaseId or nil
    )
    if not homeAnchor then
        local base = H.BaseFor(record, runtime and runtime.homeBaseId or nil)
        local point = base and H.HomePoint(record, base) or nil
        if point then
            homeAnchor = normalizeHomeAnchor(point, base.id)
        end
    end
    if PNC.Travel and PNC.Travel.Service
        and type(PNC.Travel.Service.Supersede) == "function"
    then
        local superseded, supersedeReason = PNC.Travel.Service.Supersede(
            record, "follow_player_requested")
        if superseded == false and supersedeReason ~= "journey_missing" then
            return false, supersedeReason or "TRAVEL_SUPERSEDE_FAILED"
        end
    end
    record.runtime = record.runtime or {}
    record.runtime.homeState = "AWAY"
    record.runtime.homeJourneyId = nil
    local order = {
        kind = PNC.Const.ORDER_FOLLOW,
        ownerUsername = username,
        ownerOnlineID = onlineID,
        homeAnchor = homeAnchor,
    }
    if PNC.OrderSystem and PNC.OrderSystem.SetOrder then
        PNC.OrderSystem.SetOrder(record, order)
    else
        record.orderSpec = order
    end
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "follow_player")
    end
    return true, "FOLLOWING_PLAYER"
end

function Service.GetBase(record, baseId)
    return H.BaseFor(record, baseId)
end

function Service.GetHomePoint(record, baseId)
    local base = H.BaseFor(record, baseId)
    local point, reason = H.HomePoint(record, base)
    return point, reason, base
end

return Service
