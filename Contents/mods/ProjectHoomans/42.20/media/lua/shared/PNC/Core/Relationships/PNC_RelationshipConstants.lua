-- Pure constants for the persistent directed relationship foundation.

PNC = PNC or {}
PNC.RelationshipConstants = PNC.RelationshipConstants or {}

local Constants = PNC.RelationshipConstants

Constants.SOCIAL_SCHEMA_VERSION = 3
Constants.MEMORY_LIMIT = 20
Constants.RECENT_EVENT_ID_LIMIT = 64

Constants.APPROVAL_MIN = -100
Constants.APPROVAL_MAX = 100
Constants.RESPECT_MIN = -100
Constants.RESPECT_MAX = 100
Constants.FAMILIARITY_MIN = 0
Constants.FAMILIARITY_MAX = 100
Constants.MORALE_MIN = -100
Constants.MORALE_MAX = 100
Constants.MEMORY_STRENGTH_MIN = 0
Constants.MEMORY_STRENGTH_MAX = 1
Constants.MEMORY_EFFECT_MIN = -100
Constants.MEMORY_EFFECT_MAX = 100
Constants.DECAY_PER_DAY_MIN = 0
Constants.DECAY_PER_DAY_MAX = 1

Constants.STATE_UNKNOWN = "unknown"
Constants.STATE_NEUTRAL = "neutral"
Constants.STATE_FRIEND = "friend"
Constants.STATE_RIVAL = "rival"
Constants.STATE_ENEMY = "enemy"
Constants.VALID_STATES = {
    unknown = true,
    neutral = true,
    friend = true,
    rival = true,
    enemy = true,
}

Constants.KNOWLEDGE_EXPERIENCED = "experienced"
Constants.KNOWLEDGE_WITNESSED = "witnessed"
Constants.KNOWLEDGE_TOLD_TRUSTED = "told_by_trusted_person"
Constants.KNOWLEDGE_TOLD_STRANGER = "told_by_stranger"
Constants.KNOWLEDGE_COMMUNITY_RUMOR = "community_rumor"
Constants.KNOWLEDGE_INFERRED = "inferred"
Constants.VALID_KNOWLEDGE_SOURCES = {
    experienced = true,
    witnessed = true,
    told_by_trusted_person = true,
    told_by_stranger = true,
    community_rumor = true,
    inferred = true,
}

Constants.UNKNOWN_FAMILIARITY_EXIT = 5
Constants.FRIEND_APPROVAL_ENTER = 35
Constants.FRIEND_RESPECT_ENTER = 15
Constants.FRIEND_APPROVAL_EXIT = 25
Constants.FRIEND_RESPECT_EXIT = 5
Constants.RIVAL_APPROVAL_ENTER = -25
Constants.RIVAL_RESPECT_ENTER = 25
Constants.RIVAL_APPROVAL_EXIT = -15
Constants.RIVAL_RESPECT_EXIT = 15
Constants.ENEMY_APPROVAL_ENTER = -60
Constants.ENEMY_RESPECT_MAX_ENTER = 10
Constants.ENEMY_APPROVAL_EXIT = -45

return Constants
