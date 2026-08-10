-- Shared retreat state and public combat-pressure markers.

PNC = PNC or {}
PNC.CombatTactics = PNC.CombatTactics or {}

local Tactics = PNC.CombatTactics
Tactics.Internal = Tactics.Internal or {}

local Internal = Tactics.Internal
local Core = PNC.Core
local Const = PNC.Const

function Internal.EnsureRetreatState(record)
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

function Internal.ClearActiveRetreat(record, state)
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

function Internal.SetRetreatState(record, enabled, recoveryMode)
    if not record then
        return
    end
    record.runtime = record.runtime or {}
    record.runtime.retreatMode = enabled == true
    record.runtime.staminaRecoveryMode = enabled == true and recoveryMode or nil
    record.runtime.tacticalState = enabled == true and (recoveryMode or "retreat") or nil
end

function Internal.StaminaCurrent(record)
    if record and record.stamina then
        return tonumber(record.stamina.current) or math.huge
    end
    return math.huge
end

function Tactics.ClearRetreatState(record)
    local state = Internal.EnsureRetreatState(record)
    Internal.ClearActiveRetreat(record, state)
    if state then
        state.retryAt = 0
        state.lowStaminaPhase = nil
        state.lowStaminaAttackUntil = 0
    end
end

function Tactics.MarkZombieDamage(record, sourceX, sourceY, sourceZ, now)
    local state = Internal.EnsureRetreatState(record)
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

function Tactics.MarkZombieNearMiss(record, sourceX, sourceY, sourceZ, now)
    local state = Internal.EnsureRetreatState(record)
    now = tonumber(now) or Core.Now()
    if not state then return end
    state.lastNearMissAt = now
    state.lastNearMissX = sourceX ~= nil and tonumber(sourceX) or nil
    state.lastNearMissY = sourceY ~= nil and tonumber(sourceY) or nil
    state.lastNearMissZ = sourceZ ~= nil and tonumber(sourceZ) or nil
    state.nearMissUntil = now
        + (tonumber(Const.COMBAT_KITE_NEAR_MISS_WINDOW_MS) or 1400)
end

function Tactics.NeedsRecoveryRetreat(record)
    return Internal.StaminaCurrent(record)
        < (tonumber(Const.COMBAT_RETREAT_STAMINA_CURRENT) or 20)
end

return Tactics
