local Health = PNC.Health
local Internal = Health.Internal
local Core = PNC.Core
local Const = PNC.Const
local Registry = PNC.Registry
local Settings = PNC.Sandbox

local function canApplyDamage(record, amount, damageEvent, now)
    if Core and Core.IsAuthority and not Core.IsAuthority() then
        return false
    end
    if record.alive == false or amount <= 0 then
        return false
    end
    return not (
        damageEvent
        and damageEvent.attackerKind == "zombie"
        and not Settings.CanZombieTargetRecord(record, now)
    )
end

local function rememberDamageSource(record, damageEvent, now)
    local tactics
    Health.MarkRecentDamage(record, now)
    if PNC.Perception and PNC.Perception.RememberAttacker then
        PNC.Perception.RememberAttacker(record, damageEvent, now)
    end
    if not damageEvent or damageEvent.attackerKind ~= "zombie" then
        return
    end
    record.runtime.targetKind = "zombie"
    record.runtime.combatBlockReason = "taking_zombie_damage"
    tactics = Internal.ResolveCombatTactics()
    if tactics and tactics.MarkZombieDamage then
        tactics.MarkZombieDamage(
            record,
            damageEvent.x,
            damageEvent.y,
            damageEvent.z,
            now
        )
    end
end

local function hasActiveInfection(record)
    return PNC.NPCWounds
        and PNC.NPCWounds.HasActiveInfection
        and PNC.NPCWounds.HasActiveInfection(record)
end

local function finishIncapacitated(
    record,
    zombie,
    health,
    damageEvent,
    now
)
    if hasActiveInfection(record) then
        PNC.NPCWounds.TriggerInfectionDeath(
            record,
            zombie,
            damageEvent and damageEvent.type or "zombie_infection"
        )
        return true
    end
    if now - (tonumber(health.downedAt) or 0)
        < Const.INCAPACITATED_GRACE_MS
    then
        return false
    end
    Health.Kill(
        record,
        zombie,
        damageEvent and damageEvent.type or "incapacitated_finish"
    )
    return true
end

local function applyHealthDamage(record, health, amount, damageEvent)
    if PNC.NPCWounds and PNC.NPCWounds.ApplyBodyDamage then
        PNC.NPCWounds.ApplyBodyDamage(
            record,
            amount,
            damageEvent and damageEvent.partId
        )
    else
        health.current = health.current - amount
    end
    if Registry and Registry.MarkDirty then
        Registry.MarkDirty(record, "health")
    end
end

local function handleDepletedHealth(record, zombie, damageEvent)
    if hasActiveInfection(record) then
        PNC.NPCWounds.TriggerInfectionDeath(
            record,
            zombie,
            "zombie_infection"
        )
        return true
    end
    return Health.EnterIncapacitated(
        record,
        zombie,
        damageEvent and damageEvent.type or "damage"
    )
end

function Health.ApplyDamage(record, zombie, damageEvent)
    local health = Health.Ensure(record)
    local amount =
        tonumber(damageEvent and damageEvent.amount or 0) or 0
    local now = Core.Now()
    if not canApplyDamage(record, amount, damageEvent, now) then
        return false
    end
    rememberDamageSource(record, damageEvent, now)
    if health.state == "incapacitated" then
        return finishIncapacitated(
            record,
            zombie,
            health,
            damageEvent,
            now
        )
    end
    applyHealthDamage(record, health, amount, damageEvent)
    if health.current <= 0 then
        return handleDepletedHealth(record, zombie, damageEvent)
    end
    return true
end

function Health.ApplyStrainDamage(
    record,
    zombie,
    amount,
    floorRatio,
    reason
)
    local health
    local floorHealth
    local applied
    if not record then return false end
    health = Health.Ensure(record)
    if Core and Core.IsAuthority and not Core.IsAuthority() then
        return false
    end
    if not record
        or record.alive == false
        or not health
        or health.state == "incapacitated"
    then
        return false
    end
    amount = math.max(0, tonumber(amount) or 0)
    floorRatio = Core.Clamp(tonumber(floorRatio) or 0.75, 0, 1)
    floorHealth = (tonumber(health.max) or 100) * floorRatio
    applied = math.min(
        amount,
        math.max(
            0,
            (tonumber(health.current) or 0) - floorHealth
        )
    )
    if applied <= 0 then return false end
    if PNC.NPCWounds and PNC.NPCWounds.ApplyBodyDamage then
        PNC.NPCWounds.ApplyBodyDamage(record, applied)
    else
        health.current = math.max(
            floorHealth,
            (tonumber(health.current) or 0) - applied
        )
    end
    health.lastStrainReason = tostring(reason or "strain")
    if Registry and Registry.MarkDirty then
        Registry.MarkDirty(record, "health")
    end
    return true
end
