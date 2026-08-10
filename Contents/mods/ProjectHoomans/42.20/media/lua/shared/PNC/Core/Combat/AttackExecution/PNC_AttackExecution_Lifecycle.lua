-- Attack creation, cancellation, completion, and active-state queries.

local Combat = PNC.Combat
local Internal = Combat.Internal
local AttackExecution = Internal.AttackExecution
local Core = PNC.Core

function Internal.clearAttackAction(record)
    if record and record.runtime then
        record.runtime.attackAction = nil
    end
end

function Internal.finishAttackAction(record, zombie)
    -- Clearing the authoritative action publishes an inactive snapshot. The
    -- rendering client owns FinishBump so SP and MP follow the same path.
    Internal.clearAttackAction(record)
    if record and record.runtime
        and record.runtime.forceSyncEvent == nil
    then
        record.runtime.forceSyncEvent = "attack_finish"
    end
end

function Internal.buildAttackAction(record, target, attackKind, attackType, anim, damage, skillID, extra)
    local now = Core.Now()
    local timings = Internal.ATTACK_TIMINGS[attackKind] or Internal.ATTACK_TIMINGS.melee
    local hitDelay = type(extra) == "table" and tonumber(extra.hitDelayMs) or nil
    local duration = type(extra) == "table" and tonumber(extra.durationMs) or nil
    local action = {
        attackKind = attackKind,
        attackType = attackType,
        anim = anim,
        damage = damage,
        skillID = skillID,
        startedAt = now,
        hitAt = now + (hitDelay or timings.hitDelay),
        finishAt = now + (duration or timings.duration),
        hitDone = false,
        animationRetries = 0,
        animationTriggerMode = "client_snapshot",
        animationStateEntered = false,
        animationActionState = nil,
        target = AttackExecution.captureTargetRef(target),
    }
    local key
    if type(extra) == "table" then
        for key, value in pairs(extra) do
            action[key] = value
        end
    end
    record.runtime.attackAction = action
    -- Server.OnTick consumes this after movement pumping and sends exactly one
    -- transition snapshot, avoiding both a delayed attack start and a duplicate
    -- periodic snapshot in the same tick.
    if isServer and isServer() then
        record.runtime.forceSyncEvent = action.syncEvent or "attack_start"
    end
    return action
end

function Combat.HasActiveAttack(record, now)
    local action = record and record.runtime and record.runtime.attackAction or nil
    now = tonumber(now) or Core.Now()
    return action ~= nil and now < (tonumber(action.finishAt) or 0)
end

function Combat.CancelAttackAction(record, zombie, expectedType, reason)
    local action = record and record.runtime and record.runtime.attackAction or nil
    if not action then return false, "no_attack" end
    if expectedType ~= nil
        and tostring(action.attackType or "") ~= tostring(expectedType)
    then
        return false, "attack_type_mismatch"
    end
    Internal.finishAttackAction(record, zombie)
    if record and record.runtime then
        record.runtime.lastAttackCancellation = {
            attackType = action.attackType,
            reason = tostring(reason or "cancelled"),
            at = Core.Now(),
        }
    end
    return true, reason or "attack_cancelled"
end
