-- Shared health wound, infection, and physiology record codec helpers.
local Codec = require "PNC/Core/Base/PNC_RecordCodec"
local Core = PNC.Core

local Helper = {}
local num = Codec.normalizeNumber
local str = Codec.normalizeString

local WOUND_BOOLS = { "bandaged", "stitched", "splinted", "cauterized", "haveGlass", "haveBullet", "infectedWound", "bandageDirty", "sterileDressing", "dressingLifeTracked", "dressingHealed", "virtualDressing", "zombieWound" }
local WOUND_POS_NUMS = { "alcoholLevel", "bandageLife", "splintFactor", "createdAt", "bandagedAt", "dirtyAtWorldHour", "lastHealWorldHour", "healAtWorldHour" }
local INF_BOOLS = { "active", "fatal", "pendingFatal", "nonLethalFever", "fakePeakReached" }
local INF_NUMS = { "infectedAtWorldHour", "fatalAtWorldHour", "reanimateAtWorldHour", "progress", "fever", "lastUpdatedWorldHour", "lastDamageWorldHour" }
local PHYS_BANDS = { thermalBand = "normal", wetnessBand = "dry", coldBand = "none", feverBand = "none", sicknessBand = "none" }
local PHYS_NUMS = { "wetness", "coldStrength", "feverLevel", "sicknessLevel", "lastUpdateWorldHour" }

function Helper.sanitizeWound(partId, wound)
    local out = {
        partId = tostring(wound.partId or partId),
        type = tostring(wound.type or "scratch"),
        severity = math.max(0, num(wound.severity, 0)),
        damage = math.max(0, num(wound.damage, wound.severity or 0)),
        bleedingRate = math.max(0, num(wound.bleedingRate, 0)),
        woundInfectionLevel = Core.Clamp(num(wound.woundInfectionLevel, 0), 0, 10),
        bandageType = str(wound.bandageType),
        spentBandageType = str(wound.spentBandageType),
        splintItem = str(wound.splintItem),
        splintType = str(wound.splintType),
    }
    for i = 1, #WOUND_BOOLS do local k = WOUND_BOOLS[i]; out[k] = wound[k] == true end
    for i = 1, #WOUND_POS_NUMS do local k = WOUND_POS_NUMS[i]; out[k] = math.max(0, num(wound[k], 0)) end
    if wound.dressingLifeTracked and not wound.dirtyAtWorldHour then out.dirtyAtWorldHour = nil end
    if wound.lastFractureHealHour ~= nil then out.lastFractureHealHour = num(wound.lastFractureHealHour, 0) end
    return out
end

function Helper.sanitizeInfection(inf)
    if type(inf) ~= "table" then return nil end
    local out = {
        sourcePart = str(inf.sourcePart),
        sourceWoundType = str(inf.sourceWoundType),
        knoxExposure = str(inf.knoxExposure),
        stage = tostring(inf.stage or "incubating"),
        temperatureC = Core.Clamp(num(inf.temperatureC, 37), 30, 45),
    }
    for i = 1, #INF_BOOLS do local k = INF_BOOLS[i]; out[k] = inf[k] == true end
    for i = 1, #INF_NUMS do local k = INF_NUMS[i]; out[k] = num(inf[k], 0) end
    out.progress = Core.Clamp(out.progress, 0, 1)
    out.fever = Core.Clamp(out.fever, 0, 100)
    return out
end

function Helper.sanitizePhysiology(raw)
    if type(raw) ~= "table" then return nil end
    local out = {
        coreTempC = Core.Clamp(num(raw.coreTempC, 37.0), 20, 42),
        skinTempC = Core.Clamp(num(raw.skinTempC, 33.0), 10, 42),
        hasCold = raw.hasCold == true,
        wetness = Core.Clamp(num(raw.wetness, 0), 0, 100),
        coldStrength = Core.Clamp(num(raw.coldStrength, 0), 0, 100),
        feverLevel = Core.Clamp(num(raw.feverLevel, 0), 0, 100),
        sicknessLevel = Core.Clamp(num(raw.sicknessLevel, 0), 0, 100),
        lastUpdateWorldHour = num(raw.lastUpdateWorldHour, 0),
    }
    for band, default in pairs(PHYS_BANDS) do out[band] = tostring(raw[band] or default) end
    return out
end

function Helper.compactWound(w)
    local out = {
        type = w.type ~= "scratch" and w.type or nil,
        severity = w.severity > 0 and w.severity or nil,
        damage = w.damage ~= w.severity and w.damage or nil,
        bleedingRate = w.bleedingRate > 0 and w.bleedingRate or nil,
        woundInfectionLevel = w.woundInfectionLevel > 0 and w.woundInfectionLevel or nil,
        bandageType = w.bandageType,
        spentBandageType = w.spentBandageType,
        splintItem = w.splintItem,
        splintType = w.splintType,
    }
    out.lastFractureHealHour = w.lastFractureHealHour
    for i = 1, #WOUND_BOOLS do local k = WOUND_BOOLS[i]; out[k] = w[k] == true or nil end
    for i = 1, #WOUND_POS_NUMS do local k = WOUND_POS_NUMS[i]; out[k] = (w[k] or 0) > 0 and w[k] or nil end
    return out
end

function Helper.compactInfection(inf)
    if not inf then return nil end
    local out = {
        sourcePart = inf.sourcePart,
        sourceWoundType = inf.sourceWoundType,
        knoxExposure = inf.knoxExposure,
        stage = inf.stage ~= "incubating" and inf.stage or nil,
        temperatureC = inf.temperatureC ~= 37 and inf.temperatureC or nil,
    }
    for i = 1, #INF_BOOLS do local k = INF_BOOLS[i]; out[k] = inf[k] == true or nil end
    for i = 1, #INF_NUMS do local k = INF_NUMS[i]; out[k] = (inf[k] or 0) ~= 0 and inf[k] or nil end
    return out
end

function Helper.compactPhysiology(phys)
    if not phys then return nil end
    local out = {
        coreTempC = math.abs((phys.coreTempC or 37) - 37) >= 0.05 and phys.coreTempC or nil,
        skinTempC = math.abs((phys.skinTempC or 33) - 33) >= 0.05 and phys.skinTempC or nil,
        hasCold = phys.hasCold == true or nil,
    }
    for i = 1, #PHYS_NUMS do local k = PHYS_NUMS[i]; out[k] = (phys[k] or 0) > 0 and phys[k] or nil end
    for band, default in pairs(PHYS_BANDS) do out[band] = phys[band] ~= default and phys[band] or nil end
    return Codec.hasTableEntries(out) and out or nil
end

return Helper
