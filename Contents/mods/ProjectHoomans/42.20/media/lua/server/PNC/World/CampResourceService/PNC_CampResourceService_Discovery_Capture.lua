if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.CampResourceService = PNC.CampResourceService or {}

local Service = PNC.CampResourceService
local Internal = Service.Internal or {}
Service.Internal = Internal
local Const = PNC.Const or {}
local CampSite = PNC.Semantics and PNC.Semantics.CampSite
    or require "PNC/Semantics/PNC_SemanticCampSite"
local Geometry = PNC.Semantics and PNC.Semantics.CampSiteGeometry
    or require "PNC/Semantics/PNC_SemanticCampSiteGeometry"
local number = function(value, fallback)
    return Internal.Number(value, fallback)
end
local worldHour = Internal.WorldHour
local addResource = Internal.AddResource

local function snapshotMatches(state, order, radius, campRadius)
    local stateBounds = type(state) == "table"
        and CampSite.NormalizeBounds(state.roomBounds)
    local orderBounds = Internal.RoomBounds(order)
    local scope = Internal.CampScope(order)
    return type(state) == "table"
        and tonumber(state.schemaVersion) == tonumber(Service.SCHEMA_VERSION)
        and tostring(state.campId or "") == tostring(order.campId or "")
        and tonumber(state.anchorX) == tonumber(order.x)
        and tonumber(state.anchorY) == tonumber(order.y)
        and tonumber(state.anchorZ) == tonumber(order.z)
        and tonumber(state.campRadius) == tonumber(campRadius)
        and tonumber(state.resourceRadius) == tonumber(radius)
        and tostring(state.scope or state.siteScope or "") == tostring(scope)
        and tostring(state.zoneID or "") == tostring(order.zoneID or "")
        and (scope ~= CampSite.SCOPES.ROOM
            or (tostring(state.siteID or "") == tostring(order.siteID or "")
                and tostring(state.roomID or "") == tostring(order.roomID or "")
                and tostring(state.buildingID or "")
                    == tostring(order.buildingID or "")
                and stateBounds and orderBounds
                and stateBounds.minX == orderBounds.minX
                and stateBounds.minY == orderBounds.minY
                and stateBounds.maxX == orderBounds.maxX
                and stateBounds.maxY == orderBounds.maxY
                and (stateBounds.z == nil or orderBounds.z == nil
                    or stateBounds.z == orderBounds.z)))
        and (scope ~= CampSite.SCOPES.CAMPFIRE
            or tostring(state.campfireID or "")
                == tostring(order.campfireID or order.siteID or ""))
        and type(state.resources) == "table"
end

function Service.GetCachedSnapshot(record)
    local order = Internal.CampContext(record)
    local entry
    local radius
    local campRadius
    if not order then return nil end
    entry = Internal.CacheEntry(record, order, false)
    if not entry or type(entry.state) ~= "table" then return nil end
    radius, campRadius = Internal.CampDimensions(order)
    if not snapshotMatches(entry.state, order, radius, campRadius) then
        return nil
    end
    return entry.state
end

local function newCapture(entry, record, order, radius, campRadius)
    local scope = Internal.CampScope(order)
    local bounds = Internal.RoomBounds(order)
    local state = {
        schemaVersion = Service.SCHEMA_VERSION,
        campId = tostring(order.campId or "camp:" .. tostring(record.id)),
        anchorX = number(order.x, record.x or 0),
        anchorY = number(order.y, record.y or 0),
        anchorZ = number(order.z, record.z or 0),
        campRadius = campRadius,
        resourceRadius = radius,
        scope = scope,
        siteScope = scope,
        siteID = order.siteID,
        roomID = order.roomID,
        buildingID = order.buildingID,
        roomType = order.roomType,
        roomName = order.roomName,
        roomBounds = bounds,
        campfireID = order.campfireID or order.siteID,
        zoneID = order.zoneID,
        zoneLabel = order.zoneLabel,
        capturedAtWorldHour = worldHour(),
        resources = {},
    }
    local originX = math.floor(state.anchorX)
    local originY = math.floor(state.anchorY)
    local minX = originX - math.floor(radius)
    local minY = originY - math.floor(radius)
    local maxX = originX + math.floor(radius)
    local maxY = originY + math.floor(radius)
    local truncated = false
    if scope == CampSite.SCOPES.ROOM and bounds then
        minX = math.floor(bounds.minX)
        minY = math.floor(bounds.minY)
        maxX = math.floor(bounds.maxX)
        maxY = math.floor(bounds.maxY)
        if (maxX - minX + 1) * (maxY - minY + 1)
            > Service.MAX_ROOM_SCAN_SQUARES
        then
            local side = math.floor(math.sqrt(Service.MAX_ROOM_SCAN_SQUARES))
            minX = math.max(minX, originX - math.floor(side / 2))
            minY = math.max(minY, originY - math.floor(side / 2))
            maxX = math.min(maxX, minX + side - 1)
            maxY = math.min(maxY, minY + side - 1)
            truncated = true
        end
    end
    state.scanTruncated = truncated
    return {
        entry = entry,
        record = record,
        state = state,
        seen = {},
        cell = type(getCell) == "function" and getCell() or nil,
        live = PNC.Registry and PNC.Registry.GetLiveZombie
            and PNC.Registry.GetLiveZombie(record.id) or nil,
        order = order,
        scope = scope,
        radius = radius,
        originX = originX,
        originY = originY,
        originZ = math.floor(state.anchorZ),
        span = math.floor(radius),
        dx = -math.floor(radius),
        dy = -math.floor(radius),
        minX = minX,
        minY = minY,
        maxX = maxX,
        maxY = maxY,
        scanX = minX,
        scanY = minY,
    }
end

local function finishCapture(capture)
    local entry = capture and capture.entry or nil
    local state = capture and capture.state or nil
    local maximum
    if not entry or not state then return nil end
    table.sort(state.resources, function(left, right)
        return tostring(left.resourceKey or "")
            < tostring(right.resourceKey or "")
    end)
    maximum = math.max(1, math.floor(number(
        Const.CAMP_RESOURCE_MAX, 32)))
    while #state.resources > maximum do table.remove(state.resources) end
    entry.state = state
    entry.capture = nil
    entry.lastCaptureAt = Internal.Now()
    if capture.record then capture.record.campState = state end
    -- The resource table remains a runtime cache. Do not mark every camp
    -- member dirty when discovery completes: it is intentionally not saved.
    return state
end

local function pumpCapture(capture, budget)
    local processed = 0
    local limit = math.max(1, math.floor(number(budget, 1)))
    local square
    local dx
    local dy
    local x
    local y
    if not capture then return nil, 0 end
    if not capture.cell
        or type(capture.cell.getGridSquare) ~= "function"
    then
        return finishCapture(capture), 0
    end
    while processed < limit do
        if capture.scope == CampSite.SCOPES.ROOM then
            if capture.scanX > capture.maxX then break end
            x, y = capture.scanX, capture.scanY
            capture.scanY = capture.scanY + 1
            if capture.scanY > capture.maxY then
                capture.scanX = capture.scanX + 1
                capture.scanY = capture.minY
            end
            square = capture.cell:getGridSquare(x, y, capture.originZ)
            if square and Geometry.MatchesRoom
                and not Geometry.MatchesRoom(square, capture.order)
            then
                square = nil
            end
        else
            if capture.dx > capture.span then break end
            dx, dy = capture.dx, capture.dy
            capture.dy = dy + 1
            if capture.dy > capture.span then
                capture.dx = dx + 1
                capture.dy = -capture.span
            end
            x, y = capture.originX + dx, capture.originY + dy
            square = nil
            if dx * dx + dy * dy <= capture.radius * capture.radius then
                square = capture.cell:getGridSquare(x, y, capture.originZ)
            end
        end
        processed = processed + 1
        if square then
            for _, provider in pairs(Service.Providers) do
                provider.CaptureSquare(
                    square,
                    function(resource)
                        addResource(
                            capture.state.resources,
                            capture.seen,
                            resource
                        )
                    end,
                    {
                        record = capture.record,
                        character = capture.live,
                    }
                )
            end
        end
    end
    if (capture.scope == CampSite.SCOPES.ROOM
        and capture.scanX > capture.maxX)
        or (capture.scope ~= CampSite.SCOPES.ROOM
            and capture.dx > capture.span)
    then
        return finishCapture(capture), processed
    end
    return nil, processed
end

local function requestCapture(record, force)
    local order = Internal.CampContext(record)
    local radius
    local campRadius
    local entry
    local legacyState
    local cached
    local now
    local refreshCooldown
    if not order then return nil, "NOT_CAMPED" end
    radius, campRadius = Internal.CampDimensions(order)
    legacyState = record and record.campState or nil
    entry = Service.Attach(record, order)
    cached = entry and entry.state or nil
    -- Older callers can provide a transient state on the record. Adopt it
    -- only in memory and only after the same structural validation as cache.
    if cached and legacyState and legacyState ~= cached
        and not snapshotMatches(legacyState, order, radius, campRadius)
    then
        entry.state = nil
        cached = nil
    end
    if cached and snapshotMatches(cached, order, radius, campRadius) then
        now = Internal.Now()
        refreshCooldown = tonumber(Const.CAMP_RESOURCE_REFRESH_COOLDOWN_MS)
            or 1000
        if force ~= true
            or now - (tonumber(entry.lastCaptureAt) or 0)
                < refreshCooldown
        then
            record.campState = cached
            return cached
        end
    end
    if legacyState and legacyState ~= cached and snapshotMatches(
        legacyState, order, radius, campRadius
    ) then
        entry.state = legacyState
        record.campState = legacyState
        return legacyState
    end
    if entry.capture
        and not snapshotMatches(entry.capture.state, order, radius, campRadius)
    then
        -- Never finish a scan against an obsolete camp anchor.
        entry.capture = nil
        entry.state = nil
    end
    if entry.capture then
        return nil, "CAMP_RESOURCE_CAPTURE_PENDING"
    end
    entry.capture = newCapture(entry, record, order, radius, campRadius)
    return nil, "CAMP_RESOURCE_CAPTURE_PENDING"
end

Internal.SnapshotMatches = snapshotMatches
Internal.PumpCapture = pumpCapture
Internal.RequestCapture = requestCapture

return Service
