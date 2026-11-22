PNC = PNC or {}
PNC.NPCWounds = PNC.NPCWounds or {}

local Wounds = PNC.NPCWounds

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

Wounds.VitalPartOrder = { "Head", "Torso_Upper", "Torso_Lower" }

Wounds.LocomotionPartOrder = {
    left = { "UpperLeg_L", "LowerLeg_L", "Foot_L" },
    right = { "UpperLeg_R", "LowerLeg_R", "Foot_R" },
}

Wounds.BodyPartRegions = {
    Head = "head_neck",
    Neck = "head_neck",
    Torso_Upper = "torso",
    Torso_Lower = "torso",
    Groin = "pelvis_groin",
    UpperArm_L = "upper_limb",
    UpperArm_R = "upper_limb",
    ForeArm_L = "upper_limb",
    ForeArm_R = "upper_limb",
    Hand_L = "upper_limb",
    Hand_R = "upper_limb",
    UpperLeg_L = "lower_limb",
    UpperLeg_R = "lower_limb",
    LowerLeg_L = "lower_limb",
    LowerLeg_R = "lower_limb",
    Foot_L = "lower_limb",
    Foot_R = "lower_limb",
}

Wounds.BodyRegionFunctions = {
    head_neck = { airwayOrVision = true, aimPenalty = 0.25, criticalMultiplier = 1.35 },
    torso = { breathingCore = true, staminaPenalty = 0.25, criticalMultiplier = 1.25 },
    pelvis_groin = { locomotionPelvic = true, arterialBleedRisk = true, speedPenalty = 0.30, criticalMultiplier = 1.25 },
    upper_limb = { weaponControl = true, swingAimPenalty = 0.30, criticalMultiplier = 1.0 },
    lower_limb = { locomotion = true, speedPenalty = 0.40, criticalMultiplier = 1.0 },
}

function Wounds.ClassifyBodyRegion(partId)
    return Wounds.BodyPartRegions[tostring(partId or "")] or "torso"
end

return Wounds
