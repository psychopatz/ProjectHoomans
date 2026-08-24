local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "server", "PNC/")
    .. "Settlement/"
local entry = T.read(ROOT .. "PNC_BaseValidationService.lua")
local providers = ROOT .. "BaseValidationService/"
local core = T.read(providers .. "PNC_BaseValidationService_Core.lua")
local conflicts = T.read(
    providers .. "PNC_BaseValidationService_Conflicts.lua"
)
local territory = T.read(
    providers .. "PNC_BaseValidationService_Territory.lua"
)
local upgrades = T.read(
    providers .. "PNC_BaseValidationService_Upgrades.lua"
)

T.contains(entry, "PNC.BaseValidationService.Internal",
    "entry owns the internal namespace")
T.contains(core, "function Validation.ProjectFootprint",
    "public footprint projection remains available")
T.contains(conflicts, "function Validation.CanCreate",
    "public creation validation remains available")
T.contains(territory, "function Validation.CanChange",
    "public territory validation remains available")
T.contains(upgrades, "function Validation.CanUpgradeHQ",
    "public HQ validation remains available")
T.falsy(string.find(entry, "function Validation.CanCreate", 1, true),
    "entry contains wiring rather than implementation")
