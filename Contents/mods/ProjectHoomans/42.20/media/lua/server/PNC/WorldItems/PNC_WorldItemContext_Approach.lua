-- Shared walkable approach-tile and facing calculation for world interactions.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.WorldItemContext = PNC.WorldItemContext or {}

local Context = PNC.WorldItemContext
local Cache = Context.Cache
local safeCall = Cache.SafeCall
local nowMs = Cache.NowMs

Context.Approach = Context.Approach or {}
local Approach = Context.Approach

local APPROACH_OFFSETS = {
    { x = 0, y = 1 }, { x = 0, y = -1 },
    { x = 1, y = 0 }, { x = -1, y = 0 },
    { x = 1, y = 1 }, { x = -1, y = 1 },
    { x = 1, y = -1 }, { x = -1, y = -1 },
}

function Approach.FacingToward(fromX, fromY, toX, toY)
    local dx = (tonumber(toX) or 0) - (tonumber(fromX) or 0)
    local dy = (tonumber(toY) or 0) - (tonumber(fromY) or 0)
    local vertical = dy > 0.25 and "S" or dy < -0.25 and "N" or ""
    local horizontal = dx > 0.25 and "E" or dx < -0.25 and "W" or ""
    return vertical .. horizontal
end

local function isSquareWalkableDefault(square, wx, wy, wz)
    local pathService = PNC.PathService
    if pathService and pathService.IsSquareWalkable then
        return pathService.IsSquareWalkable(wx, wy, wz) == true
    end
    if not square then return false end
    if safeCall(square, "isSolid") == true
        or safeCall(square, "isSolidTrans") == true
    then
        return false
    end
    local free = safeCall(square, "isFree", false)
    if free ~= nil then return free == true end
    return true
end

function Approach.BuildApproachTiles(cell, targetX, targetY, targetZ, npcX, npcY, options)
    options = type(options) == "table" and options or {}
    cell = cell or (getCell and getCell() or nil)
    local sx = tonumber(targetX)
    local sy = tonumber(targetY)
    local tz = math.floor(tonumber(targetZ) or 0)
    if sx == nil or sy == nil then return {} end

    local baseX, baseY = math.floor(sx), math.floor(sy)
    local ox = tonumber(npcX) or sx
    local oy = tonumber(npcY) or sy
    local now = options.now or nowMs()
    local walkableFn = type(options.isWalkable) == "function"
        and options.isWalkable or nil

    local candidates = {}
    local function tryOffset(dx, dy)
        local wx, wy = baseX + dx + 0.5, baseY + dy + 0.5
        local okWalkable = false
        if walkableFn then
            local snap = cell and Cache.GetSquareSnapshot(cell, baseX + dx, baseY + dy, tz, now) or nil
            okWalkable = walkableFn(snap and snap.square or nil, wx, wy, tz) == true
        elseif PNC.PathService and PNC.PathService.IsSquareWalkable
            and options.usePathService ~= false
        then
            okWalkable = PNC.PathService.IsSquareWalkable(wx, wy, tz) == true
        else
            local snap = cell and Cache.GetSquareSnapshot(cell, baseX + dx, baseY + dy, tz, now) or nil
            okWalkable = isSquareWalkableDefault(snap and snap.square or nil, wx, wy, tz)
        end
        if not okWalkable then return end
        local distX, distY = wx - ox, wy - oy
        local facing = Approach.FacingToward(wx, wy, sx, sy)
        candidates[#candidates + 1] = {
            x = wx,
            y = wy,
            z = tz,
            facing = facing,
            interactionFacing = facing,
            approachKey = tostring(math.floor(wx)) .. ":"
                .. tostring(math.floor(wy)) .. ":" .. tostring(tz),
            distSq = distX * distX + distY * distY,
        }
    end

    if options.includeTarget == true then tryOffset(0, 0) end
    for i = 1, #APPROACH_OFFSETS do
        tryOffset(APPROACH_OFFSETS[i].x, APPROACH_OFFSETS[i].y)
    end

    table.sort(candidates, function(a, b)
        if a.distSq ~= b.distSq then return a.distSq < b.distSq end
        return a.approachKey < b.approachKey
    end)
    return candidates
end

return Approach
