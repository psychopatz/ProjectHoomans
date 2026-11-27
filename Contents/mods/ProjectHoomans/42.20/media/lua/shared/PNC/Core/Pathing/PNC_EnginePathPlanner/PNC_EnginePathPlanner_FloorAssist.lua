--[[
    PNC Engine Path Planner: Floor Validation, Refusal Cache & Stair Assist
    Ensures upper-floor targets snap onto solid standable tiles, caches
    unreachable goals with bounded TTLs, and stages cross-floor traversal
    through the nearest loaded staircase (works identically in SP and MP).
]]

PNC = PNC or {}
PNC.EnginePathPlanner = PNC.EnginePathPlanner or {}
PNC.EnginePathPlanner.Internal = PNC.EnginePathPlanner.Internal or {}

local Planner = PNC.EnginePathPlanner
local Internal = Planner.Internal
local Const = PNC.Const or {}

local DEFAULT_SNAP_RADIUS = 2
local DEFAULT_STAIR_SCAN_RADIUS = 8
local DEFAULT_STAIR_SCAN_COOLDOWN_MS = 3000
local DEFAULT_REFUSAL_CAP = 4
local DEFAULT_NO_FLOOR_REFUSAL_MS = 10000
local DEFAULT_UNREACHABLE_REFUSAL_MS = 30000

local function getSquare(x, y, z)
    if PNC.TraversalQuery and type(PNC.TraversalQuery.GetSquare) == "function" then
        return PNC.TraversalQuery.GetSquare(x, y, z)
    end
    if type(Internal.GetSquare) == "function" then
        return Internal.GetSquare(x, y, z)
    end
    local cell = type(getCell) == "function" and getCell() or nil
    if cell and type(cell.getGridSquare) == "function" then
        return cell:getGridSquare(math.floor(x), math.floor(y), math.floor(z))
    end
    return nil
end

local function worldGridAvailable()
    local cell = type(getCell) == "function" and getCell() or nil
    return cell ~= nil and type(cell.getGridSquare) == "function"
end

function Internal.IsStandableSquare(square, z)
    if square == nil then return false end
    local level = math.floor(tonumber(z) or (square.getZ and square:getZ()) or 0)
    if type(square.TreatAsSolidFloor) == "function" then
        if square:TreatAsSolidFloor() ~= true then
            return false
        end
    elseif level >= 1 and type(square.getFloor) == "function" then
        if square:getFloor() == nil then
            return false
        end
    end
    if type(square.isFree) == "function" and square:isFree(false) ~= true then
        return false
    end
    return true
end

function Internal.SnapToStandableGoal(finalTarget, snapRadius)
    if type(finalTarget) ~= "table" or not worldGridAvailable() then
        return finalTarget, false
    end
    local tx = tonumber(finalTarget.x)
    local ty = tonumber(finalTarget.y)
    local tz = tonumber(finalTarget.z)
    if tx == nil or ty == nil or tz == nil then
        return finalTarget, false
    end
    local gx, gy, gz = math.floor(tx), math.floor(ty), math.floor(tz + 0.05)
    -- Ground floor (z == 0) never has void/air tiles; skip square scanning
    -- completely so furniture/container targets never trigger 5x5 scans.
    if gz < 1 then
        return finalTarget, false
    end
    local square = getSquare(gx, gy, gz)
    if square ~= nil and Internal.IsStandableSquare(square, gz) then
        return finalTarget, false
    end
    local radius = math.max(1, tonumber(snapRadius) or DEFAULT_SNAP_RADIUS)
    local bestSquare, bestDistSq = nil, nil
    for dx = -radius, radius do
        for dy = -radius, radius do
            if dx ~= 0 or dy ~= 0 then
                local candidate = getSquare(gx + dx, gy + dy, gz)
                if candidate and Internal.IsStandableSquare(candidate, gz) then
                    local ox = (gx + dx + 0.5) - tx
                    local oy = (gy + dy + 0.5) - ty
                    local distSq = (ox * ox) + (oy * oy)
                    if bestDistSq == nil or distSq < bestDistSq then
                        bestSquare = candidate
                        bestDistSq = distSq
                    end
                end
            end
        end
    end
    if bestSquare == nil then
        if gz >= 1 then
            return nil, "target_no_solid_floor"
        end
        return finalTarget, false
    end
    return {
        x = bestSquare:getX() + 0.5,
        y = bestSquare:getY() + 0.5,
        z = tz,
        stopDistance = finalTarget.stopDistance,
        snappedFloor = true,
    }, true
end

local function sameRefusalSpot(a, b)
    if not a or not b then return false end
    if math.abs((tonumber(a.z) or 0) - (tonumber(b.z) or 0)) >= 0.5 then
        return false
    end
    local dx = (tonumber(a.x) or 0) - (tonumber(b.x) or 0)
    local dy = (tonumber(a.y) or 0) - (tonumber(b.y) or 0)
    return (dx * dx) + (dy * dy) <= 2.25
end

function Internal.RefuseGoal(record, goal, now, ttlMs, reason)
    if not record or type(goal) ~= "table" then return end
    record.runtime = record.runtime or {}
    local list = record.runtime.refusedGoals or {}
    local keep = {}
    now = tonumber(now) or 0
    ttlMs = tonumber(ttlMs) or DEFAULT_UNREACHABLE_REFUSAL_MS
    for i = 1, #list do
        local entry = list[i]
        if entry and now < (tonumber(entry.untilAt) or 0)
            and not sameRefusalSpot(entry, goal)
        then
            keep[#keep + 1] = entry
        end
    end
    while #keep >= DEFAULT_REFUSAL_CAP do
        table.remove(keep, 1)
    end
    keep[#keep + 1] = {
        x = tonumber(goal.x) or 0,
        y = tonumber(goal.y) or 0,
        z = tonumber(goal.z) or 0,
        untilAt = now + math.max(1000, ttlMs),
        reason = reason or "goal_refused",
    }
    record.runtime.refusedGoals = keep
end

function Internal.IsGoalRefused(record, goal, now)
    local list = record and record.runtime and record.runtime.refusedGoals or nil
    if type(list) ~= "table" or #list == 0 or type(goal) ~= "table" then
        return false, nil
    end
    now = tonumber(now) or 0
    local i = 1
    while i <= #list do
        local entry = list[i]
        if not entry or now >= (tonumber(entry.untilAt) or 0) then
            table.remove(list, i)
        else
            if sameRefusalSpot(entry, goal) then
                return true, entry.reason
            end
            i = i + 1
        end
    end
    return false, nil
end

local function findNearestStairSquare(bx, by, bz, targetBuilding, radius)
    local gx, gy = math.floor(bx), math.floor(by)
    local best, bestScore = nil, nil
    for dx = -radius, radius do
        for dy = -radius, radius do
            local sq = getSquare(gx + dx, gy + dy, bz)
            if sq and type(sq.HasStairs) == "function" and sq:HasStairs() == true
                and Internal.IsStandableSquare(sq, bz)
            then
                local distSq = ((gx + dx + 0.5) - bx) ^ 2
                    + ((gy + dy + 0.5) - by) ^ 2
                local sameBuilding = targetBuilding ~= nil
                    and type(sq.getBuilding) == "function"
                    and sq:getBuilding() == targetBuilding
                -- Strongly prefer stairs belonging to the destination building.
                local score = sameBuilding and distSq or (distSq + 25)
                if bestScore == nil or score < bestScore then
                    best = { x = gx + dx + 0.5, y = gy + dy + 0.5, z = bz }
                    bestScore = score
                end
            end
        end
    end
    return best
end

function Internal.ResolveFloorTransitionTarget(record, body, finalTarget, now)
    if not body
        or type(body.getX) ~= "function"
        or type(body.getY) ~= "function"
        or type(body.getZ) ~= "function"
        or type(finalTarget) ~= "table"
        or not worldGridAvailable()
    then
        return finalTarget, nil
    end
    local bz = math.floor(tonumber(body:getZ()) or 0)
    local tz = math.floor(tonumber(finalTarget.z) or bz)
    if bz == tz then
        if record and record.runtime then
            record.runtime.stairAssist = nil
        end
        return finalTarget, nil
    end
    local bx = tonumber(body:getX()) or 0
    local by = tonumber(body:getY()) or 0
    local assist = record and record.runtime and record.runtime.stairAssist or nil
    local cooldownMs = tonumber(Const.ENGINE_PATH_STAIR_SCAN_MS)
        or DEFAULT_STAIR_SCAN_COOLDOWN_MS
    now = tonumber(now) or 0
    if not assist or assist.fromZ ~= bz or assist.toZ ~= tz
        or (assist.stair == nil and now - (tonumber(assist.scannedAt) or 0) >= cooldownMs)
    then
        local targetSq = getSquare(finalTarget.x, finalTarget.y, tz)
        local targetBuilding = targetSq and type(targetSq.getBuilding) == "function"
            and targetSq:getBuilding() or nil
        local radius = tonumber(Const.ENGINE_PATH_STAIR_SCAN_RADIUS)
            or DEFAULT_STAIR_SCAN_RADIUS
        local stair = findNearestStairSquare(bx, by, bz, targetBuilding, radius)
        assist = {
            fromZ = bz,
            toZ = tz,
            stair = stair,
            scannedAt = now,
        }
        if record and record.runtime then
            record.runtime.stairAssist = assist
        end
    end
    if not assist.stair then
        return finalTarget, "stair_none_found"
    end
    local dx = assist.stair.x - bx
    local dy = assist.stair.y - by
    if (dx * dx) + (dy * dy) > 2.25 then
        return {
            x = assist.stair.x,
            y = assist.stair.y,
            z = bz,
            stopDistance = 1.0,
            stairStage = "approach",
        }, "stair_approach"
    end
    return finalTarget, "stair_traverse"
end

Internal.DEFAULT_NO_FLOOR_REFUSAL_MS = DEFAULT_NO_FLOOR_REFUSAL_MS
Internal.DEFAULT_UNREACHABLE_REFUSAL_MS = DEFAULT_UNREACHABLE_REFUSAL_MS

return Internal
