--[[
    PNC Behavior Fire Safety
    High-priority survival gate: makes NPCs avoid walking into active fires,
    sprint off burning hazard tiles along fence-free walkable routes, and
    actively sprint around on safe ground to extinguish themselves instead of
    standing in fire, hopping fences, or bandaging while burning.
]]

PNC = PNC or {}
PNC.BehaviorFireSafety = PNC.BehaviorFireSafety or {}

local FireSafety = PNC.BehaviorFireSafety
local Core = PNC.Core
local Const = PNC.Const
local Common = PNC.BehaviorCommon
local Animation = PNC.Animation
local ActorControl = PNC.ActorControl

local CARDINAL_DIRS = {
    { 1, 0 },
    { -1, 0 },
    { 0, 1 },
    { 0, -1 },
}

local function isCampfireSquare(square)
    local health = PNC.Health
    if health and type(health.IsCampfireSquare) == "function" then
        return health.IsCampfireSquare(square) == true
    end
    return square and square.hasLitCampfire and square:hasLitCampfire() == true or false
end

local function isHazardFireSquare(square)
    local health = PNC.Health
    local burning
    if not square then return false end
    if isCampfireSquare(square) then return false end
    if health and type(health.IsBurningSquare) == "function" then
        return health.IsBurningSquare(square) == true
    end
    if square.isFire and square:isFire() == true then return true end
    local props = square.getProperties and square:getProperties() or nil
    burning = props and props.has and IsoFlagType and IsoFlagType.burning
        and props:has(IsoFlagType.burning) == true or false
    return burning
end

local function isZombieOnFire(zombie)
    return zombie and zombie.isOnFire and zombie:isOnFire() == true or false
end

local function extinguishBody(zombie)
    if not zombie then return false end
    if zombie.StopBurning then
        zombie:StopBurning()
        return true
    end
    if zombie.setOnFire then
        zombie:setOnFire(false)
        return true
    end
    return false
end

local function countNearbyHazardFires(cell, x, y, z)
    local count = 0
    local dx
    local dy
    local sq
    if not cell or not cell.getGridSquare then return 0 end
    for dx = -1, 1 do
        for dy = -1, 1 do
            sq = cell:getGridSquare(x + dx, y + dy, z)
            if isHazardFireSquare(sq) then
                count = count + 1
            end
        end
    end
    return count
end

local function isSafeFleeCandidate(square)
    if not square then return false end
    if isHazardFireSquare(square) or isCampfireSquare(square) then
        return false
    end
    if square.isFree and square:isFree(false) ~= true then
        return false
    end
    return true
end

local function canStepClear(cell, fromSq, toSq, fx, fy, tx, ty, z)
    local tq = PNC.TraversalQuery
    if not fromSq or not toSq then return false end
    if tq and type(tq.CanStep) == "function" then
        local ok, clear = pcall(tq.CanStep, fx, fy, z, tx, ty, z, cell)
        if ok then
            return clear == true
        end
    end
    if fromSq.isWallTo and fromSq:isWallTo(toSq) then return false end
    if fromSq.isBlockedTo and fromSq:isBlockedTo(toSq) then return false end
    if toSq.isFree and toSq:isFree(false) ~= true then return false end
    return true
end

-- Bounded BFS flood-fill over fence-free, wall-free, fire-free walkable steps.
-- Guarantees the chosen tile is reachable on the same side of any fence/wall.
local function findReachableSafeTile(zombie, square, opts)
    local cell
    local sx
    local sy
    local sz
    local maxDepth
    local minDist
    local preferFar
    local avoidSquare
    local queue
    local head
    local visited
    local bestSquare
    local bestScore
    local expansions = 0
    opts = type(opts) == "table" and opts or {}
    maxDepth = tonumber(opts.maxDepth) or 6
    minDist = tonumber(opts.minDist) or 1
    preferFar = opts.preferFar == true
    avoidSquare = opts.avoidSquare
    if not zombie or not square or not zombie.getCell
        or not square.getX or not square.getY
    then
        return nil
    end
    cell = zombie:getCell()
    if not cell or not cell.getGridSquare then return nil end
    sx = square:getX()
    sy = square:getY()
    sz = square.getZ and square:getZ() or math.floor(tonumber(zombie:getZ()) or 0)

    queue = { { sq = square, x = sx, y = sy, depth = 0 } }
    head = 1
    visited = { [sx .. "," .. sy] = true }

    while head <= #queue and expansions < 96 do
        local cur = queue[head]
        head = head + 1
        expansions = expansions + 1

        if cur.depth > 0 and isSafeFleeCandidate(cur.sq) then
            local adjFires = countNearbyHazardFires(cell, cur.x, cur.y, sz)
            local distPenalty
            if cur.depth >= minDist then
                distPenalty = preferFar and (-cur.depth) or cur.depth
            else
                distPenalty = 50 + (minDist - cur.depth)
            end
            local avoidPenalty = (avoidSquare and cur.sq == avoidSquare) and 200 or 0
            local score = adjFires * 1000 + avoidPenalty + distPenalty
            if bestScore == nil or score < bestScore then
                bestScore = score
                bestSquare = cur.sq
            end
        end

        if cur.depth < maxDepth then
            for i = 1, #CARDINAL_DIRS do
                local nx = cur.x + CARDINAL_DIRS[i][1]
                local ny = cur.y + CARDINAL_DIRS[i][2]
                local key = nx .. "," .. ny
                if not visited[key] then
                    visited[key] = true
                    local nextSq = cell:getGridSquare(nx, ny, sz)
                    if nextSq
                        and not isHazardFireSquare(nextSq)
                        and not isCampfireSquare(nextSq)
                        and canStepClear(cell, cur.sq, nextSq, cur.x, cur.y, nx, ny, sz)
                    then
                        queue[#queue + 1] = {
                            sq = nextSq,
                            x = nx,
                            y = ny,
                            depth = cur.depth + 1,
                        }
                    end
                end
            end
        end
    end

    return bestSquare
end

local function interruptForFire(record, zombie)
    local runtime = record and record.runtime or nil
    if not runtime then return end
    local treatment = runtime.selfTreatment
    if treatment and treatment.phase == "bandaging" then
        if Animation and Animation.FinishBump then
            pcall(Animation.FinishBump, zombie, true)
        end
        treatment.phase = "idle"
        treatment.partId = nil
        treatment.bandageType = nil
        treatment.bandageName = nil
        treatment.startedAt = 0
        treatment.finishAt = 0
        treatment.interruptedReason = "fire_hazard"
        runtime.tacticalState = nil
    end
    if runtime.animationScene and PNC.AnimationScenes and PNC.AnimationScenes.Stop then
        pcall(PNC.AnimationScenes.Stop, record, zombie, "fire_hazard")
    end
    if Common and Common.ClearCombatTarget then
        Common.ClearCombatTarget(record, "fire_hazard", zombie)
    end
    runtime.attackAction = nil
end

local function isHeadingIntoFire(record, zombie, square)
    local runtime = record and record.runtime or nil
    local intent = runtime and runtime.moveIntent or nil
    local reason
    local cell
    local sx
    local sy
    local sz
    local tx
    local ty
    local tz
    local targetSq
    local dx
    local dy
    local stepX
    local stepY
    local aheadSq
    if not intent or not zombie or not square or not zombie.getCell then
        return false
    end
    reason = tostring(intent.reason or "")
    if reason == "flee_fire" or reason == "extinguish_run" then
        return false
    end
    cell = zombie:getCell()
    if not cell or not cell.getGridSquare then return false end
    sx = square:getX()
    sy = square:getY()
    sz = square.getZ and square:getZ() or math.floor(tonumber(zombie:getZ()) or 0)
    tx = math.floor(tonumber(intent.x) or sx)
    ty = math.floor(tonumber(intent.y) or sy)
    tz = math.floor(tonumber(intent.z) or sz)
    targetSq = cell:getGridSquare(tx, ty, tz)
    if isHazardFireSquare(targetSq) then
        return true
    end
    dx = tx - sx
    dy = ty - sy
    if dx == 0 and dy == 0 then
        return false
    end
    stepX = dx > 0 and 1 or (dx < 0 and -1 or 0)
    stepY = dy > 0 and 1 or (dy < 0 and -1 or 0)
    aheadSq = cell:getGridSquare(sx + stepX, sy + stepY, sz)
    return isHazardFireSquare(aheadSq)
end

local function distanceToSquare(zombie, square)
    if not zombie or not square or not square.getX or not square.getY then
        return math.huge
    end
    local zx = tonumber(zombie.getX and zombie:getX()) or 0
    local zy = tonumber(zombie.getY and zombie:getY()) or 0
    local dx = (square:getX() + 0.5) - zx
    local dy = (square:getY() + 0.5) - zy
    return math.sqrt(dx * dx + dy * dy)
end

FireSafety.IsHazardFireSquare = isHazardFireSquare
FireSafety.FindSafeTileAwayFromFire = function(zombie, square)
    return findReachableSafeTile(zombie, square, { maxDepth = 6, minDist = 2, preferFar = false })
end

function FireSafety.Tick(record, zombie, now)
    local square
    local cell
    local sx
    local sy
    local sz
    local onFire
    local onHazard
    local nearHazard
    local headingIntoFire
    local state
    local safeSq
    local extinguishMs
    if not record or record.alive == false or not zombie then
        return false
    end
    if ActorControl and ActorControl.IsPuppetOwned
        and ActorControl.IsPuppetOwned(record)
    then
        return false
    end
    -- Do not fight an already-active fence/window traversal mid-animation.
    if PNC.PathService and PNC.PathService.IsTraversalActive
        and PNC.PathService.IsTraversalActive(record, zombie)
    then
        return false
    end
    now = tonumber(now) or (Core and Core.Now and Core.Now()) or 0
    square = zombie.getSquare and zombie:getSquare() or nil
    onFire = isZombieOnFire(zombie)
    onHazard = isHazardFireSquare(square)
    cell = zombie.getCell and zombie:getCell() or nil
    sx = square and square.getX and square:getX() or nil
    sy = square and square.getY and square:getY() or nil
    sz = square and square.getZ and square:getZ() or math.floor(tonumber(zombie:getZ()) or 0)
    nearHazard = not onHazard and sx ~= nil and sy ~= nil
        and countNearbyHazardFires(cell, sx, sy, sz) > 0 or false
    headingIntoFire = not onFire and not onHazard
        and isHeadingIntoFire(record, zombie, square) or false

    record.runtime = record.runtime or {}
    state = record.runtime.fireSafety

    if not onFire and not onHazard and not headingIntoFire then
        if state then
            record.runtime.fireSafety = nil
        end
        return false
    end

    -- Phase 1: Sprint away from any active fire tile along a fence-free walkable path.
    if onHazard or (onFire and nearHazard) or headingIntoFire then
        interruptForFire(record, zombie)
        safeSq = state and state.targetSquare or nil
        if not isSafeFleeCandidate(safeSq)
            or (safeSq and cell and safeSq.getX and safeSq.getY
                and countNearbyHazardFires(cell, safeSq:getX(), safeSq:getY(), sz) > 0)
        then
            safeSq = findReachableSafeTile(zombie, square, {
                maxDepth = 6,
                minDist = 2,
                preferFar = false,
            })
        end
        state = {
            phase = "fleeing",
            targetSquare = safeSq,
            startedAt = state and state.startedAt or now,
        }
        record.runtime.fireSafety = state
        record.activeJob = "FireSafety"
        record.activeBehavior = "FireSafety:flee"
        if safeSq and Common and Common.MoveRecord then
            Common.MoveRecord(
                record,
                zombie,
                safeSq:getX() + 0.5,
                safeSq:getY() + 0.5,
                safeSq:getZ(),
                "run",
                0.5,
                "flee_fire"
            )
        elseif Common and Common.HaltMovement then
            Common.HaltMovement(record, zombie, "flee_fire_blocked")
        end
        return true
    end

    -- Phase 2: Clear of fire tiles while still burning -> actively sprint around
    -- on fence-free safe ground to put out the flames (matching vanilla IsoPlayer).
    interruptForFire(record, zombie)
    extinguishMs = tonumber(Const and Const.FIRE_SELF_EXTINGUISH_MS) or 2200
    if not state or state.phase ~= "extinguishing" then
        state = {
            phase = "extinguishing",
            startedAt = now,
            extinguishAt = now + extinguishMs,
            runTarget = nil,
            retargetAt = 0,
        }
        record.runtime.fireSafety = state
    end
    record.activeJob = "FireSafety"
    record.activeBehavior = "FireSafety:extinguish"

    if now >= (tonumber(state.extinguishAt) or 0) then
        extinguishBody(zombie)
        record.runtime.fireState = nil
        record.runtime.fireSafety = nil
        if Common and Common.HaltMovement then
            Common.HaltMovement(record, zombie, "extinguish_done")
        end
        return false
    end

    local runTarget = state.runTarget
    local needNewTarget = not isSafeFleeCandidate(runTarget)
        or distanceToSquare(zombie, runTarget) <= 1.2
        or now >= (tonumber(state.retargetAt) or 0)
    if needNewTarget then
        runTarget = findReachableSafeTile(zombie, square, {
            maxDepth = 5,
            minDist = 3,
            preferFar = true,
            avoidSquare = runTarget,
        })
        state.runTarget = runTarget
        state.retargetAt = now + 1100
    end
    if runTarget and Common and Common.MoveRecord then
        Common.MoveRecord(
            record,
            zombie,
            runTarget:getX() + 0.5,
            runTarget:getY() + 0.5,
            runTarget:getZ(),
            "run",
            0.5,
            "extinguish_run"
        )
    elseif Common and Common.HaltMovement then
        Common.HaltMovement(record, zombie, "extinguish_self")
    end
    return true
end

return FireSafety
