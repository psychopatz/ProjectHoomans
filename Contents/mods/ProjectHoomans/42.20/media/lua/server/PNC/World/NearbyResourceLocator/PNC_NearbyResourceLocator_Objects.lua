if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Locator = PNC.NearbyResourceLocator
local H = Locator.Internal

function H.AddObject(output, seen, object, square, ordinal, originX,
    originY, originZ)
    if not object or seen[object] then return end
    local x, y, z = H.Position(square)
    if not x then return end
    local dx, dy = x - originX, y - originY
    if z ~= originZ then return end
    seen[object] = true
    output[#output + 1] = {
        object = object, square = square, x = x, y = y, z = z,
        distSq = dx * dx + dy * dy,
        key = H.ObjectKeyFor(object, x, y, z, ordinal),
    }
end

-- Some world systems (campfires, farming plots, traps, and similar
-- resources) are represented by a GlobalObject instead of an IsoObject in
-- square:getObjects().  Keep discovery generic by allowing a bounded caller
-- supplied square hook to add one primitive locator entry.  The hook is
-- read-only and its live object is discarded as soon as the lookup ends.
function H.AddSpecialObject(output, seen, special, square, ordinal, originX,
    originY, originZ)
    local object = type(special) == "table" and special.object or special
    local specialKey = type(special) == "table" and special.key or nil
    local source = type(special) == "table" and special.source or nil
    local x, y, z
    local dx, dy
    if not object or seen[object] then return end
    x, y, z = H.Position(square)
    if not x then return end
    dx, dy = x - originX, y - originY
    if z ~= originZ then return end
    seen[object] = true
    output[#output + 1] = {
        object = object, square = square, x = x, y = y, z = z,
        distSq = dx * dx + dy * dy,
        key = tostring(specialKey or H.ObjectKeyFor(
            object, x, y, z, ordinal)),
        source = source,
    }
end

function H.ScanSquareObjects(output, seen, square, originX, originY,
    originZ, options)
    local objects = H.Call(square, "getObjects")
    for index = 0, H.ListSize(objects) - 1 do
        H.AddObject(output, seen, H.ListItem(objects, index), square, index,
            originX, originY, originZ)
    end
    if options and type(options.specialObject) == "function" then
        local ok, special = pcall(options.specialObject, square)
        if ok and special then
            H.AddSpecialObject(output, seen, special, square, -1, originX,
                originY, originZ)
        end
    end
end

function Locator.FindObject(origin, options)
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
    local key = H.CacheKey(originX, originY, originZ, {
        cacheKey = tostring(options.cacheKey or "") .. ":objects",
    })
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
    -- Include the whole origin square while excluding diagonal corners that
    -- lie outside the requested tile radius.
    local scanRadius = radius + 0.5
    local radiusSq = scanRadius * scanRadius
    for dx = -radius, radius do
        for dy = -radius, radius do
            local squareDX = baseX + dx + 0.5 - originX
            local squareDY = baseY + dy + 0.5 - originY
            if squareDX * squareDX + squareDY * squareDY <= radiusSq then
                local square = cell:getGridSquare(baseX + dx, baseY + dy,
                    originZ)
                if square then
                    H.ScanSquareObjects(output, seen, square, originX,
                        originY, originZ, options)
                end
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
    if key then
        Locator.Cache[key] = {
            at = timestamp, value = accepted, negative = accepted == nil,
        }
    end
    return accepted
end
