-- Central tuning for the abstract-world foundation. Times are world hours
-- unless their names explicitly end in MS.

PNC = PNC or {}
PNC.DirectorConfig = PNC.DirectorConfig or {}

local Config = PNC.DirectorConfig

Config.SCHEMA_VERSION = 1
Config.MODDATA_KEY = "PNC_AbstractWorld_v1"
Config.LOCATION_CELL_SIZE = 100
Config.DESTINATION_QUERY_RADIUS = 900
Config.DESTINATION_CANDIDATE_LIMIT = 16
Config.LOADED_BUILDING_DISCOVERY_LIMIT = 12
Config.TRAVEL_SPEED_TILES_PER_HOUR = 300
Config.MIN_TRAVEL_HOURS = 1 / 60
Config.MAX_TRAVEL_HOURS = 12
Config.TRAVERSAL_INTERVAL_HOURS = 2 / 60
Config.DECISION_INTERVAL_HOURS = 10 / 60
Config.RECONCILE_INTERVAL_HOURS = 30 / 60
Config.ACTION_INTERVAL_HOURS = 2 / 60
Config.ENCOUNTER_INTERVAL_HOURS = 1 / 60
Config.DIRECTOR_JOB_BUDGET = 12
Config.ACTIVE_SIMULATION_RADIUS = 80
Config.ENCOUNTER_HISTORY_LIMIT = 100
Config.OCCUPANCY_HISTORY_LIMIT = 12
Config.RECENT_THREAT_HISTORY_LIMIT = 24
Config.MIN_MISSION_DURATION_HOURS = 10 / 60
Config.MISSION_REPLACEMENT_THRESHOLD = 12
Config.MANPOWER_EXPONENT = 0.72

Config.GROUP_TYPES = {
    REFUGEE = true, LOOTER = true, SCAVENGER = true,
    PATROL = true, TRADER = true, WANDERER = true,
    RAIDER = true, SETTLEMENT_PARTY = true,
}

Config.MISSIONS = {
    IDLE = true, SCAVENGE = true, REST = true, PATROL = true,
    RETURN_HOME = true, SEEK_PLAYER = true, SEARCH_AREA = true,
    FLEE = true, MIGRATE = true, RAID = true, EXTORT = true,
    TRADE = true, EXPLORE = true, REINFORCE = true,
}

Config.STATES = {
    IDLE = true, SELECTING_DESTINATION = true, TRAVELING = true,
    ARRIVED = true, PERFORMING_ACTION = true, SEARCHING = true,
    WAITING = true, RETREATING = true, MATERIALIZING = true,
    ACTIVE = true, ACTION_COMPLETE = true, ENGAGED = true,
}

Config.RESOURCE_CATEGORIES = { "food", "water", "ammo", "medical", "materials" }

Config.Actions = {
    DEFAULT_DURATION_HOURS = 30 / 60,
}

Config.Scavenging = {
    DURATION_MIN_HOURS = 35 / 60,
    DURATION_MAX_HOURS = 95 / 60,
    BASE_YIELD_SCALE = 0.22,
    MIN_REMAINING_FACTOR = 0.04,
    VARIANCE_MIN = 0.90,
    VARIANCE_MAX = 1.10,
    EFFECTIVE_SCAVENGER_EXPONENT = 0.62,
    DEPLETION_BASE = 2.5,
    DEPLETION_PER_YIELD = 0.07,
    MAX_YIELD_PER_RESOURCE = 40,
    NEED_YIELD_BONUS = 0.35,
    NEED_RESTORE_PER_RESOURCE = { food = 0.7, water = 0.9 },
}

Config.ResourceNeeds = {
    TARGET_PER_MEMBER = { food = 10, water = 10, ammo = 12,
        medical = 3, materials = 5 },
    DESTINATION_BASE_WEIGHT = { food = 1.0, water = 1.0, ammo = 0.70,
        medical = 0.75, materials = 0.35 },
    MIN_DESTINATION_WEIGHT = 0.10,
}

Config.Behavior = {
    ARCHETYPES = {
        REFUGEE = { aggression = 0.10, bravery = 0.32, greed = 0.12,
            caution = 0.88, mercy = 0.80, discipline = 0.42,
            civilianHostility = 0.03 },
        LOOTER = { aggression = 0.82, bravery = 0.62, greed = 0.90,
            caution = 0.34, mercy = 0.15, discipline = 0.55,
            civilianHostility = 0.78 },
        SCAVENGER = { aggression = 0.24, bravery = 0.44, greed = 0.48,
            caution = 0.72, mercy = 0.58, discipline = 0.52,
            civilianHostility = 0.12 },
        PATROL = { aggression = 0.42, bravery = 0.68, greed = 0.12,
            caution = 0.55, mercy = 0.50, discipline = 0.82,
            civilianHostility = 0.18 },
        TRADER = { aggression = 0.18, bravery = 0.40, greed = 0.58,
            caution = 0.72, mercy = 0.62, discipline = 0.60,
            civilianHostility = 0.08 },
        WANDERER = { aggression = 0.28, bravery = 0.45, greed = 0.35,
            caution = 0.62, mercy = 0.55, discipline = 0.42,
            civilianHostility = 0.15 },
        RAIDER = { aggression = 0.90, bravery = 0.72, greed = 0.88,
            caution = 0.25, mercy = 0.08, discipline = 0.62,
            civilianHostility = 0.88 },
        SETTLEMENT_PARTY = { aggression = 0.30, bravery = 0.58,
            greed = 0.25, caution = 0.60, mercy = 0.62,
            discipline = 0.67, civilianHostility = 0.12 },
    },
    DESPERATION_WEIGHTS = { food = 0.30, water = 0.34,
        medical = 0.12, ammo = 0.08, morale = 0.10, condition = 0.06 },
}

Config.Intent = {
    OPTIONS = { "IGNORE", "AVOID", "FLEE", "NEGOTIATE", "EXTORT", "ROB", "ATTACK" },
    BASE = { IGNORE = 20, AVOID = 18, FLEE = 4, NEGOTIATE = 15,
        EXTORT = 4, ROB = 2, ATTACK = 3 },
    VARIANCE = 2.5,
    FRIENDLY_HOSTILE_PENALTY = 120,
    HOSTILE_BONUS = 28,
    OVERWHELMING_RATIO = 0.48,
}

Config.CombatResolution = {
    MAX_ABSTRACT_COMBAT_ROUNDS = 3,
    VARIANCE = 0.10,
    CASUALTY_PRESSURE_SCALE = 0.42,
    MAX_CASUALTIES_PER_ROUND = 2,
    AMMO_EXPENDITURE_SCALE = 0.34,
    MORALE_CASUALTY_LOSS = 0.13,
    MORALE_PRESSURE_LOSS = 0.045,
    ENVIRONMENT = {
        BUILDING = { defense = 1.08, mobility = 0.94, ranged = 0.96 },
        SETTLEMENT = { defense = 1.12, mobility = 0.92, ranged = 1.0 },
        POI = { defense = 1.0, mobility = 1.0, ranged = 1.0 },
        TEMPORARY = { defense = 1.0, mobility = 1.05, ranged = 1.02 },
    },
}

Config.Casualties = {
    DAMAGE = { MINOR = 6, SERIOUS = 18, CRITICAL = 36 },
    WOUND_TYPE = { MINOR = "scratch", SERIOUS = "laceration",
        CRITICAL = "bullet" },
}

Config.Retreat = {
    MORALE_BREAK_THRESHOLD = 0.38,
    OUTMATCHED_RATIO = 0.52,
    BASE_SUCCESS = 0.42,
    FAILED_RETREAT_PRESSURE = 0.35,
    FLEE_MORALE_PENALTY = 0.10,
    ABANDON_RESOURCE_FRACTION = 0.05,
    RECENT_THREAT_COOLDOWN_HOURS = 12,
}

Config.EncounterQueue = {
    WORK_BUDGET = 4,
    PAIR_COOLDOWN_HOURS = 2,
    MAX_ATTEMPTS = 3,
}

Config.LOCATION_TYPES = {
    BUILDING = true, POI = true, SETTLEMENT = true,
    PLAYER_VICINITY = true, TEMPORARY = true,
}

Config.ARCHETYPES = {
    REFUGEE = {
        resourceWeight = 0.75, distanceWeight = 1.25,
        dangerWeight = 2.0, unvisitedBonus = 10,
        tagWeights = { SAFE = 30, SHELTER = 18, FRIENDLY = 25,
            WATER = 14, FOOD = 10, DANGEROUS = -35 },
    },
    LOOTER = {
        resourceWeight = 1.15, distanceWeight = 0.75,
        dangerWeight = 0.45, unvisitedBonus = 14,
        tagWeights = { COMMERCIAL = 25, HOUSE = 14, WAREHOUSE = 24,
            WEAPONS = 22, VULNERABLE = 16, DANGEROUS = -5 },
    },
    SCAVENGER = {
        resourceWeight = 1.4, distanceWeight = 0.9,
        dangerWeight = 1.0, unvisitedBonus = 25,
        tagWeights = { COMMERCIAL = 18, WAREHOUSE = 22,
            FOOD = 14, WATER = 14, MEDICAL = 14 },
    },
    PATROL = {
        resourceWeight = 0.2, distanceWeight = 0.8,
        dangerWeight = 0.7, unvisitedBonus = 5,
        tagWeights = { BOUNDARY = 28, CHECKPOINT = 24,
            STRATEGIC = 20, FRIENDLY = 12 },
    },
    TRADER = {
        resourceWeight = 0.7, distanceWeight = 0.8,
        dangerWeight = 1.25, unvisitedBonus = 8,
        tagWeights = { SETTLEMENT = 28, FRIENDLY = 24,
            COMMERCIAL = 18, ROAD = 12 },
    },
    WANDERER = {
        resourceWeight = 0.7, distanceWeight = 0.7,
        dangerWeight = 1.0, unvisitedBonus = 20, tagWeights = {},
    },
    RAIDER = {
        resourceWeight = 0.8, distanceWeight = 0.7,
        dangerWeight = 0.35, unvisitedBonus = 10,
        tagWeights = { VULNERABLE = 30, SETTLEMENT = 20,
            WEAPONS = 15 },
    },
    SETTLEMENT_PARTY = {
        resourceWeight = 0.8, distanceWeight = 0.9,
        dangerWeight = 0.9, unvisitedBonus = 10,
        tagWeights = { FRIENDLY = 18, SETTLEMENT = 14 },
    },
}

Config.COMBAT = {
    ROLE_FACTORS = {
        leader = 0.9, lieutenant = 1.0, enforcer = 1.0,
        raider = 1.0, guard = 1.0, scavenger = 0.75,
        trader = 0.45, medic = 0.35, mechanic = 0.4,
        laborer = 0.4, caregiver = 0.2, civilian = 0.2,
    },
    WEAPON_RATINGS = {
        unarmed = { melee = 0.25, ranged = 0 },
        weak_melee = { melee = 0.55, ranged = 0 },
        basic_melee = { melee = 0.85, ranged = 0 },
        strong_melee = { melee = 1.2, ranged = 0 },
        sidearm = { melee = 0.25, ranged = 1.15 },
        shotgun = { melee = 0.3, ranged = 1.45 },
        rifle = { melee = 0.3, ranged = 1.65 },
    },
    OVERALL_WEIGHTS = {
        manpower = 8, meleePower = 6, rangedPower = 7,
        defense = 5, mobility = 3, morale = 4,
        experience = 3, medical = 2,
    },
}

function Config.GetArchetype(groupType)
    return Config.ARCHETYPES[tostring(groupType or "WANDERER")]
        or Config.ARCHETYPES.WANDERER
end

return Config
