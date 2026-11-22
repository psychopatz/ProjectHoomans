-- Whole-body ailment and supply policy catalogs for NPC needs/health definitions.
PNC = PNC or {}
PNC.NeedsDefinitions = PNC.NeedsDefinitions or {}
local Definitions = PNC.NeedsDefinitions

Definitions.WHOLE_BODY_AILMENT_ORDER = {
    "starvation", "dehydration", "knox_fever", "blood_loss",
    "cold_illness", "hypothermia", "hyperthermia", "wound_infection",
}
Definitions.WHOLE_BODY_AILMENTS = {
    starvation = {
        id = "starvation", needType = "hunger",
        label = "Starvation", labelKey = "UI_PNC_Health_Starvation",
        cause = "Hunger", causeKey = "UI_PNC_Health_Hunger",
    },
    dehydration = {
        id = "dehydration", needType = "thirst",
        label = "Dehydration", labelKey = "UI_PNC_Health_Dehydration",
        cause = "Thirst", causeKey = "UI_PNC_Health_Thirst",
    },
    knox_fever = {
        id = "knox_fever", label = "Fever",
        labelKey = "UI_PNC_Health_Fever", feverClass = "incurable",
        curable = false, severityProgression = "building",
    },
    blood_loss = {
        id = "blood_loss", label = "Losing blood",
        labelKey = "UI_PNC_Health_Losing_Blood", displayMode = "flavor",
        flavorOnly = true, cause = "Active bleeding",
        causeKey = "UI_PNC_Health_Active_Bleeding",
    },
    cold_illness = {
        id = "cold_illness", label = "Cold",
        labelKey = "UI_PNC_Health_ColdIllness", curable = true,
        severityProgression = "building",
    },
    hypothermia = {
        id = "hypothermia", label = "Hypothermia",
        labelKey = "UI_PNC_Health_Hypothermia", curable = true,
        severityProgression = "building",
    },
    hyperthermia = {
        id = "hyperthermia", label = "Heat Stress",
        labelKey = "UI_PNC_Health_Hyperthermia", curable = true,
        severityProgression = "building",
    },
    wound_infection = {
        id = "wound_infection", label = "Wound Infection",
        labelKey = "UI_PNC_Health_WoundInfection", curable = true,
        severityProgression = "building",
    },
}

function Definitions.GetWholeBodyAilment(ailmentID)
    return Definitions.WHOLE_BODY_AILMENTS[tostring(ailmentID or "")]
end

Definitions.SUPPLY = {
    hunger = {
        resourceKind = "FOOD", trigger = 0.25, target = 0.10,
        priorityBase = 55, retryHours = 0.25, urgentRetryHours = 0.05,
    },
    thirst = {
        resourceKind = "HYDRATION", trigger = 0.25, target = 0.10,
        manualMinimum = 0.10, priorityBase = 70,
        retryHours = 0.20, urgentRetryHours = 0.04,
    },
    medical = {
        resourceKind = "MEDICAL", priorityBase = 95,
        retryHours = 0.10, urgentRetryHours = 0.025,
    },
}
Definitions.SUPPLY_MATERIAL_CHANGE = 0.10
Definitions.SUPPLY_MAX_CANDIDATES = 24
Definitions.SUPPLY_MAX_SELECTIONS = 3
Definitions.SUPPLY_MAX_USES = 8
Definitions.SUPPLY_MAX_STATE_AWARE_SELECTIONS = 64
Definitions.SLEEP_TASK = {
    actionable = 0.70, critical = 0.80, completion = 0.12, recoveryPerGameHour = 0.45,
}

return Definitions
