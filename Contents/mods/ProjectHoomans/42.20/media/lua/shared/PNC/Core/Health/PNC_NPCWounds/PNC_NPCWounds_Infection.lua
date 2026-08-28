PNC = PNC or {}
local Wounds = PNC.NPCWounds
local Internal = Wounds.Internal
local Core = PNC.Core
local Settings = PNC.Sandbox

local KNOX_FEVER_ID = "knox_fever"
local FEVER_ONSET_PROGRESS = 0.45
local FEVER_DAMAGE_PROGRESS = 0.90
local FEVER_DAMAGE_HEALTH_FRACTION = 0.95

local function infectionStage(progress)
    if progress < 0.20 then return "incubating" end
    if progress < 0.45 then return "queasy" end
    if progress < 0.65 then return "nauseous" end
    if progress < 0.85 then return "fever" end
    return "terminal"
end

local function setKnoxFever(record, severity)
    local wholeBody = Wounds.WholeBody
    if wholeBody and wholeBody.SetSeverity then
        return wholeBody.SetSeverity(record, KNOX_FEVER_ID, severity)
    end
    return severity, false
end

local function feverDamageHours(infection, currentHour, infectedAt, fatalAt)
    local duration = math.max(0.01, fatalAt - infectedAt)
    local damageStart = infectedAt
        + duration * FEVER_DAMAGE_PROGRESS
    local previousDamageHour = tonumber(infection.lastDamageWorldHour)
    if previousDamageHour == nil or previousDamageHour <= 0 then
        previousDamageHour = tonumber(infection.lastUpdatedWorldHour)
            or infectedAt
    end
    local fromHour = math.max(previousDamageHour, damageStart)
    local toHour = math.min(currentHour, fatalAt)
    return math.max(0, toHour - fromHour), toHour
end

local function applyKnoxFeverDamage(
    record,
    npcBody,
    health,
    infection,
    currentHour,
    infectedAt,
    fatalAt,
    applyDamage
)
    if applyDamage == false or not health or not PNC.Health
        or not PNC.Health.ApplyDamage
    then
        return false
    end
    local elapsed, processedUntil = feverDamageHours(
        infection, currentHour, infectedAt, fatalAt
    )
    if elapsed <= 0 then return false end
    local duration = math.max(0.01, fatalAt - infectedAt)
    local damageWindow = math.max(
        0.01, duration * (1 - FEVER_DAMAGE_PROGRESS)
    )
    local damageRate = math.max(0, tonumber(health.max) or 100)
        * FEVER_DAMAGE_HEALTH_FRACTION / damageWindow
    local applied = false
    if damageRate > 0 then
        applied = PNC.Health.ApplyDamage(record, npcBody, {
            amount = elapsed * damageRate,
            type = "knox_fever",
            attackerKind = "environment",
        }) == true
    end
    infection.lastDamageWorldHour = processedUntil
    return applied or processedUntil > (
        tonumber(infection.lastUpdatedWorldHour) or 0
    )
end

function Internal.RefreshInfectionState(
    record,
    currentHour,
    applyDamage,
    npcBody
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
    local calculatedProgress = Core.Clamp(
        (currentHour - infectedAt) / duration, 0, 1
    )
    local progress = math.max(
        Core.Clamp(tonumber(infection.progress) or 0, 0, 1),
        calculatedProgress
    )
    local fever = Core.Clamp(
        (progress - FEVER_ONSET_PROGRESS)
            / (FEVER_DAMAGE_PROGRESS - FEVER_ONSET_PROGRESS),
        0, 1
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
    local _, feverChanged = setKnoxFever(record, fever / 100)
    changed = changed or feverChanged
    changed = applyKnoxFeverDamage(
        record,
        npcBody or PNC.Registry and PNC.Registry.GetLiveZombie
            and PNC.Registry.GetLiveZombie(record.id) or nil,
        health,
        infection,
        currentHour,
        infectedAt,
        fatalAt,
        applyDamage
    ) or changed
    infection.lastUpdatedWorldHour = currentHour
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
        lastDamageWorldHour = nowHour,
    }
    setKnoxFever(record, 0)
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
    setKnoxFever(record, 0)
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
    setKnoxFever(record, 1)
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
