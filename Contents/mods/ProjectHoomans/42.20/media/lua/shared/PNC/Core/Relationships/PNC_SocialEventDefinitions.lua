-- Data-only balance registry for server-authoritative social events.

PNC = PNC or {}
PNC.Config = PNC.Config or {}
PNC.Config.Relationships = PNC.Config.Relationships or {}
if PNC.Config.Relationships.EnableSocialEvents == nil then
    PNC.Config.Relationships.EnableSocialEvents = true
end
if PNC.Config.Relationships.DebugPlayerIdentity == nil then
    PNC.Config.Relationships.DebugPlayerIdentity = false
end
if PNC.Config.Relationships.DebugCombatCallbacks == nil then
    PNC.Config.Relationships.DebugCombatCallbacks = false
end

PNC.SocialEventDefinitions = {}

local Definitions = PNC.SocialEventDefinitions

Definitions.treated_wound = {
    id = "treated_wound",
    allowedSourceSystems = { health = true, wounds = true },
    targetMemory = {
        type = "treated_wound",
        approvalEffect = 4,
        respectEffect = 2,
        moraleEffect = 2,
        familiarityGain = 2,
        strength = 1,
        decayPerDay = 0.05,
        permanent = false,
        shareable = false,
        knowledgeSource = "experienced",
        tags = { help = true, health = true, treatment = true },
    },
    cooldownHours = 12,
    contributionCaps = { approval = 20, respect = 15 },
}

Definitions.saved_from_incapacitation = {
    id = "saved_from_incapacitation",
    allowedSourceSystems = { health = true },
    targetMemory = {
        type = "saved_from_incapacitation",
        approvalEffect = 18,
        respectEffect = 25,
        moraleEffect = 12,
        familiarityGain = 8,
        strength = 1,
        decayPerDay = 0.008,
        permanent = false,
        shareable = true,
        knowledgeSource = "experienced",
        tags = {
            help = true,
            health = true,
            rescue = true,
            life_saving = true,
        },
    },
    contributionCaps = { approval = 70, respect = 80 },
}

Definitions.protected_from_attacker = {
    id = "protected_from_attacker",
    allowedSourceSystems = { combat = true },
    targetMemory = {
        type = "protected_from_attacker",
        approvalEffect = 8,
        respectEffect = 14,
        moraleEffect = 5,
        familiarityGain = 4,
        strength = 1,
        decayPerDay = 0.02,
        permanent = false,
        shareable = true,
        knowledgeSource = "experienced",
        tags = { help = true, combat = true, protective = true },
    },
    contributionCaps = { approval = 50, respect = 70 },
}

Definitions.survived_combat_together = {
    id = "survived_combat_together",
    allowedSourceSystems = { combat = true },
    targetMemory = {
        type = "survived_combat_together",
        approvalEffect = 3,
        respectEffect = 6,
        moraleEffect = 3,
        familiarityGain = 4,
        strength = 1,
        decayPerDay = 0.035,
        permanent = false,
        shareable = false,
        knowledgeSource = "experienced",
        tags = { combat = true, shared_danger = true, teamwork = true },
    },
    contributionCaps = { approval = 30, respect = 50 },
    reciprocalNPCObservers = true,
}

Definitions.abandoned_in_combat = {
    id = "abandoned_in_combat",
    allowedSourceSystems = { combat = true },
    targetMemory = {
        type = "abandoned_in_combat",
        approvalEffect = -20,
        respectEffect = -18,
        moraleEffect = -10,
        familiarityGain = 5,
        strength = 1,
        decayPerDay = 0.006,
        permanent = false,
        shareable = true,
        knowledgeSource = "experienced",
        tags = { abandonment = true, combat = true, betrayal = true },
    },
    contributionCaps = { approval = -80, respect = -80 },
}

return Definitions
