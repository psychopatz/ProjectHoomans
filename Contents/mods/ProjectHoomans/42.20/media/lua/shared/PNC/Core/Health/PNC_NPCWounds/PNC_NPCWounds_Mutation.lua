PNC = PNC or {}
require "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_CombatWoundHelpers"

local Wounds = PNC.NPCWounds
local Internal = Wounds.Internal
local Core = PNC.Core
local Settings = PNC.Sandbox

local function isKnoxEligibleWound(normalizedType, isZombieWound)
    if not isZombieWound then return false end
    return normalizedType == "bite" or normalizedType == "laceration" or normalizedType == "scratch"
end

local function applyWoundFlags(wound, normalizedType, stats, severityDamage, existing)
    local existingStats = existing and Internal.WoundStats[existing.type] or nil
    if not existingStats or stats.priority >= existingStats.priority then
        wound.type = normalizedType
    end
    wound.bleedingRate = math.min(0.18,
        math.max(tonumber(wound.bleedingRate) or 0, stats.bleedingRate) + (existing and stats.bleedingRate * 0.35 or 0))
    wound.severity = math.min(100, (tonumber(wound.severity) or 0) + severityDamage)
    wound.damage = math.min(100, (tonumber(wound.damage) or 0) + severityDamage)
    if stats.haveGlass == true then wound.haveGlass = true end
    if stats.haveBullet == true then wound.haveBullet = true end
    if stats.deepWounded == true then wound.deepWounded = true end
    if stats.fractured == true then
        wound.fractured, wound.splinted = true, false
        wound.splintItem, wound.splintType, wound.splintFactor, wound.lastFractureHealHour = nil, nil, nil, nil
    end
    if stats.burned == true then wound.burned = true end
    if normalizedType == "bite" then
        -- BodyPart.java:692 SetBitten sets infectedWound = true alongside Knox check
        wound.infectedWound = true
        wound.woundInfectionLevel = math.max(tonumber(wound.woundInfectionLevel) or 0, 1.0)
    end
    wound.bandaged, wound.stitched, wound.cauterized = false, false, false
    wound.bandagedAt, wound.healAtWorldHour = 0, 0
    wound.bandageType, wound.bandageName, wound.bandageDirty = nil, nil, false
    wound.spentBandageType, wound.sterileDressing, wound.virtualDressing = nil, nil, nil
    wound.dressingLifeTracked, wound.dressingHealed, wound.bandageLife = nil, nil, nil
    wound.bandageAppliedWorldHour, wound.lastHealWorldHour, wound.dirtyAtWorldHour, wound.firstAidLevel = 0, 0, 0, 0
    wound.alcoholLevel = tonumber(wound.alcoholLevel) or 0
end

function Internal.AddWound(record, part, woundType, now, woundDamage, options)
    local body = Wounds.Ensure(record)
    local normalizedType = Wounds.NormalizeWoundType and Wounds.NormalizeWoundType(woundType) or tostring(woundType or "scratch")
    if not Internal.WoundStats[normalizedType] then normalizedType = "scratch" end
    local stats = Internal.WoundStats[normalizedType] or Internal.WoundStats.scratch
    local severityDamage = math.max(0.1, tonumber(woundDamage) or tonumber(stats.damage) or 4)
    local existing = body.wounds[part.id]
    local wound = existing or { partId = part.id, createdAt = now }
    options = type(options) == "table" and options or {}
    local isZombieWound = options.zombieWound == true or options.attackerKind == "zombie" or normalizedType == "bite"
    wound.zombieWound = wound.zombieWound == true or isZombieWound
    applyWoundFlags(wound, normalizedType, stats, severityDamage, existing)
    body.wounds[part.id] = wound
    if isKnoxEligibleWound(normalizedType, isZombieWound) then
        local sb = PNC.Sandbox or Settings
        local canTransmit = sb and type(sb.CanZombieWoundTransmitKnox) == "function"
            and sb.CanZombieWoundTransmitKnox(normalizedType)
            or (normalizedType == "bite" and (not sb or not sb.IsZombieSalivaTransmissible or sb.IsZombieSalivaTransmissible()))
        if canTransmit then
            body.knoxExposureState = "possible"
        end
        if type(Internal.Infect) == "function" then
            Internal.Infect(record, part.id, Internal.WorldHour(), false, normalizedType, wound)
        end
    end
    Wounds.Recalculate(record)
    if Wounds.InvalidateProjection then Wounds.InvalidateProjection(record, "wound_added", true) end
    if Internal.Events and Internal.EventTypes then
        Internal.Events.emit(Internal.EventTypes.NPC_WOUNDED, record, part.id, wound.type, severityDamage)
    end
    if PNC.MedicalCareService and PNC.MedicalCareService.RequestNPC then
        PNC.MedicalCareService.RequestNPC(record, {
            source = "wound",
            sourceRef = tostring(record.id) .. ":" .. tostring(part.id),
            severity = severityDamage,
            incapacitated = record.health and record.health.state == "incapacitated",
        })
    end
    return wound, stats.damage
end

function Wounds.ApplyCombatDamage(record, npcBody, damageEvent)
    local partId = damageEvent and damageEvent.partId and tostring(damageEvent.partId) or Wounds.ChoosePartId()
    local part = Wounds.Parts[partId]
    local woundType = Internal.ResolveCombatWoundType(damageEvent)
    local amount = math.max(0, tonumber(damageEvent and damageEvent.amount) or 0)
    if not record or record.alive == false or not part or amount <= 0 then
        return false, { outcome = "invalid_target", partId = partId }
    end
    if not Internal.WoundStats[woundType] then woundType = "scratch" end
    local applied, healthReason, healthDetail = PNC.Health.ApplyDamage(record, npcBody, {
        amount = amount, partId = part.id,
        type = tostring(damageEvent and damageEvent.type or "combat_" .. woundType),
        attackerID = damageEvent and damageEvent.attackerID,
        attackerKind = damageEvent and damageEvent.attackerKind or "npc",
        attackerProvider = damageEvent and damageEvent.attackerProvider,
        attackerGeneration = damageEvent and damageEvent.attackerGeneration,
        attackerOnlineID = damageEvent and damageEvent.attackerOnlineID,
        attackerUsername = damageEvent and damageEvent.attackerUsername,
        weaponFullType = damageEvent and damageEvent.weaponFullType,
        x = damageEvent and damageEvent.x, y = damageEvent and damageEvent.y, z = damageEvent and damageEvent.z,
    })
    if not applied then
        return false, {
            outcome = "damage_rejected", reason = tostring(healthReason or "health_rejected"), partId = part.id,
            healthState = record.health and tostring(record.health.state or "") or "",
            healthCurrent = record.health and tonumber(record.health.current) or nil,
            healthMax = record.health and tonumber(record.health.max) or nil,
            bodyState = type(healthDetail) == "table" and healthDetail.bodyState or nil,
            attackType = damageEvent and damageEvent.attackType or nil,
            attackKind = damageEvent and damageEvent.attackKind or nil,
            woundType = woundType, weaponFullType = damageEvent and damageEvent.weaponFullType or nil,
        }
    end
    local wound, hitAt = nil, Core.Now()
    if record.alive ~= false then
        wound = Internal.AddWound(record, part, woundType, hitAt, amount, {
            zombieWound = damageEvent and damageEvent.attackerKind == "zombie",
            attackerKind = damageEvent and damageEvent.attackerKind,
        })
        Internal.NotifyWoundCallout(record, part.id, wound, amount, hitAt, {
            woundType = woundType,
            attackerKind = damageEvent and damageEvent.attackerKind,
            attackerID = damageEvent and damageEvent.attackerID,
            attackType = damageEvent and damageEvent.attackType,
        })
    end
    record.runtime = record.runtime or {}
    record.runtime.forceSyncEvent = record.alive == false and "death" or "combat_damage"
    if PNC.Registry and PNC.Registry.MarkDirty then PNC.Registry.MarkDirty(record, "wounds") end
    return true, {
        outcome = record.alive == false and "killed" or "wounded",
        partId = part.id, woundType = wound and wound.type or woundType, damage = amount,
        infected = Wounds.HasActiveInfection(record),
        healthState = record.health and tostring(record.health.state or "") or "",
        healthCurrent = record.health and tonumber(record.health.current) or nil,
        attackType = damageEvent and damageEvent.attackType or nil,
        attackKind = damageEvent and damageEvent.attackKind or nil,
        weaponFullType = damageEvent and damageEvent.weaponFullType or nil,
    }
end

return Wounds
