-- Bounded spiral world-item scanner with zone filtering and ring early exit.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.WorldItemContext = PNC.WorldItemContext or {}

local Context = PNC.WorldItemContext
local Zones = Context.Zones
local Classifier = Context.Classifier
local Claims = Context.Claims
local Cache = Context.Cache

Context.Scanner = Context.Scanner or {}
local Scanner = Context.Scanner
local BUCKET_SIZE = Cache.BUCKET_SIZE or 8

Scanner.Metrics = Scanner.Metrics or {
    scans = 0, squaresVisited = 0, cacheHits = 0, cacheMisses = 0,
    zoneBlocked = 0, itemsInspected = 0, earlyExits = 0, candidatesFound = 0,
}

local function nowMs() return PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0 end

local function safeCall(obj, method, ...)
    if not obj or type(obj[method]) ~= "function" then return nil end
    local ok, value = pcall(obj[method], obj, ...)
    return ok and value or nil
end

function Scanner.InvalidateCache() Cache.Invalidate() end

function Scanner.ResetMetrics()
    Scanner.Metrics = {
        scans = 0, squaresVisited = 0, cacheHits = 0, cacheMisses = 0,
        zoneBlocked = 0, itemsInspected = 0, earlyExits = 0, candidatesFound = 0,
    }
end

function Scanner.GetMetrics()
    local copy = {}
    for k, v in pairs(Scanner.Metrics) do copy[k] = v end
    return copy
end

local function sourceAllowed(sourceType, types)
    if not types then return true end
    if sourceType == "corpse" then return types.corpses ~= false end
    if sourceType == "container" then return types.containers ~= false end
    if sourceType == "floor" then return types.floorItems ~= false end
    if sourceType == "curtain" then return types.curtains ~= false end
    return true
end

local function collectRawEntries(source)
    local out = {}
    if source.sourceType == "floor" then
        local worldObjs = source.worldObjects
            or Cache.ToLuaArray(safeCall(source.square, "getWorldObjects"))
        for i = 1, #worldObjs do
            local item = safeCall(worldObjs[i], "getItem")
            if item then out[#out + 1] = { item = item, worldObject = worldObjs[i] } end
        end
        return out
    end
    local items = Cache.ToLuaArray(safeCall(source.container, "getItems"))
    for i = 1, #items do out[#out + 1] = { item = items[i] } end
    return out
end

local function inspectSource(source, npcId, filter, options, distSq, now)
    if not sourceAllowed(source.sourceType, type(options.sourceTypes) == "table" and options.sourceTypes or nil) then
        return nil, 0
    end
    if source.sourceType == "curtain" then
        if not filter or filter.mode ~= "rip_bandage" or not source.object then
            return nil, 0
        end
        local key = Claims.MakeKey("curtain", source.x, source.y, source.z, source.object)
        if Claims.IsClaimedByOther(key, npcId, now) then return nil, 1 end
        local score = 3
        return {
            sourceType = "curtain", square = source.square, object = source.object,
            container = nil, worldObject = nil, item = source.object,
            itemCtx = {
                fullType = "Base.Sheet",
                rippable = {
                    canRip = true, fabricType = "cotton",
                    outputType = "Base.RippedSheets", outputCount = 4,
                    requiresScissors = false, usableForBandage = true, clean = true,
                },
            },
            x = source.x, y = source.y, z = source.z,
            distanceSq = distSq, claimKey = key, score = score, rank = (score * 100) - distSq,
        }, 1
    end
    local raw = collectRawEntries(source)
    local limit = math.min(#raw, math.max(1, tonumber(options.maxItems) or 256))
    local best = nil
    for i = 1, limit do
        local entry = raw[i]
        local key = Claims.MakeKey(source.sourceType, source.x, source.y, source.z, entry.item)
        if not Claims.IsClaimedByOther(key, npcId, now) then
            local ctx = Classifier.InspectItem(entry.item, options)
            local ok, score = Classifier.MatchesFilter(ctx, filter, options)
            if ok then
                local rank = (score * 100) - distSq
                if not best or rank > best.rank then
                    best = {
                        sourceType = source.sourceType, square = source.square, object = source.object,
                        container = source.container, worldObject = entry.worldObject, item = entry.item,
                        itemCtx = ctx, x = source.x, y = source.y, z = source.z,
                        distanceSq = distSq, claimKey = key, score = score, rank = rank,
                    }
                end
            end
        end
    end
    return best, limit
end

function Scanner.FindBestCandidate(record, options)
    options = type(options) == "table" and options or {}
    local cell = options.cell or (getCell and getCell())
    if not record or not cell or not cell.getGridSquare then return nil, "world_unavailable" end

    local ox = math.floor(tonumber(options.x) or tonumber(record.x) or 0)
    local oy = math.floor(tonumber(options.y) or tonumber(record.y) or 0)
    local oz = math.floor(tonumber(options.z) or tonumber(record.z) or 0)
    local radius = math.max(1, math.min(16, math.floor(tonumber(options.radius) or 10)))
    local radiusSq = radius * radius
    local maxSquares = math.max(1, math.floor(tonumber(options.maxSquares) or 169))
    local maxSources = math.max(1, math.floor(tonumber(options.maxSources) or 64))
    local maxItems = math.max(1, math.floor(tonumber(options.maxItems) or 256))
    local now, filter, npcId = nowMs(), options.filter or {}, tostring(record.id or "")

    Scanner.Metrics.scans = Scanner.Metrics.scans + 1
    Claims.Prune(now)

    local visitedSq, visitedSrc, inspected = 0, 0, 0
    local best, maxRing, buckets = nil, radius, {}

    local function visit(dx, dy)
        if visitedSq >= maxSquares or visitedSrc >= maxSources or inspected >= maxItems then return true end
        local distSq = dx * dx + dy * dy
        if distSq > radiusSq then return false end
        local tx, ty = ox + dx, oy + dy
        visitedSq = visitedSq + 1
        Scanner.Metrics.squaresVisited = Scanner.Metrics.squaresVisited + 1

        if Zones.IsRestrictedSquare(tx, ty, oz, options) then
            Scanner.Metrics.zoneBlocked = Scanner.Metrics.zoneBlocked + 1
            return false
        end
        local bx, by = math.floor(tx / BUCKET_SIZE), math.floor(ty / BUCKET_SIZE)
        local bKey = tostring(bx) .. ":" .. tostring(by)
        buckets[bKey] = buckets[bKey] or Cache.ResolveBucket(cell, bx, by, oz, now)
        local sqEntry = Cache.ResolveSquareSources(cell, buckets[bKey], tx, ty, oz, Scanner.Metrics)
        if not sqEntry then return false end

        for i = 1, #sqEntry.entries do
            if visitedSrc >= maxSources or inspected >= maxItems then break end
            visitedSrc = visitedSrc + 1
            local cand, count = inspectSource(sqEntry.entries[i], npcId, filter, {
                sourceTypes = options.sourceTypes, hasScissors = options.hasScissors,
                maxItems = maxItems - inspected,
            }, distSq, now)
            inspected = inspected + count
            Scanner.Metrics.itemsInspected = Scanner.Metrics.itemsInspected + count
            if cand and (not best or cand.rank > best.rank) then
                best = cand
                if options.earlyExit ~= false then
                    maxRing = math.min(maxRing, math.ceil(math.sqrt(math.max(0, distSq))) + 1)
                end
            end
        end
        return false
    end

    for ring = 0, radius do
        if ring > maxRing then Scanner.Metrics.earlyExits = Scanner.Metrics.earlyExits + 1; break end
        if ring == 0 then
            if visit(0, 0) then break end
        else
            for dx = -ring, ring do if visit(dx, -ring) or visit(dx, ring) then break end end
            for dy = -ring + 1, ring - 1 do if visit(-ring, dy) or visit(ring, dy) then break end end
        end
        if visitedSq >= maxSquares or visitedSrc >= maxSources or inspected >= maxItems then break end
    end

    if best then Scanner.Metrics.candidatesFound = Scanner.Metrics.candidatesFound + 1; return best, nil end
    return nil, "no_matching_item"
end

return Scanner
