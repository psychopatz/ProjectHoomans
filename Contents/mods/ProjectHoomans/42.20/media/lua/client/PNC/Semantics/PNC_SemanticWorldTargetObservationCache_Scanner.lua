-- Bounded traversal of loaded-cell grid squares for world observations.
-- The cache facade supplies limits and owns result lifetime.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Scanner = PNC.Semantics.ClientWorldTargetObservationScanner or {}
PNC.Semantics.ClientWorldTargetObservationScanner = Scanner

local Projection = PNC.Semantics.ClientWorldTargetObservationProjection
    or require "PNC/Semantics/PNC_SemanticWorldTargetObservationCache_Projection"

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

function Scanner.Scan(observer, cell, originX, originY, originZ,
    radius, maxObjects, decorate, filter, includeUnknown)
    local observations = {}
    local seen = {}
    local objectCount = 0
    local inspectedObjectCount = 0
    local rejectedObjectCount = 0
    local filterErrorCount = 0
    local campfireCount = 0
    local truncated = false
    local inspectionTruncated = false
    local inspectionLimit = math.min(observer.MAX_INSPECTED_OBJECTS,
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
            and campfireCount < observer.MAX_SPECIAL_OBJECTS
        then
            campfireCount = campfireCount + 1
            Projection.AddObservation(observations, seen, campfire, square,
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
                local metadata = Projection.MetadataFor(object)
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
                    Projection.AddObservation(observations, seen, object, square,
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

return Scanner
