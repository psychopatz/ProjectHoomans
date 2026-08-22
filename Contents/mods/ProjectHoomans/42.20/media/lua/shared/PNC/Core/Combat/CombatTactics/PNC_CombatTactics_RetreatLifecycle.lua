-- Bounded retreat progression, recovery transitions, and near-miss kiting.

PNC = PNC or {}
PNC.CombatTactics = PNC.CombatTactics or {}

local Tactics = PNC.CombatTactics
Tactics.Internal = Tactics.Internal or {}

local Internal = Tactics.Internal
local Core = PNC.Core
local Const = PNC.Const

function Internal.ContinueLockedRetreat(record, zombie, target, state, now)
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
    local reengagePending
    local targetDistance
    if not state or state.phase ~= "retreat" then return false, nil end
    if state.goalX == nil or state.goalY == nil then return false, nil end
    currentX = zombie and zombie.getX and zombie:getX()
        or tonumber(record and record.x) or 0
    currentY = zombie and zombie.getY and zombie:getY()
        or tonumber(record and record.y) or 0
    goalX = tonumber(state.goalX) or currentX
    goalY = tonumber(state.goalY) or currentY
    stopDistance = tonumber(state.goalStopDistance) or 0.8
    safetyRadius = tonumber(state.safetyRadius)
    recoveryRetreat = state.lowStaminaPhase == "retreat"
    reengagePending = state.reengagePending == true
    if safetyRadius and target and target.x ~= nil and target.y ~= nil then
        targetDistance = math.sqrt(Core.DistanceSq(
            currentX, currentY, target.x, target.y
        ))
        if targetDistance >= safetyRadius then
            Internal.ClearActiveRetreat(record, state)
            if reengagePending and not Tactics.CanReengage(record) then
                state.lowStaminaPhase = "recover"
                Internal.RequestHold(record, zombie, "recovering_stamina_safe")
                return true, "recovering_stamina_safe"
            end
            Internal.RequestHold(record, zombie, "recovering_stamina_safe")
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
        Internal.ClearActiveRetreat(record, state)
        state.retryAt = 0
        if reengagePending and not Tactics.CanReengage(record) then
            state.lowStaminaPhase = "recover"
            Internal.RequestHold(record, zombie, "recovering_stamina_safe")
            return true, "recovering_stamina_safe"
        end
        if recoveryRetreat then
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
        Internal.ClearActiveRetreat(record, state)
        state.retryAt = now + retryMs
        return false, "retreat_stalled"
    end
    Internal.SetRetreatState(record, true, state.recoveryMode)
    if not Internal.RequestMove(
        record, zombie, state.goalX, state.goalY, state.goalZ or record.z,
        state.goalMode or "walk", state.goalStopDistance or 0.8,
        state.reason or "combat_retreat"
    ) then
        Internal.ClearActiveRetreat(record, state)
        state.retryAt = now + retryMs
        return false, "retreat_rejected"
    end
    return true, state.reason or "combat_retreat"
end

function Internal.StartRetreat(record, zombie, target, distance, mode, stopDistance, lockMs, reason, recoveryMode, sourceX, sourceY, sourceZ, safetyRadius, reengagePending)
    local state = Internal.EnsureRetreatState(record)
    local retreat
    local now = Core.Now()
    if not state then return false, nil end
    if now < (tonumber(state.retryAt) or 0) then
        return false, "retreat_stalled"
    end
    retreat = Internal.BuildRetreatFromSource(
        record, target, distance, sourceX, sourceY, sourceZ, state
    )
    if not retreat then return false, nil end
    state.phase = "retreat"
    state.reason = reason
    state.lockUntil = now
        + math.max(120, tonumber(lockMs) or Const.COMBAT_KITE_RETREAT_LOCK_MS)
    state.goalX = retreat.x
    state.goalY = retreat.y
    state.goalZ = retreat.z
    state.goalMode = mode
    state.goalStopDistance = tonumber(stopDistance) or 0.8
    state.recoveryMode = recoveryMode
    state.retreatDistance = distance
    state.safetyRadius = tonumber(safetyRadius)
    state.reengagePending = reengagePending == true
    state.refreshAt = now + 220
    state.startedAt = now
    state.lastProgressAt = now
    state.lastX = zombie and zombie.getX and zombie:getX()
        or tonumber(record.x) or 0
    state.lastY = zombie and zombie.getY and zombie:getY()
        or tonumber(record.y) or 0
    Internal.SetRetreatState(record, true, recoveryMode)
    if not Internal.RequestMove(
        record, zombie, retreat.x, retreat.y, retreat.z, mode,
        stopDistance, reason
    ) then
        Internal.ClearActiveRetreat(record, state)
        state.retryAt = now
            + (tonumber(Const.COMBAT_RETREAT_RETRY_MS) or 800)
        return false, "retreat_rejected"
    end
    return true, reason
end

function Internal.TryNearMissRetreat(record, zombie, target, state, now, report)
    local reason
    local sourceX
    local sourceY
    local sourceZ
    local started
    local startReason
    if not state
        or not target
        or target.kind ~= "zombie"
    then
        return false, nil
    end
    if not Tactics.IsHordeAttackRetreatTriggered(state, report, now) then
        if now <= (tonumber(state.nearMissUntil) or 0)
            and report and report.pressureCount
                < (tonumber(Const.COMBAT_TACTICAL_RETREAT_MIN_PRESSURE) or 2)
        then
            state.nearMissUntil = 0
            return false, "lone_threat_counter"
        end
        return false, nil
    end
    state.nearMissUntil = 0
    reason = state.lastZombieAttackOutcome == "damaged"
        and "zombie_damage_retreat" or "near_miss_kite"
    sourceX = state.lastZombieAttackX or state.lastNearMissX
    sourceY = state.lastZombieAttackY or state.lastNearMissY
    sourceZ = state.lastZombieAttackZ or state.lastNearMissZ
    if record.runtime and record.runtime.combatTactical then
        record.runtime.combatTactical.decision = reason
    end
    started, startReason = Internal.StartRetreat(
        record, zombie, target,
        tonumber(Const.COMBAT_KITE_DAMAGE_DISTANCE) or 2.4,
        report and report.surroundedCount >= 2 and "run" or "walk",
        0.7,
        tonumber(Const.COMBAT_KITE_DAMAGE_LOCK_MS) or 700,
        reason, nil, sourceX, sourceY, sourceZ,
        tonumber(Const.NPC_ZOMBIE_DEFENSE_RADIUS) or 2.2, true
    )
    if started then
        state.attackPressureUntil = 0
        state.damagePressureUntil = 0
    end
    return started, startReason or reason
end

return Tactics
