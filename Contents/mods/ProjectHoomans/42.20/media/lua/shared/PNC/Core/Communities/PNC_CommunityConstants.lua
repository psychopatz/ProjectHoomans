-- Pure constants for persistent faction-owned communities.

PNC = PNC or {}
PNC.CommunityConstants = PNC.CommunityConstants or {}

local Constants = PNC.CommunityConstants

Constants.REGISTRY_MODDATA_KEY = "PNC_Communities"
Constants.REGISTRY_SCHEMA_VERSION = 2
Constants.RECORD_SCHEMA_VERSION = 2
Constants.SITE_SCHEMA_VERSION = 1
Constants.ID_PREFIX = "community_"
Constants.SITE_ID_PREFIX = "community_site_"
Constants.ID_MAX_LENGTH = 192
Constants.SITE_ID_MAX_LENGTH = 240
Constants.NAME_MAX_LENGTH = 96
Constants.ID_GENERATION_RETRIES = 32

Constants.MODES = {
    "settled",
    "camped",
    "staging",
    "evacuating",
    "abandoned",
    "destroyed",
}
Constants.VALID_MODES = {}
for _, mode in ipairs(Constants.MODES) do
    Constants.VALID_MODES[mode] = true
end

Constants.STATUSES = {
    "active",
    "inactive",
    "archived",
    "destroyed",
}
Constants.VALID_STATUSES = {}
for _, status in ipairs(Constants.STATUSES) do
    Constants.VALID_STATUSES[status] = true
end

Constants.SITE_KINDS = {
    "building",
    "radius",
}
Constants.VALID_SITE_KINDS = {}
for _, kind in ipairs(Constants.SITE_KINDS) do
    Constants.VALID_SITE_KINDS[kind] = true
end

Constants.SITE_STATUSES = {
    "vacant",
    "occupied",
    "claimed",
}
Constants.VALID_SITE_STATUSES = {}
for _, status in ipairs(Constants.SITE_STATUSES) do
    Constants.VALID_SITE_STATUSES[status] = true
end

Constants.GROUP_PRESENCE_MODES = {
    "auto",
    "abstract",
    "live",
}
Constants.VALID_GROUP_PRESENCE_MODES = {}
for _, mode in ipairs(Constants.GROUP_PRESENCE_MODES) do
    Constants.VALID_GROUP_PRESENCE_MODES[mode] = true
end
Constants.GROUP_SIZE_MIN = 1
Constants.GROUP_SIZE_MAX = 24
Constants.GROUP_SIZE_DEFAULT = 4

Constants.ROLES = {
    "leader",
    "resident",
    "guard",
    "medic",
    "worker",
    "dependent",
    "prisoner",
}
Constants.VALID_ROLES = {}
for _, role in ipairs(Constants.ROLES) do
    Constants.VALID_ROLES[role] = true
end

Constants.SUPPLY_CATEGORIES = {
    "food",
    "medicine",
    "ammunition",
    "tools",
    "materials",
}
Constants.VALID_SUPPLY_CATEGORIES = {}
for _, category in ipairs(Constants.SUPPLY_CATEGORIES) do
    Constants.VALID_SUPPLY_CATEGORIES[category] = true
end

Constants.Z_MIN = -32
Constants.Z_MAX = 32
Constants.RADIUS_MIN = 1
Constants.RADIUS_MAX = 200
Constants.POPULATION_CAPACITY_MAX = 500
Constants.BEDS_MAX = 500
Constants.STORAGE_MAX = 100000
Constants.SECURITY_MIN = 0
Constants.SECURITY_MAX = 100
Constants.MORALE_MIN = -100
Constants.MORALE_MAX = 100
Constants.SUPPLY_MIN = 0
Constants.SUPPLY_MAX = 1000000

return Constants
