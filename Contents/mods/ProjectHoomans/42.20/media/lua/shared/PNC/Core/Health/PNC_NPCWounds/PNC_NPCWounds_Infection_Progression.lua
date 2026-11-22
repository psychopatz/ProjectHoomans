PNC = PNC or {}
local Wounds = PNC.NPCWounds
local Internal = Wounds.Internal
local Core = PNC.Core
local Settings = PNC.Sandbox

local KNOX_FEVER_ID = "knox_fever"
local FEVER_ONSET_PROGRESS = 0.45
local FEVER_DAMAGE_PROGRESS = 0.90
local FEVER_DAMAGE_HEALTH_FRACTION = 0.95
local FAKE_RECOVERY_HOURS = 4.0

local function infectionStage(progress, nonLethal)
    if progress < 0.20 then return "incubating" end
    if progress < 0.45 then return "queasy" end
    if progress < 0.65 then return "nauseous" end
    if progress < 0.85 or nonLethal then return "fever" end
    return "terminal"
end

local function setKnoxFever(record, severity)
    local wholeBody = Wounds.WholeBody
    if wholeBody and wholeBody.SetSeverity then
        return wholeBody.SetSeverity(record, KNOX_FEVER_ID, severity)
    end
    return severity, false
end

Internal.SetKnoxFever = setKnoxFever

local function feverDamageHours(infection, currentHour, infectedAt, fatalAt)
    local duration = math.max(0.01, fatalAt - infectedAt)
    local damageStart = infectedAt + duration * FEVER_DAMAGE_PROGRESS
    local previousDamageHour = tonumber(infection.lastDamageWorldHour)
    if previousDamageHour == nil or previousDamageHour <= 0 then
        previousDamageHour = tonumber(infection.lastUpdatedWorldHour) or infectedAt
    end
    local fromHour = math.max(previousDamageHour, damageStart)
    local toHour = math.min(currentHour, fatalAt)
    return math.max(0, toHour - fromHour), toHour
end

local function applyKnoxFeverDamage(record, npcBody, health, infection, currentHour, infectedAt, fatalAt, applyDamage)
    if infection.nonLethalFever == true or applyDamage == false or not health or not PNC.Health or not PNC.Health.ApplyDamage then
        return false
    end
    local elapsed, processedUntil = feverDamageHours(infection, currentHour, infectedAt, fatalAt)
    if elapsed <= 0 then return false end
    local duration = math.max(0.01, fatalAt - infectedAt)
    local damageWindow = math.max(0.01, duration * (1 - FEVER_DAMAGE_PROGRESS))
    local damageRate = math.max(0, tonumber(health.max) or 100) * FEVER_DAMAGE_HEALTH_FRACTION / damageWindow
    local applied = false
    if damageRate > 0 then
        applied = PNC.Health.ApplyDamage(record, npcBody, {
            amount = elapsed * damageRate,
            type = "knox_fever",
            attackerKind = "environment",
        }) == true
    end
    infection.lastDamageWorldHour = processedUntil
    return applied or processedUntil > (tonumber(infection.lastUpdatedWorldHour) or 0)
end

local function updateFakeFeverRecovery(record, body, infection, currentHour, fatalAt)
    local recovery = Core.Clamp((currentHour - fatalAt) / FAKE_RECOVERY_HOURS, 0, 1)
    local fever = (1 - recovery) * 100
    local priorStage = infection.stage
    infection.fakePeakReached = true
    infection.progress = 1
    infection.stage = "recovering"
    infection.fever = fever
    infection.temperatureC = 37 + fever / 100 * 2.5
    infection.lastUpdatedWorldHour = currentHour
    setKnoxFever(record, fever / 100)
    if recovery >= 1 then
        body.infection = nil
        body.knoxExposureState = nil
        setKnoxFever(record, 0)
    end
    if Wounds.InvalidateProjection then Wounds.InvalidateProjection(record, "knox_fake_recovery") end
    if priorStage ~= infection.stage and Internal.Events and Internal.EventTypes and Internal.EventTypes.NPC_KNOX_STAGE_CHANGED then
        Internal.Events.emit(Internal.EventTypes.NPC_KNOX_STAGE_CHANGED, record, priorStage, infection.stage)
    end
    return true
end

function Internal.RefreshInfectionState(record, currentHour, applyDamage, npcBody)
    if not Core or type(Core.IsAuthority) ~= "function" or Core.IsAuthority() ~= true then
        return false, "not_authority"
    end
    local body = Wounds.Ensure(record)
    local infection = body.infection
    local health = record and record.health or nil
    if not infection or infection.active ~= true then return false end
    local infectedAt = tonumber(infection.infectedAtWorldHour) or currentHour
    local mortalityHours = (Settings and Settings.NPCInfectionMortalityHours) and Settings.NPCInfectionMortalityHours() or 48
    local fatalAt = tonumber(infection.fatalAtWorldHour) or (infectedAt + mortalityHours)
    if infection.nonLethalFever == true and currentHour >= fatalAt then
        return updateFakeFeverRecovery(record, body, infection, currentHour, fatalAt)
    end
    local duration = math.max(0.01, fatalAt - infectedAt)
    local calculatedProgress = Core.Clamp((currentHour - infectedAt) / duration, 0, 1)
    local progress = math.max(Core.Clamp(tonumber(infection.progress) or 0, 0, 1), calculatedProgress)
    local fever = Core.Clamp((progress - FEVER_ONSET_PROGRESS) / (FEVER_DAMAGE_PROGRESS - FEVER_ONSET_PROGRESS), 0, 1) * 100
    local stage = infectionStage(progress, infection.nonLethalFever == true)
    local priorStage = infection.stage
    local changed = math.abs((tonumber(infection.progress) or -1) - progress) >= 0.001
        or math.abs((tonumber(infection.fever) or -1) - fever) >= 0.1
        or priorStage ~= stage
    infection.progress = progress
    infection.stage = stage
    infection.fever = fever
    infection.temperatureC = 37 + fever / 100 * 3.5
    if stage ~= "incubating" then infection.knoxExposure = "confirmed" end
    local _, feverChanged = setKnoxFever(record, fever / 100)
    changed = changed or feverChanged
    local liveZombie = npcBody or (PNC.Registry and PNC.Registry.GetLiveZombie and PNC.Registry.GetLiveZombie(record.id) or nil)
    changed = applyKnoxFeverDamage(record, liveZombie, health, infection, currentHour, infectedAt, fatalAt, applyDamage) or changed
    infection.lastUpdatedWorldHour = currentHour
    if priorStage ~= stage then
        if Wounds.InvalidateProjection then Wounds.InvalidateProjection(record, "knox_stage_" .. stage) end
        record.runtime = record.runtime or {}
        record.runtime.forceSyncEvent = "infection_" .. stage
        if Internal.Events and Internal.EventTypes and Internal.EventTypes.NPC_KNOX_STAGE_CHANGED then
            Internal.Events.emit(Internal.EventTypes.NPC_KNOX_STAGE_CHANGED, record, priorStage, stage)
        end
        if Internal.LogInfectionDebug then
            Internal.LogInfectionDebug(record, "stage_transition", "updated", "stage_changed", stage, progress, fever)
        end
    end
    return changed
end

function Wounds.HasActiveInfection(record)
    local body = record and record.health and record.health.body or nil
    local inf = body and body.infection or nil
    return inf and inf.active == true and inf.fatal ~= true or false
end

return Wounds
