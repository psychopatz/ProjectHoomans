local T = require "tests/support/test"
T.addPackagePaths({ { "ProjectHoomans", "client" },
    { "PsychopatzCore", "common" } })

PNC = { Network = { ClientState = {} } }
local Policy = T.load("ProjectHoomans", "client",
    "PNC/UI/Communities/ColonyManagement/PNC_BuildingPlacementPolicy.lua")

local settlement = { geometry = { region = { levels = {
    [0] = { rows = { [10] = { 10, 12 } } },
} } } }

T.truthy(Policy.IsPointInsideBase(settlement, 11, 10, 0),
    "point inside base was rejected")
T.falsy(Policy.IsPointInsideBase(settlement, 20, 10, 0),
    "point outside base was accepted")
local valid, reason = Policy.ValidatePoint(settlement, 20, 10, 0)
T.falsy(valid, "outside point passed validation")
T.equal(reason, "BUILD_TARGET_OUTSIDE_BASE",
    "outside point returned the wrong placement reason")
valid, reason = Policy.ValidatePoint(nil, 11, 10, 0)
T.falsy(valid, "missing base passed placement validation")
T.equal(reason, "BUILD_BASE_UNAVAILABLE",
    "missing base returned the wrong placement reason")

PNC.Network.ClientState.colonyManagement = { settlement = settlement }
valid = Policy.ValidateCurrentPoint(11, 10, 0)
T.truthy(valid, "current settlement was not used by placement policy")

local footprint = { levels = {
    [0] = { rows = { [10] = { 11, 13 } } },
} }
local footprintValid, footprintReason, _, invalid =
    Policy.ValidateFootprint(settlement, footprint)
T.falsy(footprintValid, "footprint crossing the base boundary was accepted")
T.equal(footprintReason, "BUILD_TARGET_OUTSIDE_BASE",
    "footprint boundary returned the wrong placement reason")
T.truthy(invalid and invalid.levels[0]
    and invalid.levels[0].rows[10],
    "invalid footprint did not identify the outside row")
T.equal(invalid.levels[0].rows[10][1], 13,
    "invalid footprint identified the wrong outside tile")

T.finish("pnc_building_placement_policy_smoke")
