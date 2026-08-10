--[[
    PNC Combat Tactics
    Owns short-range repositioning and conservative kiting rules so melee and
    ranged NPCs can create space without becoming fully evasive.
]]

PNC = PNC or {}
PNC.CombatTactics = PNC.CombatTactics or {}

local Tactics = PNC.CombatTactics
local Core = PNC.Core
local Const = PNC.Const
local PathService = PNC.PathService
local Perception = PNC.Perception
local Spatial = PNC.SpatialIndex
local Skills = PNC.Skills
local Stamina = PNC.Stamina
local TraversalQuery = PNC.TraversalQuery
local Relationships = PNC.Relationships
local COMBAT_NAVIGATION = {
    navigationPolicy = "combat",
    navigationProvider = "engine_path",
}
local buildZombieThreatCentroid

local function ensureRetreatState(record)
    local runtime
    local state
    if not record then
        return nil
    end
    record.runtime = record.runtime or {}
    runtime = record.runtime
    state = runtime.combatRetreat or {}
    runtime.combatRetreat = state
    state.phase = state.phase or nil
    state.reason = state.reason or nil
    state.lockUntil = tonumber(state.lockUntil) or 0
    state.goalX = state.goalX ~= nil and tonumber(state.goalX) or nil
    state.goalY = state.goalY ~= nil and tonumber(state.goalY) or nil
    state.goalZ = state.goalZ ~= nil and tonumber(state.goalZ) or nil
    state.goalMode = state.goalMode or nil
    state.goalStopDistance = tonumber(state.goalStopDistance) or 0.8
    state.vectorX = state.vectorX ~= nil and tonumber(state.vectorX) or nil
    state.vectorY = state.vectorY ~= nil and tonumber(state.vectorY) or nil
    state.damagePressureUntil = tonumber(state.damagePressureUntil) or 0
    state.lastZombieDamageAt = tonumber(state.lastZombieDamageAt) or 0
    state.lastZombieDamageX = state.lastZombieDamageX ~= nil and tonumber(state.lastZombieDamageX) or nil
    state.lastZombieDamageY = state.lastZombieDamageY ~= nil and tonumber(state.lastZombieDamageY) or nil
    state.lastZombieDamageZ = state.lastZombieDamageZ ~= nil and tonumber(state.lastZombieDamageZ) or nil
    state.nearMissUntil = tonumber(state.nearMissUntil) or 0
    state.lastNearMissAt = tonumber(state.lastNearMissAt) or 0
    state.lastNearMissX = state.lastNearMissX ~= nil
        and tonumber(state.lastNearMissX) or nil
    state.lastNearMissY = state.lastNearMissY ~= nil
        and tonumber(state.lastNearMissY) or nil
    state.lastNearMissZ = state.lastNearMissZ ~= nil
        and tonumber(state.lastNearMissZ) or nil
    state.approachActive = state.approachActive == true
    state.recoveryMode = state.recoveryMode or nil
    state.retreatDistance = tonumber(state.retreatDistance) or nil
    state.safetyRadius = tonumber(state.safetyRadius) or nil
    state.lowStaminaPhase = state.lowStaminaPhase or nil
    state.lowStaminaAttackUntil = tonumber(state.lowStaminaAttackUntil) or 0
    state.refreshAt = tonumber(state.refreshAt) or 0
    state.startedAt = tonumber(state.startedAt) or 0
    state.lastProgressAt = tonumber(state.lastProgressAt) or 0
    state.lastX = state.lastX ~= nil and tonumber(state.lastX) or nil
    state.lastY = state.lastY ~= nil and tonumber(state.lastY) or nil
    state.retryAt = tonumber(state.retryAt) or 0
    return state
end

local function requestMove(record, zombie, x, y, z, mode, stopDistance, reason)
    local MoveIntent = PNC.BehaviorMoveIntent
    if MoveIntent and MoveIntent.RequestMove and record and record.presenceState == Const.PRESENCE_LIVE then
        MoveIntent.RequestMove(
            record,
            x,
            y,
            z,
            mode,
            stopDistance,
            reason,
            COMBAT_NAVIGATION
        )
        return true
    end
    if PathService and PathService.MoveToward then
        return PathService.MoveToward(
            record,
            zombie,
            x,
            y,
            z,
            mode,
            stopDistance,
            reason,
            COMBAT_NAVIGATION
        )
    end
    return false
end

local function requestHold(record, zombie, reason)
    local MoveIntent = PNC.BehaviorMoveIntent
    if MoveIntent and MoveIntent.Hold
        and record and record.presenceState == Const.PRESENCE_LIVE
    then
        return MoveIntent.Hold(record, reason)
    end
    if PathService and PathService.Reset then
        PathService.Reset(record, zombie, reason)
        return true
    end
    return false
end

local function buildRetreatFromSource(record, target, distance, sourceX, sourceY, sourceZ, state)
    local dx
    local dy
    local len
    local baseX
    local baseY
    local angles
    local angle
    local cosAngle
    local sinAngle
    local candidateX
    local candidateY
    local retreatZ
    local i
    if not record then
        return nil
    end
    if sourceX ~= nil and sourceY ~= nil then
        dx = record.x - tonumber(sourceX)
        dy = record.y - tonumber(sourceY)
    elseif state and state.vectorX ~= nil and state.vectorY ~= nil then
        dx = tonumber(state.vectorX)
        dy = tonumber(state.vectorY)
    elseif target then
        dx = record.x - target.x
        dy = record.y - target.y
    else
        dx = 1
        dy = 0
    end
    len = math.sqrt((dx * dx) + (dy * dy))
    if len <= 0.001 then
        dx = 1
        dy = 0
        len = 1
    end
    baseX = dx / len
    baseY = dy / len
    retreatZ = tonumber(sourceZ) or target and target.z or record.z
    angles = { 0, 0.55, -0.55, 1.05, -1.05 }
    if TraversalQuery and TraversalQuery.CanStep and TraversalQuery.CanOccupy then
        for i = 1, #angles do
            angle = angles[i]
            cosAngle = math.cos(angle)
            sinAngle = math.sin(angle)
            dx = (baseX * cosAngle) - (baseY * sinAngle)
            dy = (baseX * sinAngle) + (baseY * cosAngle)
            candidateX = record.x + (dx * distance)
            candidateY = record.y + (dy * distance)
            if TraversalQuery.CanStep(record.x, record.y, record.z, record.x + (dx * 0.8), record.y + (dy * 0.8), retreatZ)
                and TraversalQuery.CanOccupy(candidateX, candidateY, retreatZ)
            then
                baseX = dx
                baseY = dy
                break
            end
        end
    end
    if state then
        state.vectorX = baseX
        state.vectorY = baseY
    end
    return {
        x = record.x + (baseX * distance),
        y = record.y + (baseY * distance),
        z = retreatZ,
    }
end

local function countZombiesNearPoint(x, y, z, radius)
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

local function countVisibleZombies(record, radius)
    local entries
    if Perception and Perception.GetVisibleZombieEntries then
        entries = Perception.GetVisibleZombieEntries(record, radius)
        return #entries
    end
    return Perception and Perception.CountEnemyZombies
        and Perception.CountEnemyZombies(record, radius) or 0
end

local function assessThreat(record, target)
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
        targetCrowdCount = countZombiesNearPoint(target.x, target.y, target.z or record.z, Const.COMBAT_TARGET_CROWD_RADIUS)
    end
    report = {
        targetKey = targetKey,
        x = record.x,
        y = record.y,
        targetX = target and target.x or nil,
        targetY = target and target.y or nil,
        staminaRatio = staminaRatio,
        staminaCurrent = staminaCurrent,
        retreating = runtime.retreatMode == true,
        surroundedCount = Perception and Perception.CountEnemyZombies and Perception.CountEnemyZombies(record, Const.COMBAT_SURROUND_RADIUS) or 0,
        pressureCount = Perception and Perception.CountEnemyZombies and Perception.CountEnemyZombies(record, Const.COMBAT_PRESSURE_RADIUS) or 0,
        hordeCount = Perception and Perception.CountEnemyZombies and Perception.CountEnemyZombies(record, Const.COMBAT_HORDE_RADIUS) or 0,
        visiblePressureCount = countVisibleZombies(record, Const.COMBAT_PRESSURE_RADIUS),
        visibleHordeCount = countVisibleZombies(record, Const.COMBAT_HORDE_RADIUS),
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

local function clearActiveRetreat(record, state)
    if state then
        state.phase = nil
        state.reason = nil
        state.lockUntil = 0
        state.goalX = nil
        state.goalY = nil
        state.goalZ = nil
        state.goalMode = nil
        state.goalStopDistance = 0.8
        state.vectorX = nil
        state.vectorY = nil
        state.recoveryMode = nil
        state.retreatDistance = nil
        state.safetyRadius = nil
        state.refreshAt = 0
        state.startedAt = 0
        state.lastProgressAt = 0
        state.lastX = nil
        state.lastY = nil
    end
    if record then
        record.runtime = record.runtime or {}
        record.runtime.retreatMode = false
        if record.runtime.staminaRecoveryMode == "retreat" then
            record.runtime.staminaRecoveryMode = nil
        end
        if record.runtime.tacticalState == "retreat" or record.runtime.tacticalState == "avoid_horde" then
            record.runtime.tacticalState = nil
        end
    end
end

local function setRetreatState(record, enabled, recoveryMode)
    if not record then
        return
    end
    record.runtime = record.runtime or {}
    record.runtime.retreatMode = enabled == true
    record.runtime.staminaRecoveryMode = enabled == true and recoveryMode or nil
    record.runtime.tacticalState = enabled == true and (recoveryMode or "retreat") or nil
end

function Tactics.ClearRetreatState(record)
    local state = ensureRetreatState(record)
    clearActiveRetreat(record, state)
    if state then
        state.retryAt = 0
        state.lowStaminaPhase = nil
        state.lowStaminaAttackUntil = 0
    end
end

function Tactics.MarkZombieDamage(record, sourceX, sourceY, sourceZ, now)
    local state = ensureRetreatState(record)
    now = tonumber(now) or Core.Now()
    if not state then
        return
    end
    state.lastZombieDamageAt = now
    state.lastZombieDamageX = sourceX ~= nil and tonumber(sourceX) or nil
    state.lastZombieDamageY = sourceY ~= nil and tonumber(sourceY) or nil
    state.lastZombieDamageZ = sourceZ ~= nil and tonumber(sourceZ) or nil
    -- Damage remains diagnostic only. Kiting is armed exclusively by a
    -- resolved near miss, not by every wound/bleed update.
    state.damagePressureUntil = 0
end

function Tactics.MarkZombieNearMiss(
    record,
    sourceX,
    sourceY,
    sourceZ,
    now
)
    local state = ensureRetreatState(record)
    now = tonumber(now) or Core.Now()
    if not state then return end
    state.lastNearMissAt = now
    state.lastNearMissX = sourceX ~= nil
        and tonumber(sourceX) or nil
    state.lastNearMissY = sourceY ~= nil
        and tonumber(sourceY) or nil
    state.lastNearMissZ = sourceZ ~= nil
        and tonumber(sourceZ) or nil
    state.nearMissUntil = now
        + (
            tonumber(Const.COMBAT_KITE_NEAR_MISS_WINDOW_MS)
                or 1400
        )
end

local function targetObject(target)
    if not target then return nil end
    if target.kind == "zombie" then
        return Perception and Perception.FindZombieByID
            and Perception.FindZombieByID(target.zombieId) or nil
    end
    if target.kind == "player" then
        return target.player
    end
    return nil
end

function Tactics.IsGroundTarget(target)
    local object = targetObject(target)
    local Unarmed = PNC.CombatUnarmed
    return object ~= nil
        and Unarmed
        and Unarmed.IsGroundTarget
        and Unarmed.IsGroundTarget(object) == true
end

function Tactics.ShouldUseGroundFinisher(record, target)
    local report
    if not Tactics.IsGroundTarget(target) then
        return false, "target_not_grounded"
    end
    report = assessThreat(record, target)
    if report.pressureCount
        > (tonumber(Const.COMBAT_GROUND_FINISHER_MAX_PRESSURE) or 1)
    then
        return false, "ground_finisher_unsafe"
    end
    return true, "ground_finisher_safe"
end

function Tactics.ResolveMeleeApproach(record, dist)
    local state = ensureRetreatState(record)
    local shouldApproach
    local preferredMode
    dist = tonumber(dist) or math.huge
    if not state then
        return false, Const.MELEE_RANGE, "walk"
    end
    if state.approachActive then
        if dist <= (Const.MELEE_RANGE - Const.COMBAT_KITE_MELEE_STOP_BUFFER) then
            state.approachActive = false
        end
    elseif dist > (Const.MELEE_RANGE + Const.COMBAT_KITE_MELEE_ENTER_BUFFER) then
        state.approachActive = true
    end
    shouldApproach = state.approachActive == true
    preferredMode = dist > (Const.MELEE_RANGE + Const.COMBAT_KITE_MELEE_HOLD_BUFFER) and "run" or "walk"
    return shouldApproach,
        tonumber(Const.MELEE_APPROACH_STOP_DISTANCE)
            or math.max(0.75, (tonumber(Const.MELEE_RANGE) or 1.3) - 0.35),
        preferredMode
end

local function continueLockedRetreat(record, zombie, target, state, now)
    local currentX
    local currentY
    local movedX
    local movedY
    local goalX
    local goalY
    local stopDistance
    local stallMs
    local retryMs
    local safetyRadius
    local recoveryRetreat
    local targetDistance
    if not state or state.phase ~= "retreat" then
        return false, nil
    end
    if state.goalX == nil or state.goalY == nil then
        return false, nil
    end
    currentX = zombie and zombie.getX and zombie:getX()
        or tonumber(record and record.x) or 0
    currentY = zombie and zombie.getY and zombie:getY()
        or tonumber(record and record.y) or 0
    goalX = tonumber(state.goalX) or currentX
    goalY = tonumber(state.goalY) or currentY
    stopDistance = tonumber(state.goalStopDistance) or 0.8
    safetyRadius = tonumber(state.safetyRadius)
    recoveryRetreat = state.lowStaminaPhase == "retreat"
    if safetyRadius and target and target.x ~= nil and target.y ~= nil then
        targetDistance = math.sqrt(Core.DistanceSq(
            currentX,
            currentY,
            target.x,
            target.y
        ))
        if targetDistance >= safetyRadius then
            clearActiveRetreat(record, state)
            requestHold(record, zombie, "recovering_stamina_safe")
            if recoveryRetreat then
                state.lowStaminaPhase = "recover"
                return true, "recovering_stamina_safe"
            end
            return false, "retreat_safe_radius"
        end
    end
    if Core.DistanceSq(currentX, currentY, goalX, goalY)
        <= stopDistance * stopDistance
    then
        clearActiveRetreat(record, state)
        state.retryAt = 0
        if recoveryRetreat then
            -- If the attacker closed the distance during this bounded leg,
            -- counter briefly before choosing a new escape direction.
            state.lowStaminaPhase = "counter"
            state.lowStaminaAttackUntil = now
                + (tonumber(Const.COMBAT_EXHAUSTED_COUNTER_MS) or 1800)
        end
        return false, "retreat_complete"
    end
    if state.lastX == nil or state.lastY == nil then
        state.lastX = currentX
        state.lastY = currentY
        state.lastProgressAt = now
    else
        movedX = currentX - state.lastX
        movedY = currentY - state.lastY
        if (movedX * movedX) + (movedY * movedY)
            >= (tonumber(Const.COMBAT_RETREAT_PROGRESS_DISTANCE) or 0.18) ^ 2
        then
            state.lastX = currentX
            state.lastY = currentY
            state.lastProgressAt = now
        end
    end
    stallMs = tonumber(Const.COMBAT_RETREAT_STALL_MS) or 900
    retryMs = tonumber(Const.COMBAT_RETREAT_RETRY_MS) or 800
    if now - (tonumber(state.lastProgressAt) or now) >= stallMs then
        clearActiveRetreat(record, state)
        state.retryAt = now + retryMs
        return false, "retreat_stalled"
    end
    -- Keep one fixed destination for this leg. Rebuilding it from the NPC's
    -- current position moved the finish line every tick and caused endless
    -- flight in one direction.
    setRetreatState(record, true, state.recoveryMode)
    if not requestMove(
        record,
        zombie,
        state.goalX,
        state.goalY,
        state.goalZ or record.z,
        state.goalMode or "walk",
        state.goalStopDistance or 0.8,
        state.reason or "combat_retreat"
    ) then
        clearActiveRetreat(record, state)
        state.retryAt = now + retryMs
        return false, "retreat_rejected"
    end
    return true, state.reason or "combat_retreat"
end

local function startRetreat(record, zombie, target, distance, mode, stopDistance, lockMs, reason, recoveryMode, sourceX, sourceY, sourceZ, safetyRadius)
    local state = ensureRetreatState(record)
    local retreat
    local now = Core.Now()
    if not state then
        return false, nil
    end
    if now < (tonumber(state.retryAt) or 0) then
        return false, "retreat_stalled"
    end
    retreat = buildRetreatFromSource(record, target, distance, sourceX, sourceY, sourceZ, state)
    if not retreat then
        return false, nil
    end
    state.phase = "retreat"
    state.reason = reason
    state.lockUntil = now + math.max(120, tonumber(lockMs) or Const.COMBAT_KITE_RETREAT_LOCK_MS)
    state.goalX = retreat.x
    state.goalY = retreat.y
    state.goalZ = retreat.z
    state.goalMode = mode
    state.goalStopDistance = tonumber(stopDistance) or 0.8
    state.recoveryMode = recoveryMode
    state.retreatDistance = distance
    state.safetyRadius = tonumber(safetyRadius)
    state.refreshAt = now + 220
    state.startedAt = now
    state.lastProgressAt = now
    state.lastX = zombie and zombie.getX and zombie:getX()
        or tonumber(record.x) or 0
    state.lastY = zombie and zombie.getY and zombie:getY()
        or tonumber(record.y) or 0
    setRetreatState(record, true, recoveryMode)
    if not requestMove(
        record,
        zombie,
        retreat.x,
        retreat.y,
        retreat.z,
        mode,
        stopDistance,
        reason
    ) then
        clearActiveRetreat(record, state)
        state.retryAt = now
            + (tonumber(Const.COMBAT_RETREAT_RETRY_MS) or 800)
        return false, "retreat_rejected"
    end
    return true, reason
end

local function staminaCurrent(record)
    if record and record.stamina then
        return tonumber(record.stamina.current) or math.huge
    end
    return math.huge
end

function Tactics.NeedsRecoveryRetreat(record)
    return staminaCurrent(record)
        < (tonumber(Const.COMBAT_RETREAT_STAMINA_CURRENT) or 20)
end

local function tryNearMissRetreat(record, zombie, target, state, now, report)
    if not state
        or not target
        or target.kind ~= "zombie"
        or now > (tonumber(state.nearMissUntil) or 0)
    then
        return false, nil
    end
    if report
        and report.pressureCount
            < (
                tonumber(Const.COMBAT_TACTICAL_RETREAT_MIN_PRESSURE)
                    or 2
            )
    then
        -- A lone zombie is a counterattack problem, not a kiting problem.
        -- Consume the near miss so it cannot repeatedly steal attack windows.
        state.nearMissUntil = 0
        return false, "lone_threat_counter"
    end
    state.nearMissUntil = 0
    if record.runtime and record.runtime.combatTactical then
        record.runtime.combatTactical.decision = "near_miss_kite"
    end
    return startRetreat(
        record,
        zombie,
        target,
        tonumber(Const.COMBAT_KITE_DAMAGE_DISTANCE) or 2.4,
        report and report.surroundedCount >= 2 and "run" or "walk",
        0.7,
        tonumber(Const.COMBAT_KITE_DAMAGE_LOCK_MS) or 700,
        "near_miss_kite",
        nil,
        state.lastNearMissX,
        state.lastNearMissY,
        state.lastNearMissZ
    )
end

buildZombieThreatCentroid = function(record, radius)
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

local function stableDirection(id)
    local value = tostring(id or "")
    local hash = 0
    local i
    for i = 1, #value do
        hash = (hash * 33 + string.byte(value, i)) % 360
    end
    return (hash / 360) * math.pi * 2
end

local function pointNearSegment(px, py, ax, ay, bx, by, corridor)
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

local function isProtectedNPC(record, other, target)
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

function Tactics.IsFriendlyFireSafe(record, target)
    local now
    local targetKey
    local cached
    local distance
    local midpointX
    local midpointY
    local corridor = tonumber(Const.RANGED_FRIENDLY_FIRE_CORRIDOR) or 0.62
    local candidates
    local other
    local players
    local player
    local i
    local unsafeKind
    local unsafeID
    local unsafeX
    local unsafeY
    local unsafeZ
    if not record or not target or target.x == nil or target.y == nil then
        return false, "invalid_fire_lane"
    end
    record.runtime = record.runtime or {}
    now = Core.Now()
    targetKey = tostring(target.kind or "") .. ":"
        .. tostring(target.id or target.zombieId or target.onlineID or "")
    cached = record.runtime.combatFireLane
    if cached
        and cached.targetKey == targetKey
        and now < (tonumber(cached.expiresAt) or 0)
        and Core.DistanceSq(cached.shooterX, cached.shooterY, record.x, record.y)
            <= 0.04
        and Core.DistanceSq(cached.targetX, cached.targetY, target.x, target.y)
            <= 0.04
    then
        return cached.safe == true,
            cached.safe == true and "fire_lane_clear" or "friendly_fire_risk"
    end
    distance = math.sqrt(Core.DistanceSq(record.x, record.y, target.x, target.y))
    midpointX = (record.x + target.x) * 0.5
    midpointY = (record.y + target.y) * 0.5

    candidates = Spatial and Spatial.QueryNPCs
        and Spatial.QueryNPCs(midpointX, midpointY, distance * 0.5 + corridor)
        or {}
    for i = 1, #candidates do
        other = candidates[i]
        if isProtectedNPC(record, other, target)
            and math.abs((tonumber(other.z) or record.z) - record.z) < 1
            and pointNearSegment(
                tonumber(other.x) or 0,
                tonumber(other.y) or 0,
                record.x,
                record.y,
                target.x,
                target.y,
                corridor
            )
        then
            unsafeKind = "npc"
            unsafeID = other.id
            unsafeX = other.x
            unsafeY = other.y
            unsafeZ = other.z
            break
        end
    end

    if not unsafeKind then
        players = Spatial and Spatial.QueryPlayers
            and Spatial.QueryPlayers(
                midpointX,
                midpointY,
                distance * 0.5 + corridor
            ) or {}
        for i = 1, #players do
            player = players[i]
            if player
                and player ~= target.player
                and not (
                    target.kind == "player"
                    and target.onlineID ~= nil
                    and player.getOnlineID
                    and tonumber(player:getOnlineID()) == tonumber(target.onlineID)
                )
                and math.abs(player:getZ() - record.z) < 1
                and pointNearSegment(
                    player:getX(),
                    player:getY(),
                    record.x,
                    record.y,
                    target.x,
                    target.y,
                    corridor
                )
            then
                unsafeKind = "player"
                unsafeID = player.getOnlineID and player:getOnlineID() or nil
                unsafeX = player:getX()
                unsafeY = player:getY()
                unsafeZ = player:getZ()
                break
            end
        end
    end

    record.runtime.combatFireLane = {
        targetKey = targetKey,
        safe = unsafeKind == nil,
        blockerKind = unsafeKind,
        blockerID = unsafeID,
        blockerX = unsafeX,
        blockerY = unsafeY,
        blockerZ = unsafeZ,
        shooterX = record.x,
        shooterY = record.y,
        targetX = target.x,
        targetY = target.y,
        checkedAt = now,
        expiresAt = now + (tonumber(Const.RANGED_FIRE_LANE_CACHE_MS) or 120),
    }
    if unsafeKind then
        return false, "friendly_fire_risk"
    end
    return true, "fire_lane_clear"
end

function Tactics.CanTakeRangedShot(record, target)
    local now
    local state
    local targetKey
    local aiming
    local dist
    local report
    local settleMs
    local moveTolerance
    local progress
    local confidence
    local safe
    local reason
    if not record or not target then return false, "no_target" end
    safe, reason = Tactics.IsFriendlyFireSafe(record, target)
    if not safe then return false, reason end

    record.runtime = record.runtime or {}
    now = Core.Now()
    state = record.runtime.combatAim or {}
    record.runtime.combatAim = state
    targetKey = tostring(target.kind or "") .. ":"
        .. tostring(target.id or target.zombieId or target.onlineID or "")
    moveTolerance = tonumber(Const.RANGED_AIM_MOVE_TOLERANCE) or 0.35
    if state.targetKey ~= targetKey
        or state.shooterX == nil
        or Core.DistanceSq(state.shooterX, state.shooterY, record.x, record.y)
            > moveTolerance * moveTolerance
        or state.targetX == nil
        or Core.DistanceSq(state.targetX, state.targetY, target.x, target.y)
            > (moveTolerance * 1.5) ^ 2
    then
        state.targetKey = targetKey
        state.startedAt = now
        state.shooterX = record.x
        state.shooterY = record.y
        state.targetX = target.x
        state.targetY = target.y
    end

    aiming = Skills and Skills.GetLevel and Skills.GetLevel(record, "Aiming") or 0
    dist = math.sqrt(tonumber(target.distSq)
        or Core.DistanceSq(record.x, record.y, target.x, target.y))
    report = assessThreat(record, target)
    settleMs = (tonumber(Const.RANGED_AIM_BASE_MS) or 460)
        - math.min(aiming, 10)
            * (tonumber(Const.RANGED_AIM_SKILL_REDUCTION_MS) or 32)
        + dist * (tonumber(Const.RANGED_AIM_DISTANCE_PENALTY_MS) or 22)
        + math.min(report.visiblePressureCount, 4)
            * (tonumber(Const.RANGED_AIM_PRESSURE_PENALTY_MS) or 65)
    settleMs = math.max(
        tonumber(Const.RANGED_AIM_MIN_MS) or 140,
        math.min(900, settleMs)
    )
    state.readyAt = (tonumber(state.startedAt) or now) + settleMs
    progress = math.max(0, math.min(
        1,
        (now - (tonumber(state.startedAt) or now)) / math.max(1, settleMs)
    ))
    confidence = 0.42
        + math.min(aiming, 10) * 0.045
        + progress * 0.42
        - math.min(0.18, dist / math.max(1, Const.RANGED_RANGE) * 0.18)
        - math.min(report.visiblePressureCount, 4) * 0.035
    state.confidence = math.max(0, math.min(1, confidence))
    state.settleMs = settleMs
    if now < state.readyAt or state.confidence < 0.54 then
        return false, "aiming"
    end
    return true, "aim_confident"
end

function Tactics.MarkRangedShot(record)
    local state = record and record.runtime and record.runtime.combatAim or nil
    if not state then return end
    state.startedAt = Core.Now()
    state.shooterX = record.x
    state.shooterY = record.y
    state.confidence = 0
end

function Tactics.ShouldInterruptReload(record, target)
    local action = record and record.runtime and record.runtime.attackAction or nil
    local report
    local dist
    if not action or action.attackType ~= "reload" then
        return false, nil
    end
    report = assessThreat(record, target)
    dist = target and math.sqrt(tonumber(target.distSq)
        or Core.DistanceSq(record.x, record.y, target.x, target.y))
        or math.huge
    if dist <= (tonumber(Const.RANGED_RELOAD_BREAK_DISTANCE) or 2.35)
        or report.surroundedCount >= 1
        or report.visiblePressureCount
            >= (tonumber(Const.RANGED_RELOAD_BREAK_PRESSURE_COUNT) or 2)
    then
        return true, "reload_interrupted_by_pressure"
    end
    return false, nil
end

function Tactics.GetMeleeApproachPoint(record, target)
    local candidates
    local other
    local allyCount = 0
    local angle
    local radius
    local x
    local y
    local i
    if not record or not target or not Spatial or not Spatial.QueryNPCs then
        return target and target.x, target and target.y, false
    end
    candidates = Spatial.QueryNPCs(
        target.x,
        target.y,
        tonumber(Const.COMBAT_FORMATION_QUERY_RADIUS) or 2.4
    )
    for i = 1, #candidates do
        other = candidates[i]
        if isProtectedNPC(record, other, target)
            and math.abs((tonumber(other.z) or record.z) - record.z) < 1
        then
            allyCount = allyCount + 1
        end
    end
    if allyCount <= 0 then return target.x, target.y, false end
    angle = stableDirection(record.id)
    radius = tonumber(Const.COMBAT_FORMATION_SLOT_RADIUS) or 1.05
    x = target.x + math.cos(angle) * radius
    y = target.y + math.sin(angle) * radius
    if TraversalQuery and TraversalQuery.CanOccupy
        and not TraversalQuery.CanOccupy(x, y, target.z or record.z)
    then
        angle = angle + math.pi
        x = target.x + math.cos(angle) * radius
        y = target.y + math.sin(angle) * radius
    end
    return x, y, true
end

function Tactics.PreAttackDecision(record, zombie, target, effectiveMode, equipmentInfo)
    local report
    local state
    local now
    local dist
    local meleeLane
    local grounded
    local sourceX
    local sourceY
    local centroidCount
    local skillID
    local meleeSkill
    local pressureTolerance
    local shouldShove
    local canSpendMelee
    local retreatMinPressure
    local continued
    local continueReason
    local safetyRadius
    local safetyBuffer
    local recoveryThreshold
    local retreatDistance
    if not record or not zombie or not target or target.kind ~= "zombie" then
        return false, nil, nil
    end
    now = Core.Now()
    state = ensureRetreatState(record)
    dist = math.sqrt(tonumber(target.distSq)
        or Core.DistanceSq(record.x, record.y, target.x, target.y))
    safetyRadius = tonumber(Const.NPC_ZOMBIE_DEFENSE_RADIUS) or 2.2
    safetyBuffer = tonumber(Const.COMBAT_RETREAT_SAFETY_BUFFER) or 0.25
    recoveryThreshold = tonumber(
        Const.COMBAT_EXHAUSTED_REENGAGE_CURRENT
    ) or 35
    meleeLane = effectiveMode == "melee"
        or (
            effectiveMode == "mixed"
            and dist <= (tonumber(Const.MELEE_RANGE) or 1.3) * 1.1
        )
    -- Ranged spacing must never own the tick before the weapon gets another
    -- chance to fire. Its existing retreat is refreshed later only when the
    -- ranged attempt is still cooling down.
    if not meleeLane then return false, nil, nil end
    continued, continueReason = continueLockedRetreat(
        record,
        zombie,
        target,
        state,
        now
    )
    if continued then
        return true, continueReason or state.reason or "combat_retreat", nil
    end
    if continueReason == "retreat_stalled" then
        return false, continueReason, nil
    end

    report = assessThreat(record, target)
    grounded = Tactics.IsGroundTarget(target)
    retreatMinPressure = tonumber(
        Const.COMBAT_TACTICAL_RETREAT_MIN_PRESSURE
    ) or 2
    if state.lowStaminaPhase == "recover" then
        if staminaCurrent(record) >= recoveryThreshold then
            state.lowStaminaPhase = nil
            state.lowStaminaAttackUntil = 0
        elseif dist < safetyRadius then
            retreatDistance = math.max(
                0.8,
                safetyRadius - dist + safetyBuffer
            )
            record.runtime.combatTactical.decision =
                "exhausted_recovery_retreat"
            continued, continueReason = startRetreat(
                record,
                zombie,
                target,
                retreatDistance,
                "walk",
                0.3,
                tonumber(Const.COMBAT_KITE_RETREAT_LOCK_MS) or 1100,
                "exhausted_recovery_retreat",
                "retreat",
                nil,
                nil,
                nil,
                safetyRadius
            )
            if continued then
                state.lowStaminaPhase = "retreat"
            end
            return continued, continueReason, nil
        else
            record.runtime.combatTactical.decision =
                "recovering_stamina_safe"
            requestHold(record, zombie, "recovering_stamina_safe")
            return true, "recovering_stamina_safe", nil
        end
    end
    if not grounded
        and now <= (tonumber(state.nearMissUntil) or 0)
        and report.pressureCount < retreatMinPressure
        and dist <= (tonumber(Const.COMBAT_SHOVE_RANGE) or 1.35)
    then
        state.nearMissUntil = 0
        record.runtime.combatTactical.decision =
            "lone_threat_counter"
        return false, "lone_threat_counter", "shove"
    end
    if tryNearMissRetreat(record, zombie, target, state, now, report) then
        return true, "near_miss_kite", nil
    end
    skillID = Skills and Skills.ResolveWeaponSkill
        and Skills.ResolveWeaponSkill(
            record,
            record.equipment and record.equipment.primaryFullType,
            "melee"
        ) or "Strength"
    meleeSkill = Skills and Skills.GetLevel
        and Skills.GetLevel(record, skillID) or 0
    pressureTolerance = 2
        + math.floor(math.min(meleeSkill, 9) / 3)
        + (equipmentInfo and equipmentInfo.hasWeapon and 1 or 0)
    pressureTolerance = math.min(
        tonumber(Const.COMBAT_PRESSURE_COUNT) or 4,
        pressureTolerance
    )
    shouldShove = not grounded
        and dist <= (tonumber(Const.COMBAT_SHOVE_RANGE) or 1.35)
        and report.surroundedCount
            < (tonumber(Const.COMBAT_SURROUND_COUNT) or 3)
        and report.pressureCount
            >= (tonumber(Const.COMBAT_SHOVE_PRESSURE_COUNT) or 2)
        and (
            equipmentInfo == nil
            or equipmentInfo.hasWeapon ~= true
            or report.pressureCount > pressureTolerance
        )
        and not Tactics.NeedsRecoveryRetreat(record)

    if shouldShove then
        record.runtime.combatTactical.decision = "pressure_shove"
        record.runtime.combatTactical.meleeSkill = meleeSkill
        record.runtime.combatTactical.pressureTolerance = pressureTolerance
        return false, "pressure_shove", "shove"
    end

    canSpendMelee = not Stamina
        or not Stamina.CanSpendAttack
        or Stamina.CanSpendAttack(record, "melee", skillID)
    if Tactics.NeedsRecoveryRetreat(record)
        and report.pressureCount >= retreatMinPressure
    then
        sourceX, sourceY, centroidCount = buildZombieThreatCentroid(
            record,
            Const.COMBAT_HORDE_RADIUS
        )
        record.runtime.combatTactical.decision = "recovering_stamina"
        continued, continueReason = startRetreat(
            record,
            zombie,
            target,
            2.8 + math.min(tonumber(centroidCount) or 0, 5) * 0.35,
            "walk",
            0.6,
            math.max(650, tonumber(Const.COMBAT_KITE_RETREAT_LOCK_MS) or 450),
            "recovering_stamina",
            "retreat",
            sourceX,
            sourceY,
            record.z,
            safetyRadius
        )
        if continued then
            state.lowStaminaPhase = "retreat"
        end
        return continued, continueReason, nil
    end
    if Tactics.NeedsRecoveryRetreat(record) and not grounded then
        if state.lowStaminaPhase ~= "counter" then
            state.lowStaminaPhase = "counter"
            state.lowStaminaAttackUntil = now
                + (tonumber(Const.COMBAT_EXHAUSTED_COUNTER_MS) or 1800)
        end
        if now < (tonumber(state.lowStaminaAttackUntil) or 0) then
            -- Keep fighting briefly instead of turning away the instant the
            -- reserve threshold is crossed. The emergency lease permits a
            -- weakened strike when normal stamina spending is unavailable.
            record.runtime.combatTactical.decision =
                "exhausted_lone_counter"
            if not canSpendMelee then
                record.runtime.emergencyMeleeUntil = now + 300
            end
            return false, "exhausted_lone_counter", nil
        end
        retreatDistance = math.max(
            0.8,
            safetyRadius - dist + safetyBuffer
        )
        record.runtime.combatTactical.decision =
            "exhausted_recovery_retreat"
        continued, continueReason = startRetreat(
            record,
            zombie,
            target,
            retreatDistance,
            "walk",
            0.3,
            tonumber(Const.COMBAT_KITE_RETREAT_LOCK_MS) or 1100,
            "exhausted_recovery_retreat",
            "retreat",
            nil,
            nil,
            nil,
            safetyRadius
        )
        if continued then
            state.lowStaminaPhase = "retreat"
        end
        return continued, continueReason, nil
    end
    record.runtime.combatTactical.decision = grounded
        and "ground_finisher_window" or "melee_commit_window"
    record.runtime.combatTactical.meleeSkill = meleeSkill
    record.runtime.combatTactical.pressureTolerance = pressureTolerance
    return false, nil, grounded and "ground" or nil
end

function Tactics.RepositionForClearShot(record, zombie, target)
    local state
    local now
    local dx
    local dy
    local length
    local direction
    local distance
    local candidateX
    local candidateY
    local alternateX
    local alternateY
    local z
    if not record or not zombie or not target then return false, nil end
    now = Core.Now()
    state = ensureRetreatState(record)
    if continueLockedRetreat(record, zombie, target, state, now) then
        return true, state.reason or "clearing_fire_lane"
    end
    dx = target.x - record.x
    dy = target.y - record.y
    length = math.sqrt((dx * dx) + (dy * dy))
    if length <= 0.001 then return false, "invalid_fire_lane" end
    direction = stableDirection(record.id) < math.pi and 1 or -1
    distance = tonumber(Const.RANGED_FIRE_LANE_STRAFE_DISTANCE) or 1.6
    candidateX = record.x + (-dy / length) * distance * direction
    candidateY = record.y + (dx / length) * distance * direction
    alternateX = record.x - (-dy / length) * distance * direction
    alternateY = record.y - (dx / length) * distance * direction
    z = target.z or record.z
    if TraversalQuery and TraversalQuery.CanOccupy
        and not TraversalQuery.CanOccupy(candidateX, candidateY, z)
    then
        candidateX = alternateX
        candidateY = alternateY
    end
    state.phase = "strafe"
    state.reason = "clearing_fire_lane"
    state.lockUntil = now
        + (tonumber(Const.RANGED_FIRE_LANE_LOCK_MS) or 500)
    state.goalX = candidateX
    state.goalY = candidateY
    state.goalZ = z
    state.goalMode = "walk"
    state.goalStopDistance = 0.25
    setRetreatState(record, true, nil)
    requestMove(
        record,
        zombie,
        candidateX,
        candidateY,
        z,
        "walk",
        0.25,
        "clearing_fire_lane"
    )
    return true, "clearing_fire_lane"
end

function Tactics.MaintainRangedSpacing(record, zombie, target)
    local state
    local now
    local dist
    local preferredMin
    local report
    local pressure
    local sourceX
    local sourceY
    local centroidCount
    local retreatDistance
    local mode
    local reason
    if not record or not zombie or not target then return false, nil end
    now = Core.Now()
    state = ensureRetreatState(record)
    if continueLockedRetreat(record, zombie, target, state, now) then
        return true, state.reason or "ranged_disengage"
    end

    dist = math.sqrt(tonumber(target.distSq or 0) or 0)
    preferredMin = tonumber(Const.RANGED_PREFERRED_MIN_DISTANCE) or 5.0
    report = assessThreat(record, target)
    pressure = target.kind == "zombie" and (
        report.pressureCount >= (tonumber(Const.RANGED_PRESSURE_COUNT) or 2)
        or report.hordeCount >= Const.COMBAT_HORDE_COUNT
        or (
            dist < preferredMin
            and report.targetCrowdCount >= Const.COMBAT_TARGET_CROWD_COUNT
        )
    )

    if dist >= preferredMin and not pressure then
        clearActiveRetreat(record, state)
        return false, nil
    end

    if pressure then
        sourceX, sourceY, centroidCount = buildZombieThreatCentroid(
            record,
            Const.COMBAT_HORDE_RADIUS
        )
    end
    retreatDistance = (tonumber(Const.RANGED_RETREAT_STEP) or 3.2)
        + math.max(0, preferredMin - dist)
        + math.min(tonumber(centroidCount) or 0, 5) * 0.2
    mode = pressure
        and report.staminaRatio > Const.COMBAT_RETREAT_STAMINA_RATIO
        and "run"
        or "walk"
    reason = pressure and "ranged_avoiding_horde" or "ranged_disengage"
    return startRetreat(
        record,
        zombie,
        target,
        math.min(5.5, retreatDistance),
        mode,
        0.45,
        math.max(Const.COMBAT_KITE_RETREAT_LOCK_MS, 650),
        reason,
        report.staminaRatio <= Const.COMBAT_RETREAT_STAMINA_RATIO
            and "retreat"
            or nil,
        sourceX,
        sourceY,
        record.z
    )
end

function Tactics.AvoidThreat(record, zombie, target, options)
    local state
    local now
    local staminaRatio
    local distance
    local mode
    local continued
    local continueReason
    local radius
    if not record or not target then return false, "avoid_target_missing" end
    options = type(options) == "table" and options or {}
    now = Core.Now()
    state = ensureRetreatState(record)
    continued, continueReason =
        continueLockedRetreat(record, zombie, target, state, now)
    if continued then
        return true, state.reason or "companion_avoiding_threat"
    end
    if continueReason == "retreat_stalled"
        or now < (tonumber(state and state.retryAt) or 0)
    then
        return false, "retreat_stalled"
    end
    staminaRatio = Stamina and Stamina.GetRatio
        and Stamina.GetRatio(record) or 1
    distance = math.sqrt(tonumber(target.distSq) or Core.DistanceSq(
        record.x,
        record.y,
        target.x,
        target.y
    ))
    radius = tonumber(options.radius)
        or tonumber(Const.COMPANION_AVOID_THREAT_RADIUS)
        or 10
    if distance > radius then
        clearActiveRetreat(record, state)
        state.retryAt = 0
        return false, "threat_outside_avoid_radius"
    end
    mode = staminaRatio > (tonumber(Const.COMBAT_RETREAT_STAMINA_RATIO) or 0.1)
        and "run" or "walk"
    return startRetreat(
        record,
        zombie,
        target,
        tonumber(options.distance)
            or tonumber(Const.COMPANION_AVOID_THREAT_DISTANCE)
            or 5,
        tostring(options.mode or mode),
        tonumber(options.stopDistance) or 0.8,
        tonumber(options.lockMs)
            or tonumber(Const.COMPANION_AVOID_THREAT_LOCK_MS)
            or 750,
        tostring(options.reason or "companion_avoiding_threat"),
        options.recoveryMode
            or (
                staminaRatio
                    <= (tonumber(Const.COMBAT_RETREAT_STAMINA_RATIO) or 0.1)
                and "retreat"
                or nil
            )
    )
end

function Tactics.TryReposition(record, zombie, target, effectiveMode, reason, equipmentInfo)
    local aiming
    local dist
    local report
    local now
    local state

    if not record or not zombie or not target then
        return false, nil
    end
    if reason == "friendly_fire_risk" then
        return Tactics.RepositionForClearShot(record, zombie, target)
    end

    now = Core.Now()
    state = ensureRetreatState(record)
    dist = math.sqrt(tonumber(target.distSq or 0) or 0)
    report = assessThreat(record, target)
    if continueLockedRetreat(record, zombie, target, state, now) then
        return true, state.reason or "combat_retreat"
    end

    if tryNearMissRetreat(record, zombie, target, state, now, report) then
        return true, "near_miss_kite"
    end

    if Tactics.NeedsRecoveryRetreat(record)
        and report.pressureCount >= (
            tonumber(Const.COMBAT_TACTICAL_RETREAT_MIN_PRESSURE)
                or 2
        )
    then
        return startRetreat(
            record,
            zombie,
            target,
            3.8 + math.min(report.pressureCount, 4) * 0.35,
            "walk",
            0.8,
            Const.COMBAT_KITE_RETREAT_LOCK_MS,
            "recovering_stamina",
            "retreat"
        )
    end

    clearActiveRetreat(record, state)

    if effectiveMode == "ranged" or effectiveMode == "mixed" then
        aiming = Skills and Skills.GetLevel and Skills.GetLevel(record, "Aiming") or 0
        -- A single nearby target is not enough reason to run during every
        -- cooldown. That behavior continually replaced the aim hold with a
        -- retreat intent and starved ranged NPCs of reliable follow-up shots.
        if target.kind == "zombie" and dist < (tonumber(Const.RANGED_MIN_STANDOFF) or 2.2) then
            return startRetreat(
                record,
                zombie,
                target,
                1.4 + math.min(aiming, 6) * 0.12,
                report.pressureCount >= 2 and "run" or "walk",
                0.25,
                Const.COMBAT_KITE_RETREAT_LOCK_MS,
                "maintaining_range",
                nil
            )
        end
        return false, nil
    end

    return false, nil
end
