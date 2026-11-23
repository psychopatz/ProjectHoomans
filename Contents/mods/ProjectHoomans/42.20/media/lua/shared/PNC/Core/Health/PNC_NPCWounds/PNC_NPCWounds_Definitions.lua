PNC = PNC or {}
PNC.NPCWounds = PNC.NPCWounds or {}
PNC.NPCWounds.Internal = PNC.NPCWounds.Internal or {}

require "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_PartCatalog"

local Wounds = PNC.NPCWounds
local Internal = Wounds.Internal
local Core = PNC.Core
local Settings = PNC.Sandbox

-- Physical trauma severity is independent from Knox transmission risk:
-- `priority` orders dominant wound selection; `physicalSeverityRank` measures acute trauma.
Internal.WoundStats = {
    scratch = { priority = 2, tier = "least", physicalSeverityRank = 1, damage = 4, bleedingRate = 0.018, canInfectOrdinary = true, canTransmitKnoxFromZombie = true },
    laceration = { priority = 3, tier = "moderate", physicalSeverityRank = 3, damage = 8, bleedingRate = 0.055, canInfectOrdinary = true, canTransmitKnoxFromZombie = true },
    burn = { priority = 4, tier = "severe", physicalSeverityRank = 3, damage = 9, bleedingRate = 0.020, burned = true, canInfectOrdinary = true, canTransmitKnoxFromZombie = false },
    fracture = { priority = 4, tier = "severe", physicalSeverityRank = 4, damage = 10, bleedingRate = 0.010, fractured = true, canInfectOrdinary = false, canTransmitKnoxFromZombie = false },
    deep_wound = { priority = 4, tier = "severe", physicalSeverityRank = 4, damage = 10, bleedingRate = 0.070, deepWounded = true, canInfectOrdinary = true, canTransmitKnoxFromZombie = false },
    deep_wound_glass = { priority = 4, tier = "severe", physicalSeverityRank = 4, damage = 11, bleedingRate = 0.075, deepWounded = true, haveGlass = true, canInfectOrdinary = true, canTransmitKnoxFromZombie = false },
    bullet = { priority = 5, tier = "critical", physicalSeverityRank = 5, damage = 14, bleedingRate = 0.095, haveBullet = true, canInfectOrdinary = true, canTransmitKnoxFromZombie = false },
    bite = { priority = 6, tier = "worst", physicalSeverityRank = 3, damage = 12, bleedingRate = 0.065, bitten = true, canInfectOrdinary = true, canTransmitKnoxFromZombie = true },
}
Internal.WoundAliases = {
    scratched = "scratch",
    cut = "laceration",
    bitten = "bite",
    glass = "deep_wound_glass",
    deepwound = "deep_wound",
    deep_wounded = "deep_wound",
    burned = "burn",
    fractured = "fracture",
    gunshot = "bullet",
}

function Wounds.NormalizeWoundType(rawType)
    local key = string.lower(tostring(rawType or ""))
    if key == "" then return nil end
    key = Internal.WoundAliases[key] or key
    return Internal.WoundStats[key] and key or nil
end

function Wounds.GetWoundStats(woundType)
    local normalized = Wounds.NormalizeWoundType(woundType)
    return normalized and Internal.WoundStats[normalized] or nil
end

Internal.DebugWoundTypes = { "scratch", "laceration", "bite" }
Internal.CoveragePartAliases = {
    UpperBody = "Torso_Upper",
    LowerBody = "Torso_Lower",
}
Internal.Events = require "PsychopatzCore/Events/PC_EventBus"
Internal.EventTypes = require "PNC/Core/Events/PNC_EventDefinitions"

function Internal.SettingNumber(name, fallback, minimum, maximum)
    local getter = Settings and Settings[name]
    local value = getter and getter() or fallback
    value = tonumber(value) or tonumber(fallback) or 0
    if minimum ~= nil then value = math.max(value, minimum) end
    if maximum ~= nil then value = math.min(value, maximum) end
    return value
end

function Internal.WorldHour()
    local gameTime = getGameTime and getGameTime() or nil
    if gameTime and gameTime.getWorldAgeHours then
        return tonumber(gameTime:getWorldAgeHours()) or 0
    end
    return (tonumber(Core.Now()) or 0) / 3600000
end

function Internal.RandomPercent()
    if ZombRand then return (tonumber(ZombRand(10000)) or 0) / 100 end
    return math.random() * 100
end

function Internal.ChoosePart()
    local total, part, roll = 0, nil, 0
    for i = 1, #Wounds.PartOrder do
        part = Wounds.Parts[Wounds.PartOrder[i]]
        total = total + (tonumber(part.weight) or 1)
    end
    roll = ZombRand and ZombRand(math.max(1, total)) or math.floor(math.random() * total)
    for i = 1, #Wounds.PartOrder do
        part = Wounds.Parts[Wounds.PartOrder[i]]
        roll = roll - (tonumber(part.weight) or 1)
        if roll < 0 then return part end
    end
    return Wounds.Parts.Torso_Upper
end

function Wounds.ChoosePartId()
    local part = Internal.ChoosePart()
    return part and part.id or "Torso_Upper"
end

return Wounds
