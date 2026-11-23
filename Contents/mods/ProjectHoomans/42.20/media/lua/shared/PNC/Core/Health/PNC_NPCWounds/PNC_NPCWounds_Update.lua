PNC = PNC or {}
require "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_OrdinaryInfection"
require "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_Physiology"

local Wounds = PNC.NPCWounds
local Internal = Wounds.Internal
local Core = PNC.Core
local Const = PNC.Const
local Dressing = require "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_Dressing"

local function healWound(record, body, partId, wound, amount)
    local damage = math.max(0, tonumber(wound.damage) or tonumber(wound.severity) or 0)
    local healed = math.min(damage, amount)
    if healed > 0 then
        Wounds.ApplyBodyHealing(record, healed, partId)
        wound.damage = damage - healed
        wound.severity = math.max(0, (tonumber(wound.severity) or damage) - healed)
    end
    if damage - healed > 0.001 then return healed end
    if (wound.dressingLifeTracked and not wound.virtualDressing) or wound.splintItem then
        wound.dressingHealed = true
        wound.bleedingRate = 0
        wound.woundInfectionLevel, wound.infectedWound = 0, false
    else
        body.wounds[partId] = nil
    end
    Internal.EmitWoundStateChange(record, partId, "wound_healed", wound)
    return healed
end

local function updateFracture(record, body, partId, wound, currentHour)
    if wound.type ~= "fracture" or wound.dressingHealed then return false end
    local elapsed = math.max(0, currentHour - (tonumber(wound.lastFractureHealHour) or currentHour))
    wound.lastFractureHealHour = currentHour
    if elapsed == 0 then return false end
    local multiplier = Dressing.NativeMultiplierPerWorldHour() or 3600
    local factor = wound.splinted and (tonumber(wound.splintFactor) or 0) or 0
    local rate = (factor > 0 and 0.00005 * factor or 0.000005) * multiplier
    healWound(record, body, partId, wound, elapsed * rate)
    return true
end

local function updateBandagedWound(record, body, partId, wound, currentHour)
    local changed = false
    if wound.bandageHealedPoints == nil then wound.bandageHealedPoints = 0; changed = true end
    if wound.bandageInitialDamage == nil then
        wound.bandageInitialDamage = math.max(0, (tonumber(wound.damage) or tonumber(wound.severity) or 0) + (tonumber(wound.bandageHealedPoints) or 0))
        changed = true
    end
    if not wound.dressingLifeTracked and (tonumber(wound.lastHealWorldHour) or 0) <= 0 then
        wound.lastHealWorldHour = currentHour
        wound.bandageAppliedWorldHour = currentHour
        wound.dirtyAtWorldHour = currentHour + (tonumber(Const.BANDAGE_DIRTY_AFTER_WORLD_HOURS) or 8)
        wound.healAtWorldHour = 0
        changed = true
    end
    if wound.dressingHealed == true then return changed end
    if wound.bandageDirty == true and not wound.dressingLifeTracked then return changed end
    local lastHealHour = tonumber(wound.lastHealWorldHour) or currentHour
    local dirtyAtHour = tonumber(wound.dirtyAtWorldHour) or math.huge
    local healUntilHour = wound.dressingLifeTracked and currentHour or math.min(currentHour, dirtyAtHour)
    local healElapsed = math.max(0, healUntilHour - lastHealHour)
    if healElapsed > 0 and wound.type ~= "fracture" then
        local baseRate = tonumber(Const.BANDAGE_HEAL_PER_WORLD_HOUR) or 1.5
        local infPenalty = math.max(0.35, 1 - (tonumber(wound.woundInfectionLevel) or 0) * 0.06)
        local healRate = math.max(0.01, (tonumber(wound.healRatePerWorldHour) or baseRate) * infPenalty)
        wound.lastHealWorldHour = healUntilHour
        local healed = healWound(record, body, partId, wound, healElapsed * healRate)
        wound.bandageHealedPoints = math.max(0, tonumber(wound.bandageHealedPoints) or 0) + healed
        changed = true
    end
    if body.wounds[partId] and not wound.bandageDirty and currentHour >= dirtyAtHour then
        wound.bandageDirty = true
        wound.bandageLife = 0
        wound.lastHealWorldHour = currentHour
        changed = true
        Internal.EmitWoundStateChange(record, partId, "bandage_dirty", wound)
    end
    return changed
end

local function applyBleeding(record, zombie, body, health, now)
    if body.lastBleedAt <= 0 then body.lastBleedAt = now; return false end
    local elapsed = now - body.lastBleedAt
    if elapsed < (tonumber(Const.WOUND_BLEED_UPDATE_MS) or 1000) then return false end
    body.lastBleedAt = now
    if health.state ~= "normal" or (tonumber(body.bleedingRate) or 0) <= 0 then return false end
    local bleedDamage = body.bleedingRate * math.min(10, elapsed / 1000)
    local partId
    for _, wound in pairs(body.wounds) do
        if wound.bandaged ~= true then partId = wound.partId; break end
    end
    PNC.Health.ApplyDamage(record, zombie, {
        amount = bleedDamage, partId = partId, type = "blood_loss", attackerKind = "wound",
    })
    if health.state ~= "normal" or record.alive == false then return true end
    record.runtime = record.runtime or {}
    if now - (tonumber(record.runtime.lastWoundDirtyAt) or 0) >= (tonumber(Const.WOUND_DIRTY_FLUSH_MS) or 5000) then
        record.runtime.lastWoundDirtyAt = now
        if PNC.Registry and PNC.Registry.MarkDirty then PNC.Registry.MarkDirty(record, "health") end
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
        if Internal.RefreshInfectionState(record, currentHour, false, zombie) then changed = true end
        if infection.nonLethalFever ~= true and (infection.pendingFatal == true
            or currentHour >= (tonumber(infection.fatalAtWorldHour) or math.huge))
        then
            Wounds.TriggerInfectionDeath(record, zombie, "zombie_infection")
            return true
        end
    end
    local totalOrdInf = 0
    for partId, wound in pairs(body.wounds) do
        if not wound.dressingHealed and Internal.UpdateOrdinaryWoundInfection(record, partId, wound, currentHour) then changed = true end
        if wound.bandaged == true and updateBandagedWound(record, body, partId, wound, currentHour) then changed = true end
        if body.wounds[partId] and updateFracture(record, body, partId, wound, currentHour) then changed = true end
        if body.wounds[partId] and not wound.dressingHealed then totalOrdInf = totalOrdInf + (tonumber(wound.woundInfectionLevel) or 0) end
    end
    if Wounds.WholeBody and Wounds.WholeBody.SetSeverity then
        local sev = totalOrdInf >= 2.0 and Core.Clamp(totalOrdInf / 20.0, 0, 1) or 0
        local _, wbChanged = Wounds.WholeBody.SetSeverity(record, "wound_infection", sev)
        if wbChanged then changed = true end
    end
    if body.infection and body.infection.active == true and Internal.RefreshInfectionState(record, currentHour, true, zombie) then
        changed = true
    end
    if type(Wounds.UpdatePhysiology) == "function" and Wounds.UpdatePhysiology(record, nil, nil) then
        changed = true
    end
    if changed then
        Wounds.Recalculate(record)
        if Wounds.InvalidateProjection then Wounds.InvalidateProjection(record, "wound_tick", true) end
        record.runtime = record.runtime or {}
        record.runtime.forceSyncEvent = record.runtime.forceSyncEvent or "wound_healed"
        if PNC.Registry and PNC.Registry.MarkDirty then PNC.Registry.MarkDirty(record, "wounds") end
    end
    now = tonumber(now) or Core.Now()
    if applyBleeding(record, zombie, body, health, now) then changed = true end
    return changed
end

return Wounds
