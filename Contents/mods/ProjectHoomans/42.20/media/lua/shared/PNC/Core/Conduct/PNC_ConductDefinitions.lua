-- Data-only objective conduct mappings for accepted social events.

PNC = PNC or {}
PNC.ConductDefinitions = {
    treated_wound = {
        role = "caregiver",
        participants = "actor",
        effects = { compassion = 2, generosity = 1 },
        decayPerDay = 0.02,
        visibility = "direct",
        shareable = false,
        tags = { treatment = true, help = true },
    },
    saved_from_incapacitation = {
        role = "rescuer",
        participants = "actor",
        effects = {
            compassion = 8, courage = 5,
            groupLoyalty = 4, reliability = 3,
        },
        decayPerDay = 0.0025,
        visibility = "direct",
        shareable = true,
        tags = { rescue = true, help = true, life_saving = true },
    },
    protected_from_attacker = {
        role = "protector",
        participants = "actor",
        effects = {
            courage = 6, groupLoyalty = 3, reliability = 2,
        },
        decayPerDay = 0.0075,
        visibility = "direct",
        shareable = true,
        tags = { protection = true, combat = true },
    },
    survived_combat_together = {
        role = "participant",
        participants = "actor_and_target",
        effects = {
            reliability = 2, courage = 2, groupLoyalty = 1,
        },
        decayPerDay = 0.015,
        visibility = "direct",
        shareable = false,
        tags = { combat = true, teamwork = true, shared_danger = true },
    },
    abandoned_in_combat = {
        role = "abandoner",
        participants = "actor",
        effects = {
            reliability = -8, courage = -6,
            groupLoyalty = -8, compassion = -3,
        },
        decayPerDay = 0.003,
        visibility = "direct",
        shareable = true,
        tags = { abandonment = true, betrayal = true, combat = true },
    },
}

return PNC.ConductDefinitions
