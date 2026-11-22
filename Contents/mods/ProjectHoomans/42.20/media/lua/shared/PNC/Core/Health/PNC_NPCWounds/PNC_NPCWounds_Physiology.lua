-- Lightweight Build 42-aligned thermoregulation, wetness, cold, fever, and sickness
-- shared between Live (`Wounds.Update`) and Abstract (`Needs.Update`) NPCs.
PNC = PNC or {}
local Env = require "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_PhysiologyEnv"
local Wounds = PNC.NPCWounds
local Internal = Wounds.Internal
local Core = PNC.Core

local function stepPhysiologyState(record, body, p, env, dt)
    local wetDelta = (not env.indoors and env.rainIntensity > 0.02)
        and (env.rainIntensity * (1 - env.clothingWaterRes * 0.65) * 42 * dt)
        or ((env.indoors and -25 or -12) * dt)
    p.wetness = Core.Clamp(p.wetness + wetDelta, 0, 100)
    local inf = type(body.infection) == "table" and body.infection or nil
    local knoxFever = (inf and inf.active == true) and (tonumber(inf.fever) or 0) or 0
    local totalOrd = 0
    for _, w in pairs(body.wounds or {}) do totalOrd = totalOrd + (tonumber(w.woundInfectionLevel) or 0) end
    local targetFever = math.max(knoxFever, totalOrd >= 2.0 and math.min(45, totalOrd * 4.5) or 0)
    local targetSick = math.max(knoxFever * 0.85, totalOrd >= 2.0 and math.min(35, totalOrd * 3.0) or 0)
    p.feverLevel = targetFever > p.feverLevel and targetFever or math.max(targetFever, p.feverLevel - 12 * dt)
    p.sicknessLevel = targetSick > p.sicknessLevel and targetSick or math.max(targetSick, p.sicknessLevel - 10 * dt)
    local effIns = env.clothingInsulation * (1 - (p.wetness / 100) * 0.75)
    local setPoint = 37.0 + (p.feverLevel / 100) * 2.0
    local coldDrag = math.max(0, 18.0 - env.ambientTempC) * (1 - effIns * 0.80) * (1 + (p.wetness / 100) * 0.90) * 0.14
    local heatPush = math.max(0, env.ambientTempC - 28.0) * (0.12 + effIns * 0.18 + env.exertion * 0.15)
    local coreTarget = Core.Clamp(setPoint - coldDrag + heatPush + env.exertion * 0.45, 28.0, 41.5)
    local skinTarget = Core.Clamp(env.ambientTempC + 10.0 + effIns * 8.0 - (p.wetness / 100) * 4.5, 16.0, 39.0)
    local alpha = math.min(1, dt * 0.65)
    p.coreTempC = Core.Clamp(p.coreTempC + (coreTarget - p.coreTempC) * alpha, 20, 42)
    p.skinTempC = Core.Clamp(p.skinTempC + (skinTarget - p.skinTempC) * alpha, 10, 42)
    if p.skinTempC < 33.0 and (not env.indoors or p.coreTempC < 36.2 or p.wetness >= 35) then
        local mult = Env.ColdTraitMultiplier(record) * (p.wetness >= 40 and 1.35 or 1.0)
        p.coldStrength = Core.Clamp(p.coldStrength + (33.0 - p.skinTempC) * 2.8 * mult * dt, 0, 100)
    elseif env.indoors and p.wetness < 15 and p.coreTempC >= 36.2 then
        p.coldStrength = Core.Clamp(p.coldStrength - 10 * dt, 0, 100)
    end
    p.hasCold = p.coldStrength >= 20
end

function Wounds.UpdatePhysiology(record, elapsedHours, envOverride)
    if type(record) ~= "table" or record.alive == false then return false end
    local body = Wounds.Ensure(record)
    local p = Wounds.EnsurePhysiology(record)
    local nowHour = Internal.WorldHour and Internal.WorldHour() or ((tonumber(Core.Now()) or 0) / 3600000)
    local dt = tonumber(elapsedHours)
    if dt == nil then
        if p.lastUpdateWorldHour == nil then p.lastUpdateWorldHour = nowHour; return false end
        dt = math.max(0, nowHour - (tonumber(p.lastUpdateWorldHour) or nowHour))
        if dt < 0.05 and envOverride == nil then return false end
        p.lastUpdateWorldHour = nowHour
    else
        dt = math.max(0, dt)
        p.lastUpdateWorldHour = nowHour
    end
    local env = Wounds.ResolveEnvironmentExposure(record, envOverride)
    if dt > 0 then stepPhysiologyState(record, body, p, env, dt) end
    if Wounds.WholeBody and Wounds.WholeBody.SetSeverity then
        Wounds.WholeBody.SetSeverity(record, "cold_illness", p.hasCold and Core.Clamp(p.coldStrength / 100, 0, 1) or 0)
        Wounds.WholeBody.SetSeverity(record, "hypothermia", p.coreTempC < 35.0 and Core.Clamp((35.0 - p.coreTempC) / 5.0, 0, 1) or 0)
        Wounds.WholeBody.SetSeverity(record, "hyperthermia", (p.coreTempC >= 38.8 and p.feverLevel < 25) and Core.Clamp((p.coreTempC - 38.5) / 2.5, 0, 1) or 0)
    end
    local bandChanges = Env.ComputeBandChanges(p)
    if bandChanges then
        if Wounds.InvalidateProjection then Wounds.InvalidateProjection(record, "physiology_band_changed") end
        if PNC.Registry and PNC.Registry.MarkDirty then PNC.Registry.MarkDirty(record, "physiology") end
        if Internal.Events and Internal.EventTypes and Internal.EventTypes.NPC_PHYSIOLOGY_BAND_CHANGED then
            Internal.Events.emit(Internal.EventTypes.NPC_PHYSIOLOGY_BAND_CHANGED, record, bandChanges, p)
        end
        return true, bandChanges
    end
    return false, nil
end

return Wounds
