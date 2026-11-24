PNC = PNC or {}
local Wounds = PNC.NPCWounds
local Internal = Wounds.Internal
local Core = PNC.Core
local Settings = PNC.Sandbox

local function hasAuthority()
    return Core and type(Core.IsAuthority) == "function"
        and Core.IsAuthority() == true
end

function Wounds.ApplyDebugWound(
    record,
    npcBody,
    partId,
    woundType,
    amount
)
    if not hasAuthority() then
        return false, { outcome = "not_authority" }
    end
    local part = partId
        and Wounds.Parts[tostring(partId)]
        or Internal.ChoosePart()
    local selectedType = Wounds.NormalizeWoundType
        and Wounds.NormalizeWoundType(woundType)
        or tostring(woundType or "")
    if not record or record.alive == false or not part then
        return false, { outcome = "invalid_target" }
    end
    if not Internal.WoundStats[selectedType] then
        local types = Internal.DebugWoundTypes
        local roll = ZombRand and ZombRand(#types)
            or math.floor(math.random() * #types)
        selectedType =
            types[(tonumber(roll) or 0) + 1] or "scratch"
    end
    local hitAt = Core.Now()
    local wound, defaultDamage = Internal.AddWound(
        record,
        part,
        selectedType,
        hitAt,
        amount
    )
    local appliedDamage = math.max(
        0.1,
        tonumber(amount) or tonumber(defaultDamage) or 4
    )
    PNC.Health.ApplyDamage(record, npcBody, {
        amount = appliedDamage,
        partId = part.id,
        type = "debug_" .. selectedType,
        attackerKind = "debug",
    })
    if record.alive ~= false and type(Internal.NotifyWoundCallout) == "function" then
        Internal.NotifyWoundCallout(record, part.id, wound, appliedDamage, hitAt, {
            woundType = wound and wound.type or selectedType,
            attackerKind = selectedType == "bite" and "zombie" or "debug",
            provenance = "debug",
        })
    end
    record.runtime = record.runtime or {}
    record.runtime.forceSyncEvent = "debug_wound"
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "wounds")
    end
    return true, {
        outcome = "wounded",
        partId = part.id,
        woundType = wound.type,
        damage = appliedDamage,
        infected = Wounds.HasActiveInfection(record),
    }
end

function Wounds.ApplyDebugInfection(
    record,
    npcBody,
    partId,
    stage
)
    if not hasAuthority() then
        if Internal.LogInfectionDebug then
            Internal.LogInfectionDebug(
                record, "debug_apply", "rejected", "not_authority"
            )
        end
        return false, "not_authority"
    end
    local selectedPartId = partId
        and tostring(partId)
        or Wounds.ChoosePartId()
    local progressByStage = {
        incubating = 0.05,
        queasy = 0.30,
        nauseous = 0.55,
        fever = 0.72,
        terminal = 0.92,
    }
    local requestedStage = tostring(stage or "incubating")
    local progress = progressByStage[requestedStage]
        or progressByStage.incubating
    if not record
        or record.alive == false
        or not Wounds.Parts[selectedPartId]
    then
        if Internal.LogInfectionDebug then
            Internal.LogInfectionDebug(
                record, "debug_apply", "rejected", "invalid_target"
            )
        end
        return false, "invalid_target"
    end
    local body = Wounds.Ensure(record)
    if not body.wounds[selectedPartId] then
        local woundApplied, woundResult =
            Wounds.ApplyDebugWound(
                record,
                npcBody,
                selectedPartId,
                "bite"
            )
        if not woundApplied then return false, woundResult end
        if record.alive == false then
            local deathInfection = body.infection
            return deathInfection
                    and deathInfection.fatal == true,
                deathInfection
                    and deathInfection.stage
                    or "target_died"
        end
    end
    if not Wounds.HasActiveInfection(record) then
        Wounds.ForceInfection(record, selectedPartId)
    end
    local infection = body.infection
    if not infection or infection.active ~= true then
        if Internal.LogInfectionDebug then
            Internal.LogInfectionDebug(
                record, "debug_apply", "rejected", "infection_unavailable"
            )
        end
        return false, "infection_unavailable"
    end
    local currentHour = Internal.WorldHour()
    local mortality = Settings.NPCInfectionMortalityHours()
    infection.sourcePart = selectedPartId
    infection.infectedAtWorldHour =
        currentHour - mortality * progress
    infection.fatalAtWorldHour =
        currentHour + mortality * (1 - progress)
    infection.pendingFatal = false
    infection.lastDamageWorldHour = infection.infectedAtWorldHour
    Internal.RefreshInfectionState(record, currentHour, true)
    if requestedStage == "fatal" then
        local killed, reason = Wounds.TriggerInfectionDeath(
            record,
            npcBody,
            "debug_zombie_infection"
        )
        if not killed
            and reason ~= "awaiting_live_body"
        then
            return false, reason
        end
    end
    record.runtime = record.runtime or {}
    record.runtime.forceSyncEvent =
        "debug_infection_" .. tostring(infection.stage)
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "infection")
    end
    if Internal.LogInfectionDebug then
        Internal.LogInfectionDebug(
            record,
            "debug_apply",
            "applied",
            "debug_stage_set",
            infection.stage,
            infection.progress,
            infection.fever
        )
    end
    return true, infection.stage
end

function Wounds.ApplyDebugWoundState(record, npcBody, partId, stateAction)
    if not hasAuthority() then
        return false, "not_authority"
    end
    if not record or record.alive == false then
        return false, "invalid_target"
    end
    local action = string.lower(tostring(stateAction or ""))
    if action == "heal_all" then
        if PNC.Health and PNC.Health.Recover then
            PNC.Health.Recover(record, npcBody)
            return true, "healed"
        end
        return false, "health_unavailable"
    end
    if action == "incapacitate" then
        if PNC.Health and PNC.Health.EnterIncapacitated then
            PNC.Health.EnterIncapacitated(record, npcBody, "debug_incapacitate")
            return true, "incapacitated"
        end
        record.health = record.health or {}
        record.health.state = "incapacitated"
        record.health.incapacitatedReason = "debug_incapacitate"
        return true, "incapacitated"
    end

    local body = Wounds.Ensure(record)
    local targetPartId = partId and Wounds.Parts[tostring(partId)]
        and tostring(partId) or nil
    if not targetPartId then
        for existingPartId in pairs(body.wounds or {}) do
            targetPartId = existingPartId
            break
        end
        targetPartId = targetPartId or Wounds.ChoosePartId()
    end
    local part = Wounds.Parts[targetPartId]
    if not part then return false, "invalid_part" end
    local wound = body.wounds and body.wounds[targetPartId] or nil

    if action == "clear_part_wound" then
        if not wound then return false, "no_wound" end
        body.wounds[targetPartId] = nil
    elseif action == "dirty_bandage" then
        if not wound then
            wound = Internal.AddWound(record, part, "scratch", Core.Now())
        end
        wound.bandaged = true
        wound.bandageDirty = true
        wound.dirtyAtWorldHour = Internal.WorldHour()
        wound.bandageType = wound.bandageType or "Base.Bandage"
    elseif action == "toggle_stitched" then
        if not wound then
            wound = Internal.AddWound(record, part, "deep_wound", Core.Now())
        end
        wound.stitched = not (wound.stitched == true)
        if wound.stitched then
            wound.bandaged = false
            wound.bleedingRate = 0
        end
    elseif action == "toggle_splint" then
        if not wound then
            wound = Internal.AddWound(record, part, "fracture", Core.Now())
        end
        wound.splinted = not (wound.splinted == true)
        if wound.splinted then
            wound.splintType = wound.splintType or "Base.Splint"
        end
    elseif action == "toggle_ordinary_infection" then
        if not wound then
            wound = Internal.AddWound(record, part, "scratch", Core.Now())
        end
        local infected = not (wound.infected == true or wound.ordinaryInfected == true)
        wound.infected = infected
        wound.ordinaryInfected = infected
        wound.woundInfectionLevel = infected and 10 or 0
    elseif action == "toggle_bleeding" then
        if not wound then
            wound = Internal.AddWound(record, part, "laceration", Core.Now())
        end
        local bleeding = (tonumber(wound.bleedingRate) or 0) <= 0
        wound.bleedingRate = bleeding and 0.065 or 0
        if bleeding then wound.bandaged = false end
    else
        return false, "unknown_state_action"
    end

    if Internal.RefreshBodySummary then Internal.RefreshBodySummary(record) end
    record.runtime = record.runtime or {}
    record.runtime.forceSyncEvent = "debug_wound_state"
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "wounds")
    end
    return true, action
end

return Wounds
