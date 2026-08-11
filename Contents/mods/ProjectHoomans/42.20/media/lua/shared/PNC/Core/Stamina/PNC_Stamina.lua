PNC = PNC or {}
PNC.Stamina = PNC.Stamina or {}

local Stamina = PNC.Stamina
local Core = PNC.Core
local Const = PNC.Const
local Skills = PNC.Skills

local function clamp(value, minValue, maxValue)
    local numeric = tonumber(value) or minValue
    if numeric < minValue then
        return minValue
    end
    if numeric > maxValue then
        return maxValue
    end
    return numeric
end

local function ensureState(record)
    local averageCombat
    local endurance
    local strength
    local resolvedMax
    local effectiveMax
    local encumbrance
    local previousBaseMax
    local current
    if type(record) ~= "table" then
        return nil
    end
    averageCombat = Skills.GetAverage(record, { "Axe", "LongBlade", "LongBlunt", "ShortBlade", "ShortBlunt", "Spear", "Aiming" })
    endurance = Skills.GetLevel(record, "Fitness")
    strength = Skills.GetLevel(record, "Strength")
    resolvedMax = math.floor(100 + ((averageCombat + endurance + strength) * 2.5))
    encumbrance = PNC.Inventory
        and PNC.Inventory.GetEncumbranceState
        and PNC.Inventory.GetEncumbranceState(record)
        or nil
    effectiveMax = math.max(1, math.floor(resolvedMax
        * (tonumber(encumbrance and encumbrance.staminaMultiplier) or 1)))
    if type(record.stamina) ~= "table" then
        record.stamina = {}
    end
    previousBaseMax = tonumber(record.stamina.baseMax)
    current = tonumber(record.stamina.current)
    if current == nil then
        current = effectiveMax
    elseif previousBaseMax and previousBaseMax > 0 and previousBaseMax ~= resolvedMax then
        current = current * (resolvedMax / previousBaseMax)
    end
    record.stamina.baseMax = resolvedMax
    record.stamina.max = effectiveMax
    record.stamina.current = clamp(current, 0, effectiveMax)
    record.stamina.encumbranceLevel = encumbrance and encumbrance.level or "normal"
    record.stamina.encumbranceRatio = encumbrance and encumbrance.ratio or 0
    record.stamina.encumbranceDrainMultiplier =
        encumbrance and encumbrance.drainMultiplier or 1
    record.stamina.encumbranceRecoveryMultiplier =
        encumbrance and encumbrance.recoveryMultiplier or 1
    record.stamina.state = record.stamina.state or "fresh"
    record.stamina.visibleUntil = tonumber(record.stamina.visibleUntil) or 0
    record.stamina.lastUpdatedAt = tonumber(record.stamina.lastUpdatedAt) or Core.Now()
    return record.stamina
end

local function applySevereEncumbranceDamage(record, zombie, now)
    local stamina = record and record.stamina or nil
    local runtime
    local lastDamageAt
    local interval
    if not stamina
        or (tonumber(stamina.encumbranceRatio) or 0)
            < (tonumber(Const.ENCUMBRANCE_SEVERE_RATIO) or 1.75)
    then
        if record and record.runtime then
            record.runtime.lastEncumbranceDamageAt = nil
        end
        return false
    end
    record.runtime = record.runtime or {}
    runtime = record.runtime
    lastDamageAt = tonumber(runtime.lastEncumbranceDamageAt)
    interval = tonumber(Const.ENCUMBRANCE_DAMAGE_INTERVAL_MS) or 5000
    if not lastDamageAt then
        runtime.lastEncumbranceDamageAt = now
        return false
    end
    if now - lastDamageAt < interval then return false end
    runtime.lastEncumbranceDamageAt = now
    if PNC.Health and PNC.Health.ApplyStrainDamage then
        return PNC.Health.ApplyStrainDamage(
            record,
            zombie,
            tonumber(Const.ENCUMBRANCE_DAMAGE_AMOUNT) or 1,
            tonumber(Const.ENCUMBRANCE_DAMAGE_FLOOR_RATIO) or 0.75,
            "severe_encumbrance"
        )
    end
    return false
end

local function ratioFor(stamina)
    if not stamina then
        return 1
    end
    return clamp(
        (tonumber(stamina.current) or tonumber(stamina.max) or 1)
            / math.max(1, tonumber(stamina.max) or 1),
        0,
        1
    )
end

local function updateState(record, stamina)
    local ratio
    stamina = stamina or ensureState(record)
    if not stamina then
        return nil
    end
    ratio = ratioFor(stamina)
    if ratio <= 0.15 then
        stamina.state = "exhausted"
    elseif ratio <= 0.4 then
        stamina.state = "winded"
    elseif ratio <= 0.7 then
        stamina.state = "working"
    else
        stamina.state = "fresh"
    end
    return stamina
end

function Stamina.GetRatio(record)
    local stamina = ensureState(record)
    return ratioFor(stamina)
end

function Stamina.GetAttackDrain(record, attackType, skillID)
    local baseCost
    local skillLevel
    local normalized
    if tostring(attackType or "") == "ranged" then
        baseCost = Const.STAMINA_RANGED_COST
    elseif tostring(attackType or "") == "downed_shove" then
        baseCost = Const.STAMINA_DOWNED_SHOVE_COST
    else
        baseCost = Const.STAMINA_MELEE_COST
    end
    skillLevel = Skills.GetLevel(record, skillID or "Strength")
    normalized = clamp(skillLevel / 10, 0, 1)
    return math.max(1, baseCost * (1 - (normalized * 0.65)))
end

function Stamina.CanSpendAttack(record, attackType, skillID)
    local stamina = ensureState(record)
    local drain
    if not stamina then
        return false
    end
    drain = Stamina.GetAttackDrain(record, attackType, skillID)
    return (tonumber(stamina.current) or 0) >= math.min(drain, Const.STAMINA_ATTACK_MIN_RESERVE)
end

function Stamina.SpendAttack(record, attackType, skillID)
    local stamina = ensureState(record)
    local drain
    if not stamina then
        return false
    end
    drain = Stamina.GetAttackDrain(record, attackType, skillID)
    stamina.current = clamp((tonumber(stamina.current) or 0) - drain, 0, tonumber(stamina.max) or 100)
    stamina.visibleUntil = Core.Now() + Const.STAMINA_VISIBLE_MS
    updateState(record, stamina)
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "stamina")
    end
    return true
end

function Stamina.Update(record, zombie, now)
    local stamina = ensureState(record)
    local lastUpdatedAt
    local elapsed
    local recoverRate
    local runtime
    local moveDrain
    if not stamina then
        return
    end
    now = tonumber(now) or Core.Now()
    runtime = record and record.runtime or nil
    lastUpdatedAt = tonumber(stamina.lastUpdatedAt) or now
    elapsed = math.max(0, now - lastUpdatedAt) / 1000
    stamina.lastUpdatedAt = now
    if elapsed <= 0 then
        return
    end

    applySevereEncumbranceDamage(record, zombie, now)

    if Stamina.ApplyMovementDrain then
        moveDrain = Stamina.ApplyMovementDrain(record, elapsed)
    else
        moveDrain = 0
    end

    recoverRate = Const.STAMINA_RECOVERY_IDLE
    if record.runtime and record.runtime.target then
        recoverRate = Const.STAMINA_RECOVERY_COMBAT
    end
    if record.health and record.health.state == "incapacitated" then
        recoverRate = Const.STAMINA_RECOVERY_DOWNED
    end
    if record.runtime and record.runtime.pathing and (record.runtime.pathing.phase == "requested" or record.runtime.pathing.phase == "active") then
        recoverRate = math.min(recoverRate, Const.STAMINA_RECOVERY_MOVING)
    end
    if zombie and zombie.isRunning and zombie:isRunning() then
        recoverRate = Const.STAMINA_RECOVERY_MOVING
    end
    if runtime and runtime.staminaRecoveryMode == "retreat" then
        recoverRate = math.max(recoverRate, Const.STAMINA_RECOVERY_IDLE)
    elseif runtime and runtime.staminaRecoveryMode == "move_recovery" then
        recoverRate = math.max(recoverRate, Const.STAMINA_RECOVERY_IDLE)
    end
    recoverRate = recoverRate
        * (tonumber(stamina.encumbranceRecoveryMultiplier) or 1)

    local previous = tonumber(stamina.current) or 0
    stamina.current = clamp(previous + (recoverRate * elapsed), 0, tonumber(stamina.max) or 100)
    updateState(record, stamina)
end

function Stamina.BuildSnapshot(record)
    -- Vitals updates own derived stamina/encumbrance refreshes. Replication is
    -- much more frequent and must not redo skill and inventory resolution for
    -- every recipient payload. Newly created records still initialize here.
    local stamina = record and record.stamina or nil
    if type(stamina) ~= "table" then
        stamina = ensureState(record)
    end
    return {
        current = stamina and stamina.current or 0,
        max = stamina and stamina.max or 100,
        baseMax = stamina and stamina.baseMax or 100,
        state = stamina and stamina.state or "fresh",
        encumbranceLevel = stamina and stamina.encumbranceLevel or "normal",
        encumbranceRatio = stamina and stamina.encumbranceRatio or 0,
        visibleUntil = stamina and stamina.visibleUntil or 0,
    }
end

require "PNC/Core/Stamina/PNC_Stamina_Movement"
