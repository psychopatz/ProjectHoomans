-- Build 42 player-compatible need values. Zero is satisfied; one is maximum
-- hunger, thirst, or fatigue, matching CharacterStat in the base game.
PNC = PNC or {}
PNC.NeedsDefinitions = PNC.NeedsDefinitions or {}

local Definitions = PNC.NeedsDefinitions

Definitions.VERSION = 1
Definitions.TYPES = { "hunger", "thirst", "fatigue" }
Definitions.BY_ID = {
    hunger = { id = "hunger", translationKey = "UI_PNC_Need_Hunger",
        iconKey = "need.hunger", highIsBad = true, format = "percent",
        minimum = 0, maximum = 1, default = 0,
        task = { kind = "EAT", capability = "food.access" } },
    thirst = { id = "thirst", translationKey = "UI_PNC_Need_Thirst",
        iconKey = "need.thirst", highIsBad = true, format = "percent",
        minimum = 0, maximum = 1, default = 0,
        task = { kind = "DRINK", capability = "water.access" } },
    fatigue = { id = "fatigue", translationKey = "UI_PNC_Need_Fatigue",
        iconKey = "need.fatigue", highIsBad = true, format = "percent",
        minimum = 0, maximum = 1, default = 0,
        task = { kind = "SLEEP", capability = "sleep.bed" } },
}

-- Installed Build 42 MoodleStat thresholds. Hydration maps to THIRST.
Definitions.MOODLE_THRESHOLDS = {
    hunger = { 0.15, 0.25, 0.45, 0.70 },
    thirst = { 0.12, 0.25, 0.70, 0.84 },
    fatigue = { 0.60, 0.70, 0.80, 0.90 },
}
Definitions.LEVELS = { "NORMAL", "MINOR", "MODERATE", "SEVERE", "CRITICAL" }

function Definitions.Register(definition)
    if type(definition) ~= "table" then return false, "INVALID_NEED_DEFINITION" end
    local id = tostring(definition.id or "")
    if id == "" then return false, "NEED_ID_REQUIRED" end
    if Definitions.BY_ID[id] then return false, "NEED_ALREADY_REGISTERED" end
    definition.id = id
    definition.minimum = tonumber(definition.minimum) or 0
    definition.maximum = tonumber(definition.maximum) or 1
    definition.default = tonumber(definition.default) or definition.minimum
    Definitions.BY_ID[id] = definition
    Definitions.TYPES[#Definitions.TYPES + 1] = id
    return true, definition
end

function Definitions.List()
    local output = {}
    for _, id in ipairs(Definitions.TYPES) do output[#output + 1] = Definitions.BY_ID[id] end
    return output
end

Definitions.INDIVIDUAL_INITIAL_MIN = 0
Definitions.INDIVIDUAL_INITIAL_MAX = 0
Definitions.GROUP_INITIAL_MIN = 0
Definitions.GROUP_INITIAL_MAX = 0.20

-- Per-world-hour equivalents of the installed Build 42 ZomboidGlobals rates
-- at the standard 60-minute day. PlayerNeedsModel applies appetite, activity,
-- sleep, and physiological trait multipliers.
Definitions.VANILLA_RATES_PER_HOUR = {
    hunger = 0.0432,
    hungerRunning = 0.0288,
    hungerFighting = 0.0864,
    hungerSleeping = 0.0045,
    thirst = 0.03456,
    fatigue = 0.044712,
}
-- Colony needs use the vanilla-shaped rates above but deliberately advance
-- more slowly. Unlike a single player character, several colonists are being
-- managed at once and should not all require food, water, or sleep every few
-- game hours. Sleep recovery and calorie burn are not scaled by this table.
Definitions.INDIVIDUAL_RATE_SCALE = {
    hunger = 0.50,
    thirst = 0.50,
    fatigue = 0.60,
}
Definitions.INDIVIDUAL_ACTIVITY = {
    idle = true, walking = true, running = true, fighting = true,
    working = true, traveling = true, resting = true, sleeping = true,
}
Definitions.GROUP_RATES_PER_HOUR = {
    hunger = 0.0432, thirst = 0.03456, fatigue = 0.044712,
}
Definitions.GROUP_SIZE_RATE_PER_MEMBER = 0.08
Definitions.GROUP_ACTIVITY = {
    idle = { hunger = 1.0, thirst = 1.0, fatigue = 1.0 },
    traveling = { hunger = 1.0, thirst = 1.2, fatigue = 1.35 },
    scavenging = { hunger = 1.0, thirst = 1.0, fatigue = 1.25 },
    fighting = { hunger = 2.0, thirst = 1.2, fatigue = 1.6 },
    resting = { hunger = 1.0, thirst = 1.0, fatigue = 0.67 },
    at_home = { hunger = 1.0, thirst = 1.0, fatigue = 0.8 },
}
Definitions.ABSTRACT_SCAVENGE = {
    hungerGainMin = 0.20, hungerGainMax = 0.45,
    thirstGainMin = 0.20, thirstGainMax = 0.50,
}
Definitions.DEBUG_HISTORY_LIMIT = 40
Definitions.SCHEDULER_INTERVAL_MS = 30000
-- Individual need updates are spread across server ticks. The batch count is
-- only a safety cap; the time budget below is the primary hitch guard.
Definitions.SCHEDULER_BATCH_SIZE = 4
Definitions.SCHEDULER_TIME_BUDGET_MS = 2
Definitions.MAX_CATCHUP_HOURS = 168
Definitions.NUTRITION = {
    defaultCalories = 0, minimumCalories = -12000, maximumCalories = 12000,
    defaultWeight = 80, minimumWeight = 35, maximumWeight = 200,
    calorieBurnPerHour = 2000 / 24, caloriesPerKilogram = 7700,
}
Definitions.CONSEQUENCES = {
    criticalThreshold = 0.84, nonlethalHealthFloor = 10,
}
-- Whole Body ailments are abstract conditions. Their state lives on the
-- NPC's health body rather than on a bandageable body part. Server-side need
-- consequence policies decide how each condition builds, recovers, and
-- damages health; these shared definitions describe their source and UI.
Definitions.WHOLE_BODY_AILMENT_ORDER = {
    "starvation", "dehydration", "knox_fever", "blood_loss",
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
    -- Fever classes are metadata, not UI copy. A future curable fever can
    -- use the same Whole Body slot without changing the state shape.
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
        priorityBase = 70, retryHours = 0.20, urgentRetryHours = 0.04,
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
-- Critical need responses may exceed the normal three-item refill batch, but
-- still have a hard safety bound. Selection math stops at the actual deficit.
Definitions.SUPPLY_MAX_STATE_AWARE_SELECTIONS = 64
-- Needs owns when sleep becomes actionable and when rest is complete. Tasking
-- consumes this policy as intent metadata; it must not duplicate thresholds.
Definitions.SLEEP_TASK = {
    actionable = 0.70,
    critical = 0.80,
    completion = 0.12,
    recoveryPerGameHour = 0.45,
}

function Definitions.Get(needType)
    return Definitions.BY_ID[tostring(needType or "")]
end

function Definitions.GetLevel(needType, value)
    if value == nil then
        value = needType
        needType = "hunger"
    end
    value = tonumber(value) or 0
    local definition = Definitions.Get(needType)
    local thresholds = definition and definition.thresholds
        or Definitions.MOODLE_THRESHOLDS[needType]
        or Definitions.MOODLE_THRESHOLDS.hunger
    for index = 1, #thresholds do
        if value < thresholds[index] then return Definitions.LEVELS[index] end
    end
    return "CRITICAL"
end

function Definitions.Clamp(needType, value)
    local definition = Definitions.Get(needType)
    if not definition then return nil end
    value = tonumber(value)
    if value == nil then value = definition.default end
    return math.max(definition.minimum, math.min(definition.maximum, value))
end

return Definitions
