-- Movement requests and bounded retreat lifecycle management.

PNC = PNC or {}
PNC.CombatTactics = PNC.CombatTactics or {}

local Tactics = PNC.CombatTactics
Tactics.Internal = Tactics.Internal or {}

local Internal = Tactics.Internal
local Core = PNC.Core
local Const = PNC.Const
local PathService = PNC.PathService
local TraversalQuery = PNC.TraversalQuery
local COMBAT_NAVIGATION = {
    navigationPolicy = "combat",
    navigationProvider = "engine_path",
}

function Internal.RequestMove(record, zombie, x, y, z, mode, stopDistance, reason)
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

function Internal.RequestHold(record, zombie, reason)
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

function Internal.BuildRetreatFromSource(record, target, distance, sourceX, sourceY, sourceZ, state)
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
            Internal.ClearActiveRetreat(record, state)
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
    -- Keep one fixed destination for this leg. Rebuilding it from the NPC's
    -- current position moved the finish line every tick.
    Internal.SetRetreatState(record, true, state.recoveryMode)
    if not Internal.RequestMove(
        record,
        zombie,
        state.goalX,
        state.goalY,
        state.goalZ or record.z,
        state.goalMode or "walk",
        state.goalStopDistance or 0.8,
        state.reason or "combat_retreat"
    ) then
        Internal.ClearActiveRetreat(record, state)
        state.retryAt = now + retryMs
        return false, "retreat_rejected"
    end
    return true, state.reason or "combat_retreat"
end

function Internal.StartRetreat(record, zombie, target, distance, mode, stopDistance, lockMs, reason, recoveryMode, sourceX, sourceY, sourceZ, safetyRadius)
    local state = Internal.EnsureRetreatState(record)
    local retreat
    local now = Core.Now()
    if not state then
        return false, nil
    end
    if now < (tonumber(state.retryAt) or 0) then
        return false, "retreat_stalled"
    end
    retreat = Internal.BuildRetreatFromSource(
        record,
        target,
        distance,
        sourceX,
        sourceY,
        sourceZ,
        state
    )
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
    Internal.SetRetreatState(record, true, recoveryMode)
    if not Internal.RequestMove(
        record,
        zombie,
        retreat.x,
        retreat.y,
        retreat.z,
        mode,
        stopDistance,
        reason
    ) then
        Internal.ClearActiveRetreat(record, state)
        state.retryAt = now
            + (tonumber(Const.COMBAT_RETREAT_RETRY_MS) or 800)
        return false, "retreat_rejected"
    end
    return true, reason
end

function Internal.TryNearMissRetreat(record, zombie, target, state, now, report)
    if not state
        or not target
        or target.kind ~= "zombie"
        or now > (tonumber(state.nearMissUntil) or 0)
    then
        return false, nil
    end
    if report
        and report.pressureCount
            < (tonumber(Const.COMBAT_TACTICAL_RETREAT_MIN_PRESSURE) or 2)
    then
        state.nearMissUntil = 0
        return false, "lone_threat_counter"
    end
    state.nearMissUntil = 0
    if record.runtime and record.runtime.combatTactical then
        record.runtime.combatTactical.decision = "near_miss_kite"
    end
    return Internal.StartRetreat(
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

return Tactics
