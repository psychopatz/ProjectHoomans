local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "shared", "PNC/Core/")
local SHARED_ROOT = T.path("ProjectHoomans", "shared", "")
local CORE_ROOT = T.path("PsychopatzCore", "common", "")
T.addPackagePaths()

T.finish("pnc_combat_resolution_standardization_smoke")
