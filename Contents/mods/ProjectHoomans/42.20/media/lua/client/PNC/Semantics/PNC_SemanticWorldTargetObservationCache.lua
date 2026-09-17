-- Bounded client observation cache for semantic world targets.
--
-- This module owns the expensive part of client-side target discovery:
-- reading metadata from objects in the currently loaded cell.  It stores only
-- primitive observations, never Java objects, so the matcher can reuse one
-- short-lived scan for several surface phrases without retaining live world
-- references or contacting the server.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and PsychopatzCore.RuntimeRole.AllowsClientCode
    and not PsychopatzCore.RuntimeRole.AllowsClientCode()
then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Observer = PNC.Semantics.ClientWorldTargetObservationCache or {}
PNC.Semantics.ClientWorldTargetObservationCache = Observer

local SquareRules
local loadedRules, loadedSquareRules = pcall(
    require, "PsychopatzCore/World/PsychopatzSquareRules")
if loadedRules then SquareRules = loadedSquareRules end

Observer.VERSION = 2
Observer.DEFAULT_CACHE_MS = 500
Observer.MAX_RADIUS = 24
-- The observer is intentionally bounded, but a square-distance scan that
-- starts in the far corner of the radius can spend the whole budget on
-- unrelated objects before it reaches the object the player is looking at.
-- Keep this high enough for a dense loaded cell while retaining a hard cap.
Observer.MAX_OBJECTS = 512
Observer.MAX_OBJECTS_HARD = 1024
-- Candidate filtering may skip hundreds of floor/wall entries before it
-- reaches a meaningful object. Keep that pre-filter pass bounded as well;
-- otherwise a debug refresh could trade the old false-positive flood for a
-- different unbounded metadata scan.
Observer.MAX_INSPECTED_OBJECTS = 4096
-- Campfires are GlobalObjects and must remain discoverable even when a dense
-- square exhausts the ordinary-object budget.  This separate cap keeps the
-- priority path bounded without allowing it to inflate into an unbounded scan.
Observer.MAX_SPECIAL_OBJECTS = 32
Observer.Cache = Observer.Cache or {}

local function call(object, method, ...)
    local fn = object and object[method]
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, object, ...)
    return ok and value or nil
end

local function number(value)
    value = tonumber(value)
    if value ~= nil and value == value then return value end
    return nil
end

local function text(value)
    value = tostring(value or "")
    return value ~= "" and value or nil
end

local function addUnique(values, seen, value, normalizer)
    value = text(value)
    if not value then return end
    local key = normalizer and normalizer(value) or value
    if key == "" or seen[key] then return end
    seen[key] = true
    values[#values + 1] = value
end

-- Decoration is an optional client-local extension point. Keep the cache
-- boundary primitive even when a perception provider briefly inspects a Java
-- object: only booleans, numbers, strings, and plain nested tables survive.
local function copyPrimitive(value, depth)
    local valueType = type(value)
    depth = tonumber(depth) or 0
    if valueType == "number" or valueType == "string"
        or valueType == "boolean"
    then
        return value
    end
    if valueType ~= "table" or depth >= 5 then return nil end
    local output = {}
    for key, child in pairs(value) do
        local keyType = type(key)
        if keyType == "string" or keyType == "number"
            or keyType == "boolean"
        then
            local copied = copyPrimitive(child, depth + 1)
            if copied ~= nil then output[key] = copied end
        end
    end
    return output
end

local function metadataFor(object)
    local labels = {}
    local sprites = {}
    local seenLabels = {}
    local seenSprites = {}
    local sprite = call(object, "getSprite")
    local spriteName = call(object, "getSpriteName")
    local container = call(object, "getContainer")

    addUnique(labels, seenLabels, call(object, "getObjectName"))
    addUnique(labels, seenLabels, call(object, "getName"))
    addUnique(labels, seenLabels, spriteName)
    addUnique(sprites, seenSprites, spriteName, string.lower)
    addUnique(labels, seenLabels, call(sprite, "getName"))
    addUnique(labels, seenLabels, call(sprite, "getSpriteName"))
    addUnique(sprites, seenSprites, call(sprite, "getName"), string.lower)
    addUnique(sprites, seenSprites,
        call(sprite, "getSpriteName"), string.lower)
    addUnique(labels, seenLabels, call(container, "getType"))

    if SquareRules and type(SquareRules.GetObjectProperty) == "function" then
        addUnique(labels, seenLabels,
            SquareRules.GetObjectProperty(object, "CustomName"))
        addUnique(labels, seenLabels,
            SquareRules.GetObjectProperty(object, "GroupName"))
        addUnique(labels, seenLabels,
            SquareRules.GetObjectProperty(object, "Type"))
        addUnique(labels, seenLabels,
            SquareRules.GetObjectProperty(object, "FurnitureType"))
    end
    return {
        labels = labels,
        spriteNames = sprites,
        objectName = text(call(object, "getObjectName")),
        displayName = text(call(object, "getName")),
        spriteName = text(spriteName),
    }
end

local function listSize(list)
    if not list then return 0 end
    local size = call(list, "size")
    if size ~= nil then return tonumber(size) or 0 end
    return #list
end

local function listItem(list, index)
    local item = call(list, "get", index)
    if item ~= nil then return item end
    return list[index + 1]
end

local function objectBudget(value)
    return math.max(1, math.min(Observer.MAX_OBJECTS_HARD,
        math.floor(number(value) or Observer.MAX_OBJECTS)))
end

local function cacheKey(originX, originY, originZ, radius, maxObjects, cacheTag)
    return tostring(math.floor(originX)) .. ":"
        .. tostring(math.floor(originY)) .. ":"
        .. tostring(originZ) .. ":" .. tostring(radius) .. ":"
        .. tostring(maxObjects) .. ":" .. tostring(cacheTag or "plain")
end

local function observationFor(output, seen, object, square, originZ,
    specialKind, objectIndex, decorate, suppliedMetadata)
    if not object or seen[object] then return end
    local squareX = number(call(square, "getX"))
    local squareY = number(call(square, "getY"))
    local squareZ = number(call(square, "getZ")) or originZ
    local x = number(call(object, "getX")) or squareX
    local y = number(call(object, "getY")) or squareY
    local z = number(call(object, "getZ")) or squareZ
    if x == nil or y == nil or z ~= originZ then return end

    local metadata = suppliedMetadata or metadataFor(object)
    metadata.special = specialKind
        or (call(object, "isCampfire") == true and "campfire" or nil)
    seen[object] = true
    local keyPrefix = metadata.special == "campfire"
        and "campfire" or "world_object"
    local observationKey = keyPrefix .. ":" .. tostring(x) .. ":"
        .. tostring(y) .. ":" .. tostring(z) .. ":"
        .. tostring(objectIndex or 0)
    local observation = {
        x = x,
        y = y,
        z = z,
        objectIndex = objectIndex,
        objectKey = observationKey,
        targetID = observationKey,
        resourceKey = observationKey,
        metadata = metadata,
        source = "client_loaded_world",
    }
    if type(decorate) == "function" then
        local ok, facts = pcall(decorate, object, square, observation)
        if ok and type(facts) == "table" then
            observation.facts = copyPrimitive(facts)
        end
    end
    output[#output + 1] = observation
end

local function scan(cell, originX, originY, originZ, radius, maxObjects,
    decorate, filter, includeUnknown)
    local observations = {}
    local seen = {}
    local objectCount = 0
    local inspectedObjectCount = 0
    local rejectedObjectCount = 0
    local filterErrorCount = 0
    local campfireCount = 0
    local truncated = false
    local inspectionTruncated = false
    local inspectionLimit = math.min(Observer.MAX_INSPECTED_OBJECTS,
        math.max(maxObjects, maxObjects * 8))
    local baseX = math.floor(originX)
    local baseY = math.floor(originY)
    local radiusSq = (radius + 0.5) * (radius + 0.5)

    local function visit(dx, dy)
        local squareDX
        local squareDY
        local square
        local objects
        local campfire
        squareDX = baseX + dx + 0.5 - originX
        squareDY = baseY + dy + 0.5 - originY
        if squareDX * squareDX + squareDY * squareDY > radiusSq then
            return
        end
        square = call(cell, "getGridSquare", baseX + dx, baseY + dy,
            originZ)
        if not square then return end

        -- Campfires are GlobalObjects in some engine versions and are not
        -- guaranteed to appear in getObjects().  Check them before ordinary
        -- objects and continue this cheap special check after the ordinary
        -- budget is exhausted.
        campfire = call(square, "getCampfire")
        if campfire and not seen[campfire]
            and campfireCount < Observer.MAX_SPECIAL_OBJECTS
        then
            campfireCount = campfireCount + 1
            observationFor(observations, seen, campfire, square,
                originZ, "campfire", -1, decorate)
        end

        if truncated or inspectionTruncated then return end
        objects = call(square, "getObjects")
        for index = 0, listSize(objects) - 1 do
            if objectCount >= maxObjects then
                truncated = true
                break
            end
            if inspectedObjectCount >= inspectionLimit then
                inspectionTruncated = true
                break
            end
            inspectedObjectCount = inspectedObjectCount + 1
            local object = listItem(objects, index)
            if object then
                local metadata = metadataFor(object)
                local accepted = includeUnknown == true
                    or type(filter) ~= "function"
                if not accepted then
                    local filterOk, filterResult = pcall(filter, object,
                        square, metadata)
                    if filterOk then
                        accepted = filterResult == true
                    else
                        filterErrorCount = filterErrorCount + 1
                    end
                end
                if accepted then
                    objectCount = objectCount + 1
                    observationFor(observations, seen, object, square,
                        originZ, nil, index, decorate, metadata)
                else
                    rejectedObjectCount = rejectedObjectCount + 1
                end
            end
        end
    end

    -- Visit the nearest squares first. The previous row-major order could
    -- consume the ordinary budget on distant clutter and miss a nearby bin.
    for ring = 0, radius do
        if ring == 0 then
            visit(0, 0)
        else
            for dx = -ring, ring do
                visit(dx, -ring)
                if ring > 0 then visit(dx, ring) end
            end
            for dy = -ring + 1, ring - 1 do
                visit(-ring, dy)
                visit(ring, dy)
            end
        end
    end
    return observations, objectCount, truncated, campfireCount,
        inspectedObjectCount, rejectedObjectCount, filterErrorCount,
        inspectionTruncated
end

function Observer.ClearCache()
    Observer.Cache = {}
end

function Observer.Invalidate(cell)
    if cell then
        Observer.Cache[cell] = nil
    else
        Observer.ClearCache()
    end
end

function Observer.Observe(cell, originX, originY, originZ, options)
    options = type(options) == "table" and options or {}
    originX = number(originX)
    originY = number(originY)
    originZ = number(originZ) or 0
    if not cell then return nil, { reason = "cell_unavailable" } end
    if originX == nil or originY == nil then
        return nil, { reason = "world_origin_unavailable" }
    end
    if type(cell.getGridSquare) ~= "function" then
        return nil, { reason = "cell_unavailable" }
    end

    local radius = math.max(1, math.min(Observer.MAX_RADIUS,
        math.floor(number(options.radius) or 16)))
    local maxObjects = objectBudget(options.maxObjects)
    local timestamp = number(options.nowMs) or 0
    local cacheMs = math.max(0, number(options.cacheMs)
        or Observer.DEFAULT_CACHE_MS)
    local bucket = Observer.Cache[cell]
    if not bucket then
        bucket = {}
        Observer.Cache[cell] = bucket
    end
    local key = cacheKey(originX, originY, originZ, radius, maxObjects,
        options.cacheTag)
    local cached = bucket[key]
    if cached and timestamp - cached.at <= cacheMs then
        return cached.observations, {
            objectCount = cached.objectCount,
            campfireCount = cached.campfireCount,
            truncated = cached.truncated,
            inspectedObjectCount = cached.inspectedObjectCount,
            rejectedObjectCount = cached.rejectedObjectCount,
            filterErrorCount = cached.filterErrorCount,
            inspectionTruncated = cached.inspectionTruncated,
            maxObjects = cached.maxObjects,
            cached = true,
        }
    end

    local observations, objectCount, truncated, campfireCount,
        inspectedObjectCount, rejectedObjectCount, filterErrorCount,
        inspectionTruncated = scan(
        cell, originX, originY, originZ, radius, maxObjects,
        options.decorate, options.filter or options.candidate,
        options.includeUnknown == true)
    bucket[key] = {
        at = timestamp,
        observations = observations,
        objectCount = objectCount,
        campfireCount = campfireCount,
        truncated = truncated,
        inspectedObjectCount = inspectedObjectCount,
        rejectedObjectCount = rejectedObjectCount,
        filterErrorCount = filterErrorCount,
        inspectionTruncated = inspectionTruncated,
        maxObjects = maxObjects,
    }
    return observations, {
        objectCount = objectCount,
        campfireCount = campfireCount,
        truncated = truncated,
        inspectedObjectCount = inspectedObjectCount,
        rejectedObjectCount = rejectedObjectCount,
        filterErrorCount = filterErrorCount,
        inspectionTruncated = inspectionTruncated,
        maxObjects = maxObjects,
        cached = false,
    }
end

-- Detailed observations use the same bounded scan and cache as semantic target
-- hints, but store provider facts alongside each primitive record. A distinct
-- cache tag prevents a plain hint lookup from satisfying a detailed debug
-- lookup with an undecorated snapshot.
function Observer.ObserveDetailed(cell, originX, originY, originZ, options)
    options = type(options) == "table" and options or {}
    local detailed = {}
    for key, value in pairs(options) do detailed[key] = value end
    detailed.cacheTag = detailed.cacheTag or "detailed"
    return Observer.Observe(cell, originX, originY, originZ, detailed)
end

return Observer
