local T = require "tests/support/test"

T.contains(T.path("ProjectHoomans", "shared", "PNC/Core.lua"),
    "/" .. T.runtime.ProjectHoomans .. "/media/lua/shared/PNC/Core.lua",
    "Project Hoomans runtime path")
T.contains(T.path("PsychopatzCore", "shared", "PsychopatzCore/Core.lua"),
    "/" .. T.runtime.PsychopatzCore .. "/media/lua/shared/PsychopatzCore/Core.lua",
    "Core runtime path")
T.contains(T.path("PsychopatzCore", "common", "PsychopatzCore/Core.lua"),
    "/common/media/lua/shared/PsychopatzCore/Core.lua", "Core common path")
T.equal(4, 4, "shared equality")
T.truthy(true, "shared truthy")
T.falsy(false, "shared falsy")
T.near(1.001, 1, 0.01, "shared near")

T.finish("pnc_test_harness_smoke")
