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
Config.MOBILE_ACCIDENT_INTERVAL_HOURS = 2
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

Config.RESOURCE_CATEGORIES = {
    "food", "water", "ammo", "medical", "materials",
}

Config.Actions = { DEFAULT_DURATION_HOURS = 30 / 60 }

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
    TARGET_PER_MEMBER = {
        food = 10, water = 10, ammo = 12, medical = 3, materials = 5,
    },
    DESTINATION_BASE_WEIGHT = {
        food = 1.0, water = 1.0, ammo = 0.70,
        medical = 0.75, materials = 0.35,
    },
    MIN_DESTINATION_WEIGHT = 0.10,
}
