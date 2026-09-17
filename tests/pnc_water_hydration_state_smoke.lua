local T = require "tests/support/test"

T.addPackagePaths()

PNC = {
    FacilityJobs = {},
    FacilityJobsBehaviorInternal = {
        KIND = "facility_activity",
    },
}

local Internal = T.load("ProjectHoomans", "shared",
    "PNC/Core/Facilities/FacilityJobsBehavior/PNC_FacilityJobsBehavior_State.lua")
local state = Internal.Normalize(nil, {
    resourceKind = "water_refill",
    resourceKey = "sink:reload",
    manual = true,
    manualOverride = true,
    waterContextKind = "MANUAL_OVERRIDE",
    waterBaseId = "base:1",
})

T.equal(state.resourceKind, "water_refill",
    "normalized refill state keeps its water resource kind")
T.truthy(state.manual,
    "normalized refill state keeps manual activity authority")
T.truthy(state.manualOverride,
    "normalized refill state keeps explicit manual override")
T.equal(state.waterContextKind, "MANUAL_OVERRIDE",
    "normalized refill state keeps hydration context")
T.equal(state.waterBaseId, "base:1",
    "normalized refill state keeps its base identity")

T.finish("pnc_water_hydration_state_smoke")
