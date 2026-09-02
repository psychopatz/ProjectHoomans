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

Definitions.witnessed_player_kill = {
    id = "witnessed_player_kill",
    allowedSourceSystems = { combat = true },
    targetMemory = {
        type = "witnessed_player_kill",
        approvalEffect = 2,
        respectEffect = 4,
        moraleEffect = 1,
        familiarityGain = 2,
        strength = 1,
        decayPerDay = 0.03,
        permanent = false,
        shareable = true,
        knowledgeSource = "experienced",
        tags = { combat = true, witnessed = true },
    },
}

Definitions.witnessed_player_hurt = {
    id = "witnessed_player_hurt",
    allowedSourceSystems = { combat = true },
    targetMemory = {
        type = "witnessed_player_hurt",
        approvalEffect = -2,
        respectEffect = -3,
        moraleEffect = -1,
        familiarityGain = 0,
        strength = 1,
        decayPerDay = 0.03,
        permanent = false,
        shareable = true,
        knowledgeSource = "experienced",
        tags = { combat = true, witnessed = true, vulnerability = true },
    },
}

Definitions.player_damaged_npc = {
    id = "player_damaged_npc",
    allowedSourceSystems = { combat = true },
    targetMemory = {
        type = "player_damaged_npc",
        approvalEffect = -3,
        respectEffect = -4,
        moraleEffect = -1,
        familiarityGain = 0,
        strength = 1,
        decayPerDay = 0.025,
        permanent = false,
        shareable = true,
        knowledgeSource = "experienced",
        tags = { combat = true, witnessed = false, hostility = true },
    },
}

Definitions.faction_member_attacked = {
    id = "faction_member_attacked",
    allowedSourceSystems = { combat = true },
    targetMemory = {
        type = "faction_member_attacked",
        approvalEffect = -2,
        respectEffect = -3,
        moraleEffect = -1,
        familiarityGain = 0,
        strength = 1,
        decayPerDay = 0.025,
        permanent = false,
        shareable = true,
        knowledgeSource = "community_rumor",
        tags = {
            combat = true,
            faction = true,
            retaliation = true,
            hostility = true,
        },
    },
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

Definitions.player_emote_insult = {
    id = "player_emote_insult",
    allowedSourceSystems = { player_emote = true },
    targetMemory = {
        type = "player_insulted",
        approvalEffect = -4,
        respectEffect = -3,
        moraleEffect = -1,
        -- Repeated direct abuse is still a real interaction.  A small
        -- familiarity gain lets a previously unknown NPC cross the social
        -- state gate instead of remaining permanently "unknown".
        familiarityGain = 1,
        strength = 1,
        decayPerDay = 0.05,
        permanent = false,
        shareable = false,
        knowledgeSource = "experienced",
        tags = { hostile = true, emote = true, abuse = true },
    },
    -- Keep the cumulative contribution bounded by the normal relationship
    -- range, but do not stop insults while the NPC is still only disliked.
    -- The old -40/-35 caps made the enemy threshold unreachable from a
    -- neutral baseline and silently turned later insults into no-ops.
    contributionCaps = { approval = -100, respect = -100 },
}

Definitions.player_emote_thumbsdown = {
    id = "player_emote_thumbsdown",
    allowedSourceSystems = { player_emote = true },
    targetMemory = {
        type = "player_disapproved",
        approvalEffect = -1,
        respectEffect = -1,
        moraleEffect = 0,
        familiarityGain = 0,
        strength = 1,
        decayPerDay = 0.08,
        permanent = false,
        shareable = false,
        knowledgeSource = "experienced",
        tags = { hostile = true, emote = true, disapproval = true },
    },
    contributionCaps = { approval = -15, respect = -15 },
}

local function positiveEmoteDefinition(id, memoryType, approval, respect,
    morale, familiarity, decay, cooldown, caps, tags)
    return {
        id = id,
        allowedSourceSystems = { player_emote = true },
        targetMemory = {
            type = memoryType,
            approvalEffect = approval,
            respectEffect = respect,
            moraleEffect = morale,
            familiarityGain = familiarity,
            strength = 1,
            decayPerDay = decay,
            permanent = false,
            shareable = false,
            knowledgeSource = "experienced",
            tags = tags,
        },
        cooldownHours = cooldown,
        contributionCaps = caps,
    }
end

Definitions.player_emote_wavehi = positiveEmoteDefinition(
    "player_emote_wavehi", "player_greeted", 2, 0, 1, 2, 0.08, 2,
    { approval = 20, respect = 10 }, { greeting = true, emote = true }
)

-- NPC-initiated proximity greetings use the same daily greeting ledger as
-- wavehi.  There is deliberately no cooldown here: the daily gate and the
-- server-side enter edge prevent farming without suppressing negative emotes.
Definitions.npc_proximity_greeting = {
    id = "npc_proximity_greeting",
    allowedSourceSystems = { proximity_greeting = true },
    targetMemory = {
        type = "npc_greeted_player",
        approvalEffect = 2,
        respectEffect = 0,
        moraleEffect = 1,
        familiarityGain = 2,
        strength = 1,
        decayPerDay = 0.08,
        permanent = false,
        shareable = false,
        knowledgeSource = "experienced",
        tags = {
            greeting = true,
            npc_initiated = true,
            proximity = true,
        },
    },
    contributionCaps = { approval = 20, respect = 10 },
}

Definitions.player_emote_wavebye = positiveEmoteDefinition(
    "player_emote_wavebye", "player_farewelled", 1, 0, 0, 1, 0.10, 2,
    { approval = 10, respect = 5 }, { farewell = true, emote = true }
)
Definitions.player_emote_thankyou = positiveEmoteDefinition(
    "player_emote_thankyou", "player_thanked", 3, 1, 1, 1, 0.05, 1,
    { approval = 25, respect = 15 }, { gratitude = true, emote = true }
)
Definitions.player_emote_thumbsup = positiveEmoteDefinition(
    "player_emote_thumbsup", "player_praised", 3, 2, 1, 1, 0.05, 1,
    { approval = 25, respect = 20 }, { praise = true, emote = true }
)
Definitions.player_emote_clap = positiveEmoteDefinition(
    "player_emote_clap", "player_praised", 3, 2, 1, 1, 0.05, 1,
    { approval = 25, respect = 20 }, { praise = true, emote = true }
)
Definitions.player_emote_salute = positiveEmoteDefinition(
    "player_emote_salute", "player_saluted", 0, 3, 0, 1, 0.05, 2,
    { approval = 10, respect = 25 }, { respect = true, emote = true }
)

return Definitions
