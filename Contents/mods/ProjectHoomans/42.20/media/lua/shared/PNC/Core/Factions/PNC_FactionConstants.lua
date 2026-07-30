-- Pure constants for persistent organizational factions and NPC affiliation.

PNC = PNC or {}
PNC.FactionConstants = PNC.FactionConstants or {}

local Constants = PNC.FactionConstants

Constants.REGISTRY_MODDATA_KEY = "PNC_Factions"
Constants.REGISTRY_SCHEMA_VERSION = 2
Constants.AFFILIATION_SCHEMA_VERSION = 1
Constants.ID_PREFIX = "faction_"
Constants.ID_MAX_LENGTH = 192
Constants.NAME_MAX_LENGTH = 96
Constants.TAG_KEY_MAX_LENGTH = 96
Constants.TAG_VALUE_MAX_LENGTH = 192
Constants.FORMER_FACTION_LIMIT = 8
Constants.ID_GENERATION_RETRIES = 32
Constants.DIPLOMACY_REASON_MAX_LENGTH = 192

Constants.DIPLOMACY_WAR = "war"
Constants.DIPLOMACY_PEACE = "peace"
Constants.VALID_DIPLOMACY_STATES = {
    war = true,
    peace = true,
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
