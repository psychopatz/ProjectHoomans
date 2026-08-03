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
Config.DIRECTOR_JOB_BUDGET = 12
Config.ACTIVE_SIMULATION_RADIUS = 80
Config.ENCOUNTER_HISTORY_LIMIT = 100
Config.OCCUPANCY_HISTORY_LIMIT = 12
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
    ACTIVE = true,
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
