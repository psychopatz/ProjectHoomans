-- Bounded retreat progression, recovery transitions, and near-miss kiting.

PNC = PNC or {}
PNC.CombatTactics = PNC.CombatTactics or {}

local Tactics = PNC.CombatTactics
Tactics.Internal = Tactics.Internal or {}

local Internal = Tactics.Internal
local Core = PNC.Core
local Const = PNC.Const

local function isAuthority()
    local ok
    local result
    if Core and type(Core.IsAuthority) == "function" then
        ok, result = pcall(Core.IsAuthority)
        return ok and result == true
    end
    return type(isServer) == "function" and isServer() == true
end

local function hordeEscapeDistance(distance)
    local minimumDistance = (tonumber(Const.COMBAT_HORDE_RADIUS) or 5.5)
        + (tonumber(Const.COMBAT_RETREAT_SAFETY_BUFFER) or 0.25)
    return math.max(tonumber(distance) or minimumDistance, minimumDistance)
end

local function clearHordeSurvivalPending(state)
    if not state then return end
    state.hordeSurvivalPending = false
    state.hordeSurvivalOriginX = nil
    state.hordeSurvivalOriginY = nil
    state.hordeSurvivalMinDistance = nil
end

local function recordHordeSurvival(record, state, currentX, currentY)
    local memoryEvents
    local entityRef
    local selfKey
    local ok
    local recorded
    local originX
    local originY
    local minimumDistance
    if not state or state.hordeSurvivalPending ~= true then
        return false
    end
    if not isAuthority() then return false end
    originX = tonumber(state.hordeSurvivalOriginX)
    originY = tonumber(state.hordeSurvivalOriginY)
    minimumDistance = tonumber(state.hordeSurvivalMinDistance)
        or hordeEscapeDistance(0)
    if not record or record.alive == false
        or originX == nil or originY == nil
        or currentX == nil or currentY == nil
        or Core.DistanceSq(originX, originY, currentX, currentY)
            < minimumDistance * minimumDistance
    then
        clearHordeSurvivalPending(state)
        return false
    end
    clearHordeSurvivalPending(state)
    memoryEvents = PNC.Conversation
        and PNC.Conversation.Memory
        and PNC.Conversation.Memory.Events or nil
    entityRef = PNC.EntityRef
    selfKey = entityRef and type(entityRef.ForNPC) == "function"
        and entityRef.ForNPC(record.id) or nil
    if not memoryEvents
        or type(memoryEvents.RecordRelationshipMemory) ~= "function"
        or not selfKey
    then
        return false
    end
    ok, recorded = pcall(
        memoryEvents.RecordRelationshipMemory,
        record,
        {
            type = "survived_horde_attack",
            aboutKey = selfKey,
            shareable = true,
        },
        selfKey
    )
    return ok and recorded == true
end

function Internal.MarkHordeSurvivalPending(record, state)
    local tracker
    if not state then return false end
    state.hordeSurvivalPending = true
    state.hordeSurvivalOriginX = tonumber(state.lastX)
        or tonumber(record and record.x)
    state.hordeSurvivalOriginY = tonumber(state.lastY)
        or tonumber(record and record.y)
    state.hordeSurvivalMinDistance = hordeEscapeDistance(0)
    if isAuthority() then
        tracker = PNC.SocialEncounterTracker
        if tracker and type(tracker.MarkHordeAttack) == "function" then
            pcall(tracker.MarkHordeAttack, record and record.id)
        end
    end
    return true
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
            recordHordeSurvival(record, state, currentX, currentY)
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
        recordHordeSurvival(record, state, currentX, currentY)
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
        clearHordeSurvivalPending(state)
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
        clearHordeSurvivalPending(state)
        state.retryAt = now + retryMs
        return false, "retreat_rejected"
    end
    return true, state.reason or "combat_retreat"
end

function Internal.StartRetreat(record, zombie, target, distance, mode, stopDistance, lockMs, reason, recoveryMode, sourceX, sourceY, sourceZ, safetyRadius, reengagePending)
    local state = Internal.EnsureRetreatState(record)
    local retreat
    local now = Core.Now()
    local wasStaminaRetreat
    local socialHooks
    if not state then return false, nil end
    if now < (tonumber(state.retryAt) or 0) then
        return false, "retreat_stalled"
    end
    wasStaminaRetreat = state.phase == "retreat"
        and state.recoveryMode == "retreat"
        and Tactics.IsStaminaRecoveryReason
        and Tactics.IsStaminaRecoveryReason(state.reason)
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
    if recoveryMode == "retreat"
        and Tactics.IsStaminaRecoveryReason
        and Tactics.IsStaminaRecoveryReason(reason)
        and Tactics.BeginStaminaRecovery
    then
        Tactics.BeginStaminaRecovery(record, reason)
        if not wasStaminaRetreat then
            socialHooks = PNC and PNC.SocialEventHooks
            if socialHooks
                and type(socialHooks.RecordZombieStaminaRetreat) == "function"
            then
                pcall(
                    socialHooks.RecordZombieStaminaRetreat,
                    record,
                    reason,
                    now
                )
            end
        end
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
        hordeEscapeDistance(
            tonumber(Const.COMBAT_KITE_DAMAGE_DISTANCE) or 2.4
        ),
        report and math.max(
            tonumber(report.worldSurroundedCount) or 0,
            tonumber(report.surroundedCount) or 0
        ) >= 2 and "run" or "walk",
        0.7,
        tonumber(Const.COMBAT_KITE_DAMAGE_LOCK_MS) or 700,
        reason, nil, sourceX, sourceY, sourceZ,
        nil, true
    )
    if started then
        state.attackPressureUntil = 0
        state.damagePressureUntil = 0
        Internal.MarkHordeSurvivalPending(record, state)
    end
    return started, startReason or reason
end

return Tactics
