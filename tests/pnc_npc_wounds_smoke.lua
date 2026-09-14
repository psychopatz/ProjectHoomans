local T = require "tests/support/test"

T.addPackagePaths()

local body = {
    bleedingRate = 0,
    openWoundCount = 0,
    bandagedWoundCount = 1,
}
PNC = {
    Core = {},
    NPCWounds = {
        Recalculate = function() return body end,
    },
}

local Wounds = T.load("ProjectHoomans", "shared",
    "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_Snapshot.lua")
local status = Wounds.BuildStatusSummary({})
T.falsy(status.bleeding, "bandaged wound is not active bleeding")
T.equal(status.openWoundCount, 0, "status preserves open wound count")
T.equal(status.bandagedWoundCount, 1,
    "status preserves bandaged wound count")

body = {
    bleedingRate = 0.05,
    openWoundCount = 1,
    bandagedWoundCount = 1,
}
status = Wounds.BuildStatusSummary({})
T.truthy(status.bleeding, "open wound reports active bleeding")
T.equal(status.openWoundCount, 1, "status preserves active wound count")
T.equal(status.bandagedWoundCount, 1,
    "status preserves treated wound count")

T.finish("pnc_npc_wounds_smoke")
