-- Environment exposure, trait vulnerability multipliers, and default state initialization
-- for Build 42-aligned cold/wetness/fever/thermoregulation physiology.
PNC = PNC or {}
local Wounds = PNC.NPCWounds
local Core = PNC.Core
local Env = {}

local function hasTraitNamed(record, target)
    local lower = string.lower(target)
    if PNC.PlayerNeedsModel and type(PNC.PlayerNeedsModel.HasTrait) == "function" then
        if PNC.PlayerNeedsModel.HasTrait(record, target) then return true end
    end
    for _, bag in pairs({ record and record.vanillaTraits, record and record.traits, record and record.dynamicTraits }) do
        if type(bag) == "table" then
            if bag[target] == true or bag[lower] == true then return true end
            for _, v in pairs(bag) do
                if type(v) == "string" and string.lower(v) == lower then return true end
            end
        end
    end
    return false
end

function Env.ColdTraitMultiplier(record)
    local mult = 1.0
    if hasTraitNamed(record, "ProneToIllness") then mult = mult * 1.7 end
    if hasTraitNamed(record, "Resilient") then mult = mult * 0.45 end
    if hasTraitNamed(record, "Outdoorsman") then mult = mult * 0.25 end
    return mult
end

function Wounds.EnsurePhysiology(record)
    local body = Wounds.Ensure(record)
    if type(body.physiology) ~= "table" then
        body.physiology = {
            coreTempC = 37.0, skinTempC = 33.0, wetness = 0, coldStrength = 0,
            hasCold = false, feverLevel = 0, sicknessLevel = 0,
            thermalBand = "normal", wetnessBand = "dry", coldBand = "none",
            feverBand = "none", sicknessBand = "none",
        }
    end
    local p = body.physiology
    p.coreTempC = tonumber(p.coreTempC) or 37.0
    p.skinTempC = tonumber(p.skinTempC) or 33.0
    p.wetness = tonumber(p.wetness) or 0
    p.coldStrength = tonumber(p.coldStrength) or 0
    p.hasCold = p.hasCold == true
    p.feverLevel = tonumber(p.feverLevel) or 0
    p.sicknessLevel = tonumber(p.sicknessLevel) or 0
    p.thermalBand = tostring(p.thermalBand or "normal")
    p.wetnessBand = tostring(p.wetnessBand or "dry")
    p.coldBand = tostring(p.coldBand or "none")
    p.feverBand = tostring(p.feverBand or "none")
    p.sicknessBand = tostring(p.sicknessBand or "none")
    return p
end

function Wounds.ResolveEnvironmentExposure(record, envOverride)
    local env = type(envOverride) == "table" and envOverride or {}
    local indoors = env.indoors
    if indoors == nil then
        local live = PNC.Registry and PNC.Registry.GetLiveZombie and PNC.Registry.GetLiveZombie(record.id) or nil
        local sq = live and live.getCurrentSquare and live:getCurrentSquare() or nil
        if sq and sq.getRoom then indoors = sq:getRoom() ~= nil end
    end
    if indoors == nil then indoors = record and record.sheltered == true or false end
    local cm = getClimateManager and getClimateManager() or nil
    local ambientTemp = tonumber(env.ambientTempC) or (cm and cm.getTemperature and tonumber(cm:getTemperature())) or 18.0
    local rain = tonumber(env.rainIntensity) or (cm and cm.getRainIntensity and tonumber(cm:getRainIntensity())) or 0.0
    if indoors then ambientTemp = math.max(ambientTemp, 14.0); rain = 0 end
    local ins = tonumber(env.clothingInsulation) or 0.45
    local waterRes = tonumber(env.clothingWaterRes) or 0.30
    local exertion = tonumber(env.exertion) or 0.15
    return {
        indoors = indoors == true,
        ambientTempC = ambientTemp,
        rainIntensity = Core.Clamp(rain, 0, 1),
        clothingInsulation = Core.Clamp(ins, 0, 1),
        clothingWaterRes = Core.Clamp(waterRes, 0, 1),
        exertion = Core.Clamp(exertion, 0, 1),
    }
end

local function resolveBandThermal(coreTempC, feverLevel)
    if coreTempC < 35.0 then return "hypothermic" end
    if coreTempC < 36.2 then return "chilled" end
    if coreTempC >= 38.8 and (feverLevel or 0) < 25 then return "hyperthermic" end
    if coreTempC >= 39.5 then return "hyperthermic" end
    if coreTempC >= 37.8 then return "warm" end
    return "normal"
end

local function band3(val, t1, t2, t3, b0, b1, b2, b3)
    if val >= t3 then return b3 end
    if val >= t2 then return b2 end
    if val >= t1 then return b1 end
    return b0
end

function Env.ComputeBandChanges(p)
    local prev = { p.thermalBand, p.wetnessBand, p.coldBand, p.feverBand, p.sicknessBand }
    p.thermalBand = resolveBandThermal(p.coreTempC, p.feverLevel)
    p.wetnessBand = band3(p.wetness, 15, 45, 75, "dry", "damp", "wet", "soaked")
    p.coldBand = band3(p.coldStrength, 20, 45, 75, "none", "sniffles", "moderately_ill", "nasty_cold")
    p.feverBand = band3(p.feverLevel, 15, 45, 75, "none", "low_grade", "feverish", "high_fever")
    p.sicknessBand = band3(p.sicknessLevel, 20, 45, 75, "none", "queasy", "nauseous", "severely_sick")
    local changed, any = {}, false
    local names = { "thermalBand", "wetnessBand", "coldBand", "feverBand", "sicknessBand" }
    for i = 1, 5 do
        if prev[i] ~= p[names[i]] then
            changed[names[i]] = { from = prev[i], to = p[names[i]] }
            any = true
        end
    end
    return any and changed or nil
end

Wounds.Internal = Wounds.Internal or {}
Wounds.Internal.PhysiologyEnv = Env
return Env
