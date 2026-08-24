if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Locator = PNC.NearbyResourceLocator
local H = Locator.Internal

function H.ListSize(list)
    return list and list.size and list:size() or 0
end

function H.ListItem(list, index)
    return list and list.get and list:get(index) or nil
end

function H.Call(object, method, ...)
    local fn = object and object[method]
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, object, ...)
    return ok and value or nil
end

function H.NowMs()
    if getTimestampMs then return tonumber(getTimestampMs()) or 0 end
    local gameTime = getGameTime and getGameTime() or nil
    local hours = gameTime and H.Call(gameTime, "getWorldAgeHours") or 0
    return (tonumber(hours) or 0) * 3600000
end

function H.KeyFor(item, x, y, z, ordinal)
    local fullType = H.Call(item, "getFullType") or "item"
    local id = H.Call(item, "getID")
    return tostring(fullType) .. "@" .. tostring(x) .. ":"
        .. tostring(y) .. ":" .. tostring(z) .. "#"
        .. tostring(id or ordinal or 0)
end

function H.ObjectKeyFor(object, x, y, z, ordinal)
    local sprite = H.Call(H.Call(object, "getSprite"), "getName")
    local id = H.Call(object, "getID")
    return tostring(sprite or "object") .. "@" .. tostring(x) .. ":"
        .. tostring(y) .. ":" .. tostring(z) .. "#"
        .. tostring(id or ordinal or 0)
end

function H.Position(square)
    local x = H.Call(square, "getX")
    local y = H.Call(square, "getY")
    local z = H.Call(square, "getZ")
    if x == nil or y == nil then return nil end
    return (tonumber(x) or 0) + 0.5, (tonumber(y) or 0) + 0.5,
        tonumber(z) or 0
end

function H.CacheKey(originX, originY, originZ, options)
    local root = tostring(options.cacheKey or "")
    if root == "" then return nil end
    return root .. "|" .. tostring(math.floor(originX)) .. ":"
        .. tostring(math.floor(originY)) .. ":" .. tostring(originZ)
end

function H.ValidCached(cached, accept)
    return cached and cached.value and (not accept or accept(cached.value))
end

function Locator.Invalidate(cacheKeyValue)
    local prefix = tostring(cacheKeyValue or "")
    for key in pairs(Locator.Cache) do
        if prefix == "" or string.sub(key, 1, #prefix) == prefix then
            Locator.Cache[key] = nil
        end
    end
end

Locator.KeyFor = H.KeyFor
Locator.ObjectKeyFor = H.ObjectKeyFor
