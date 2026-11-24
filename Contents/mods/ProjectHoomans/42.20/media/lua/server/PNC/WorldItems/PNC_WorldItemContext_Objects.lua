-- Unified world-object discovery and spatial radius iterator.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.WorldItemContext = PNC.WorldItemContext or {}

local Context = PNC.WorldItemContext
local Cache = Context.Cache
local Zones = Context.Zones
local safeCall = Cache.SafeCall
local nowMs = Cache.NowMs

Context.Objects = Context.Objects or {}
local Objects = Context.Objects

local function readOriginCoords(origin, options)
    options = type(options) == "table" and options or {}
    local ox, oy, oz = options.x, options.y, options.z
    if ox == nil and type(origin) == "table" and origin.x ~= nil then
        ox, oy, oz = origin.x, origin.y, origin.z
    end
    if ox == nil and origin ~= nil then
        ox, oy, oz = safeCall(origin, "getX"), safeCall(origin, "getY"), safeCall(origin, "getZ")
    end
    if ox == nil or oy == nil then return nil end
    return tonumber(ox) or 0, tonumber(oy) or 0, math.floor(tonumber(oz) or 0)
end

function Objects.DefaultObjectKey(object, x, y, z, ordinal)
    local sprite = safeCall(safeCall(object, "getSprite"), "getName")
    local id = safeCall(object, "getID")
    return tostring(sprite or "object") .. "@" .. tostring(x) .. ":"
        .. tostring(y) .. ":" .. tostring(z) .. "#"
        .. tostring(id or ordinal or 0)
end

function Objects.ForEachSquareInRadius(cell, ox, oy, oz, radius, visitor, options)
    if not cell or type(cell.getGridSquare) ~= "function" or type(visitor) ~= "function" then
        return 0
    end
    options = type(options) == "table" and options or {}

    local baseX, baseY = math.floor(tonumber(ox) or 0), math.floor(tonumber(oy) or 0)
    local z = math.floor(tonumber(oz) or 0)
    local rad = math.max(0, math.floor(tonumber(radius) or 10))
    local maxSquares = options.maxSquares and math.max(1, math.floor(tonumber(options.maxSquares))) or nil
    local checkZones = options.allowRestrictedZones == false and Zones ~= nil
    local metrics, now, visited, stopped = options.metrics, options.now or nowMs(), 0, false

    local scanRadiusSq = options.radiusSq
    if scanRadiusSq == nil and options.euclidean ~= false then
        scanRadiusSq = (rad + 0.5) * (rad + 0.5)
    end
    local refX = tonumber(options.originX) or (baseX + 0.5)
    local refY = tonumber(options.originY) or (baseY + 0.5)

    local function visitTile(tx, ty, ring)
        if stopped or (maxSquares and visited >= maxSquares) then
            stopped = true
            return true
        end
        local dx, dy = tx + 0.5 - refX, ty + 0.5 - refY
        local distSq = dx * dx + dy * dy
        if scanRadiusSq and distSq > scanRadiusSq then return false end
        visited = visited + 1
        if checkZones and Zones.IsRestrictedSquare(tx, ty, z, options) then return false end
        local snap = Cache.GetSquareSnapshot(cell, tx, ty, z, now, metrics)
        if snap and visitor(snap, tx, ty, z, distSq, ring) == true then
            stopped = true
            return true
        end
        return false
    end

    if options.mode == "box" then
        for dx = -rad, rad do
            for dy = -rad, rad do
                if visitTile(baseX + dx, baseY + dy, math.max(math.abs(dx), math.abs(dy))) then
                    return visited
                end
            end
        end
        return visited
    end

    for ring = 0, rad do
        if stopped or (options.shouldStopRing and options.shouldStopRing(ring)) then break end
        if ring == 0 then
            visitTile(baseX, baseY, 0)
        else
            for d = -ring, ring do
                if visitTile(baseX + d, baseY - ring, ring) or visitTile(baseX + d, baseY + ring, ring) then
                    break
                end
            end
            for d = -ring + 1, ring - 1 do
                if stopped or visitTile(baseX - ring, baseY + d, ring) or visitTile(baseX + ring, baseY + d, ring) then
                    break
                end
            end
        end
    end
    return visited
end

local function isBetterCandidate(candidate, best)
    if not best then return true end
    local cs, bs = tonumber(candidate.score) or 0, tonumber(best.score) or 0
    if cs ~= bs then return cs > bs end
    if candidate.distSq ~= best.distSq then return candidate.distSq < best.distSq end
    return tostring(candidate.key) < tostring(best.key)
end

function Objects.FindBestObject(origin, options)
    options = type(options) == "table" and options or {}
    local originX, originY, originZ = readOriginCoords(origin, options)
    if originX == nil then return nil, "origin_unavailable" end
    local cell = options.cell or (getCell and getCell() or nil)
    if not cell or type(cell.getGridSquare) ~= "function" then
        return nil, "world_unavailable"
    end

    local radius = math.max(0, math.floor(tonumber(options.radius) or 10))
    local maxRing = radius
    local acceptFn = type(options.accept) == "function" and options.accept or nil
    local scoreFn = type(options.score) == "function" and options.score or nil
    local earlyExit = options.earlyExit ~= false and options.scanFullRadius ~= true and not scoreFn
    local best, seen = nil, {}
    local keyFn = type(options.objectKey) == "function" and options.objectKey or Objects.DefaultObjectKey
    local specialFn = type(options.specialObject) == "function" and options.specialObject or nil

    local function consider(obj, sq, cx, cy, z, distSq, key, source)
        if not obj or seen[obj] then return end
        seen[obj] = true
        local cand = {
            object = obj, square = sq, x = cx, y = cy, z = z,
            distSq = distSq, key = key, source = source,
        }
        if acceptFn and not acceptFn(cand) then return end
        cand.score = scoreFn and (tonumber(scoreFn(cand)) or 0) or 0
        if isBetterCandidate(cand, best) then
            best = cand
            if earlyExit then
                local ringBound = math.ceil(math.sqrt(math.max(0, distSq))) + 1
                if ringBound < maxRing then maxRing = ringBound end
            end
        end
    end

    Objects.ForEachSquareInRadius(cell, originX, originY, originZ, radius,
        function(snap, tx, ty, z, distSq)
            local cx, cy, objs = tx + 0.5, ty + 0.5, snap.objects or {}
            for i = 1, #objs do
                consider(objs[i], snap.square, cx, cy, z, distSq,
                    keyFn(objs[i], cx, cy, z, i - 1))
            end
            if specialFn then
                local ok, sp = pcall(specialFn, snap.square)
                if ok and sp then
                    local t = type(sp) == "table"
                    local obj = t and sp.object or sp
                    consider(obj, snap.square, cx, cy, z, distSq,
                        tostring((t and sp.key) or keyFn(obj, cx, cy, z, -1)),
                        t and sp.source or nil)
                end
            end
        end, {
            originX = originX, originY = originY, maxSquares = options.maxSquares,
            allowRestrictedZones = options.allowRestrictedZones ~= false,
            player = options.player, allowTheft = options.allowTheft,
            metrics = options.metrics, now = options.now,
            shouldStopRing = function(ring) return earlyExit and ring > maxRing end,
        })

    if best then return best, nil end
    return nil, "no_matching_object"
end

return Objects
