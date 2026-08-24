local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "server", "PNC/")
    .. "Director/"
local entry = T.read(ROOT .. "PNC_AbstractTraversal.lua")
local providers = ROOT .. "AbstractTraversal/"
local destinations = T.read(
    providers .. "PNC_AbstractTraversal_Destinations.lua"
)
local travel = T.read(providers .. "PNC_AbstractTraversal_Travel.lua")
local batches = T.read(providers .. "PNC_AbstractTraversal_Batches.lua")

T.contains(entry, "PNC.AbstractTraversal.Internal",
    "entry owns the internal namespace")
T.contains(destinations, "function Traversal.ScoreDestination",
    "public destination scoring remains available")
T.contains(travel, "function Traversal.Begin",
    "public travel start remains available")
T.contains(travel, "function Traversal.Arrive",
    "public arrival remains available")
T.contains(batches, "function Traversal.AdvanceBatch",
    "public bounded batch API remains available")
T.falsy(string.find(entry, "function Traversal.Begin", 1, true),
    "entry contains wiring rather than implementation")
