-- Pure constants for actor-owned behavioral conduct records.

PNC = PNC or {}
PNC.ConductConstants = PNC.ConductConstants or {}

local Constants = PNC.ConductConstants

Constants.SCHEMA_VERSION = 1
Constants.SCORE_MIN = -100
Constants.SCORE_MAX = 100
Constants.EFFECT_MIN = -100
Constants.EFFECT_MAX = 100
Constants.STRENGTH_MIN = 0
Constants.STRENGTH_MAX = 1
Constants.DECAY_MIN = 0
Constants.DECAY_MAX = 1
Constants.EVIDENCE_LIMIT = 64
Constants.RECENT_EVIDENCE_ID_LIMIT = 64

Constants.DIMENSIONS = {
    "reliability",
    "generosity",
    "compassion",
    "courage",
    "restraint",
    "honesty",
    "groupLoyalty",
}
Constants.VALID_DIMENSIONS = {}
for _, dimension in ipairs(Constants.DIMENSIONS) do
    Constants.VALID_DIMENSIONS[dimension] = true
end

Constants.VISIBILITY_PRIVATE = "private"
Constants.VISIBILITY_DIRECT = "direct"
Constants.VISIBILITY_WITNESSED = "witnessed"
Constants.VISIBILITY_PUBLIC = "public"
Constants.VALID_VISIBILITY = {
    private = true,
    direct = true,
    witnessed = true,
    public = true,
}

return Constants
