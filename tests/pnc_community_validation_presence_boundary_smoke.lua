local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "server", "PNC/")
local entry = T.read(ROOT .. "Communities/PNC_CommunityValidation.lua")
local providers = ROOT .. "Communities/CommunityValidation/"
local core = T.read(providers .. "PNC_CommunityValidation_Core.lua")
local registry = T.read(
    providers .. "PNC_CommunityValidation_Registry.lua")

T.contains(entry, "PNC.CommunityValidation.Internal",
    "entry owns the internal namespace")
T.contains(core, "function H.SafePersistent",
    "persistence checks stay behind the internal boundary")
T.contains(registry, "function Validation.ValidateRegistry",
    "community registry validation remains available")
T.contains(registry, "function Validation.RepairIndexes",
    "explicit index repair remains available")
T.falsy(string.find(entry, "function Validation.ValidateRegistry", 1, true),
    "entry contains wiring rather than implementation")
