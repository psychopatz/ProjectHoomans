--[[
    PNC Health
    Single writer for NPC HP, incapacitation, revive recovery, and death state.
    It also owns recent-damage timers that drive overhead combat visibility.
]]

PNC = PNC or {}
PNC.Health = PNC.Health or {}

local Health = PNC.Health
local Core = PNC.Core
local Const = PNC.Const
local Registry = PNC.Registry
local Settings = PNC.Sandbox

local function resolvePathService()
    return PNC.PathService
end

local function resolveAnimation()
    return PNC.Animation
end

local function resolveCombatTactics()
    return PNC.CombatTactics
end

local function resolveLiveBodyControl()
    return PNC.LiveBodyControl
end

function Health.Ensure(record)
    if not record.health then
        record.health = {
            current = Const.DEFAULT_HP_MAX,
            max = Const.DEFAULT_HP_MAX,
            state = "normal",
            lastDamageAt = 0,
            downedAt = 0,
            recentDamageUntil = 0,
            reviveUntil = 0,
            reviveProtectionUntil = 0,
        }
    end
    if record.health.recentDamageUntil == nil then
        record.health.recentDamageUntil = 0
    end
    if record.health.reviveUntil == nil then
        record.health.reviveUntil = 0
    end
    if record.health.reviveProtectionUntil == nil then
        record.health.reviveProtectionUntil = 0
    end
    if type(record.health.body) ~= "table" then
        record.health.body = {
            wounds = {}, bleedingRate = 0, openWoundCount = 0,
            bandagedWoundCount = 0, lastBleedAt = 0,
        }
    end
    return record.health
end

function Health.MarkRecentDamage(record, now)
    local health = Health.Ensure(record)
    local damageAt = tonumber(now) or Core.Now()
    health.lastDamageAt = damageAt
    health.recentDamageUntil = damageAt + Const.RECENT_DAMAGE_SHOW_MS
    record.runtime = record.runtime or {}
    record.runtime.inCombatUntil = math.max(
        tonumber(record.runtime.inCombatUntil or 0) or 0,
        damageAt + Const.DEBUG_COMBAT_HOLD_MS
    )
    if Registry and Registry.MarkDirty then
        Registry.MarkDirty(record, "health")
    end
end

local function applyIncapacitatedLiveState(record, zombie)
    local Animation = resolveAnimation()
    local path = record and record.runtime and record.runtime.pathing or nil
    local moving = path and (path.phase == "requested" or path.phase == "active") and path.mode == "crawl"
    if not zombie then
        return
    end
    if zombie.setRunning then
        zombie:setRunning(false)
    end
    if zombie.setUseless then
        zombie:setUseless(true)
    end
    if zombie.setZombiesDontAttack then
        zombie:setZombiesDontAttack(not Settings.CanZombieTargetRecord(record))
    end
    if zombie.setHealth then
        zombie:setHealth(Const.INCAPACITATED_ENGINE_BUFFER)
    end
    if Animation and Animation.ApplyDowned then
        Animation.ApplyDowned(zombie, record, moving == true)
    end
end

local function applyNormalLiveState(record, zombie)
    local Animation = resolveAnimation()
    local LiveBodyControl = resolveLiveBodyControl()
    if not zombie then
        return
    end
    if zombie.setUseless then
        zombie:setUseless(true)
    end
    if zombie.setZombiesDontAttack then
        zombie:setZombiesDontAttack(not Settings.CanZombieTargetRecord(record))
    end
    if zombie.setHealth then
        zombie:setHealth(Const.DEFAULT_ENGINE_BUFFER)
    end
    if LiveBodyControl and LiveBodyControl.ApplyHumanizedBodyFlags then
        LiveBodyControl.ApplyHumanizedBodyFlags(zombie)
    end
    if Animation and Animation.ClearDowned then
        Animation.ClearDowned(zombie)
    end
    if Animation and Animation.Apply then
        Animation.Apply(zombie, record, "Idle")
    end
end

local function refreshNormalLiveBuffer(record, zombie)
    if not zombie then
        return
    end
    if zombie.setUseless then
        zombie:setUseless(true)
    end
    if zombie.setZombiesDontAttack then
        zombie:setZombiesDontAttack(not Settings.CanZombieTargetRecord(record))
    end
    if zombie.setHealth then
        zombie:setHealth(Const.DEFAULT_ENGINE_BUFFER)
    end
end

function Health.EnterIncapacitated(record, zombie, reason)
    local health = Health.Ensure(record)
    local PathService = resolvePathService()
    local now = Core.Now()
    if not record or record.alive == false then
        return false
    end
    health.current = math.max(Const.INCAPACITATED_HP, 1)
    health.state = "incapacitated"
    health.downedAt = now
    health.incapacitatedReason = reason or "unknown"
    health.recentDamageUntil = now + Const.RECENT_DAMAGE_SHOW_MS
    health.reviveUntil = 0
    health.reviveProtectionUntil = 0
    record.runtime.forceLive = true
    record.runtime.target = nil
    record.runtime.lastPathX = nil
    record.runtime.lastPathY = nil
    record.runtime.attackAction = nil
    record.runtime.inCombatUntil = now + Const.DEBUG_COMBAT_HOLD_MS
    record.activeJob = "Incapacitated"
    record.activeBehavior = "Incapacitated"
    if PathService and PathService.Reset then
        PathService.Reset(zombie, record)
    end
    applyIncapacitatedLiveState(record, zombie)
    -- Bite impact is pumped after the normal NPC scheduler pass. Queue a near
    -- follow-up so a hit reaction that settles later in this frame is repaired
    -- immediately by the idempotent downed-state maintenance path.
    if PNC.Scheduler and PNC.Scheduler.Schedule then
        PNC.Scheduler.Schedule(record, now + 50)
    end
    if zombie
        and not Settings.CanZombieTargetRecord(record)
        and PNC.ZombieAggro
        and PNC.ZombieAggro.ClearForNPCBody
    then
        PNC.ZombieAggro.ClearForNPCBody(zombie)
    end
    if Registry and Registry.MarkDirty then
        Registry.MarkDirty(record, "health")
    end
    return true
end

function Health.Revive(record, zombie)
    local health = Health.Ensure(record)
    local revivedHP = math.min(health.max, math.max(Const.INCAPACITATED_HP, Const.REVIVE_HP))
    local now = Core.Now()
    health.current = revivedHP
    health.state = "normal"
    health.downedAt = 0
    health.incapacitatedReason = nil
    health.reviveUntil = 0
    health.reviveProtectionUntil = now + Const.REVIVE_PROTECTION_MS
    health.recentDamageUntil = now + Const.RECENT_DAMAGE_SHOW_MS
    if PNC.NPCWounds and PNC.NPCWounds.BandageAll then
        PNC.NPCWounds.BandageAll(record, now)
    end
    record.alive = true
    record.runtime.forceLive = false
    record.runtime.target = nil
    record.runtime.attackAction = nil
    record.runtime.inCombatUntil = 0
    if zombie and PNC.ZombieAggro and PNC.ZombieAggro.ClearForNPCBody then
        PNC.ZombieAggro.ClearForNPCBody(zombie)
    end
    applyNormalLiveState(record, zombie)
    if Registry and Registry.MarkDirty then
        Registry.MarkDirty(record, "health")
    end
    return true
end

function Health.Recover(record, zombie)
    local health = Health.Ensure(record)
    health.current = health.max
    health.state = "normal"
    health.downedAt = 0
    health.incapacitatedReason = nil
    health.reviveUntil = 0
    health.reviveProtectionUntil = 0
    health.recentDamageUntil = 0
    if PNC.NPCWounds and PNC.NPCWounds.Clear then
        PNC.NPCWounds.Clear(record)
    end
    record.alive = true
    record.runtime.forceLive = false
    record.runtime.target = nil
    record.runtime.attackAction = nil
    record.runtime.inCombatUntil = 0
    applyNormalLiveState(record, zombie)
    if Registry and Registry.MarkDirty then
        Registry.MarkDirty(record, "health")
    end
    return true
end

function Health.CanRevive(record)
    local health
    if not record then
        return false
    end
    health = Health.Ensure(record)
    return record
        and record.alive ~= false
        and health.state == "incapacitated"
        and not (PNC.NPCWounds and PNC.NPCWounds.HasActiveInfection
            and PNC.NPCWounds.HasActiveInfection(record))
end

function Health.ApplyDamageToPlayer(player, amount)
    local current
    if not player or not player.getHealth or not player.setHealth then
        return false
    end
    current = tonumber(player:getHealth()) or 1
    player:setHealth(math.max(0, current - (tonumber(amount) or 0) / 100))
    return true
end

function Health.Kill(record, zombie, reason)
    local health = Health.Ensure(record)
    health.current = 0
    health.state = "dead"
    health.reviveUntil = 0
    health.reviveProtectionUntil = 0
    health.recentDamageUntil = Core.Now() + Const.RECENT_DAMAGE_SHOW_MS
    record.alive = false
    record.presenceState = Const.PRESENCE_CORPSE
    record.runtime.forceLive = false
    record.runtime.target = nil
    record.runtime.attackAction = nil
    record.runtime.lastPathX = nil
    record.runtime.lastPathY = nil
    record.deathReason = reason or "unknown"

    if zombie then
        if zombie.setHealth then
            zombie:setHealth(0)
        end
        PNC.BodyLifecycle.CreateInertCorpse(record, zombie, reason or "death")
    elseif not record.corpse then
        record.corpse = {
            token = nil,
            x = record.x,
            y = record.y,
            z = record.z,
            createdWorldHour = 0,
        }
    end
    if Registry and Registry.MarkDirty then
        Registry.MarkDirty(record, "health")
    end
end

function Health.ApplyDamage(record, zombie, damageEvent)
    local health = Health.Ensure(record)
    local amount = tonumber(damageEvent and damageEvent.amount or 0) or 0
    local now = Core.Now()

    if record.alive == false or amount <= 0 then
        return false
    end

    if damageEvent
        and damageEvent.attackerKind == "zombie"
        and not Settings.CanZombieTargetRecord(record, now)
    then
        return false
    end

    Health.MarkRecentDamage(record, now)
    if damageEvent and damageEvent.attackerKind == "zombie" then
        record.runtime.targetKind = "zombie"
        record.runtime.combatBlockReason = "taking_zombie_damage"
        if resolveCombatTactics() and resolveCombatTactics().MarkZombieDamage then
            resolveCombatTactics().MarkZombieDamage(record, damageEvent.x, damageEvent.y, damageEvent.z, now)
        end
    end

    if health.state == "incapacitated" then
        if PNC.NPCWounds and PNC.NPCWounds.HasActiveInfection
            and PNC.NPCWounds.HasActiveInfection(record)
        then
            PNC.NPCWounds.TriggerInfectionDeath(
                record,
                zombie,
                damageEvent and damageEvent.type or "zombie_infection"
            )
            return true
        end
        if (now - (tonumber(health.downedAt) or 0)) < Const.INCAPACITATED_GRACE_MS then
            return false
        end
        Health.Kill(record, zombie, damageEvent and damageEvent.type or "incapacitated_finish")
        return true
    end

    health.current = health.current - amount
    if Registry and Registry.MarkDirty then
        Registry.MarkDirty(record, "health")
    end

    if health.current <= 0 then
        if PNC.NPCWounds and PNC.NPCWounds.HasActiveInfection
            and PNC.NPCWounds.HasActiveInfection(record)
        then
            PNC.NPCWounds.TriggerInfectionDeath(record, zombie, "zombie_infection")
            return true
        end
        return Health.EnterIncapacitated(record, zombie, damageEvent and damageEvent.type or "damage")
    end

    return true
end

function Health.Update(record, zombie, now)
    local health = Health.Ensure(record)
    if record.alive == false then
        return
    end
    if PNC.NPCWounds and PNC.NPCWounds.Update then
        PNC.NPCWounds.Update(record, zombie, now)
        if record.alive == false then return end
    end
    if health.state == "incapacitated" then
        applyIncapacitatedLiveState(record, zombie)
        health.current = Const.INCAPACITATED_HP
        return
    end
    if (tonumber(health.reviveProtectionUntil) or 0) > 0
        and now >= (tonumber(health.reviveProtectionUntil) or 0)
    then
        health.reviveProtectionUntil = 0
        if Registry and Registry.MarkDirty then
            Registry.MarkDirty(record, "health")
        end
    end
    if zombie then
        refreshNormalLiveBuffer(record, zombie)
    end
end
