-- Bounded world discovery and shared camp snapshot cache.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.CampResourceService = PNC.CampResourceService or {}

local Service = PNC.CampResourceService
local Internal = Service.Internal or {}
Service.Internal = Internal
local Const = PNC.Const or {}
local Resources = PNC.FacilityResources
local Water = PNC.NearbyWaterService
local Locator = PNC.NearbyResourceLocator
local CampSite = PNC.Semantics and PNC.Semantics.CampSite
    or require "PNC/Semantics/PNC_SemanticCampSite"
local Geometry = PNC.Semantics and PNC.Semantics.CampSiteGeometry
    or require "PNC/Semantics/PNC_SemanticCampSiteGeometry"

local function number(value, fallback)
    return Internal.Number(value, fallback)
end

local function worldHour()
    return Internal.WorldHour()
end

local function eachObject(square, visitor)
    local objects = square and square.getObjects
        and square:getObjects() or nil
    if not objects then return end
    if objects.size and objects.get then
        for index = 0, objects:size() - 1 do
            visitor(objects:get(index), index)
        end
        return
    end
    for index = 1, #objects do visitor(objects[index], index) end
end

local function primitiveCopyValue(value)
    local valueType = type(value)
    if valueType == "number" or valueType == "string"
        or valueType == "boolean"
    then
        return value
    end
    if valueType ~= "table" then return nil end
    local output = {}
    for key, child in pairs(value) do
        local copied = primitiveCopyValue(child)
        if copied ~= nil then output[key] = copied end
    end
    return output
end

local function primitiveCopy(source)
    return primitiveCopyValue(source) or {}
end

local function spriteName(object)
    if not object or type(object.getSprite) ~= "function" then return nil end
    local sprite = object:getSprite()
    if not sprite or type(sprite.getName) ~= "function" then return nil end
    return sprite:getName()
end

local function bedKey(resource)
    return "bed:" .. tostring(math.floor((number(resource.x, 0) * 2) + 0.5))
        .. ":" .. tostring(math.floor((number(resource.y, 0) * 2) + 0.5))
        .. ":" .. tostring(number(resource.z, 0))
end

local function addResource(resources, seen, resource)
    if type(resource) ~= "table" then return end
    local copy = primitiveCopy(resource)
    local key = tostring(copy.resourceKey or copy.key or "")
    if key == "" or seen[key] then return end
    copy.resourceKey = key
    copy.kind = copy.kind or "discovered"
    copy.readOnly = true
    if type(copy.seatSpots) == "table" then
        local maximum = math.max(1, math.floor(number(
            Const.CAMP_RESOURCE_SPOT_MAX, 8)))
        while #copy.seatSpots > maximum do
            table.remove(copy.seatSpots)
        end
    end
    seen[key] = true
    resources[#resources + 1] = copy
end

local function describeSleepResource(square, object, detectorId)
    local detector = Resources and Resources.GetDetector
        and Resources.GetDetector(detectorId) or nil
    if not detector or type(detector.matches) ~= "function"
        or type(detector.describe) ~= "function"
    then return nil end
    local matched = detector.matches(square, object)
    if matched ~= true then return nil end
    matched = detector.describe(square, object)
    if type(matched) ~= "table" then return nil end
    matched = primitiveCopy(matched)
    matched.resourceKey = type(detector.key) == "function"
        and detector.key(matched) or bedKey(matched)
    matched.detectorId = detectorId
    matched.targetResolver = detectorId
    matched.resourceKind = matched.resourceKind or "sleep_surface"
    matched.role = matched.role or detector.role
    matched.sleepSurface = matched.sleepSurface or detector.sleepSurface
        or detectorId
    matched.sleepPriority = matched.sleepPriority
        or detector.sleepPriority or 0
    matched.exclusive = matched.exclusive ~= false
    matched.available = true
    matched.originX = square and square.getX and square:getX() or matched.originX
    matched.originY = square and square.getY and square:getY() or matched.originY
    matched.originZ = square and square.getZ and square:getZ() or matched.originZ
    return matched
end

local function describeFaucet(square, object, ordinal)
    if not Water or not Water.IsCleanFaucet
        or not Water.IsCleanFaucet(object)
    then return nil end
    local x = square and square.getX and square:getX() or nil
    local y = square and square.getY and square:getY() or nil
    local z = square and square.getZ and square:getZ() or nil
    if x == nil or y == nil then return nil end
    local key
    if Locator and Locator.ObjectKeyFor then
        key = Locator.ObjectKeyFor(object, x, y, z or 0, ordinal)
    end
    key = tostring(key or ("faucet:" .. tostring(x) .. ":" .. tostring(y)
        .. ":" .. tostring(z or 0) .. ":" .. tostring(ordinal or 0)))
    return {
        kind = "discovered", detectorId = "faucet",
        targetResolver = "faucet", resourceKind = "water_source",
        role = "survival.world_water", capability = "survival.drink.world",
        resourceKey = key, key = key, x = x + 0.5, y = y + 0.5,
        z = z or 0, originX = x, originY = y, originZ = z or 0,
        sprite = spriteName(object), exclusive = false, available = true,
        readOnly = true,
    }
end

local function describeSeat(square, object, context, ordinal)
    local detector = Resources and Resources.GetDetector
        and Resources.GetDetector("seat") or nil
    if not detector or type(detector.matches) ~= "function"
        or type(detector.describe) ~= "function"
    then return nil end
    local matched = detector.matches(square, object)
    if matched ~= true then return nil end
    local resource = detector.describe(
        square,
        object,
        { objectIndex = ordinal, character = context and context.character }
    )
    if type(resource) ~= "table" then return nil end
    resource.detectorId = "seat"
    resource.targetResolver = "seat"
    resource.resourceKind = "seating_surface"
    resource.role = "living.chair"
    resource.exclusive = true
    resource.available = true
    return resource
end

function Service.RegisterProvider(id, provider)
    id = tostring(id or "")
    if id == "" or type(provider) ~= "table"
        or type(provider.CaptureSquare) ~= "function"
    then return false, "INVALID_CAMP_RESOURCE_PROVIDER" end
    provider.id = id
    Service.Providers[id] = provider
    return true, provider
end

Service.RegisterProvider("bed", {
    resourceKind = "sleep_surface",
    CaptureSquare = function(square, add)
        local detector = Resources and Resources.GetDetector
            and Resources.GetDetector("bed") or nil
        local emitted = {}
        if detector and detector.collect then
            detector.collect(square, function(object)
                emitted[object] = true
                add(describeSleepResource(square, object, "bed"))
            end)
        end
        eachObject(square, function(object)
            if not emitted[object] then
                add(describeSleepResource(square, object, "bed"))
            end
        end)
    end,
})

Service.RegisterProvider("sofa", {
    resourceKind = "sleep_surface",
    CaptureSquare = function(square, add)
        eachObject(square, function(object)
            add(describeSleepResource(square, object, "sofa"))
        end)
    end,
})

Service.RegisterProvider("faucet", {
    resourceKind = "water_source",
    CaptureSquare = function(square, add)
        eachObject(square, function(object, ordinal)
            add(describeFaucet(square, object, ordinal))
        end)
    end,
})

Service.RegisterProvider("seat", {
    resourceKind = "seating_surface",
    CaptureSquare = function(square, add, context)
        eachObject(square, function(object, ordinal)
            add(describeSeat(square, object, context, ordinal))
        end)
    end,
})

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

function Service.Capture(record, force)
    local order = Internal.CampContext(record)
    local entry
    local state
    local reason
    if not order then return nil, "NOT_CAMPED" end
    state, reason = requestCapture(record, force)
    if state then return state end
    if reason ~= "CAMP_RESOURCE_CAPTURE_PENDING" then
        return nil, reason
    end
    entry = Service.Attach(record, order)
    while entry and entry.capture do
        state = pumpCapture(entry.capture, 1000000)
        if state then return state end
    end
    return entry and entry.state or nil
end

function Service.GetSnapshot(record, force)
    return requestCapture(record, force)
end

function Service.Pump(nowValue)
    local budget = math.max(1, math.floor(number(
        Const.CAMP_RESOURCE_SCAN_SQUARES_PER_TICK, 32)))
    local processed = 0
    local used
    local entry
    for _, candidate in pairs(Service.Runtime.camps) do
        if processed >= budget then break end
        entry = candidate
        if entry and entry.capture then
            _, used = pumpCapture(entry.capture, budget - processed)
            processed = processed + (tonumber(used) or 0)
        end
    end
    Internal.EvictCacheEntries()
    return processed
end

Internal.PrimitiveCopy = primitiveCopy
Internal.SnapshotMatches = snapshotMatches
Internal.PumpCapture = pumpCapture
Internal.RequestCapture = requestCapture

return Service
