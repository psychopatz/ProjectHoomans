-- Pure constants for persistent organizational factions and NPC affiliation.

PNC = PNC or {}
PNC.Config = PNC.Config or {}
PNC.Config.Factions = PNC.Config.Factions or {}
if PNC.Config.Factions
    .EnemyRelationshipCanImmediatelyDeclareWar == nil
then
    PNC.Config.Factions
        .EnemyRelationshipCanImmediatelyDeclareWar = false
end
PNC.FactionConstants = PNC.FactionConstants or {}

local Constants = PNC.FactionConstants

Constants.REGISTRY_MODDATA_KEY = "PNC_Factions"
Constants.REGISTRY_SCHEMA_VERSION = 3
Constants.AFFILIATION_SCHEMA_VERSION = 1
Constants.RELATION_SCHEMA_VERSION = 1
Constants.POLICY_SCHEMA_VERSION = 1
Constants.POLICY_GENERATION_VERSION = 1
Constants.ID_PREFIX = "faction_"
Constants.ID_MAX_LENGTH = 192
Constants.NAME_MAX_LENGTH = 96
Constants.TAG_KEY_MAX_LENGTH = 96
Constants.TAG_VALUE_MAX_LENGTH = 192
Constants.FORMER_FACTION_LIMIT = 8
Constants.ID_GENERATION_RETRIES = 32
Constants.DIPLOMACY_REASON_MAX_LENGTH = 192
Constants.INCIDENT_ID_MAX_LENGTH = 256
Constants.INCIDENT_TYPE_MAX_LENGTH = 96
Constants.INCIDENT_LIMIT = 64
Constants.RECENT_INCIDENT_ID_LIMIT = 128
Constants.ATTACK_AGGREGATION_HOURS = 0.01

Constants.STANDING_MIN = -100
Constants.STANDING_MAX = 100
Constants.TRUST_MIN = -100
Constants.TRUST_MAX = 100
Constants.FEAR_MIN = 0
Constants.FEAR_MAX = 100
Constants.GRIEVANCE_MIN = 0
Constants.GRIEVANCE_MAX = 100

Constants.STANDING_DECAY_PER_DAY = 0.05
Constants.TRUST_DECAY_PER_DAY = 0.025
Constants.FEAR_DECAY_PER_DAY = 0.10
Constants.GRIEVANCE_DECAY_PER_DAY = 0.01
Constants.PEACE_GRIEVANCE_DECAY_MULTIPLIER = 2

Constants.DIPLOMACY_WAR = "war"
Constants.DIPLOMACY_PEACE = "peace"
Constants.VALID_DIPLOMACY_STATES = {
    war = true,
    peace = true,
}

Constants.RELATION_STATES = {
    "unknown",
    "friendly",
    "neutral",
    "wary",
    "hostile",
    "war",
    "truce",
    "allied",
}
Constants.VALID_RELATION_STATES = {}
for _, state in ipairs(Constants.RELATION_STATES) do
    Constants.VALID_RELATION_STATES[state] = true
end

Constants.INTENTS = {
    "protect",
    "cooperate",
    "obey",
    "tolerate",
    "observe",
    "avoid",
    "threaten",
    "pursue",
    "attack",
}
Constants.VALID_INTENTS = {}
for _, intent in ipairs(Constants.INTENTS) do
    Constants.VALID_INTENTS[intent] = true
end

Constants.VALID_OUTSIDER_POLICIES = {
    neutral = true,
    predatory = true,
    commercial = true,
    cautious = true,
    sheltering = true,
}

Constants.WAR_REASONS = {
    member_killed = true,
    severe_assault = true,
    repeated_aggression = true,
    leader_killed = true,
    truce_broken = true,
    manual_debug = true,
    scripted = true,
    unknown = true,
}

Constants.TREATY_AUDIT_INCIDENTS = {
    war_declared = true,
    peace_made = true,
    truce_started = true,
    alliance_formed = true,
    alliance_broken = true,
}

Constants.INCIDENT_TYPES = {
    member_attacked_minor = true,
    member_attacked_severe = true,
    member_killed = true,
    member_rescued = true,
    member_protected = true,
    members_fought_together = true,
    member_abandoned = true,
    personal_grievance_report = true,
    war_declared = true,
    peace_made = true,
    truce_started = true,
    alliance_formed = true,
    alliance_broken = true,
}

Constants.STATUS_ACTIVE = "active"
Constants.STATUS_INACTIVE = "inactive"
Constants.STATUS_ARCHIVED = "archived"
Constants.STATUS_DESTROYED = "destroyed"
Constants.VALID_FACTION_STATUSES = {
    active = true,
    inactive = true,
    archived = true,
    destroyed = true,
}

Constants.MEMBERSHIP_UNAFFILIATED = "unaffiliated"
Constants.MEMBERSHIP_GUEST = "guest"
Constants.MEMBERSHIP_REFUGEE = "refugee"
Constants.MEMBERSHIP_MEMBER = "member"
Constants.VALID_MEMBERSHIP_STATUSES = {
    unaffiliated = true,
    applicant = true,
    guest = true,
    refugee = true,
    member = true,
    probationary_member = true,
    prisoner = true,
    mercenary = true,
    deserter = true,
    exile = true,
}

Constants.ROLES = {
    "leader",
    "lieutenant",
    "guard",
    "enforcer",
    "raider",
    "trader",
    "medic",
    "farmer",
    "builder",
    "scavenger",
    "cook",
    "mechanic",
    "laborer",
    "caregiver",
    "civilian",
    "prisoner",
}
Constants.VALID_ROLES = {}
for _, role in ipairs(Constants.ROLES) do
    Constants.VALID_ROLES[role] = true
end

Constants.RANKS = {
    "member",
    "senior",
    "officer",
    "second",
    "leader",
}
Constants.VALID_RANKS = {}
for _, rank in ipairs(Constants.RANKS) do
    Constants.VALID_RANKS[rank] = true
end

Constants.VALID_LEAVE_REASONS = {
    left = true,
    removed = true,
    faction_archived = true,
    faction_destroyed = true,
    transferred = true,
    unknown = true,
}

return Constants
