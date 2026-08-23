local Config = PNC.DirectorConfig

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
    WOUND_TYPE = {
        MINOR = "scratch", SERIOUS = "laceration", CRITICAL = "bullet",
    },
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
