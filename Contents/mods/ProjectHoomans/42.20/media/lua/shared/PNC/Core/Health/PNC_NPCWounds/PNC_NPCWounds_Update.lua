PNC = PNC or {}
local Wounds = PNC.NPCWounds
local Internal = Wounds.Internal
local Core = PNC.Core
local Const = PNC.Const

local function updateBandagedWound(
    record,
    body,
    partId,
    wound,
    currentHour
)
    local changed = false
    if wound.bandageHealedPoints == nil then
        wound.bandageHealedPoints = 0
        changed = true
    end
    if wound.bandageInitialDamage == nil then
        wound.bandageInitialDamage = math.max(
            0,
            (tonumber(wound.damage)
                or tonumber(wound.severity)
                or 0)
                + (tonumber(wound.bandageHealedPoints) or 0)
        )
        changed = true
    end
    if (tonumber(wound.lastHealWorldHour) or 0) <= 0 then
        wound.lastHealWorldHour = currentHour
        wound.bandageAppliedWorldHour = currentHour
        wound.dirtyAtWorldHour = currentHour
            + (
                tonumber(
                    Const.BANDAGE_DIRTY_AFTER_WORLD_HOURS
                ) or 8
            )
        wound.healAtWorldHour = 0
        changed = true
    end
    if wound.bandageDirty == true then return changed end
    local lastHealHour =
        tonumber(wound.lastHealWorldHour) or currentHour
    local dirtyAtHour =
        tonumber(wound.dirtyAtWorldHour) or math.huge
    local healUntilHour = math.min(currentHour, dirtyAtHour)
    local healElapsed =
        math.max(0, healUntilHour - lastHealHour)
    if healElapsed > 0 then
        local healRate = math.max(
            0.01,
            tonumber(wound.healRatePerWorldHour)
                or (
                    (
                        tonumber(
                            Const.BANDAGE_HEAL_PER_WORLD_HOUR
                        ) or 1.5
                    )
                    + (tonumber(wound.firstAidLevel) or 0)
                        * (
                            tonumber(
                                Const.BANDAGE_FIRST_AID_HEAL_BONUS
                            ) or 0.25
                        )
                ) * Internal.GetBandageQuality(
                    wound.bandageType
                )
        )
        local remainingDamage = math.max(
            0,
            tonumber(wound.damage)
                or tonumber(wound.severity)
                or 0
        )
        local healAmount = math.min(
            remainingDamage,
            healElapsed * healRate
        )
        wound.lastHealWorldHour = healUntilHour
        if healAmount > 0 then
            Wounds.ApplyBodyHealing(
                record,
                healAmount,
                partId
            )
            wound.damage =
                math.max(0, remainingDamage - healAmount)
            wound.severity = math.max(
                0,
                (tonumber(wound.severity) or remainingDamage)
                    - healAmount
            )
            wound.bandageHealedPoints = math.max(
                0,
                tonumber(wound.bandageHealedPoints) or 0
            ) + healAmount
            changed = true
        end
        if (tonumber(wound.damage) or 0) <= 0.001 then
            body.wounds[partId] = nil
        end
    end
    if body.wounds[partId]
        and currentHour >= dirtyAtHour
    then
        wound.bandageDirty = true
        wound.lastHealWorldHour = currentHour
        changed = true
    end
    return changed
end

local function applyBleeding(record, zombie, body, health, now)
    if body.lastBleedAt <= 0 then
        body.lastBleedAt = now
        return false
    end
    local elapsed = now - body.lastBleedAt
    if elapsed
        < (tonumber(Const.WOUND_BLEED_UPDATE_MS) or 1000)
    then
        return false
    end
    body.lastBleedAt = now
    if health.state ~= "normal"
        or (tonumber(body.bleedingRate) or 0) <= 0
    then
        return false
    end
    local bleedDamage =
        body.bleedingRate * math.min(10, elapsed / 1000)
    local partId
    local wound
    for _, wound in pairs(body.wounds) do
        if wound.bandaged ~= true then
            partId = wound.partId
            break
        end
    end
    PNC.Health.ApplyDamage(record, zombie, {
        amount = bleedDamage,
        partId = partId,
        type = "blood_loss",
        attackerKind = "wound",
    })
    if health.state ~= "normal" or record.alive == false then
        return true
    end
    record.runtime = record.runtime or {}
    if now - (tonumber(
        record.runtime.lastWoundDirtyAt
    ) or 0) >= (
        tonumber(Const.WOUND_DIRTY_FLUSH_MS) or 5000
    ) then
        record.runtime.lastWoundDirtyAt = now
        if PNC.Registry and PNC.Registry.MarkDirty then
            PNC.Registry.MarkDirty(record, "health")
        end
    end
    return true
end

function Wounds.Update(record, zombie, now)
    local health = record and record.health or nil
    local body = health and Wounds.Ensure(record) or nil
    local infection = body and body.infection or nil
    if not body or record.alive == false then return false end
    local currentHour = Internal.WorldHour()
    local changed = false
    if infection and infection.active == true then
        if Internal.RefreshInfectionState(
            record,
            currentHour,
            false,
            zombie
        ) then
            changed = true
        end
        if infection.pendingFatal == true
            or currentHour >= (
                tonumber(infection.fatalAtWorldHour)
                    or math.huge
            )
        then
            Wounds.TriggerInfectionDeath(
                record,
                zombie,
                "zombie_infection"
            )
            return true
        end
    end
    local partId
    local wound
    for partId, wound in pairs(body.wounds) do
        if wound.bandaged == true
            and updateBandagedWound(
                record,
                body,
                partId,
                wound,
                currentHour
            )
        then
            changed = true
        end
    end
    if infection
        and infection.active == true
        and Internal.RefreshInfectionState(
            record,
            currentHour,
            true,
            zombie
        )
    then
        changed = true
    end
    if changed then
        Wounds.Recalculate(record)
        record.runtime = record.runtime or {}
        record.runtime.forceSyncEvent =
            record.runtime.forceSyncEvent
            or "wound_healed"
        if PNC.Registry and PNC.Registry.MarkDirty then
            PNC.Registry.MarkDirty(record, "wounds")
        end
    end
    now = tonumber(now) or Core.Now()
    if applyBleeding(
        record,
        zombie,
        body,
        health,
        now
    ) then
        changed = true
    end
    return changed
end

return Wounds
