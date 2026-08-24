if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Locator = PNC.NearbyResourceLocator
local H = Locator.Internal

function H.AddItem(output, seen, item, owner, square, ordinal, originX,
    originY, originZ)
    if not item or seen[item] then return end
    local x, y, z = H.Position(square)
    if not x then return end
    local dx, dy = x - originX, y - originY
    if z ~= originZ then return end
    seen[item] = true
    output[#output + 1] = {
        item = item, owner = owner, square = square, x = x, y = y, z = z,
        distSq = dx * dx + dy * dy, key = H.KeyFor(item, x, y, z, ordinal),
    }
end

function H.WalkContainer(output, seen, container, owner, square, originX,
    originY, originZ, depth)
    if not container or depth > 6 then return end
    local items = H.Call(container, "getItems")
    for index = 0, H.ListSize(items) - 1 do
        local item = H.ListItem(items, index)
        H.AddItem(output, seen, item, owner, square, index, originX, originY,
            originZ)
        local nested = H.Call(item, "getItemContainer")
        if nested then
            H.WalkContainer(output, seen, nested, owner, square, originX,
                originY, originZ, depth + 1)
        end
    end
end

function H.ScanSquare(output, seen, square, originX, originY, originZ)
    local objects = H.Call(square, "getObjects")
    for index = 0, H.ListSize(objects) - 1 do
        local object = H.ListItem(objects, index)
        local container = H.Call(object, "getContainer")
        if container then
            H.WalkContainer(output, seen, container, object, square, originX,
                originY, originZ, 0)
        end
    end
    local worldObjects = H.Call(square, "getWorldObjects")
    for index = 0, H.ListSize(worldObjects) - 1 do
        local worldObject = H.ListItem(worldObjects, index)
        local item = H.Call(worldObject, "getItem")
        H.AddItem(output, seen, item, worldObject, square, index, originX,
            originY, originZ)
        local container = H.Call(item, "getItemContainer")
        if container then
            H.WalkContainer(output, seen, container, worldObject, square,
                originX, originY, originZ, 0)
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
    local output, seen = {}, {}
    local baseX, baseY = math.floor(originX), math.floor(originY)
    for dx = -radius, radius do
        for dy = -radius, radius do
            local square = cell:getGridSquare(baseX + dx, baseY + dy, originZ)
            if square then
                H.ScanSquare(output, seen, square, originX, originY, originZ)
            end
        end
    end
    table.sort(output, function(a, b)
        if a.distSq ~= b.distSq then return a.distSq < b.distSq end
        return tostring(a.key) < tostring(b.key)
    end)
    local accepted
    for index = 1, #output do
        if not options.accept or options.accept(output[index]) then
            accepted = output[index]
            break
        end
    end
    if key then Locator.Cache[key] = { at = timestamp, value = accepted } end
    return accepted
end
