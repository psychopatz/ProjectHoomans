-- Camp-local resource snapshots. A camp is not a settlement facility: it is
-- a durable anchor plus a bounded, primitive description of useful objects
-- found around that anchor. Providers can be added without changing tasking.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.CampResourceService = PNC.CampResourceService or {}

local Service = PNC.CampResourceService
local Const = PNC.Const or {}
local Resources = PNC.FacilityResources
local Targets = PNC.FacilityInteractionTargets
local Water = PNC.NearbyWaterService
local Locator = PNC.NearbyResourceLocator

-- Bump this whenever resource classification or target metadata changes. Old
-- camp snapshots are world-state caches, not authoritative sleep decisions.
Service.SCHEMA_VERSION = 3
Service.Providers = Service.Providers or {}
Service.Runtime = Service.Runtime or {}
Service.Runtime.camps = Service.Runtime.camps or {}

local function number(value, fallback)
    local result = tonumber(value)
    return result ~= nil and result or fallback
end

local function campFacilityId(campId)
    campId = tostring(campId or "")
    return string.sub(campId, 1, 5) == "camp:"
        and campId or "camp:" .. campId
end

local function campOrder(record)
    local order = record and record.orderSpec or nil
    if tostring(order and order.kind or "") ~= tostring(Const.ORDER_CAMP or "camp") then
        return nil
    end
    return order
end

-- Facility activities temporarily replace the camp order. Keep the camp
-- anchor available to resource revalidation while a need task is active.
local function campContext(record)
    local order = campOrder(record)
    if order then return order end
    local activity = record and record.runtime
        and record.runtime.facilityActivity or nil
    local state = record and record.campState or nil
    if not activity or activity.campActivity ~= true then return nil end
    return {
        kind = Const.ORDER_CAMP or "camp",
        campId = tostring(activity.campId or state and state.campId
            or "camp:" .. tostring(record.id)),
        x = number(activity.campX or state and state.anchorX,
            record and record.anchorX or record and record.x or 0),
        y = number(activity.campY or state and state.anchorY,
            record and record.anchorY or record and record.y or 0),
        z = number(activity.campZ or state and state.anchorZ,
            record and record.anchorZ or record and record.z or 0),
        radius = number(activity.campRadius or state and state.campRadius,
            Const.CAMP_RADIUS or 3),
        resourceRadius = number(activity.resourceRadius
            or state and state.resourceRadius,
            Const.CAMP_RESOURCE_RADIUS or 12),
    }
end

-- A camp resource is deliberately local to the captured camp anchor. The
-- resource snapshot is bounded, but a live seat target can be regenerated
-- from animation data after a reload; keep a malformed or stale target from
-- turning a need activity into an unbounded travel order.
local function targetWithinCamp(record, target)
    local order = campContext(record)
    local targetX = tonumber(target and target.x)
    local targetY = tonumber(target and target.y)
    local targetZ = tonumber(target and target.z)
    local anchorX
    local anchorY
    local anchorZ
    local radius
    local dx
    local dy
    local anchorTargetX
    local anchorTargetY
    local anchorTargetZ
    if not order or not targetX or not targetY or not targetZ then
        return false
    end
    anchorX, anchorY, anchorZ = tonumber(order.x), tonumber(order.y),
        tonumber(order.z)
    radius = number(order.radius, Const.CAMP_RADIUS or 3)
    if not anchorX or not anchorY or not anchorZ
        or math.abs(targetZ - anchorZ) > 0.5
    then
        return false
    end
    dx, dy = targetX - anchorX, targetY - anchorY
    if (dx * dx) + (dy * dy) > (radius + 0.5) * (radius + 0.5) then
        return false
    end
    anchorTargetX = tonumber(target.seatAnchorX)
    anchorTargetY = tonumber(target.seatAnchorY)
    anchorTargetZ = tonumber(target.seatAnchorZ or target.z)
    if anchorTargetX and anchorTargetY and anchorTargetZ then
        if math.abs(anchorTargetZ - anchorZ) > 0.5 then return false end
        dx, dy = anchorTargetX - anchorX, anchorTargetY - anchorY
        if (dx * dx) + (dy * dy) > (radius + 0.5) * (radius + 0.5) then
            return false
        end
    end
    return true
end

local function worldHour()
    if PNC.NeedsUtils and PNC.NeedsUtils.WorldAgeHours then
        return PNC.NeedsUtils.WorldAgeHours()
    end
    return PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
end

local function markDirty(record, reason)
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, reason or "camp_resources")
    end
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
    return type(state) == "table"
        and tonumber(state.schemaVersion) == tonumber(Service.SCHEMA_VERSION)
        and tostring(state.campId or "") == tostring(order.campId or "")
        and tonumber(state.anchorX) == tonumber(order.x)
        and tonumber(state.anchorY) == tonumber(order.y)
        and tonumber(state.anchorZ) == tonumber(order.z)
        and tonumber(state.campRadius) == tonumber(campRadius)
        and tonumber(state.resourceRadius) == tonumber(radius)
        and type(state.resources) == "table"
end

local function campDimensions(order)
    local radius = math.max(1, math.min(24, number(
        order and order.resourceRadius,
        number(Const.CAMP_RESOURCE_RADIUS, 12))))
    local campRadius = math.max(0.5, math.min(24, number(
        order and order.radius,
        number(Const.CAMP_RADIUS, 3))))
    return radius, campRadius
end

local function campCacheKey(record, order)
    return tostring(order and order.campId
        or "camp:" .. tostring(record and record.id or "unknown"))
end

local function cacheEntry(record, order, create)
    local key = campCacheKey(record, order)
    local entry = Service.Runtime.camps[key]
    if not entry and create ~= false then
        entry = { campId = key, members = {}, state = nil }
        Service.Runtime.camps[key] = entry
    end
    return entry, key
end

local function detachRecord(record)
    local runtime = record and record.runtime or nil
    local key = runtime and runtime.campCacheId or nil
    local entry
    local memberID
    local hasMembers
    if not key then return end
    entry = Service.Runtime.camps[tostring(key)]
    memberID = tostring(record and record.id or "")
    if entry and entry.members then entry.members[memberID] = nil end
    if entry and entry.members then
        hasMembers = false
        for _ in pairs(entry.members) do
            hasMembers = true
            break
        end
        if not hasMembers then
            Service.Runtime.camps[tostring(key)] = nil
        end
    end
    runtime.campCacheId = nil
    if record then record.campState = nil end
end

function Service.Attach(record, order)
    local runtime
    local entry
    local key
    local memberID
    if not record then return nil end
    order = order or campContext(record)
    if not order then return nil end
    runtime = record.runtime or {}
    record.runtime = runtime
    if runtime.campCacheId
        and tostring(runtime.campCacheId) ~= campCacheKey(record, order)
    then
        detachRecord(record)
    end
    entry, key = cacheEntry(record, order, true)
    memberID = tostring(record.id or "")
    entry.members[memberID] = true
    runtime.campCacheId = key
    return entry
end

function Service.GetCachedSnapshot(record)
    local order = campContext(record)
    local entry
    local radius
    local campRadius
    if not order then return nil end
    entry = cacheEntry(record, order, false)
    if not entry or type(entry.state) ~= "table" then return nil end
    radius, campRadius = campDimensions(order)
    if not snapshotMatches(entry.state, order, radius, campRadius) then
        return nil
    end
    return entry.state
end

local function newCapture(entry, record, order, radius, campRadius)
    local state = {
        schemaVersion = Service.SCHEMA_VERSION,
        campId = tostring(order.campId or "camp:" .. tostring(record.id)),
        anchorX = number(order.x, record.x or 0),
        anchorY = number(order.y, record.y or 0),
        anchorZ = number(order.z, record.z or 0),
        campRadius = campRadius,
        resourceRadius = radius,
        capturedAtWorldHour = worldHour(),
        resources = {},
    }
    return {
        entry = entry,
        record = record,
        state = state,
        seen = {},
        cell = type(getCell) == "function" and getCell() or nil,
        live = PNC.Registry and PNC.Registry.GetLiveZombie
            and PNC.Registry.GetLiveZombie(record.id) or nil,
        radius = radius,
        originX = math.floor(state.anchorX),
        originY = math.floor(state.anchorY),
        originZ = math.floor(state.anchorZ),
        span = math.floor(radius),
        dx = -math.floor(radius),
        dy = -math.floor(radius),
    }
end

local function finishCapture(capture)
    local entry = capture and capture.entry or nil
    local state = capture and capture.state or nil
    local maximum
    local now
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
    now = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
    entry.lastCaptureAt = now
    if capture.record then capture.record.campState = state end
    -- The resource table remains a runtime cache. Do not mark every camp
    -- member dirty when discovery completes: that would create a needless
    -- persistence/network fan-out for data that is intentionally not saved.
    return state
end

local function pumpCapture(capture, budget)
    local processed = 0
    local limit = math.max(1, math.floor(number(budget, 1)))
    local square
    local dx
    local dy
    if not capture then return nil, 0 end
    if not capture.cell
        or type(capture.cell.getGridSquare) ~= "function"
    then
        return finishCapture(capture), 0
    end
    while capture.dx <= capture.span and processed < limit do
        dx, dy = capture.dx, capture.dy
        capture.dy = dy + 1
        if capture.dy > capture.span then
            capture.dx = dx + 1
            capture.dy = -capture.span
        end
        processed = processed + 1
        if dx * dx + dy * dy <= capture.radius * capture.radius then
            square = capture.cell:getGridSquare(
                capture.originX + dx,
                capture.originY + dy,
                capture.originZ
            )
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
    end
    if capture.dx > capture.span then
        return finishCapture(capture), processed
    end
    return nil, processed
end

local function requestCapture(record, force)
    local order = campContext(record)
    local radius
    local campRadius
    local entry
    local legacyState
    local cached
    local now
    local refreshCooldown
    if not order then return nil, "NOT_CAMPED" end
    radius, campRadius = campDimensions(order)
    legacyState = record and record.campState or nil
    entry = Service.Attach(record, order)
    cached = entry and entry.state or nil
    -- Tests and older runtime callers can still provide a transient state on
    -- the record. It is adopted only in memory; it is never serialized.
    if cached and legacyState and legacyState ~= cached
        and not snapshotMatches(legacyState, order, radius, campRadius)
    then
        entry.state = nil
        cached = nil
    end
    if cached and snapshotMatches(cached, order, radius, campRadius) then
        now = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
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
        -- The camp id can survive an anchor edit. Never finish a scan against
        -- an obsolete anchor or let it poison the shared cache.
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
    local order = campContext(record)
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

function Service.Pump(now)
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
    return processed
end

local function floorSlot(record, order)
    local hash = 0
    local id = tostring(record and record.id or "npc")
    for index = 1, #id do
        hash = (hash + (string.byte(id, index) or 0) * index) % 8
    end
    local offsets = {
        { 0, 0 }, { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 },
        { 1, 1 }, { -1, 1 }, { 1, -1 },
    }
    local slot = offsets[hash + 1]
    local x = math.floor(number(order.x, record.x or 0)) + slot[1] + 0.5
    local y = math.floor(number(order.y, record.y or 0)) + slot[2] + 0.5
    local campId = tostring(order.campId or "camp:" .. id)
    return {
        kind = "virtual", targetResolver = "floor",
        resourceKind = "floor_sleep", role = "sleep.floor",
        resourceKey = campId .. ":floor:" .. id,
        x = x, y = y, z = number(order.z, record.z or 0),
        originX = math.floor(x), originY = math.floor(y),
        originZ = math.floor(number(order.z, record.z or 0)),
        exclusive = false, available = true,
        sceneId = "facility.sleep.floor", sleepSurface = "floor",
    }
end

local function reserved(resource, excludeKey)
    local key = tostring(resource and resource.resourceKey or "")
    if key == "" then return false end
    if tostring(excludeKey or "") ~= "" and key == tostring(excludeKey) then
        return true
    end
    return PNC.FacilityReservations
        and PNC.FacilityReservations.ByResource
        and PNC.FacilityReservations.ByResource[key] ~= nil
end

local function resolveSleep(resource, abstract)
    local sleepSurface = tostring(resource and resource.sleepSurface or "")
    local detectorId = tostring(resource and resource.detectorId or "")
    if type(resource) ~= "table"
        or tostring(resource.resourceKind or "") ~= "sleep_surface"
        or (sleepSurface ~= "bed" and sleepSurface ~= "sofa")
        or detectorId ~= sleepSurface
    then
        return nil, {}
    end
    local targets = Targets and Targets.ResolveResource
        and Targets.ResolveResource(resource, { abstract = abstract == true }) or {}
    if targets[1] and Resources and Resources.IsValidSleepTarget
        and not Resources.IsValidSleepTarget(resource, targets[1])
    then
        return nil, targets
    end
    return targets[1], targets
end

local function resolveSeat(resource, abstract, character, approachKey)
    local targets = Targets and Targets.ResolveResource
        and Targets.ResolveResource(resource, {
            abstract = abstract == true, character = character,
            approachKey = approachKey,
        }) or {}
    return targets[1], targets
end

local function resolveWater(record, resource)
    local key = tostring(resource and resource.resourceKey or "")
    local source
    if key ~= "" and Water and Water.Resolve then
        source = Water.Resolve(record, key)
    end
    -- Captured faucet keys include the object ordinal. A loaded world can
    -- legitimately produce a different ordinal after a reload, so use the
    -- captured square as a bounded fallback before declaring the source gone.
    if not source and Water and Water.FindAt and resource then
        source = Water.FindAt(record, resource.originX, resource.originY,
            resource.originZ or resource.z)
    end
    return source
end

local function resolveWaterTarget(record, resource, abstract)
    local source = resolveWater(record, resource)
    local target
    local targets
    if source and Water and Water.BuildApproach then
        target, targets = Water.BuildApproach(record, source)
        if target then
            target.sceneId = target.sceneId or "survival.drink.world"
            target.resourceKey = resource.resourceKey
            target.resourceKind = "world_water"
            return target, targets, source
        end
    end
    if abstract == true then
        return {
            x = number(resource.x, resource.originX or 0),
            y = number(resource.y, resource.originY or 0),
            z = number(resource.z, resource.originZ or 0),
            sceneId = "survival.drink.world",
            resourceKey = resource.resourceKey,
            resourceKind = "world_water",
        }, nil, resource
    end
    return nil, nil, source
end

function Service.FindSleep(record, options)
    options = type(options) == "table" and options or {}
    local state = Service.GetSnapshot(record, options.force == true)
    local resources = state and state.resources or {}
    local selected
    for index = 1, #resources do
        local resource = resources[index]
        local sleepSurface = tostring(resource.sleepSurface or "")
        if tostring(resource.resourceKind or "") == "sleep_surface"
            and tostring(resource.detectorId or "") == sleepSurface
            and (sleepSurface == "bed" or sleepSurface == "sofa")
            and not reserved(resource, options.excludeKey)
        then
            local target, targets = resolveSleep(resource, options.abstract)
            if target and targetWithinCamp(record, target) then
                local priority = tonumber(resource.sleepPriority) or 0
                if not selected
                    or priority > selected.priority
                    or (priority == selected.priority
                        and tostring(resource.resourceKey or "")
                            < tostring(selected.resource.resourceKey or ""))
                then
                    selected = {
                        resource = resource, target = target, targets = targets,
                        priority = priority,
                    }
                end
            end
        end
    end
    if selected then
        return selected.resource, selected.target, selected.targets
    end
    if options.allowFloor ~= false then
        local resource = floorSlot(record, campContext(record) or {})
        return resource, {
            x = resource.x, y = resource.y, z = resource.z,
            sceneId = resource.sceneId, sleepSurface = resource.sleepSurface,
            resourceKey = resource.resourceKey,
            resourceKind = resource.resourceKind,
        }, nil
    end
    return nil, nil, nil, "CAMP_SLEEP_UNAVAILABLE"
end

function Service.FindSeat(record, options)
    options = type(options) == "table" and options or {}
    local state = Service.GetSnapshot(record, options.force == true)
    local resources = state and state.resources or {}
    local live = options.character
        or PNC.Registry and PNC.Registry.GetLiveZombie
            and PNC.Registry.GetLiveZombie(record.id) or nil
    for index = 1, #resources do
        local resource = resources[index]
        if tostring(resource.resourceKind or "") == "seating_surface"
            and not reserved(resource, options.excludeKey)
        then
            local target, targets = resolveSeat(
                resource, options.abstract, live)
            if target and targetWithinCamp(record, target) then
                return resource, target, targets
            end
        end
    end
    return nil, nil, nil, "CAMP_SEAT_UNAVAILABLE"
end

function Service.FindWater(record, options)
    options = type(options) == "table" and options or {}
    local state = Service.GetSnapshot(record, options.force == true)
    local resources = state and state.resources or {}
    local excludeKey = tostring(options.excludeKey or "")
    for index = 1, #resources do
        local resource = resources[index]
        local key = tostring(resource.resourceKey or "")
        if tostring(resource.resourceKind or "") == "water_source"
            and key ~= excludeKey and not reserved(resource, excludeKey)
        then
            local target, targets, source = resolveWaterTarget(
                record, resource, options.abstract == true)
            if target and targetWithinCamp(record, target) then
                return resource, target, targets, source
            end
        end
    end
    return nil, nil, nil, nil, "CAMP_WATER_UNAVAILABLE"
end

local function reserve(record, resource, campId)
    local reservations = PNC.FacilityReservations
    if not reservations or not reservations.ReserveResource then
        return false, "CAMP_RESERVATIONS_UNAVAILABLE"
    end
    return reservations.ReserveResource(
        campFacilityId(campId), resource, record.id, "sleep", 30000,
        { campId = campId, campResource = true })
end

local function reserveSeat(record, resource, campId)
    local reservations = PNC.FacilityReservations
    if not reservations or not reservations.ReserveResource then
        return false, "CAMP_RESERVATIONS_UNAVAILABLE"
    end
    return reservations.ReserveResource(
        campFacilityId(campId), resource, record.id, "living", 30000,
        { campId = campId, campResource = true })
end

local function reserveWater(record, resource, campId)
    local reservations = PNC.FacilityReservations
    if not reservations or not reservations.ReserveResource then
        return false, "CAMP_RESERVATIONS_UNAVAILABLE"
    end
    return reservations.ReserveResource(
        campFacilityId(campId), resource, record.id, "world_water", 30000,
        { campId = campId, campResource = true })
end

function Service.AcquireSleep(record, options)
    options = type(options) == "table" and options or {}
    local order = campOrder(record)
    if not order then return nil, "NOT_CAMPED" end
    local resource, target, targets, reason = Service.FindSleep(record, options)
    if not resource then return nil, reason or "CAMP_SLEEP_UNAVAILABLE" end
    local campId = tostring(order.campId or "camp:" .. tostring(record.id))
    local ok, reservation = reserve(record, resource, campId)
    if not ok then return nil, reservation or "CAMP_SLEEP_RESERVATION_FAILED" end
    return {
        ok = true, facilityId = campFacilityId(campId), componentId = "",
        reservationId = reservation.id, role = resource.role,
        resource = resource, resourceKey = resource.resourceKey,
        resourceKind = resource.resourceKind, target = target,
        approachCandidates = targets, campId = campId, campActivity = true,
        sleepVariant = "CAMP_NEARBY",
        sleepTargetPolicy = resource.sleepSurface == "sofa"
            and "CAMP_NEARBY_SOFA"
            or resource.resourceKind == "sleep_surface"
                and "CAMP_NEARBY_BED" or "CAMP_FLOOR_FALLBACK",
        campX = order.x, campY = order.y, campZ = order.z,
        campRadius = number(order.radius, Const.CAMP_RADIUS or 3),
        resourceRadius = number(order.resourceRadius,
            Const.CAMP_RESOURCE_RADIUS or 12),
        executionMode = options.abstract == true and "ABSTRACT" or "LIVE",
    }
end

function Service.AcquireSeat(record, options)
    options = type(options) == "table" and options or {}
    local order = campOrder(record)
    if not order then return nil, "NOT_CAMPED" end
    local resource, target, targets, reason = Service.FindSeat(record, options)
    if not resource then return nil, reason or "CAMP_SEAT_UNAVAILABLE" end
    local campId = tostring(order.campId or "camp:" .. tostring(record.id))
    local ok, reservation = reserveSeat(record, resource, campId)
    if not ok then return nil, reservation or "CAMP_SEAT_RESERVATION_FAILED" end
    return {
        ok = true, facilityId = campFacilityId(campId), componentId = "",
        reservationId = reservation.id, role = resource.role,
        resource = resource, resourceKey = resource.resourceKey,
        resourceKind = resource.resourceKind, target = target,
        approachCandidates = targets, campId = campId, campActivity = true,
        campX = order.x, campY = order.y, campZ = order.z,
        campRadius = number(order.radius, Const.CAMP_RADIUS or 3),
        resourceRadius = number(order.resourceRadius,
            Const.CAMP_RESOURCE_RADIUS or 12),
        seating = true,
        executionMode = options.abstract == true and "ABSTRACT" or "LIVE",
    }
end

function Service.AcquireWater(record, options)
    options = type(options) == "table" and options or {}
    local order = campOrder(record)
    if not order then return nil, "NOT_CAMPED" end
    local resource, target, targets, source, reason = Service.FindWater(
        record, options)
    if not resource then return nil, reason or "CAMP_WATER_UNAVAILABLE" end
    local campId = tostring(order.campId or "camp:" .. tostring(record.id))
    local ok, reservation = reserveWater(record, resource, campId)
    if not ok then return nil, reservation or "CAMP_WATER_RESERVATION_FAILED" end
    return {
        ok = true, facilityId = campFacilityId(campId), componentId = "",
        reservationId = reservation.id,
        role = resource.role or "survival.world_water",
        resource = resource, resourceKey = resource.resourceKey,
        resourceKind = "world_water", target = target,
        approachCandidates = targets, campId = campId, campActivity = true,
        campX = order.x, campY = order.y, campZ = order.z,
        campRadius = number(order.radius, Const.CAMP_RADIUS or 3),
        resourceRadius = number(order.resourceRadius,
            Const.CAMP_RESOURCE_RADIUS or 12),
        waterSource = source,
        executionMode = options.abstract == true and "ABSTRACT" or "LIVE",
    }
end

local function applyTarget(record, target)
    if not target then return false end
    local activity = record.runtime and record.runtime.facilityActivity or {}
    local order = record.orderSpec or {}
    order.x, order.y, order.z = target.x, target.y, target.z
    order.seatAnchorX = target.seatAnchorX
    order.seatAnchorY = target.seatAnchorY
    order.seatAnchorZ = target.seatAnchorZ
    order.interactionX, order.interactionY, order.interactionZ =
        target.interactionX, target.interactionY, target.interactionZ
    order.interactionSurfaceOffset = target.interactionSurfaceOffset
    order.interactionAxis, order.interactionFacing = target.interactionAxis,
        target.interactionFacing
    order.sleepAnchorX, order.sleepAnchorY, order.sleepAnchorZ =
        target.sleepAnchorX, target.sleepAnchorY, target.sleepAnchorZ
    order.sleepAxis, order.sleepFacing = target.sleepAxis, target.sleepFacing
    order.sleepSprite = target.sleepSprite
    order.sleepGridX, order.sleepGridY = target.sleepGridX, target.sleepGridY
    order.sleepGridWidth, order.sleepGridHeight = target.sleepGridWidth,
        target.sleepGridHeight
    order.seatDirection, order.seatSide = target.seatDirection,
        target.seatSide
    if target.approachKey ~= nil then order.approachKey = target.approachKey end
    if target.validSpot ~= nil then order.validSpot = target.validSpot end
    order.validationState = target.validationState
    order.rejectionReason = target.rejectionReason
    order.routeStatus = target.routeStatus
    if target.stopDistance ~= nil then order.stopDistance = target.stopDistance end
    if target.arrivalDistance ~= nil then
        order.arrivalDistance = target.arrivalDistance
    end
    order.sceneId, order.sleepSurface = target.sceneId or "",
        target.sleepSurface or ""
    activity.target = { x = target.x, y = target.y, z = target.z }
    activity.seatAnchor = target.seatAnchorX and {
        x = tonumber(target.seatAnchorX),
        y = tonumber(target.seatAnchorY),
        z = tonumber(target.seatAnchorZ or target.z),
    } or nil
    activity.sceneId, activity.sleepSurface = order.sceneId, order.sleepSurface
    if tostring(activity.capability or "") == "sleep" then
        PNC.SleepRuntime = PNC.SleepRuntime or {}
        PNC.SleepRuntime.LiveObjects = PNC.SleepRuntime.LiveObjects or {}
        PNC.SleepRuntime.LiveObjects[tostring(record.id)] = target.object
    end
    activity.seatDirection, activity.seatSide = order.seatDirection,
        order.seatSide
    activity.approachKey = order.approachKey or activity.approachKey
    activity.validSpot = order.validSpot ~= false
    activity.seatValidation = tostring(order.validationState or "")
    activity.seatRejectionReason = tostring(order.rejectionReason or "")
    activity.seatRouteStatus = tostring(order.routeStatus or "UNTESTED")
    if order.stopDistance ~= nil then
        activity.seatStopDistance = tonumber(order.stopDistance)
    end
    if order.arrivalDistance ~= nil then
        activity.seatArrivalDistance = tonumber(order.arrivalDistance)
    end
    return true
end

function Service.ResolveActivityTarget(record)
    local activity = record and record.runtime
        and record.runtime.facilityActivity or record and record.orderSpec or nil
    if not activity or activity.campActivity ~= true
        or tostring(activity.facilityId or ""):sub(1, 5) ~= "camp:"
    then return nil end
    local key = tostring(activity.resourceKey or "")
    local live = PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record.id) or nil
    local abstract = live == nil
    local snapshot = Service.GetSnapshot(record, false)
    for index = 1, #(snapshot and snapshot.resources or {}) do
        local resource = snapshot.resources[index]
        if tostring(resource.resourceKey or "") == key then
            local target
            local resolvedResource
            if tostring(activity.capability or "") == "living" then
                target = resolveSeat(
                    resource, abstract, live, activity.approachKey)
            elseif tostring(activity.capability or "")
                    == "survival.drink.world"
                or tostring(activity.resourceKind or "") == "world_water"
            then
                target, _, resolvedResource = resolveWaterTarget(
                    record, resource, abstract)
            else
                target = resolveSleep(resource, abstract)
            end
            if target and targetWithinCamp(record, target) then
                target.campResource = true
                return target, resolvedResource or resource
            end
        end
    end
    if tostring(activity.capability or "") == "living" then
        local _, target = Service.FindSeat(record, {
            abstract = abstract, force = true, excludeKey = key,
        })
        if target then target.campResource = true end
        return target
    end
    if tostring(activity.capability or "") == "survival.drink.world"
        or tostring(activity.resourceKind or "") == "world_water"
    then
        local _, target, _, source = Service.FindWater(record, {
            abstract = abstract, force = true, excludeKey = key,
        })
        if target then target.campResource = true end
        return target, source
    end
    if tostring(activity.resourceKind or "") == "floor_sleep"
        or tostring(activity.sleepSurface or "") == "floor"
    then
        local target = activity.target or {
            x = activity.x, y = activity.y, z = activity.z,
        }
        if not Resources or not Resources.IsValidSleepTarget
            or not Resources.IsValidSleepTarget({
                resourceKind = "floor_sleep", sleepSurface = "floor",
            }, {
                sceneId = target.sceneId,
                sleepSurface = target.sleepSurface,
                seating = target.seating,
            })
        then
            target = nil
        end
        if not target then
            local floor = floorSlot(record, campContext(record) or {})
            target = {
                x = floor.x, y = floor.y, z = floor.z,
                sceneId = floor.sceneId, sleepSurface = floor.sleepSurface,
            }
        end
        target.resourceKey = target.resourceKey or key
        target.resourceKind = target.resourceKind or activity.resourceKind
        target.sleepSurface = target.sleepSurface or activity.sleepSurface
        target.campResource = true
        return target
    end
    local _, target = Service.FindSleep(record, {
        abstract = false, force = true, excludeKey = key,
    })
    if target then target.campResource = true end
    return target
end

function Service.ApplyMaterializationTarget(record, zombie, target)
    if Resources and Resources.ApplyMaterializationTarget then
        return Resources.ApplyMaterializationTarget(record, zombie, target)
    end
    return false
end

function Service.RefreshActivity(record, zombie)
    local runtime = record and record.runtime
        and record.runtime.facilityActivity or nil
    if not runtime or runtime.campActivity ~= true
        or (tostring(runtime.capability or "") ~= "sleep"
            and tostring(runtime.capability or "") ~= "living"
            and tostring(runtime.capability or "")
                ~= "survival.drink.world")
    then return true end
    local target, liveResource = Service.ResolveActivityTarget(record)
    if target
        and (tostring(runtime.capability or "") == "living"
            or tostring(runtime.capability or "") == "survival.drink.world"
            or tostring(target.sleepSurface or "")
                == tostring(runtime.sleepSurface or ""))
        and (target.resourceKey == nil
            or tostring(runtime.resourceKey or "")
                == tostring(target.resourceKey or ""))
    then
        applyTarget(record, target)
        if liveResource then runtime.resource = liveResource end
        return true
    end
    local oldKey = tostring(runtime.resourceKey or "")
    local live = zombie or PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record.id) or nil
    local abstract = live == nil
    local resource, replacement, targets, replacementSource
    local isLiving = tostring(runtime.capability or "") == "living"
    local isWater = tostring(runtime.capability or "")
        == "survival.drink.world"
    if isLiving then
        resource, replacement, targets = Service.FindSeat(record, {
            abstract = abstract, force = true, excludeKey = oldKey,
        })
    elseif isWater then
        resource, replacement, targets, replacementSource =
            Service.FindWater(record, {
            abstract = abstract, force = true, excludeKey = oldKey,
            })
    else
        resource, replacement, targets = Service.FindSleep(record, {
            abstract = abstract, force = true, excludeKey = oldKey,
        })
    end
    if not resource or not replacement then
        return false, isLiving and "CAMP_SEAT_TARGET_UNAVAILABLE"
            or isWater and "CAMP_WATER_TARGET_UNAVAILABLE"
            or "CAMP_SLEEP_TARGET_UNAVAILABLE"
    end
    local order = record.orderSpec or {}
    local campId = tostring(runtime.campId or order.campId or record.id)
    local reserveFunction = isLiving and reserveSeat
        or isWater and reserveWater or reserve
    local ok, reservation = reserveFunction(record, resource, campId)
    if not ok then
        return false, reservation or (isLiving
            and "CAMP_SEAT_RESERVATION_FAILED"
            or isWater and "CAMP_WATER_RESERVATION_FAILED"
            or "CAMP_SLEEP_RESERVATION_FAILED")
    end
    if PNC.FacilityReservations and runtime.reservationId
        and PNC.FacilityReservations.Release
    then
        PNC.FacilityReservations.Release(runtime.reservationId,
            "camp_resource_replaced")
    end
    runtime.reservationId = reservation.id
    runtime.resource = replacementSource or resource
    runtime.resourceKey = tostring(resource.resourceKey or "")
    runtime.resourceKind = isWater and "world_water"
        or tostring(resource.resourceKind or "")
    runtime.approachCandidates = targets
    runtime.approachIndex = 1
    order.reservationId = reservation.id
    order.resourceKey = runtime.resourceKey
    order.resourceKind = runtime.resourceKind
    applyTarget(record, replacement)
    local lease = runtime.taskLeaseId ~= "" and PNC.TaskLeaseService
        and PNC.TaskLeaseService.Get
        and PNC.TaskLeaseService.Get(runtime.taskLeaseId) or nil
    if lease then
        lease.reservationId = reservation.id
        lease.resourceKey = runtime.resourceKey
        lease.resourceKind = runtime.resourceKind
    end
    markDirty(record, "camp_activity_resource_refreshed")
    return true
end

function Service.OnOrderChanged(record, previous, current)
    local campKind = tostring(Const.ORDER_CAMP or "camp")
    local activityKind = "facility_activity"
    local previousKind = tostring(previous and previous.kind or "")
    local currentKind = tostring(current and current.kind or "")
    local currentIsCampActivity = currentKind == activityKind
        and current and current.campActivity == true
    if currentKind == campKind then
        if previousKind ~= campKind then
            detachRecord(record)
        end
        Service.Attach(record, current)
    elseif currentIsCampActivity then
        -- Need activities temporarily replace the durable camp order. Keep
        -- the shared cache attached until the activity restores or ends.
        Service.Attach(record, current)
    elseif currentKind ~= activityKind then
        detachRecord(record)
        markDirty(record, "camp_ended")
    end
end

return Service
