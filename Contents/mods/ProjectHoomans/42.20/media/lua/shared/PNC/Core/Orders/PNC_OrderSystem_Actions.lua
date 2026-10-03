local OrderSystem = require "PNC/Core/Orders/PNC_OrderSystem_Base"
require "PNC/Core/Orders/PNC_OrderSystem_Recovery"

local Internal = OrderSystem.Internal or {}
local Core = Internal.Core
local Const = Internal.Const
local recoveryState = Internal.recoveryState
local wakeRecord = Internal.wakeRecord

local function safeFallbackOrder(record, kind)
    local hostile = record and record.tacticalClass == "hostile"
        or kind == "hostile_roam" or kind == "hostile_hunt"
    local x = tonumber(record and record.x) or tonumber(record and record.anchorX)
    local y = tonumber(record and record.y) or tonumber(record and record.anchorY)
    local z = tonumber(record and record.z) or tonumber(record and record.anchorZ) or 0
    if hostile then
        return {
            kind = Const.ORDER_HOSTILE_HUNT or "hostile_hunt",
            x = x, y = y, z = z,
        }
    end
    return { kind = Const.ORDER_GUARD or "guard", x = x, y = y, z = z }
end

local function recoverDirectOrder(record, zombie, now, snapshot)
    local state = recoveryState(record,
        record.orderSpec and record.orderSpec.kind or "")
    local attempts = (tonumber(state.attempts) or 0) + 1
    local kind = tostring(record.orderSpec and record.orderSpec.kind or "")
    local reason = tostring(snapshot and snapshot.recoveryReason
        or "order_progress_timeout")
    local currentOrder = Core.DeepCopy(record.orderSpec)
    state.attempts = attempts
    state.lastRecoveryAt = now
    state.lastReason = reason
    if attempts >= OrderSystem.MAX_RECOVERY_ATTEMPTS then
        if kind == tostring(Const.ORDER_FOLLOW or "follow") then
            -- Follow is an explicit player command. A native path stall must
            -- not silently turn it into a local guard order; clear the stale
            -- movement lane and keep retrying the player's durable order.
            OrderSystem.SetOrder(record, currentOrder)
            record.runtime = record.runtime or {}
            record.runtime.orderRecovery = {
                kind = kind,
                attempts = 0,
                nextAttemptAt = now
                    + OrderSystem.RECOVERY_RETRY_INTERVAL_MS,
                missingSince = now,
                lastRecoveryAt = now,
                lastReason = reason,
                preservedOrder = true,
            }
            return true
        end
        OrderSystem.SetOrder(record, safeFallbackOrder(record, kind))
        record.runtime = record.runtime or {}
        record.runtime.orderRecovery = {
            kind = tostring(record.orderSpec and record.orderSpec.kind or ""),
            attempts = 0,
            fallbackFrom = kind,
            lastReason = reason,
        }
        return true
    end
    OrderSystem.SetOrder(record, currentOrder)
    record.runtime = record.runtime or {}
    record.runtime.orderRecovery = {
        kind = kind,
        attempts = attempts,
        observedProgressAt = state.observedProgressAt,
        nextAttemptAt = now + OrderSystem.RECOVERY_RETRY_INTERVAL_MS,
        missingSince = now,
        lastRecoveryAt = now,
        lastReason = reason,
    }
    return true
end

function OrderSystem.RecoverStalled(record, zombie, now)
    now = tonumber(now) or Core.Now()
    local snapshot = OrderSystem.GetRecoveryState(record, zombie, now)
    local progressAt
    local timeoutMs
    if not snapshot or snapshot.watchable ~= true then return false end
    if snapshot.action == true and snapshot.forceRecovery == true then
        if PNC.Combat and PNC.Combat.CancelAttackAction then
            PNC.Combat.CancelAttackAction(record, zombie, nil,
                snapshot.recoveryReason or "combat_action_timeout")
        elseif record.runtime then
            record.runtime.attackAction = nil
        end
        return true
    end
    progressAt = tonumber(snapshot.lastProgressAt) or now
    timeoutMs = tonumber(snapshot.timeoutMs)
        or OrderSystem.RECOVERY_TIMEOUT_MS
    if snapshot.forceRecovery ~= true and now - progressAt < timeoutMs then
        return false
    end
    return recoverDirectOrder(record, zombie, now, snapshot)
end

function OrderSystem.SetHostility(record, modeSpec)
    record.hostility = record.hostility or {}
    if modeSpec and modeSpec.mode ~= nil then
        record.hostility.mode = tostring(modeSpec.mode)
    else
        record.hostility.mode = tostring(record.hostility.mode or "neutral")
    end
    if modeSpec and modeSpec.attackPlayers ~= nil then
        record.hostility.attackPlayers = modeSpec.attackPlayers == true
    else
        record.hostility.attackPlayers = record.hostility.attackPlayers == true
    end
    if modeSpec and modeSpec.attackNPCs ~= nil then
        record.hostility.attackNPCs = modeSpec.attackNPCs == true
    else
        record.hostility.attackNPCs = record.hostility.attackNPCs == true
    end
    if modeSpec and modeSpec.attackZombies ~= nil then
        record.hostility.attackZombies = modeSpec.attackZombies == true
    else
        record.hostility.attackZombies = record.hostility.attackZombies == true
    end
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "hostility")
    end
    wakeRecord(record)
end

return OrderSystem
