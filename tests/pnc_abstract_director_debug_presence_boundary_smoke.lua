local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "server", "PNC/")
    .. "Director/"
local entry = T.read(ROOT .. "PNC_AbstractDirectorDebug.lua")
local providers = ROOT .. "AbstractDirectorDebug/"
local summaries = T.read(
    providers .. "PNC_AbstractDirectorDebug_Summaries.lua"
)
local snapshot = T.read(
    providers .. "PNC_AbstractDirectorDebug_Snapshot.lua"
)
local actions = T.read(
    providers .. "PNC_AbstractDirectorDebug_Actions.lua"
)

T.contains(entry, "PNC.AbstractDirectorDebug.Internal",
    "entry owns the internal namespace")
T.contains(summaries, "function H.GroupSummary",
    "group summary stays behind the internal boundary")
T.contains(snapshot, "function Debug.BuildSnapshot",
    "public snapshot API remains available")
T.contains(actions, "function Debug.PerformAction",
    "public action API remains available")
T.falsy(string.find(entry, "function Debug.PerformAction", 1, true),
    "entry contains wiring rather than implementation")
