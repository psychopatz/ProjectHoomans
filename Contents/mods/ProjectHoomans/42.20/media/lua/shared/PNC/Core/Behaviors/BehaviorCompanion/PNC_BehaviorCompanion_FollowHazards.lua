-- Zombie-density sensing and short-lived steering targets for followers.

local Internal = PNC.BehaviorCompanion.Internal
local Core = PNC.Core
local Const = PNC.Const
local Spatial = PNC.SpatialIndex
local TraversalQuery = PNC.TraversalQuery

function Internal.AssessFollowHazards(record, zombie, now)
    local runtime = record.runtime or {}
    local cached = runtime.followHazard
    local radius = tonumber(Const.FOLLOW_HORDE_AVOID_RADIUS) or 6.5
    local radiusSq = radius * radius
    local nearDistance = tonumber(Const.FOLLOW_HORDE_NEAR_DISTANCE) or 2.4
    local candidates
    local candidate
    local x = zombie and zombie.getX and zombie:getX()
        or tonumber(record.x) or 0
    local y = zombie and zombie.getY and zombie:getY()
        or tonumber(record.y) or 0
    local z = zombie and zombie.getZ and zombie:getZ()
        or tonumber(record.z) or 0
    local zx
    local zy
    local dx
    local dy
    local distSq
    local distance
    local weight
    local i
    local cacheDx
    local cacheDy

    record.runtime = runtime
    cacheDx = cached and x - (tonumber(cached.x) or x) or 0
    cacheDy = cached and y - (tonumber(cached.y) or y) or 0
    if cached
        and now < (tonumber(cached.expiresAt) or 0)
        and (cacheDx * cacheDx) + (cacheDy * cacheDy) <= 0.25
    then
        return cached
    end

    cached = cached or {}
    cached.x = x
    cached.y = y
    cached.z = z
    cached.count = 0
    cached.nearestDistance = math.huge
    cached.repelX = 0
    cached.repelY = 0
    cached.expiresAt = now
        + (tonumber(Const.FOLLOW_HORDE_SCAN_MS) or 150)
    candidates = Spatial and Spatial.QueryZombies
        and Spatial.QueryZombies(x, y, radius) or {}
    for i = 1, #candidates do
        candidate = candidates[i]
        if candidate
            and (not candidate.isDead or not candidate:isDead())
            and (
                not Core.IsManagedNPCBody
                or not Core.IsManagedNPCBody(candidate)
            )
            and candidate.getX
            and candidate.getY
            and candidate.getZ
            and math.abs(candidate:getZ() - z) < 1
        then
            zx = candidate:getX()
            zy = candidate:getY()
            dx = x - zx
            dy = y - zy
            distSq = (dx * dx) + (dy * dy)
            if distSq <= radiusSq then
                distance = math.sqrt(math.max(0.0025, distSq))
                weight = math.max(0, (radius - distance) / radius)
                cached.count = cached.count + 1
                cached.nearestDistance = math.min(
                    cached.nearestDistance,
                    distance
                )
                cached.repelX = cached.repelX
                    + ((dx / distance) * weight * weight)
                cached.repelY = cached.repelY
                    + ((dy / distance) * weight * weight)
            end
        end
    end
    cached.active = cached.count
            >= (tonumber(Const.FOLLOW_HORDE_AVOID_COUNT) or 3)
        or cached.nearestDistance <= nearDistance
    if cached.count <= 0 then
        cached.nearestDistance = nil
    end
    runtime.followHazard = cached
    return cached
end

local function canUseFollowSteer(record, x, y, z, dirX, dirY)
    if TraversalQuery and TraversalQuery.CanStep
        and not TraversalQuery.CanStep(
            record.x,
            record.y,
            record.z,
            record.x + (dirX * 0.75),
            record.y + (dirY * 0.75),
            z
        )
    then
        return false
    end
    return not TraversalQuery
        or not TraversalQuery.CanOccupy
        or TraversalQuery.CanOccupy(x, y, z)
end

function Internal.ResolveHordeAwareFollowTarget(
    record,
    slotTarget,
    slotDist,
    hazard,
    now
)
    local runtime = record.runtime or {}
    local target = runtime.followAvoidanceTarget or {}
    local baseX
    local baseY
    local repelX
    local repelY
    local tangentX
    local tangentY
    local dirX
    local dirY
    local dot
    local distance
    local candidateX
    local candidateY
    local candidateZ

    record.runtime = runtime
    runtime.followAvoidanceTarget = target
    if not slotTarget
        or not hazard
        or hazard.active ~= true
        or slotTarget.indoorApproach == true
        or math.abs((tonumber(slotTarget.z) or record.z) - record.z) >= 1
    then
        target.active = false
        return nil
    end
    if target.active == true
        and now < (tonumber(target.expiresAt) or 0)
        and Core.DistanceSq(
            record.x,
            record.y,
            tonumber(target.x) or record.x,
            tonumber(target.y) or record.y
        ) > 0.49
    then
        return target
    end

    baseX, baseY = Internal.NormalizeDirection(
        slotTarget.x - record.x,
        slotTarget.y - record.y
    )
    repelX, repelY = Internal.NormalizeDirection(
        tonumber(hazard.repelX) or 0,
        tonumber(hazard.repelY) or 0
    )
    if not baseX or not repelX then
        target.active = false
        return nil
    end

    dirX, dirY = Internal.NormalizeDirection(
        baseX + (
            repelX * math.min(1.35, 0.45 + hazard.count * 0.2)
        ),
        baseY + (
            repelY * math.min(1.35, 0.45 + hazard.count * 0.2)
        )
    )
    dot = dirX and ((dirX * baseX) + (dirY * baseY)) or -1
    if dot < 0.25 then
        tangentX = -baseY
        tangentY = baseX
        if (tangentX * repelX) + (tangentY * repelY) < 0 then
            tangentX = -tangentX
            tangentY = -tangentY
        end
        dirX, dirY = Internal.NormalizeDirection(
            (baseX * 0.38) + (tangentX * 0.92),
            (baseY * 0.38) + (tangentY * 0.92)
        )
    end
    if not dirX then
        target.active = false
        return nil
    end

    distance = math.min(
        tonumber(Const.FOLLOW_HORDE_STEER_DISTANCE) or 3.4,
        math.max(1.4, tonumber(slotDist) or 1.4)
    )
    candidateZ = tonumber(slotTarget.z) or record.z
    candidateX = record.x + (dirX * distance)
    candidateY = record.y + (dirY * distance)
    if not canUseFollowSteer(
        record,
        candidateX,
        candidateY,
        candidateZ,
        dirX,
        dirY
    ) then
        -- The opposite side still makes forward progress toward the owner.
        dirX, dirY = Internal.NormalizeDirection(
            (baseX * 0.38) + (baseY * 0.92),
            (baseY * 0.38) - (baseX * 0.92)
        )
        candidateX = record.x + (dirX * distance)
        candidateY = record.y + (dirY * distance)
        if not canUseFollowSteer(
            record,
            candidateX,
            candidateY,
            candidateZ,
            dirX,
            dirY
        ) then
            target.active = false
            return nil
        end
    end

    target.x = candidateX
    target.y = candidateY
    target.z = candidateZ
    target.stopDistance = 0.55
    target.active = true
    target.avoidance = true
    target.hazardCount = hazard.count
    target.expiresAt = now
        + (tonumber(Const.FOLLOW_HORDE_STEER_MS) or 350)
    return target
end
