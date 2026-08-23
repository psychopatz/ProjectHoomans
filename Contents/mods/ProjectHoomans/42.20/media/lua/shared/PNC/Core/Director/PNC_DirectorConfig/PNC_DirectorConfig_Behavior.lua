local Config = PNC.DirectorConfig

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
    DESPERATION_WEIGHTS = {
        food = 0.30, water = 0.34, medical = 0.12,
        ammo = 0.08, morale = 0.10, condition = 0.06,
    },
}

Config.Intent = {
    OPTIONS = {
        "IGNORE", "AVOID", "FLEE", "NEGOTIATE", "EXTORT", "ROB", "ATTACK",
    },
    BASE = {
        IGNORE = 20, AVOID = 18, FLEE = 4, NEGOTIATE = 15,
        EXTORT = 4, ROB = 2, ATTACK = 3,
    },
    VARIANCE = 2.5,
    FRIENDLY_HOSTILE_PENALTY = 120,
    HOSTILE_BONUS = 28,
    OVERWHELMING_RATIO = 0.48,
}
