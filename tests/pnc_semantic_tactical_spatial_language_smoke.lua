local T = require "tests/support/test"
T.addPackagePaths()

PNC = {
    Semantics = {},
    Translation = {
        GetKey = function(_, fallback) return fallback end,
    },
}
PsychopatzCore = {}

require "PsychopatzCore/Spatial/PsychopatzSpatialRelation"
local Language = require
    "PNC/Semantics/PNC_SemanticTacticalSpatialLanguage"

local spatial = {
    clockToken = "CLOCK_08",
    relativeSector8 = "REAR_LEFT",
}

local clockMode, clockReason = Language.SelectMode({
    affiliation = { role = "guard" },
}, {}, spatial)
T.equal(clockMode, "clock", "guard uses clock presentation")
T.contains(clockReason, "tactical_role", "guard mode has grounded reason")

local veteranMode = Language.SelectMode({}, {
    traits = { pnc_veteran = true },
}, spatial)
T.equal(veteranMode, "clock", "veteran trait uses clock presentation")

local civilianMode, civilianReason = Language.SelectMode({
    affiliation = { role = "trader" },
}, { traits = {} }, spatial)
T.equal(civilianMode, "coarse", "ordinary civilian uses coarse presentation")
T.equal(civilianReason, "civilian_fallback", "civilian mode reason")

local clockText, clockTextReason, clockMeta = Language.Decorate(
    "Fight or fall back?", "zombie_group", spatial, "clock"
)
T.truthy(clockText, clockTextReason)
T.contains(clockText, "Zombies, 8 o'clock!",
    "clock callout is composed from canonical phrase plus Core label")
T.equal(clockMeta.clockToken, "CLOCK_08", "clock metadata retained")

local coarseText, coarseReason, coarseMeta = Language.Decorate(
    "Fight or fall back?", "zombie_group", spatial, "coarse"
)
T.truthy(coarseText, coarseReason)
T.contains(coarseText, "Zombies behind us, left side!",
    "civilian callout uses same fact as coarse relation")
T.equal(coarseMeta.relativeSector8, "REAR_LEFT",
    "coarse metadata retained")

local hostileText = Language.Decorate(
    "", "human_hostile",
    { clockToken = "CLOCK_03", relativeSector8 = "RIGHT" },
    "clock"
)
T.contains(hostileText, "Hostiles at 3 o'clock!",
    "hostile callout reuses generic clock language")

local omitted, omittedReason = Language.ComposePrefix(
    "zombie_group", {}, "clock"
)
T.equal(omitted, nil, "missing clock is safely omitted")
T.equal(omittedReason, "clock_unavailable", "missing clock reason")

T.finish("pnc_semantic_tactical_spatial_language_smoke")
