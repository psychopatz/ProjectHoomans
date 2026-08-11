-- Phase 1 NPC Needs configuration. Values are reserves: lower is always worse.
PNC = PNC or {}
PNC.NeedsDefinitions = PNC.NeedsDefinitions or {}

local Definitions = PNC.NeedsDefinitions

Definitions.VERSION = 1
Definitions.TYPES = { "hunger", "hydration", "fatigue" }
Definitions.BY_ID = {
    hunger = { id = "hunger", minimum = 0, maximum = 100, default = 100 },
    hydration = { id = "hydration", minimum = 0, maximum = 100, default = 100 },
    fatigue = { id = "fatigue", minimum = 0, maximum = 100, default = 100 },
}

Definitions.LEVELS = {
    { id = "GOOD", minimum = 75 },
    { id = "STABLE", minimum = 50 },
    { id = "LOW", minimum = 25 },
    { id = "CRITICAL", minimum = 10 },
    { id = "EMERGENCY", minimum = 0 },
}

Definitions.INDIVIDUAL_INITIAL_MIN = 80
Definitions.INDIVIDUAL_INITIAL_MAX = 100
Definitions.GROUP_INITIAL_MIN = 70
Definitions.GROUP_INITIAL_MAX = 100
Definitions.INDIVIDUAL_RATES_PER_HOUR = {
    hunger = 0.45, hydration = 0.70, fatigue = 0.35,
}
Definitions.INDIVIDUAL_ACTIVITY = {
    idle = { hunger = 1.0, hydration = 1.0, fatigue = 1.0 },
    walking = { hunger = 1.1, hydration = 1.15, fatigue = 1.25 },
    running = { hunger = 1.3, hydration = 1.45, fatigue = 1.65 },
    fighting = { hunger = 1.45, hydration = 1.60, fatigue = 1.85 },
    working = { hunger = 1.2, hydration = 1.3, fatigue = 1.45 },
    traveling = { hunger = 1.2, hydration = 1.35, fatigue = 1.5 },
    resting = { hunger = 0.9, hydration = 0.9, fatigue = -4.0 },
    sleeping = { hunger = 0.7, hydration = 0.75, fatigue = -7.5 },
}
Definitions.GROUP_RATES_PER_HOUR = {
    hunger = 0.55, hydration = 0.85, fatigue = 0.45,
}
Definitions.GROUP_SIZE_RATE_PER_MEMBER = 0.08
Definitions.GROUP_ACTIVITY = {
    idle = { hunger = 1.0, hydration = 1.0, fatigue = 1.0 },
    traveling = { hunger = 1.25, hydration = 1.40, fatigue = 1.55 },
    scavenging = { hunger = 1.20, hydration = 1.25, fatigue = 1.40 },
    fighting = { hunger = 1.45, hydration = 1.60, fatigue = 1.80 },
    resting = { hunger = 1.0, hydration = 1.0, fatigue = -5.0 },
    at_home = { hunger = 0.85, hydration = 0.85, fatigue = 0.50 },
}
Definitions.ABSTRACT_SCAVENGE = {
    hungerGainMin = 20, hungerGainMax = 45,
    hydrationGainMin = 20, hydrationGainMax = 50,
}
Definitions.DEBUG_HISTORY_LIMIT = 40
Definitions.SCHEDULER_INTERVAL_MS = 30000
Definitions.SUPPLY = {
    hunger = {
        resourceKind = "FOOD", trigger = 50, target = 75,
        priorityBase = 55, retryHours = 0.25, urgentRetryHours = 0.05,
    },
    hydration = {
        resourceKind = "HYDRATION", trigger = 55, target = 80,
        priorityBase = 70, retryHours = 0.20, urgentRetryHours = 0.04,
    },
    medical = {
        resourceKind = "MEDICAL", priorityBase = 95,
        retryHours = 0.10, urgentRetryHours = 0.025,
    },
}
Definitions.SUPPLY_MATERIAL_CHANGE = 10
Definitions.SUPPLY_MAX_CANDIDATES = 24
Definitions.SUPPLY_MAX_SELECTIONS = 3
Definitions.SUPPLY_MAX_USES = 8

function Definitions.Get(needType)
    return Definitions.BY_ID[tostring(needType or "")]
end

function Definitions.GetLevel(value)
    value = tonumber(value) or 0
    for _, level in ipairs(Definitions.LEVELS) do
        if value >= level.minimum then return level.id end
    end
    return "EMERGENCY"
end

function Definitions.Clamp(needType, value)
    local definition = Definitions.Get(needType)
    if not definition then return nil end
    value = tonumber(value) or definition.default
    return math.max(definition.minimum, math.min(definition.maximum, value))
end

return Definitions
