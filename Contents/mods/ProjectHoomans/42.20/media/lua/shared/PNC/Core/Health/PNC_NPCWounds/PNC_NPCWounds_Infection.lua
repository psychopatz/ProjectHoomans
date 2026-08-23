PNC = PNC or {}
local Wounds = PNC.NPCWounds
local Internal = Wounds.Internal
local Core = PNC.Core
local Settings = PNC.Sandbox

local function infectionStage(progress)
    if progress < 0.20 then return "incubating" end
    if progress < 0.45 then return "queasy" end
    if progress < 0.65 then return "nauseous" end
    if progress < 0.85 then return "fever" end
    return "terminal"
end

function Internal.RefreshInfectionState(
    record,
    currentHour,
    applyDecline
)
    local body = Wounds.Ensure(record)
    local infection = body.infection
    local health = record and record.health or nil
    if not infection or infection.active ~= true then return false end
    local infectedAt =
        tonumber(infection.infectedAtWorldHour) or currentHour
    local fatalAt = tonumber(infection.fatalAtWorldHour)
        or (infectedAt + Settings.NPCInfectionMortalityHours())
    local duration = math.max(0.01, fatalAt - infectedAt)
    local progress = Core.Clamp(
        (currentHour - infectedAt) / duration, 0, 1
    )
    local fever = Core.Clamp(
        (progress - 0.45) / 0.45, 0, 1
    ) * 100
    local stage = infectionStage(progress)
    local priorStage = infection.stage
    local changed =
        math.abs((tonumber(infection.progress) or -1) - progress)
            >= 0.001
        or math.abs((tonumber(infection.fever) or -1) - fever)
            >= 0.1
        or priorStage ~= stage
    infection.progress = progress
    infection.stage = stage
    infection.fever = fever
    infection.temperatureC = 37 + fever / 100 * 3.5
    infection.lastUpdatedWorldHour = currentHour
    if applyDecline ~= false and health and progress > 0.65 then
        local decline = Core.Clamp(
            (progress - 0.65) / 0.35, 0, 1
        )
        local targetHealth = math.max(
            (tonumber(health.max) or 100) * 0.05,
            (tonumber(health.max) or 100)
                * (1 - decline * 0.95)
        )
        if (tonumber(health.current) or 0) > targetHealth + 0.01 then
            Wounds.ApplyBodyDamage(
                record,
                health.current - targetHealth
            )
            changed = true
        end
    end
    if priorStage ~= stage then
        record.runtime = record.runtime or {}
        record.runtime.forceSyncEvent = "infection_" .. stage
    end
    return changed
end

function Wounds.HasActiveInfection(record)
    local body = record and record.health
        and record.health.body or nil
    local infection = body and body.infection or nil
    return infection
        and infection.active == true
        and infection.fatal ~= true
        or false
end

function Internal.Infect(record, partId, nowHour, force)
    local body = Wounds.Ensure(record)
    local chance = Settings.NPCZombieInfectionChance()
    if body.infection
        and (
            body.infection.active == true
            or body.infection.fatal == true
        )
    then
        return false, "already_infected"
    end
    if force ~= true then
        if chance <= 0 then return false, "disabled" end
        if Internal.RandomPercent() >= chance then
            return false, "roll_failed"
        end
    end
    body.infection = {
        active = true,
        fatal = false,
        pendingFatal = false,
        sourcePart = partId,
        infectedAtWorldHour = nowHour,
        fatalAtWorldHour =
            nowHour + Settings.NPCInfectionMortalityHours(),
        reanimateAtWorldHour = 0,
        progress = 0,
        stage = "incubating",
        fever = 0,
        temperatureC = 37,
        lastUpdatedWorldHour = nowHour,
    }
    return true, "infected"
end

function Wounds.ForceInfection(record, partId)
    local applied, reason = Internal.Infect(
        record,
        tostring(partId or Wounds.ChoosePartId()),
        Internal.WorldHour(),
        true
    )
    if applied and PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "infection")
    end
    return applied, reason
end

function Wounds.ClearInfection(record, source)
    if not record or record.alive == false then
        return false, "invalid_target"
    end
    local body = Wounds.Ensure(record)
    local infection = body.infection
    if not infection
        or (
            infection.active ~= true
            and infection.fatal ~= true
            and infection.pendingFatal ~= true
        )
    then
        return false, "not_infected"
    end
    body.infection = nil
    record.runtime = record.runtime or {}
    record.runtime.forceSyncEvent =
        tostring(source or "infection_cleared")
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "infection")
    end
    return true, "infection_cleared"
end

function Wounds.PrepareInfectionDeath(record)
    local body = Wounds.Ensure(record)
    local infection = body.infection
    if not infection or infection.active ~= true then return false end
    infection.active = false
    infection.fatal = true
    infection.progress = 1
    infection.stage = "fatal"
    infection.fever = 100
    infection.temperatureC = 40.5
    infection.fatalAtWorldHour =
        tonumber(infection.fatalAtWorldHour)
        or Internal.WorldHour()
    infection.reanimateAtWorldHour = Internal.WorldHour()
    return true
end

function Wounds.TriggerInfectionDeath(record, zombie, reason)
    local body = Wounds.Ensure(record)
    local infection = body.infection
    if not infection or infection.active ~= true then
        return false, "not_infected"
    end
    if not zombie then
        local newlyPending = infection.pendingFatal ~= true
        infection.pendingFatal = true
        Wounds.SetOverallHealth(
            record,
            math.max(1, tonumber(record.health.current) or 1)
        )
        record.health.current =
            math.max(1, tonumber(record.health.current) or 1)
        if newlyPending
            and PNC.Registry
            and PNC.Registry.MarkDirty
        then
            PNC.Registry.MarkDirty(record, "infection")
        end
        return false, "awaiting_live_body"
    end
    Wounds.PrepareInfectionDeath(record)
    PNC.Health.Kill(
        record,
        zombie,
        reason or "zombie_infection"
    )
    return true, "killed"
end

return Wounds
