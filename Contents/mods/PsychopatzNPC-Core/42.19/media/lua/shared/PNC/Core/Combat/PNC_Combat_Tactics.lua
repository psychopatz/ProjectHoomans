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
    state.approachActive = state.approachActive == true
    return state
end

local function requestMove(record, zombie, x, y, z, mode, stopDistance, reason)
    local MoveIntent = PNC.BehaviorMoveIntent
    if MoveIntent and MoveIntent.RequestMove and record and record.presenceState == Const.PRESENCE_LIVE then
        MoveIntent.RequestMove(record, x, y, z, mode, stopDistance, reason)
        return true
    end
    if PathService and PathService.MoveToward then
        return PathService.MoveToward(record, zombie, x, y, z, mode, stopDistance, reason)
    end
    return false
end

local function requestCombatFacing(record, zombie, target, leaseMs, reason)
    if PathService and PathService.RequestCombatFacing then
        PathService.RequestCombatFacing(record, zombie, target, leaseMs, reason)
    end
end

local function isManagedNPCBody(zombie)
    local modData
    if not zombie or not zombie.getModData then
        return false
    end
    modData = zombie:getModData()
    return modData and modData.PNC_NPC == true
end

local function buildRetreatPoint(record, target, distance)
    local dx
    local dy
    local len
    if not record or not target then
        return nil
    end
    dx = record.x - target.x
    dy = record.y - target.y
    len = math.sqrt((dx * dx) + (dy * dy))
    if len <= 0.001 then
        dx = 1
        dy = 0
        len = 1
    end
    return {
        x = record.x + (dx / len) * distance,
        y = record.y + (dy / len) * distance,
        z = target.z or record.z,
    }
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
        if zombie and (not zombie:isDead()) and (not isManagedNPCBody(zombie)) and math.abs(zombie:getZ() - z) < 1 then
            distSq = Core.DistanceSq(x, y, zombie:getX(), zombie:getY())
            if distSq <= radiusSq then
                count = count + 1
            end
        end
    end
    return count
end

local function assessThreat(record, target)
    local staminaRatio = Stamina and Stamina.GetRatio and Stamina.GetRatio(record) or 1
    local runtime = record and record.runtime or {}
    local targetCrowdCount = 0
    if target and target.kind == "zombie" then
        targetCrowdCount = countZombiesNearPoint(target.x, target.y, target.z or record.z, Const.COMBAT_TARGET_CROWD_RADIUS)
    end
    return {
        staminaRatio = staminaRatio,
        retreating = runtime.retreatMode == true,
        surroundedCount = Perception and Perception.CountEnemyZombies and Perception.CountEnemyZombies(record, Const.COMBAT_SURROUND_RADIUS) or 0,
        pressureCount = Perception and Perception.CountEnemyZombies and Perception.CountEnemyZombies(record, Const.COMBAT_PRESSURE_RADIUS) or 0,
        hordeCount = Perception and Perception.CountEnemyZombies and Perception.CountEnemyZombies(record, Const.COMBAT_HORDE_RADIUS) or 0,
        targetCrowdCount = targetCrowdCount,
    }
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
    clearActiveRetreat(record, ensureRetreatState(record))
end

function Tactics.ShouldPressureShove(record)
    local surroundedCount
    if not record then
        return false
    end
    surroundedCount = Perception and Perception.CountEnemyZombies and Perception.CountEnemyZombies(record, Const.COMBAT_SURROUND_RADIUS) or 0
    return surroundedCount >= Const.COMBAT_SURROUND_COUNT
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
    state.damagePressureUntil = now + Const.COMBAT_KITE_DAMAGE_PRESSURE_MS
end

function Tactics.GetRetreatState(record)
    return ensureRetreatState(record)
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
    return shouldApproach, Const.MELEE_RANGE, preferredMode
end

local function continueLockedRetreat(record, zombie, target, state, now)
    if not state or now >= (tonumber(state.lockUntil) or 0) then
        return false, nil
    end
    if state.goalX == nil or state.goalY == nil then
        return false, nil
    end
    setRetreatState(record, true, "retreat")
    requestMove(
        record,
        zombie,
        state.goalX,
        state.goalY,
        state.goalZ or record.z,
        state.goalMode or "walk",
        state.goalStopDistance or 0.8,
        state.reason or "combat_retreat"
    )
    return true, state.reason or "combat_retreat"
end

local function startRetreat(record, zombie, target, distance, mode, stopDistance, lockMs, reason, recoveryMode, sourceX, sourceY, sourceZ)
    local state = ensureRetreatState(record)
    local retreat
    local now = Core.Now()
    if not state then
        return false, nil
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
    setRetreatState(record, true, recoveryMode)
    requestMove(record, zombie, retreat.x, retreat.y, retreat.z, mode, stopDistance, reason)
    return true, reason
end

function Tactics.TryReposition(record, zombie, target, effectiveMode, reason, equipmentInfo)
    local nearbyCount
    local aiming
    local meleeSkill
    local dist
    local report
    local keepRetreating
    local now
    local state
    local forcedDamageRetreat

    if not record or not zombie or not target or not PathService or not PathService.MoveToward then
        return false, nil
    end

    now = Core.Now()
    state = ensureRetreatState(record)
    dist = math.sqrt(tonumber(target.distSq or 0) or 0)
    report = assessThreat(record, target)
    nearbyCount = Perception and Perception.CountEnemyZombies and Perception.CountEnemyZombies(record, 2.6) or 0

    if continueLockedRetreat(record, zombie, target, state, now) then
        return true, state.reason or "combat_retreat"
    end

    keepRetreating = report.retreating and report.staminaRatio < Const.COMBAT_REENGAGE_STAMINA_RATIO
    forcedDamageRetreat = target.kind == "zombie"
        and report.pressureCount >= 2
        and dist <= (Const.MELEE_RANGE + 0.35)
        and state
        and now <= (tonumber(state.damagePressureUntil) or 0)
    if forcedDamageRetreat then
        return startRetreat(
            record,
            zombie,
            target,
            Const.COMBAT_KITE_DAMAGE_DISTANCE,
            report.surroundedCount >= 2 and "run" or "walk",
            0.7,
            Const.COMBAT_KITE_DAMAGE_LOCK_MS,
            "damage_pressure_retreat",
            "retreat",
            state.lastZombieDamageX,
            state.lastZombieDamageY,
            state.lastZombieDamageZ
        )
    end

    if report.staminaRatio <= Const.COMBAT_RETREAT_STAMINA_RATIO or keepRetreating then
        return startRetreat(
            record,
            zombie,
            target,
            3.8 + math.min(report.pressureCount, 4) * 0.35,
            report.surroundedCount >= 2 and "run" or "walk",
            0.8,
            Const.COMBAT_KITE_RETREAT_LOCK_MS,
            "recovering_stamina",
            "retreat"
        )
    end

    if target.kind == "zombie" and (report.hordeCount >= Const.COMBAT_HORDE_COUNT or report.targetCrowdCount >= Const.COMBAT_TARGET_CROWD_COUNT) then
        return startRetreat(
            record,
            zombie,
            target,
            2.8 + math.min(report.targetCrowdCount, 4) * 0.45,
            report.surroundedCount >= 2 and "run" or "walk",
            0.8,
            Const.COMBAT_KITE_RETREAT_LOCK_MS,
            "avoiding_horde",
            report.staminaRatio <= 0.35 and "retreat" or "avoid_horde"
        )
    end

    clearActiveRetreat(record, state)

    if effectiveMode == "ranged" or effectiveMode == "mixed" then
        aiming = Skills and Skills.GetLevel and Skills.GetLevel(record, "Aiming") or 0
        if target.kind == "zombie" and (dist < 4.2 or (reason == "cooldown_active" and nearbyCount >= 1)) then
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

    meleeSkill = Skills and Skills.GetLevel and Skills.GetLevel(record, equipmentInfo and equipmentInfo.primaryType == "barehand" and "Strength"
        or (Skills.ResolveWeaponSkill and Skills.ResolveWeaponSkill(record, record.equipment and record.equipment.primaryFullType, "melee") or "Strength")) or 0
    if target.kind == "zombie" and (reason == "cooldown_active" or reason == "stamina_exhausted") and nearbyCount >= 2 then
        return startRetreat(
            record,
            zombie,
            target,
            0.75 + math.min(meleeSkill, 6) * 0.08,
            report.surroundedCount >= 2 and "run" or "walk",
            0.2,
            Const.COMBAT_KITE_RETREAT_LOCK_MS,
            "melee_kiting",
            nil
        )
    end

    return false, nil
end
