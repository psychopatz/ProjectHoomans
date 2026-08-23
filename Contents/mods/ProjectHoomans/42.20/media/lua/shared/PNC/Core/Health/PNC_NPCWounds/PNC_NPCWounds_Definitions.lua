PNC = PNC or {}
PNC.NPCWounds = PNC.NPCWounds or {}
PNC.NPCWounds.Internal = PNC.NPCWounds.Internal or {}

local Wounds = PNC.NPCWounds
local Internal = Wounds.Internal
local Core = PNC.Core
local Settings = PNC.Sandbox

Wounds.Parts = {
    Head = { id = "Head", label = "Head", engine = "Head", x = 0.50, y = 0.08, weight = 5 },
    Neck = { id = "Neck", label = "Neck", engine = "Neck", x = 0.50, y = 0.16, weight = 3 },
    Torso_Upper = { id = "Torso_Upper", label = "Upper Torso", engine = "Torso_Upper", x = 0.50, y = 0.28, weight = 18 },
    Torso_Lower = { id = "Torso_Lower", label = "Lower Torso", engine = "Torso_Lower", x = 0.50, y = 0.42, weight = 14 },
    Groin = { id = "Groin", label = "Groin", engine = "Groin", x = 0.50, y = 0.51, weight = 5 },
    UpperArm_L = { id = "UpperArm_L", label = "Left Upper Arm", engine = "UpperArm_L", x = 0.24, y = 0.30, weight = 6 },
    UpperArm_R = { id = "UpperArm_R", label = "Right Upper Arm", engine = "UpperArm_R", x = 0.76, y = 0.30, weight = 6 },
    ForeArm_L = { id = "ForeArm_L", label = "Left Forearm", engine = "ForeArm_L", x = 0.15, y = 0.45, weight = 5 },
    ForeArm_R = { id = "ForeArm_R", label = "Right Forearm", engine = "ForeArm_R", x = 0.85, y = 0.45, weight = 5 },
    Hand_L = { id = "Hand_L", label = "Left Hand", engine = "Hand_L", x = 0.09, y = 0.58, weight = 3 },
    Hand_R = { id = "Hand_R", label = "Right Hand", engine = "Hand_R", x = 0.91, y = 0.58, weight = 3 },
    UpperLeg_L = { id = "UpperLeg_L", label = "Left Thigh", engine = "UpperLeg_L", x = 0.39, y = 0.62, weight = 8 },
    UpperLeg_R = { id = "UpperLeg_R", label = "Right Thigh", engine = "UpperLeg_R", x = 0.61, y = 0.62, weight = 8 },
    LowerLeg_L = { id = "LowerLeg_L", label = "Left Shin", engine = "LowerLeg_L", x = 0.39, y = 0.80, weight = 6 },
    LowerLeg_R = { id = "LowerLeg_R", label = "Right Shin", engine = "LowerLeg_R", x = 0.61, y = 0.80, weight = 6 },
    Foot_L = { id = "Foot_L", label = "Left Foot", engine = "Foot_L", x = 0.36, y = 0.96, weight = 2 },
    Foot_R = { id = "Foot_R", label = "Right Foot", engine = "Foot_R", x = 0.64, y = 0.96, weight = 2 },
}

Wounds.PartOrder = {
    "Head", "Neck", "Torso_Upper", "Torso_Lower", "Groin",
    "UpperArm_L", "UpperArm_R", "ForeArm_L", "ForeArm_R",
    "Hand_L", "Hand_R", "UpperLeg_L", "UpperLeg_R",
    "LowerLeg_L", "LowerLeg_R", "Foot_L", "Foot_R",
}

Internal.WoundStats = {
    scratch = { priority = 1, damage = 4, bleedingRate = 0.018 },
    laceration = { priority = 2, damage = 8, bleedingRate = 0.055 },
    bite = { priority = 3, damage = 12, bleedingRate = 0.085 },
    bullet = { priority = 4, damage = 14, bleedingRate = 0.095 },
}
Internal.BandageQuality = {
    ["Base.AlcoholBandage"] = 1.35,
    ["Base.Bandage"] = 1.20,
    ["Base.Bandaid"] = 0.65,
    ["Base.AlcoholRippedSheets"] = 1.10,
    ["Base.RippedSheets"] = 0.90,
}
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
    local total = 0
    local roll
    local i
    local part
    for i = 1, #Wounds.PartOrder do
        part = Wounds.Parts[Wounds.PartOrder[i]]
        total = total + (tonumber(part.weight) or 1)
    end
    roll = ZombRand and ZombRand(math.max(1, total))
        or math.floor(math.random() * total)
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
