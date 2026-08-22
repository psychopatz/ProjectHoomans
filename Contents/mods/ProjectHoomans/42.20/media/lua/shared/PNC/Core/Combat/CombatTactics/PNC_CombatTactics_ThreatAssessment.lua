-- Spatial threat assessment and deterministic tactical geometry helpers.

PNC = PNC or {}
PNC.CombatTactics = PNC.CombatTactics or {}

local Tactics = PNC.CombatTactics
Tactics.Internal = Tactics.Internal or {}

local Internal = Tactics.Internal
local Core = PNC.Core
local Const = PNC.Const
local Perception = PNC.Perception
local Spatial = PNC.SpatialIndex
local Stamina = PNC.Stamina
local Relationships = PNC.Relationships

function Internal.CountZombiesNearPoint(x, y, z, radius)
    local zombies
    local count = 0
    local i
    local zombie
    local distSq
    local radiusSq = (tonumber(radius) or 0) ^ 2
    if not Spatial or not Spatial.QueryZombies then
        return 0
    end
    zombies = Spatial.QueryZombies(x, y, tonumber(radius) or 0)
    for i = 1, #zombies do
        zombie = zombies[i]
        if zombie and (not zombie:isDead()) and (not Core.IsManagedNPCBody(zombie)) and math.abs(zombie:getZ() - z) < 1 then
            distSq = Core.DistanceSq(x, y, zombie:getX(), zombie:getY())
            if distSq <= radiusSq then
                count = count + 1
            end
        end
    end
    return count
end

function Internal.CountVisibleZombies(record, radius)
    local entries
    if Perception and Perception.GetVisibleZombieEntries then
        entries = Perception.GetVisibleZombieEntries(record, radius)
        return #entries
    end
    return Perception and Perception.CountEnemyZombies
        and Perception.CountEnemyZombies(record, radius) or 0
end

-- Threat is a survival concern even when the NPC is configured not to
-- initiate attacks against zombies. Count the physical frame entries here,
-- rather than Perception.CountEnemyZombies, whose contract intentionally
-- returns zero for attackZombies=false records.
function Internal.CountWorldZombies(record, radius)
    if Perception and Perception.CountZombiesInFrame then
        return Perception.CountZombiesInFrame(record, radius)
    end
    if Spatial and Spatial.QueryZombies then
        return Internal.CountZombiesNearPoint(
            record.x,
            record.y,
            record.z,
            radius
        )
    end
    return Perception and Perception.CountEnemyZombies
        and Perception.CountEnemyZombies(record, radius) or 0
end

function Internal.AssessThreat(record, target)
    local now = Core.Now()
    local staminaRatio = Stamina and Stamina.GetRatio and Stamina.GetRatio(record) or 1
    local staminaCurrent = tonumber(
        record and record.stamina and record.stamina.current
    ) or 100
    local runtime = record and record.runtime or {}
    local cached = runtime.combatThreatAssessment
    local targetKey = target and (
        tostring(target.kind or "") .. ":"
        .. tostring(target.id or target.zombieId or target.onlineID or "")
    ) or "none"
    local targetCrowdCount = 0
    local worldSurroundedCount
    local worldPressureCount
    local worldHordeCount
    local report
    if cached
        and cached.targetKey == targetKey
        and cached.x ~= nil
        and cached.y ~= nil
        and now < (tonumber(cached.expiresAt) or 0)
        and Core.DistanceSq(
            tonumber(cached.x) or record.x,
            tonumber(cached.y) or record.y,
            record.x,
            record.y
        ) <= 0.16
        and (
            not target
            or cached.targetX == nil
            or Core.DistanceSq(
                tonumber(cached.targetX) or target.x,
                tonumber(cached.targetY) or target.y,
                target.x,
                target.y
            ) <= 0.16
        )
    then
        return cached
    end
    if target and target.kind == "zombie" then
        targetCrowdCount = Internal.CountZombiesNearPoint(
            target.x,
            target.y,
            target.z or record.z,
            Const.COMBAT_TARGET_CROWD_RADIUS
        )
    end
    worldSurroundedCount = Internal.CountWorldZombies(
        record,
        Const.COMBAT_SURROUND_RADIUS
    )
    worldPressureCount = Internal.CountWorldZombies(
        record,
        Const.COMBAT_PRESSURE_RADIUS
    )
    worldHordeCount = Internal.CountWorldZombies(
        record,
        Const.COMBAT_HORDE_RADIUS
    )
    report = {
        targetKey = targetKey,
        x = record.x,
        y = record.y,
        targetX = target and target.x or nil,
        targetY = target and target.y or nil,
        staminaRatio = staminaRatio,
        staminaCurrent = staminaCurrent,
        retreating = runtime.retreatMode == true,
        surroundedCount = worldSurroundedCount,
        pressureCount = worldPressureCount,
        hordeCount = worldHordeCount,
        visiblePressureCount = Internal.CountVisibleZombies(record, Const.COMBAT_PRESSURE_RADIUS),
        visibleHordeCount = Internal.CountVisibleZombies(record, Const.COMBAT_HORDE_RADIUS),
        targetCrowdCount = targetCrowdCount,
        expiresAt = now + (tonumber(Const.COMBAT_TACTICAL_DIAGNOSTIC_MS) or 200),
    }
    runtime.combatThreatAssessment = report
    runtime.combatTactical = {
        surrounded = report.surroundedCount,
        pressure = report.pressureCount,
        visiblePressure = report.visiblePressureCount,
        horde = report.hordeCount,
        visibleHorde = report.visibleHordeCount,
        targetCrowd = report.targetCrowdCount,
        stamina = report.staminaRatio,
        staminaCurrent = report.staminaCurrent,
        assessedAt = now,
    }
    return report
end

function Internal.BuildZombieThreatCentroid(record, radius)
    local zombies
    local zombie
    local count = 0
    local sumX = 0
    local sumY = 0
    local i
    if not record or not Spatial or not Spatial.QueryZombies then
        return nil, nil, 0
    end
    zombies = Spatial.QueryZombies(record.x, record.y, tonumber(radius) or 0)
    for i = 1, #zombies do
        zombie = zombies[i]
        if zombie
            and (not zombie:isDead())
            and (not Core.IsManagedNPCBody(zombie))
            and math.abs(zombie:getZ() - record.z) < 1
        then
            count = count + 1
            sumX = sumX + zombie:getX()
            sumY = sumY + zombie:getY()
        end
    end
    if count <= 0 then return nil, nil, 0 end
    return sumX / count, sumY / count, count
end

function Internal.StableDirection(id)
    local value = tostring(id or "")
    local hash = 0
    local i
    for i = 1, #value do
        hash = (hash * 33 + string.byte(value, i)) % 360
    end
    return (hash / 360) * math.pi * 2
end

function Internal.PointNearSegment(px, py, ax, ay, bx, by, corridor)
    local vx = bx - ax
    local vy = by - ay
    local lengthSq = (vx * vx) + (vy * vy)
    local projection
    local closestX
    local closestY
    if lengthSq <= 0.001 then return false end
    projection = (((px - ax) * vx) + ((py - ay) * vy)) / lengthSq
    if projection <= 0.06 or projection >= 0.98 then return false end
    closestX = ax + (vx * projection)
    closestY = ay + (vy * projection)
    return Core.DistanceSq(px, py, closestX, closestY)
        <= corridor * corridor
end

function Internal.IsProtectedNPC(record, other, target)
    if not other
        or other == record
        or other.alive == false
        or tostring(other.id or "") == tostring(target and target.id or "")
    then
        return false
    end
    if Relationships and Relationships.AreNPCsEnemies then
        return not Relationships.AreNPCsEnemies(record, other)
    end
    return tostring(other.faction or "") == tostring(record.faction or "")
end

return Tactics
