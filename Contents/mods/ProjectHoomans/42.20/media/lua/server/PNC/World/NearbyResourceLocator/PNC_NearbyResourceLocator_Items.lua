if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Locator = PNC.NearbyResourceLocator
local H = Locator.Internal

function H.AddItem(output, seen, item, owner, square, ordinal, originX,
    originY, originZ, bestState)
    if not item or seen[item] then return end
    local x, y, z = H.Position(square)
    if not x then return end
    if z ~= originZ then return end
    local dx, dy = x - originX, y - originY
    local distSq = dx * dx + dy * dy
    if bestState then
        if bestState.entry ~= nil and distSq > bestState.distSq then
            return
        end
        seen[item] = true
        local entry = {
            item = item, owner = owner, square = square, x = x, y = y, z = z,
            distSq = distSq, key = H.KeyFor(item, x, y, z, ordinal),
        }
        if not bestState.accept or bestState.accept(entry) then
            if bestState.entry == nil
                or distSq < bestState.distSq
                or (distSq == bestState.distSq
                    and tostring(entry.key) < tostring(bestState.entry.key))
            then
                bestState.entry = entry
                bestState.distSq = distSq
            end
        end
        return
    end
    seen[item] = true
    output[#output + 1] = {
        item = item, owner = owner, square = square, x = x, y = y, z = z,
        distSq = distSq, key = H.KeyFor(item, x, y, z, ordinal),
    }
end

function H.WalkContainer(output, seen, container, owner, square, originX,
    originY, originZ, depth, bestState)
    if not container or depth > 6 then return end
    local items = H.Call(container, "getItems")
    for index = 0, H.ListSize(items) - 1 do
        local item = H.ListItem(items, index)
        H.AddItem(output, seen, item, owner, square, index, originX, originY,
            originZ, bestState)
        local nested = H.Call(item, "getItemContainer")
        if nested then
            H.WalkContainer(output, seen, nested, owner, square, originX,
                originY, originZ, depth + 1, bestState)
        end
    end
end

function H.ScanSquare(output, seen, square, originX, originY, originZ, bestState)
    if bestState and bestState.entry ~= nil then
        local sx, sy = H.Position(square)
        if sx then
            local sdx, sdy = sx - originX, sy - originY
            if (sdx * sdx + sdy * sdy) > bestState.distSq then
                return
            end
        end
    end
    local objects = H.Call(square, "getObjects")
    for index = 0, H.ListSize(objects) - 1 do
        local object = H.ListItem(objects, index)
        local container = H.Call(object, "getContainer")
        if container then
            H.WalkContainer(output, seen, container, object, square, originX,
                originY, originZ, 0, bestState)
        end
    end
    local worldObjects = H.Call(square, "getWorldObjects")
    for index = 0, H.ListSize(worldObjects) - 1 do
        local worldObject = H.ListItem(worldObjects, index)
        local item = H.Call(worldObject, "getItem")
        H.AddItem(output, seen, item, worldObject, square, index, originX,
            originY, originZ, bestState)
        local container = H.Call(item, "getItemContainer")
        if container then
            H.WalkContainer(output, seen, container, worldObject, square,
                originX, originY, originZ, 0, bestState)
        end
    end
end

function H.ScanSnapshot(output, seen, snap, originX, originY, originZ, bestState)
    local square = snap and snap.square
    if not square then return end
    if bestState and bestState.entry ~= nil then
        local sx, sy = H.Position(square)
        if sx then
            local sdx, sdy = sx - originX, sy - originY
            if (sdx * sdx + sdy * sdy) > bestState.distSq then
                return
            end
        end
    end
    local objects = snap.objects or {}
    for index = 1, #objects do
        local object = objects[index]
        local container = H.Call(object, "getContainer")
        if container then
            H.WalkContainer(output, seen, container, object, square, originX,
                originY, originZ, 0, bestState)
        end
    end
    local worldObjects = snap.worldObjects or {}
    for index = 1, #worldObjects do
        local worldObject = worldObjects[index]
        local item = H.Call(worldObject, "getItem")
        H.AddItem(output, seen, item, worldObject, square, index - 1,
            originX, originY, originZ, bestState)
        local container = H.Call(item, "getItemContainer")
        if container then
            H.WalkContainer(output, seen, container, worldObject, square,
                originX, originY, originZ, 0, bestState)
        end
    end
end

function Locator.Find(origin, options)
    options = type(options) == "table" and options or {}
    if not origin then return nil end
    local originX = H.Call(origin, "getX")
    local originY = H.Call(origin, "getY")
    local originZ = H.Call(origin, "getZ")
    if originX == nil or originY == nil then return nil end
    originX, originY, originZ = tonumber(originX) or 0, tonumber(originY) or 0,
        tonumber(originZ) or 0
    local radius = math.max(0, math.floor(tonumber(options.radius)
        or Locator.DEFAULT_RADIUS))
    local key = H.CacheKey(originX, originY, originZ, options)
    local timestamp = H.NowMs()
    local cached = key and Locator.Cache[key] or nil
    if cached and timestamp - cached.at <= (tonumber(options.cacheMs)
        or Locator.DEFAULT_CACHE_MS) and H.ValidCached(cached, options.accept)
    then
        return cached.value
    end
    local cell = options.cell or (getCell and getCell() or nil)
    if not cell or not cell.getGridSquare then return nil end
    local seen = {}
    local bestState = {
        entry = nil,
        distSq = math.huge,
        accept = options.accept,
    }
    local context = PNC and PNC.WorldItemContext
    if context and context.ForEachSquareInRadius then
        context.ForEachSquareInRadius(cell, originX, originY, originZ, radius,
            function(snap)
                H.ScanSnapshot(nil, seen, snap, originX, originY, originZ, bestState)
            end, {
                originX = originX,
                originY = originY,
                allowRestrictedZones = options.allowRestrictedZones ~= false,
                now = timestamp,
                mode = "box",
            })
    else
        local baseX, baseY = math.floor(originX), math.floor(originY)
        -- Expand in concentric rings so a nearby match immediately prunes all
        -- farther rings without scanning the full 41x41 box.
        local scanRadius = radius + 0.5
        local radiusSq = scanRadius * scanRadius
        for ring = 0, radius do
            if bestState.entry ~= nil and ring > 1 then
                local minRingDist = ring - 1.5
                if minRingDist > 0 and (minRingDist * minRingDist) > bestState.distSq then
                    break
                end
            end
            for dx = -ring, ring do
                for dy = -ring, ring do
                    if math.abs(dx) == ring or math.abs(dy) == ring then
                        local squareDX = baseX + dx + 0.5 - originX
                        local squareDY = baseY + dy + 0.5 - originY
                        if squareDX * squareDX + squareDY * squareDY <= radiusSq then
                            local square = cell:getGridSquare(baseX + dx, baseY + dy,
                                originZ)
                            if square then
                                H.ScanSquare(nil, seen, square, originX, originY,
                                    originZ, bestState)
                            end
                        end
                    end
                end
            end
        end
    end
    local accepted = bestState.entry
    if key then
        Locator.Cache[key] = {
            at = timestamp, value = accepted, negative = accepted == nil,
        }
    end
    return accepted
end
