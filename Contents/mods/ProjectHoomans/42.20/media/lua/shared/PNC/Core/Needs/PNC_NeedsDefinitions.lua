-- Build 42 player-compatible need values. Zero is satisfied; one is maximum
-- hunger, thirst, or fatigue, matching CharacterStat in the base game.
PNC = PNC or {}
PNC.NeedsDefinitions = PNC.NeedsDefinitions or {}

local Definitions = PNC.NeedsDefinitions

Definitions.VERSION = 2
Definitions.TYPES = { "hunger", "hydration", "fatigue" }
Definitions.BY_ID = {
    hunger = { id = "hunger", minimum = 0, maximum = 1, default = 0 },
    hydration = { id = "hydration", minimum = 0, maximum = 1, default = 0 },
    fatigue = { id = "fatigue", minimum = 0, maximum = 1, default = 0 },
}

-- Installed Build 42 MoodleStat thresholds. Hydration maps to THIRST.
Definitions.MOODLE_THRESHOLDS = {
    hunger = { 0.15, 0.25, 0.45, 0.70 },
    hydration = { 0.12, 0.25, 0.70, 0.84 },
    fatigue = { 0.60, 0.70, 0.80, 0.90 },
}
Definitions.LEVELS = { "GOOD", "STABLE", "LOW", "CRITICAL", "EMERGENCY" }

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
    hydration = 0.03456,
    fatigue = 0.044712,
}
Definitions.INDIVIDUAL_ACTIVITY = {
    idle = true, walking = true, running = true, fighting = true,
    working = true, traveling = true, resting = true, sleeping = true,
}
Definitions.GROUP_RATES_PER_HOUR = {
    hunger = 0.0432, hydration = 0.03456, fatigue = 0.044712,
}
Definitions.GROUP_SIZE_RATE_PER_MEMBER = 0.08
Definitions.GROUP_ACTIVITY = {
    idle = { hunger = 1.0, hydration = 1.0, fatigue = 1.0 },
    traveling = { hunger = 1.0, hydration = 1.2, fatigue = 1.35 },
    scavenging = { hunger = 1.0, hydration = 1.0, fatigue = 1.25 },
    fighting = { hunger = 2.0, hydration = 1.2, fatigue = 1.6 },
    resting = { hunger = 1.0, hydration = 1.0, fatigue = 0.67 },
    at_home = { hunger = 1.0, hydration = 1.0, fatigue = 0.8 },
}
Definitions.ABSTRACT_SCAVENGE = {
    hungerGainMin = 0.20, hungerGainMax = 0.45,
    hydrationGainMin = 0.20, hydrationGainMax = 0.50,
}
Definitions.DEBUG_HISTORY_LIMIT = 40
Definitions.SCHEDULER_INTERVAL_MS = 30000
Definitions.SUPPLY = {
    hunger = {
        resourceKind = "FOOD", trigger = 0.25, target = 0.10,
        priorityBase = 55, retryHours = 0.25, urgentRetryHours = 0.05,
    },
    hydration = {
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
    return "EMERGENCY"
end

function Definitions.Clamp(needType, value)
    local definition = Definitions.Get(needType)
    if not definition then return nil end
    value = tonumber(value)
    if value == nil then value = definition.default end
    return math.max(definition.minimum, math.min(definition.maximum, value))
end

return Definitions
