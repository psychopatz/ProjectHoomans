local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "server", "PNC/")
    .. "WorldDiscovery/"
local entry = T.read(ROOT .. "PNC_WorldDiscovery_Entities.lua")
local providers = ROOT .. "WorldDiscovery_Entities/"
local registry = T.read(
    providers .. "PNC_WorldDiscovery_Entities_Registry.lua")
local phases = T.read(
    providers .. "PNC_WorldDiscovery_Entities_Phases.lua")
local snapshots = T.read(
    providers .. "PNC_WorldDiscovery_Entities_Snapshots.lua")

T.contains(entry, "Discovery.WorldEntityCache",
    "entry owns entity cache initialization")
T.contains(registry, "function Discovery.ListWorldEntities",
    "world entity projection remains available")
T.contains(phases, "function Discovery.SetResolvedPhase",
    "discovery phase mutation remains available")
T.contains(snapshots, "function Discovery.BuildSnapshot",
    "client projection remains available")
T.falsy(string.find(entry, "function Discovery.BuildSnapshot", 1, true),
    "entry contains wiring rather than implementation")
