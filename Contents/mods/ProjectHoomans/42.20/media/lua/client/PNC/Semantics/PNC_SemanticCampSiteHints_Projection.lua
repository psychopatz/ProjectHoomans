-- Convert bounded room and campfire observations into primitive hints.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Projection = {}

local function number(value)
    value = tonumber(value)
    if value ~= nil and value == value then return value end
    return nil
end

local function text(value, maximum)
    local result = tostring(value or "")
    if maximum then result = string.sub(result, 1, maximum) end
    return result ~= "" and result or nil
end

function Projection.Room(site, query, timestamp, hints, campSite)
    if not site then return nil end
    local distance = number(site.distance) or 0
    local score = math.max(0.62, math.min(1,
        1 - distance / math.max(8, hints.MAX_RADIUS)))
    return {
        version = hints.VERSION,
        source = "client_loaded_rooms",
        kind = campSite.KIND,
        scope = campSite.SCOPES.ROOM,
        siteScope = campSite.SCOPES.ROOM,
        siteID = text(site.siteID, 128),
        roomID = text(site.roomID, 128),
        buildingID = text(site.buildingID, 128),
        roomType = text(site.roomType, 48),
        roomName = text(site.roomName, 64),
        label = text(site.label, campSite.MAX_LABEL),
        labelKey = text(site.labelKey, 96),
        risk = text(site.risk, 32),
        query = text(query, campSite.MAX_QUERY),
        x = number(site.x),
        y = number(site.y),
        z = number(site.z) or 0,
        minX = site.roomBounds and site.roomBounds.minX,
        minY = site.roomBounds and site.roomBounds.minY,
        maxX = site.roomBounds and site.roomBounds.maxX,
        maxY = site.roomBounds and site.roomBounds.maxY,
        radius = hints.MAX_RADIUS,
        score = score,
        observedAt = timestamp,
    }
end

function Projection.Campfire(
    target, context, origin, timestamp, cell, hints, campSite, worldHints)
    if type(worldHints) ~= "table"
        or type(worldHints.Resolve) ~= "function"
    then
        return nil, "world_hint_unavailable"
    end
    local hint, reason = worldHints.Resolve({
        kind = "campfire",
        category = "CAMPFIRE",
        concept = "CAMPFIRE",
        text = "campfire",
        radius = target and target.radius or 16,
    }, context, { origin = origin, cell = cell })
    if not hint then return nil, reason end
    return {
        version = hints.VERSION,
        source = "client_loaded_campfire",
        kind = "campfire",
        scope = campSite.SCOPES.CAMPFIRE,
        siteScope = campSite.SCOPES.CAMPFIRE,
        campfireID = hint.targetID or hint.resourceKey,
        label = "campfire",
        query = "campfire",
        x = hint.x,
        y = hint.y,
        z = hint.z,
        radius = hint.radius,
        score = hint.score,
        observedAt = timestamp,
    }
end

return Projection
