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
            wounds = {}, parts = {}, bleedingRate = 0, openWoundCount = 0,
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
    if Animation and Animation.ApplyDowned
        and not (record.runtime and record.runtime.selfTreatment
            and record.runtime.selfTreatment.phase == "bandaging")
    then
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
    if PNC.NPCWounds and PNC.NPCWounds.SetOverallHealth then
        PNC.NPCWounds.SetOverallHealth(record, math.max(Const.INCAPACITATED_HP, 1))
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

function Health.ResumeFromIncapacitated(record, zombie, reason)
    local health = Health.Ensure(record)
    local now = Core.Now()
    if health.state ~= "incapacitated"
        or (tonumber(health.current) or 0)
            < (tonumber(Const.INCAPACITATED_RECOVERY_HP) or 5)
    then
        return false
    end
    health.state = "normal"
    health.downedAt = 0
    health.incapacitatedReason = nil
    health.reviveUntil = 0
    health.reviveProtectionUntil = now + Const.REVIVE_PROTECTION_MS
    health.recentDamageUntil = now + Const.RECENT_DAMAGE_SHOW_MS
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
    if Core and Core.LogRecordDebug then
        Core.LogRecordDebug(record, "NPC " .. tostring(record.id)
            .. " recovered from incapacitation hp="
            .. string.format("%.2f", tonumber(health.current) or 0)
            .. " reason=" .. tostring(reason or "bandage_healing"))
    end
    return true
end

-- Compatibility entry point for older UI/debug callers. "Revive" no longer
-- grants HP or stands the NPC up; it only controls bleeding. Normal wound
-- healing owns the transition back to walking at the recovery threshold.
function Health.Revive(record, zombie, options)
    if not record or not PNC.NPCWounds or not PNC.NPCWounds.BandageAll then
        return false
    end
    return PNC.NPCWounds.BandageAll(record, Core.Now(), options)
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
    if PNC.NPCWounds and PNC.NPCWounds.SetOverallHealth then
        PNC.NPCWounds.SetOverallHealth(record, health.max)
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
    local treatable
    if not record then
        return false
    end
    health = Health.Ensure(record)
    treatable = PNC.NPCWounds and PNC.NPCWounds.GetTreatableWounds
        and PNC.NPCWounds.GetTreatableWounds(record) or {}
    return record
        and record.alive ~= false
        and health.state == "incapacitated"
        and #treatable > 0
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
    local corpseOK
    local corpseCreated
    local deathMarker
    if PNC.CompanionVehicle and PNC.CompanionVehicle.Release then
        PNC.CompanionVehicle.Release(record, "npc_death")
    end
    if PNC.NPCWounds and PNC.NPCWounds.SetOverallHealth then
        PNC.NPCWounds.SetOverallHealth(record, 0)
    end
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
        local createCorpse = PNC.BodyLifecycle and (
            PNC.BodyLifecycle.CreateVanillaCorpse
            or PNC.BodyLifecycle.CreateInertCorpse
        ) or nil
        if createCorpse then
            corpseOK, corpseCreated = pcall(
                createCorpse,
                record,
                zombie,
                reason or "death"
            )
        else
            corpseOK, corpseCreated = false, "corpse_service_unavailable"
        end
        if (not corpseOK or corpseCreated ~= true) and Core and Core.Log then
            Core.Log("ERROR", "NPC corpse creation failed npc=" .. tostring(record.id)
                .. " reason=" .. tostring(corpseCreated or "unknown"))
        end
    elseif not record.corpse then
        record.corpse = {
            token = nil,
            x = record.x,
            y = record.y,
            z = record.z,
            createdWorldHour = 0,
        }
    end
    -- Retire the heavyweight NPC immediately. From this point the vanilla
    -- corpse owns appearance/items and PNC retains only a compact location
    -- marker until that corpse disappears (or reanimates).
    if Registry and Registry.AddDeathMarker then
        deathMarker = Registry.AddDeathMarker(record)
    end
    if deathMarker and Registry and Registry.RemoveRecord then
        record.runtime.deathRetired = true
        Registry.RemoveRecord(record.id)
        if PNC.Network and PNC.Network.BroadcastRemoval then
            PNC.Network.BroadcastRemoval(record.id, "death")
        end
    elseif Registry and Registry.MarkDirty then
        Registry.MarkDirty(record, "health")
    end
    return deathMarker ~= nil, deathMarker
end

function Health.ApplyDamage(record, zombie, damageEvent)
    local health = Health.Ensure(record)
    local amount = tonumber(damageEvent and damageEvent.amount or 0) or 0
    local now = Core.Now()

    if Core and Core.IsAuthority and not Core.IsAuthority() then
        return false
    end
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
    if PNC.Perception and PNC.Perception.RememberAttacker then
        PNC.Perception.RememberAttacker(record, damageEvent, now)
    end
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

    if PNC.NPCWounds and PNC.NPCWounds.ApplyBodyDamage then
        PNC.NPCWounds.ApplyBodyDamage(record, amount, damageEvent and damageEvent.partId)
    else
        health.current = health.current - amount
    end
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

function Health.ApplyStrainDamage(record, zombie, amount, floorRatio, reason)
    local health
    local floorHealth
    local applied
    if not record then return false end
    health = Health.Ensure(record)
    if Core and Core.IsAuthority and not Core.IsAuthority() then
        return false
    end
    if not record or record.alive == false or not health
        or health.state == "incapacitated"
    then
        return false
    end
    amount = math.max(0, tonumber(amount) or 0)
    floorRatio = Core.Clamp(tonumber(floorRatio) or 0.75, 0, 1)
    floorHealth = (tonumber(health.max) or 100) * floorRatio
    applied = math.min(amount,
        math.max(0, (tonumber(health.current) or 0) - floorHealth))
    if applied <= 0 then return false end

    if PNC.NPCWounds and PNC.NPCWounds.ApplyBodyDamage then
        PNC.NPCWounds.ApplyBodyDamage(record, applied)
    else
        health.current = math.max(floorHealth,
            (tonumber(health.current) or 0) - applied)
    end
    health.lastStrainReason = tostring(reason or "strain")
    if Registry and Registry.MarkDirty then
        Registry.MarkDirty(record, "health")
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
        if (tonumber(health.current) or 0)
            >= (tonumber(Const.INCAPACITATED_RECOVERY_HP) or 5)
        then
            Health.ResumeFromIncapacitated(record, zombie, "bandage_healing")
            return
        end
        applyIncapacitatedLiveState(record, zombie)
        return
    end
    if (tonumber(health.reviveProtectionUntil) or 0) > 0
        and now >= (tonumber(health.reviveProtectionUntil) or 0)
    then
        health.reviveProtectionUntil = 0
    end
    if zombie then
        refreshNormalLiveBuffer(record, zombie)
    end
end
