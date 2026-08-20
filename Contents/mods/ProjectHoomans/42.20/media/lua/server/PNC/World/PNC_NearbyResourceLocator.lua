-- Fast, deterministic queries over loaded world resources.  Resource
-- policies belong in callers; this module only discovers positioned items.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.NearbyResourceLocator = PNC.NearbyResourceLocator or {}

local Locator = PNC.NearbyResourceLocator
Locator.Cache = Locator.Cache or {}
Locator.DEFAULT_RADIUS = 12
Locator.DEFAULT_CACHE_MS = 500

local function listSize(list)
    return list and list.size and list:size() or 0
end

local function listItem(list, index)
    return list and list.get and list:get(index) or nil
end

local function call(object, method, ...)
    local fn = object and object[method]
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, object, ...)
    return ok and value or nil
end

local function nowMs()
    if getTimestampMs then return tonumber(getTimestampMs()) or 0 end
    local gameTime = getGameTime and getGameTime() or nil
    local hours = gameTime and call(gameTime, "getWorldAgeHours") or 0
    return (tonumber(hours) or 0) * 3600000
end

local function keyFor(item, x, y, z, ordinal)
    local fullType = call(item, "getFullType") or "item"
    local id = call(item, "getID")
    return tostring(fullType) .. "@" .. tostring(x) .. ":"
        .. tostring(y) .. ":" .. tostring(z) .. "#"
        .. tostring(id or ordinal or 0)
end

local function position(square)
    local x = call(square, "getX")
    local y = call(square, "getY")
    local z = call(square, "getZ")
    if x == nil or y == nil then return nil end
    return (tonumber(x) or 0) + 0.5, (tonumber(y) or 0) + 0.5,
        tonumber(z) or 0
end

local function addItem(output, seen, item, owner, square, ordinal, originX,
    originY, originZ)
    if not item or seen[item] then return end
    local x, y, z = position(square)
    if not x then return end
    local dx, dy = x - originX, y - originY
    if z ~= originZ then return end
    seen[item] = true
    output[#output + 1] = {
        item = item, owner = owner, square = square, x = x, y = y, z = z,
        distSq = dx * dx + dy * dy, key = keyFor(item, x, y, z, ordinal),
    }
end

local function walkContainer(output, seen, container, owner, square, originX,
    originY, originZ, depth)
    if not container or depth > 6 then return end
    local items = call(container, "getItems")
    for index = 0, listSize(items) - 1 do
        local item = listItem(items, index)
        addItem(output, seen, item, owner, square, index, originX, originY,
            originZ)
        local nested = call(item, "getItemContainer")
        if nested then
            walkContainer(output, seen, nested, owner, square, originX,
                originY, originZ, depth + 1)
        end
    end
end

local function scanSquare(output, seen, square, originX, originY, originZ)
    local objects = call(square, "getObjects")
    for index = 0, listSize(objects) - 1 do
        local object = listItem(objects, index)
        local container = call(object, "getContainer")
        if container then
            walkContainer(output, seen, container, object, square, originX,
                originY, originZ, 0)
        end
    end
    local worldObjects = call(square, "getWorldObjects")
    for index = 0, listSize(worldObjects) - 1 do
        local worldObject = listItem(worldObjects, index)
        local item = call(worldObject, "getItem")
        addItem(output, seen, item, worldObject, square, index, originX,
            originY, originZ)
        local container = call(item, "getItemContainer")
        if container then
            walkContainer(output, seen, container, worldObject, square,
                originX, originY, originZ, 0)
        end
    end
end

local function cacheKey(originX, originY, originZ, options)
    local root = tostring(options.cacheKey or "")
    if root == "" then return nil end
    return root .. "|" .. tostring(math.floor(originX)) .. ":"
        .. tostring(math.floor(originY)) .. ":" .. tostring(originZ)
end

local function validCached(cached, accept)
    return cached and cached.value and (not accept or accept(cached.value))
end

function Locator.Find(origin, options)
    options = type(options) == "table" and options or {}
    if not origin then return nil end
    local originX = call(origin, "getX")
    local originY = call(origin, "getY")
    local originZ = call(origin, "getZ")
    if originX == nil or originY == nil then return nil end
    originX, originY, originZ = tonumber(originX) or 0, tonumber(originY) or 0,
        tonumber(originZ) or 0
    local radius = math.max(0, math.floor(tonumber(options.radius)
        or Locator.DEFAULT_RADIUS))
    local key = cacheKey(originX, originY, originZ, options)
    local timestamp = nowMs()
    local cached = key and Locator.Cache[key] or nil
    if cached and timestamp - cached.at <= (tonumber(options.cacheMs)
        or Locator.DEFAULT_CACHE_MS) and validCached(cached, options.accept)
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
                scanSquare(output, seen, square, originX, originY, originZ)
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

function Locator.Invalidate(cacheKeyValue)
    local prefix = tostring(cacheKeyValue or "")
    for key in pairs(Locator.Cache) do
        if prefix == "" or string.sub(key, 1, #prefix) == prefix then
            Locator.Cache[key] = nil
        end
    end
end

Locator.KeyFor = keyFor

return Locator
