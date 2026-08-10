-- Pure constants for the server-authoritative player-character identity domain.

PNC = PNC or {}
PNC.PlayerCharacterConstants = PNC.PlayerCharacterConstants or {}

local Constants = PNC.PlayerCharacterConstants

Constants.REGISTRY_MODDATA_KEY = "PNC_PlayerCharacters"
Constants.REGISTRY_SCHEMA_VERSION = 6
Constants.IDENTITY_VERSION = 2
Constants.UUID_PREFIX = "char"
Constants.MAX_COMPONENT_LENGTH = 128
Constants.MAX_GENERATION_ATTEMPTS = 16
Constants.LIFECYCLE_PUMP_MS = 1000

Constants.MODDATA_UUID_FIELD = "PNC_CharacterUUID"
Constants.MODDATA_VERSION_FIELD = "PNC_CharacterIdentityVersion"
Constants.MODDATA_ACCOUNT_KEY_FIELD = "PNC_CharacterAccountKey"
Constants.MIGRATION_BACKUP_MODDATA_KEY = "PNC_PlayerCharacters_v3_Backup"

Constants.STATUS_ACTIVE = "active"
Constants.STATUS_DEAD = "dead"
Constants.STATUS_RETIRED = "retired"
Constants.VALID_STATUSES = {
    active = true,
    dead = true,
    retired = true,
}

return Constants
