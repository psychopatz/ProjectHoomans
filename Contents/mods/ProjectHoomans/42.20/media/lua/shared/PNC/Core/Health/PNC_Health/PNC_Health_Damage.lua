local Health = PNC.Health
local Internal = Health.Internal
local Core = PNC.Core
local Const = PNC.Const
local Registry = PNC.Registry
local Settings = PNC.Sandbox

local function bodyIsDead(body)
    local ok
    local dead
    if not body or not body.isDead then
        return false
    end
    ok, dead = pcall(body.isDead, body)
    return ok and dead == true
end

function Health.IsDead(record, body)
    local health = record and record.health or nil
    if not record or record.alive == false then
        return true
    end
    if health and health.state == "dead" then
        return true
    end
    return bodyIsDead(body)
end

local function bodyState(body)
    local ok
    local dead
    if not body then
        return "missing"
    end
    if not body.isDead then
        return "unknown"
    end
    ok, dead = pcall(body.isDead, body)
    if not ok then
        return "unknown"
    end
    return dead == true and "dead" or "live"
end

local function rejectionDetail(record, body, health, reason, amount)
    return {
        reason = tostring(reason or "damage_rejected"),
        amount = tonumber(amount) or 0,
        recordAlive = record and record.alive ~= false or false,
        healthState = health and tostring(health.state or "") or "",
        healthCurrent = health and tonumber(health.current) or nil,
        healthMax = health and tonumber(health.max) or nil,
        bodyState = bodyState(body),
    }
end

local function canApplyDamage(record, body, amount, damageEvent, now)
    if Core and Core.IsAuthority and not Core.IsAuthority() then
        return false, "not_authority"
    end
    if not record then
        return false, "missing_record"
    end
    if record.alive == false
        or record.health and record.health.state == "dead"
    then
        return false, "dead_record"
    end
    if bodyIsDead(body) then
        return false, "dead_body"
    end
    if amount <= 0 then
        return false, "invalid_amount"
    end
    if damageEvent
        and damageEvent.attackerKind == "zombie"
        and (not Settings or not Settings.CanZombieTargetRecord
            or not Settings.CanZombieTargetRecord(record, now))
    then
        return false, "zombie_target_not_allowed"
    end
    return true
end

local function rememberDamageSource(record, damageEvent, now)
    local tactics
    Health.MarkRecentDamage(record, now, damageEvent)
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
        return true, "infection_death"
    end
    if now - (tonumber(health.downedAt) or 0)
        < Const.INCAPACITATED_GRACE_MS
    then
        return false, "incapacitated_grace"
    end
    Health.Kill(
        record,
        zombie,
        damageEvent and damageEvent.type or "incapacitated_finish",
        damageEvent
    )
    return true, "incapacitated_finished"
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
    local health
    local amount =
        tonumber(damageEvent and damageEvent.amount or 0) or 0
    local now
    local allowed
    local reason
    local transitioned
    if not record then
        return false, "missing_record", rejectionDetail(
            record,
            zombie,
            nil,
            "missing_record",
            amount
        )
    end
    health = Health.Ensure(record)
    now = Core.Now()
    allowed, reason = canApplyDamage(
        record,
        zombie,
        amount,
        damageEvent,
        now
    )
    if not allowed then
        return false, reason, rejectionDetail(
            record,
            zombie,
            health,
            reason,
            amount
        )
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
        transitioned = handleDepletedHealth(record, zombie, damageEvent)
        if transitioned then
            return true, "incapacitated"
        end
        return false, "incapacitation_transition_rejected", rejectionDetail(
            record,
            zombie,
            health,
            "incapacitation_transition_rejected",
            amount
        )
    end
    return true, "applied"
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
        or Health.IsDead(record)
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
