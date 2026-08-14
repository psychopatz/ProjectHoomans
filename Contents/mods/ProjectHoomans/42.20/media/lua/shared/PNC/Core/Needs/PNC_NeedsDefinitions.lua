-- Build 42 player-compatible need values. Zero is satisfied; one is maximum
-- hunger, thirst, or fatigue, matching CharacterStat in the base game.
PNC = PNC or {}
PNC.NeedsDefinitions = PNC.NeedsDefinitions or {}

local Definitions = PNC.NeedsDefinitions

Definitions.VERSION = 1
Definitions.TYPES = { "hunger", "thirst", "fatigue" }
Definitions.BY_ID = {
    hunger = { id = "hunger", minimum = 0, maximum = 1, default = 0 },
    thirst = { id = "thirst", minimum = 0, maximum = 1, default = 0 },
    fatigue = { id = "fatigue", minimum = 0, maximum = 1, default = 0 },
}

-- Installed Build 42 MoodleStat thresholds. Hydration maps to THIRST.
Definitions.MOODLE_THRESHOLDS = {
    hunger = { 0.15, 0.25, 0.45, 0.70 },
    thirst = { 0.12, 0.25, 0.70, 0.84 },
    fatigue = { 0.60, 0.70, 0.80, 0.90 },
}
Definitions.LEVELS = { "NORMAL", "MINOR", "MODERATE", "SEVERE", "CRITICAL" }

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
Definitions.SCHEDULER_BATCH_SIZE = 100
Definitions.MAX_CATCHUP_HOURS = 168
Definitions.NUTRITION = {
    defaultCalories = 0, minimumCalories = -12000, maximumCalories = 12000,
    defaultWeight = 80, minimumWeight = 35, maximumWeight = 200,
    calorieBurnPerHour = 2000 / 24, caloriesPerKilogram = 7700,
}
Definitions.CONSEQUENCES = {
    criticalThreshold = 0.84, nonlethalHealthFloor = 10,
}
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
    local thresholds = Definitions.MOODLE_THRESHOLDS[needType]
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
