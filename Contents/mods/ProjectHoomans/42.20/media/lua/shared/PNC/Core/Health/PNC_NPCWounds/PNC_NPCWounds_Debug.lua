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
    local selectedType = tostring(woundType or "")
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
    local wound, defaultDamage = Internal.AddWound(
        record,
        part,
        selectedType,
        Core.Now(),
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

return Wounds
