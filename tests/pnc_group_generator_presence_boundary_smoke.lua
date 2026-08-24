local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "server", "PNC/")
    .. "Director/Population/"
local entry = T.read(ROOT .. "PNC_GroupGenerator.lua")
local selection = T.read(
    ROOT .. "GroupGenerator/PNC_GroupGenerator_Selection.lua"
)
local planning = T.read(
    ROOT .. "GroupGenerator/PNC_GroupGenerator_Planning.lua"
)
local rollback = T.read(
    ROOT .. "GroupGenerator/PNC_GroupGenerator_Rollback.lua"
)
local commit = T.read(
    ROOT .. "GroupGenerator/PNC_GroupGenerator_Commit.lua"
)

T.contains(entry, "PNC.GroupGenerator.Internal",
    "entry owns the internal namespace")
T.contains(selection, "function Generator.ChooseArchetype",
    "public archetype selection remains available")
T.contains(planning, "function Generator.BuildPlan",
    "public planning API remains available")
T.contains(planning, "function Generator.Validate",
    "public validation API remains available")
T.contains(rollback, "function H.RollbackFaction",
    "rollback stays behind the internal boundary")
T.contains(commit, "function Generator.Commit",
    "public commit API remains available")
T.falsy(string.find(entry, "function Generator.Commit", 1, true),
    "entry contains wiring rather than implementation")
