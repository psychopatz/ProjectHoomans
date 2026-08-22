local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "shared", "PNC/Core/")
local SHARED = T.path("ProjectHoomans", "shared", "")
local CORE = T.path("PsychopatzCore", "common", "")
T.addPackagePaths()

T.finish("pnc_npc_wounds_smoke")
