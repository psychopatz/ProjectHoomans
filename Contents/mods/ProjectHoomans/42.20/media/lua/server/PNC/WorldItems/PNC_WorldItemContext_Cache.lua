-- Lazy spatial-bucket source/object snapshot cache shared across subsystems.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.WorldItemContext = PNC.WorldItemContext or {}
PNC.WorldItemContext.Cache = PNC.WorldItemContext.Cache or {}

local Cache = PNC.WorldItemContext.Cache
local Zones = PNC.WorldItemContext.Zones

local BUCKET_SIZE = 8
local CACHE_TTL_MS = 2500
local MAX_BUCKETS = 64

Cache.BUCKET_SIZE = BUCKET_SIZE
Cache._buckets = Cache._buckets or {}
Cache._bucketOrder = Cache._bucketOrder or {}
Cache._stats = Cache._stats or { hits = 0, misses = 0 }

local function nowMs()
    if PNC and PNC.Core and PNC.Core.Now then
        return tonumber(PNC.Core.Now()) or 0
    end
    if getTimestampMs then return tonumber(getTimestampMs()) or 0 end
    local gameTime = getGameTime and getGameTime() or nil
    if gameTime and type(gameTime.getWorldAgeHours) == "function" then
        local ok, hours = pcall(gameTime.getWorldAgeHours, gameTime)
        if ok and hours then return (tonumber(hours) or 0) * 3600000 end
    end
    return 0
end

local function safeCall(obj, method, ...)
    if not obj or type(obj[method]) ~= "function" then return nil end
    local ok, value = pcall(obj[method], obj, ...)
    return ok and value or nil
end

Cache.NowMs = nowMs
Cache.SafeCall = safeCall

function Cache.ToLuaArray(list)
    local output = {}
    if not list then return output end
    if type(list) == "table" and not list.size then
        for i = 1, #list do output[#output + 1] = list[i] end
        return output
    end
    if list.size and list.get then
        for i = 0, list:size() - 1 do output[#output + 1] = list:get(i) end
    end
    return output
end

local function isCorpse(object)
    if not object then return false end
    if instanceof then
        local ok, result = pcall(instanceof, object, "IsoDeadBody")
        if ok and result == true then return true end
    end
    if object.isDeadBody == true then return true end
    local name = string.lower(tostring(safeCall(object, "getObjectName")
        or safeCall(object, "getName") or ""))
    return name == "corpse" or name == "isodeadbody"
end

local function isCurtain(object)
    if not object then return false end
    if instanceof then
        local ok, result = pcall(instanceof, object, "IsoCurtain")
        if ok and result == true then return true end
    end
    if object.isCurtain == true then return true end
    local name = string.lower(tostring(safeCall(object, "getObjectName") or ""))
    return name == "curtain" or name == "isocurtain"
end

local function pushEntry(entries, kind, square, obj, cont, ci, sx, sy, bz)
    if not cont then return end
    entries[#entries + 1] = {
        sourceType = kind, square = square, object = obj,
        container = cont, containerIndex = ci, x = sx, y = sy, z = bz,
    }
end

local function inspectSquareSnapshot(square, sx, sy, bz)
    if not square then return false end
    local entries, seenObj = {}, {}
    -- Never call IsoDeadBody:getItem() during scans (Build 42 crashes).
    local corpses = Cache.ToLuaArray(safeCall(square, "getStaticMovingObjects"))
    local objects = Cache.ToLuaArray(safeCall(square, "getObjects"))

    local function pushCorpse(obj)
        if not seenObj[obj] then
            seenObj[obj] = true
            pushEntry(entries, "corpse", square, obj,
                safeCall(obj, "getContainer"), nil, sx, sy, bz)
        end
    end

    local function pushCurtain(curtainObj)
        if curtainObj and not seenObj[curtainObj] then
            seenObj[curtainObj] = true
            entries[#entries + 1] = {
                sourceType = "curtain", square = square, object = curtainObj,
                x = sx, y = sy, z = bz,
            }
        end
    end

    for i = 1, #corpses do
        if isCorpse(corpses[i]) then pushCorpse(corpses[i]) end
    end
    for i = 1, #objects do
        local obj = objects[i]
        if isCorpse(obj) then
            pushCorpse(obj)
        elseif isCurtain(obj) then
            pushCurtain(obj)
        else
            local winCurtain = safeCall(obj, "HasCurtains")
            if winCurtain then
                pushCurtain(winCurtain)
            end
            local cCount = tonumber(safeCall(obj, "getContainerCount")) or 0
            if cCount > 0 and obj.getContainerByIndex then
                for ci = 0, cCount - 1 do
                    pushEntry(entries, "container", square, obj,
                        safeCall(obj, "getContainerByIndex", ci), ci, sx, sy, bz)
                end
            else
                pushEntry(entries, "container", square, obj,
                    safeCall(obj, "getContainer"), 0, sx, sy, bz)
            end
        end
    end

    local worldObjs = Cache.ToLuaArray(safeCall(square, "getWorldObjects"))
    if #worldObjs > 0 then
        entries[#entries + 1] = {
            sourceType = "floor", square = square, worldObjects = worldObjs,
            x = sx, y = sy, z = bz,
        }
    end
    return {
        square = square, x = sx, y = sy, z = bz,
        entries = entries, objects = objects, worldObjects = worldObjs,
    }
end

local function bucketKeyFor(cell, bx, by, bz)
    return tostring(cell) .. ":" .. tostring(bx) .. ":"
        .. tostring(by) .. ":" .. tostring(bz)
end

local function tileCoords(tx, ty, bz)
    local ix = math.floor(tonumber(tx) or 0)
    local iy = math.floor(tonumber(ty) or 0)
    local iz = math.floor(tonumber(bz) or 0)
    return ix, iy, iz, math.floor(ix / BUCKET_SIZE), math.floor(iy / BUCKET_SIZE)
end

function Cache.ResolveBucket(cell, bx, by, bz, now)
    now = now or nowMs()
    local key = bucketKeyFor(cell, bx, by, bz)
    local cached = Cache._buckets[key]
    if cached and (now - cached.builtAt) < CACHE_TTL_MS then return cached end
    if cached then
        cached.builtAt, cached.bySquare = now, {}
        return cached
    end
    if #Cache._bucketOrder >= MAX_BUCKETS then
        local oldest = table.remove(Cache._bucketOrder, 1)
        if oldest then Cache._buckets[oldest] = nil end
    end
    local record = { key = key, builtAt = now, bySquare = {} }
    Cache._buckets[key] = record
    Cache._bucketOrder[#Cache._bucketOrder + 1] = key
    return record
end

function Cache.ResolveSquareSnapshot(cell, bucket, tx, ty, bz, metrics)
    local sqKey = tostring(tx) .. ":" .. tostring(ty)
    local cached = bucket.bySquare[sqKey]
    if cached ~= nil then
        Cache._stats.hits = Cache._stats.hits + 1
        if metrics then metrics.cacheHits = (metrics.cacheHits or 0) + 1 end
        return cached ~= false and cached or nil
    end
    Cache._stats.misses = Cache._stats.misses + 1
    if metrics then metrics.cacheMisses = (metrics.cacheMisses or 0) + 1 end
    local res = inspectSquareSnapshot(cell:getGridSquare(tx, ty, bz), tx, ty, bz)
    bucket.bySquare[sqKey] = res
    return res ~= false and res or nil
end

function Cache.ResolveSquareSources(cell, bucket, tx, ty, bz, metrics)
    local snap = Cache.ResolveSquareSnapshot(cell, bucket, tx, ty, bz, metrics)
    return (snap and #snap.entries > 0) and snap or nil
end

function Cache.GetSquareSnapshot(cell, tx, ty, bz, now, metrics)
    if not (cell and cell.getGridSquare and tx and ty) then return nil end
    local ix, iy, iz, bx, by = tileCoords(tx, ty, bz)
    local b = Cache.ResolveBucket(cell, bx, by, iz, now or nowMs())
    return Cache.ResolveSquareSnapshot(cell, b, ix, iy, iz, metrics)
end

function Cache.ClearSquare(cell, tx, ty, bz)
    if not (cell and tx and ty) then return end
    local ix, iy, iz, bx, by = tileCoords(tx, ty, bz)
    local c = Cache._buckets[bucketKeyFor(cell, bx, by, iz)]
    if c then c.bySquare[tostring(ix) .. ":" .. tostring(iy)] = nil end
end

function Cache.GetStats() return { hits = Cache._stats.hits, misses = Cache._stats.misses } end
function Cache.ResetStats() Cache._stats = { hits = 0, misses = 0 } end
function Cache.Invalidate()
    Cache._buckets, Cache._bucketOrder = {}, {}
    if Zones and Zones.InvalidateCache then Zones.InvalidateCache() end
end

return Cache
