PNC = PNC or {}
local Wounds = PNC.NPCWounds
local Internal = Wounds.Internal
local Core = PNC.Core

function Internal.AddWound(
    record,
    part,
    woundType,
    now,
    woundDamage
)
    local body = Wounds.Ensure(record)
    local stats = Internal.WoundStats[woundType]
        or Internal.WoundStats.scratch
    local severityDamage = math.max(
        0.1,
        tonumber(woundDamage) or tonumber(stats.damage) or 4
    )
    local existing = body.wounds[part.id]
    local existingStats = existing
        and Internal.WoundStats[existing.type] or nil
    local wound = existing or {
        partId = part.id,
        createdAt = now,
    }
    if not existingStats
        or stats.priority >= existingStats.priority
    then
        wound.type = woundType
    end
    wound.bleedingRate = math.min(
        0.18,
        math.max(
            tonumber(wound.bleedingRate) or 0,
            stats.bleedingRate
        ) + (existing and stats.bleedingRate * 0.35 or 0)
    )
    wound.severity = math.min(
        100,
        (tonumber(wound.severity) or 0) + severityDamage
    )
    wound.damage = math.min(
        100,
        (tonumber(wound.damage) or 0) + severityDamage
    )
    wound.bandaged = false
    wound.bandagedAt = 0
    wound.healAtWorldHour = 0
    wound.bandageType = nil
    wound.bandageName = nil
    wound.bandageDirty = false
    wound.bandageAppliedWorldHour = 0
    wound.lastHealWorldHour = 0
    wound.dirtyAtWorldHour = 0
    wound.firstAidLevel = 0
    body.wounds[part.id] = wound
    if woundType == "bite" then
        Internal.Infect(
            record,
            part.id,
            Internal.WorldHour()
        )
    end
    Wounds.Recalculate(record)
    Internal.Events.emit(
        Internal.EventTypes.NPC_WOUNDED,
        record,
        part.id,
        wound.type,
        severityDamage
    )
    if PNC.MedicalCareService
        and PNC.MedicalCareService.RequestNPC
    then
        PNC.MedicalCareService.RequestNPC(record, {
            source = "wound",
            sourceRef = tostring(record.id) .. ":" .. tostring(part.id),
            severity = severityDamage,
            incapacitated = record.health
                and record.health.state == "incapacitated",
        })
    end
    return wound, stats.damage
end

function Wounds.ApplyCombatDamage(record, npcBody, damageEvent)
    local partId = damageEvent and damageEvent.partId
        and tostring(damageEvent.partId)
        or Wounds.ChoosePartId()
    local part = Wounds.Parts[partId]
    local woundType = tostring(
        damageEvent and damageEvent.woundType or "scratch"
    )
    local amount = math.max(
        0,
        tonumber(damageEvent and damageEvent.amount) or 0
    )
    if not record
        or record.alive == false
        or not part
        or amount <= 0
    then
        return false, {
            outcome = "invalid_target",
            partId = partId,
        }
    end
    if not Internal.WoundStats[woundType] then
        woundType = "scratch"
    end
    local applied = PNC.Health.ApplyDamage(record, npcBody, {
        amount = amount,
        partId = part.id,
        type = tostring(
            damageEvent
                and damageEvent.type
                or "combat_" .. woundType
        ),
        attackerID = damageEvent and damageEvent.attackerID,
        attackerKind = damageEvent
            and damageEvent.attackerKind or "npc",
        attackerOnlineID =
            damageEvent and damageEvent.attackerOnlineID,
        attackerUsername =
            damageEvent and damageEvent.attackerUsername,
        weaponFullType =
            damageEvent and damageEvent.weaponFullType,
        x = damageEvent and damageEvent.x,
        y = damageEvent and damageEvent.y,
        z = damageEvent and damageEvent.z,
    })
    if not applied then
        return false, {
            outcome = "damage_rejected",
            partId = part.id,
        }
    end
    local wound
    if record.alive ~= false then
        wound = Internal.AddWound(
            record,
            part,
            woundType,
            Core.Now(),
            amount
        )
    end
    record.runtime = record.runtime or {}
    record.runtime.forceSyncEvent =
        record.alive == false and "death" or "combat_damage"
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "wounds")
    end
    return true, {
        outcome = record.alive == false and "killed" or "wounded",
        partId = part.id,
        woundType = wound and wound.type or woundType,
        damage = amount,
        infected = Wounds.HasActiveInfection(record),
    }
end

return Wounds
