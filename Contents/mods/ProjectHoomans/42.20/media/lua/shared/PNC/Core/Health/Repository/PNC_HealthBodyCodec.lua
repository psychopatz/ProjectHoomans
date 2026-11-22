-- Health-owned body schema normalization; no lifecycle or engine authority.
local Codec = require "PNC/Core/Base/PNC_RecordCodec"
local WoundCodec = require "PNC/Core/Health/Repository/PNC_HealthWoundCodec"
local Internal = { normalizeString = Codec.normalizeString, normalizeNumber = Codec.normalizeNumber }
local Core = PNC.Core

Internal.HEALTH_PART_IDS = {
    "Head", "Neck", "Torso_Upper", "Torso_Lower", "Groin",
    "UpperArm_L", "UpperArm_R", "ForeArm_L", "ForeArm_R",
    "Hand_L", "Hand_R", "UpperLeg_L", "UpperLeg_R",
    "LowerLeg_L", "LowerLeg_R", "Foot_L", "Foot_R",
}

local function normalizePart(partHealth)
    local num = Internal.normalizeNumber
    if type(partHealth) == "number" then
        return { current = Core.Clamp(num(partHealth, 100), 0, 100), max = 100 }
    end
    if type(partHealth) ~= "table" then return nil end
    local maximum = math.max(1, num(partHealth.max or partHealth.m, 100))
    return { current = Core.Clamp(num(partHealth.current or partHealth.c, maximum), 0, maximum), max = maximum }
end

local function normalizeAilments(rawAilments)
    local result = {}
    for ailmentID, ailment in pairs(type(rawAilments) == "table" and rawAilments or {}) do
        local severity = type(ailment) == "table" and tonumber(ailment.severity) or tonumber(ailment)
        if severity and severity > 1 then severity = severity / 1000 end
        if severity and severity > 0 then
            result[tostring(ailmentID)] = { severity = Core.Clamp(severity, 0, 1) }
        elseif type(ailment) == "table" and ailment.active == true and ailment.flavorOnly == true then
            result[tostring(ailmentID)] = { active = true, flavorOnly = true }
        end
    end
    return result
end

function Internal.sanitizeHealthBody(rawBody)
    local source = type(rawBody) == "table" and rawBody or {}
    local wounds, parts = {}, {}
    local bleedingRate, openWoundCount, bandagedWoundCount = 0, 0, 0
    for partId, wound in pairs(type(source.wounds) == "table" and source.wounds or {}) do
        if type(wound) == "table" then
            local entry = WoundCodec.sanitizeWound(partId, wound)
            wounds[entry.partId] = entry
            if entry.bandaged then bandagedWoundCount = bandagedWoundCount + 1
            else openWoundCount = openWoundCount + 1; bleedingRate = bleedingRate + entry.bleedingRate end
        end
    end
    local normalizedBase = source.partBase ~= nil and normalizePart(source.partBase) or nil
    if normalizedBase then
        for i = 1, #Internal.HEALTH_PART_IDS do
            parts[Internal.HEALTH_PART_IDS[i]] = { current = normalizedBase.current, max = normalizedBase.max }
        end
    end
    for partId, partHealth in pairs(type(source.parts) == "table" and source.parts or {}) do
        local normalized = normalizePart(partHealth)
        if normalized then parts[tostring(partId)] = normalized end
    end
    local totalPartHealth, totalPartMax, partCount = 0, 0, 0
    for _, partHealth in pairs(parts) do
        totalPartHealth = totalPartHealth + math.max(0, tonumber(partHealth.current) or 0)
        totalPartMax = totalPartMax + math.max(1, tonumber(partHealth.max) or 100)
        partCount = partCount + 1
    end
    return {
        wounds = wounds,
        parts = parts,
        infection = WoundCodec.sanitizeInfection(source.infection),
        physiology = WoundCodec.sanitizePhysiology(source.physiology),
        knoxExposureState = Internal.normalizeString(source.knoxExposureState),
        wholeBodyAilments = normalizeAilments(source.wholeBodyAilments),
        totalPartHealth = partCount > 0 and totalPartHealth or math.max(0, Internal.normalizeNumber(source.totalPartHealth, 0)),
        totalPartMax = partCount > 0 and totalPartMax or math.max(0, Internal.normalizeNumber(source.totalPartMax, 0)),
        overallPercent = partCount > 0 and Core.Clamp(totalPartMax > 0 and totalPartHealth / totalPartMax * 100 or 0, 0, 100)
            or Core.Clamp(Internal.normalizeNumber(source.overallPercent, 100), 0, 100),
        bleedingRate = bleedingRate,
        openWoundCount = openWoundCount,
        bandagedWoundCount = bandagedWoundCount,
        lastBleedAt = 0,
    }
end

return Internal
