local T = require "tests/support/test"

local SERVER = T.path("ProjectHoomans", "server", "PNC/")
local entry = T.read(SERVER .. "Needs/PNC_NeedsDebug.lua")
local summaries = T.read(
    SERVER .. "Needs/NeedsDebug/PNC_NeedsDebug_Summaries.lua"
)
local snapshot = T.read(
    SERVER .. "Needs/NeedsDebug/PNC_NeedsDebug_Snapshot.lua"
)
local actions = T.read(
    SERVER .. "Needs/NeedsDebug/PNC_NeedsDebug_Actions.lua"
)

T.contains(entry, "PNC.NeedsDebug.Internal",
    "entry owns the internal namespace")
T.contains(summaries, "function H.IndividualSummary",
    "summary construction stays behind the internal boundary")
T.contains(snapshot, "function Debug.BuildSnapshot",
    "public snapshot API remains available")
T.contains(actions, "function Debug.PerformAction",
    "public action API remains available")
T.contains(actions, "function Debug.CleanupIndividual",
    "public cleanup API remains available")
T.falsy(string.find(entry, "function Debug.PerformAction", 1, true),
    "entry contains wiring rather than implementation")
