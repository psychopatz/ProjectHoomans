local Health = PNC.Health
local Internal = Health.Internal
local Core = PNC.Core
local Const = PNC.Const
local Registry = PNC.Registry
local Settings = PNC.Sandbox

function Health.EnterIncapacitated(record, zombie, reason)
    local health = Health.Ensure(record)
    local PathService = Internal.ResolvePathService()
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
        if PathService.Commands and PathService.Commands.Reset then
            PathService.Commands.Reset(
                record,
                zombie,
                "incapacitated"
            )
        else
            PathService.Reset(zombie, record)
        end
    end
    Internal.ApplyIncapacitatedLiveState(record, zombie)
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
    local socialEpisodeID
    local socialOccurredAt
    if health.state ~= "incapacitated"
        or (tonumber(health.current) or 0)
            < (tonumber(Const.INCAPACITATED_RECOVERY_HP) or 5)
    then
        return false
    end
    if PNC.SocialEventHooks then
        socialEpisodeID =
            PNC.SocialEventHooks.GetDownedEpisodeID(
                record,
                health.downedAt
            )
        socialOccurredAt =
            PNC.SocialEventHooks.WorldAgeHours()
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
    Internal.ApplyNormalLiveState(record, zombie)
    if Registry and Registry.MarkDirty then
        Registry.MarkDirty(record, "health")
    end
    if Core and Core.LogRecordDebug then
        Core.LogRecordDebug(record, "NPC " .. tostring(record.id)
            .. " recovered from incapacitation hp="
            .. string.format("%.2f", tonumber(health.current) or 0)
            .. " reason=" .. tostring(reason or "bandage_healing"))
    end
    if socialEpisodeID
        and PNC.SocialEventHooks
        and PNC.SocialEventHooks.OnIncapacitationRecovered
    then
        PNC.SocialEventHooks.OnIncapacitationRecovered(
            record,
            socialEpisodeID,
            socialOccurredAt
        )
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
    Internal.ApplyNormalLiveState(record, zombie)
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
