local T = require "tests/support/test"

local SERVER = T.path("ProjectHoomans", "server", "PNC/")
local entry = T.read(SERVER .. "Communities/PNC_CommunityDirector.lua")
local core = T.read(
    SERVER .. "Communities/CommunityDirector/PNC_CommunityDirector_Core.lua"
)
local generation = T.read(
    SERVER .. "Communities/CommunityDirector/PNC_CommunityDirector_Generation.lua"
)
local sites = T.read(
    SERVER .. "Communities/CommunityDirector/PNC_CommunityDirector_SiteSelection.lua"
)
local spawner = T.read(
    SERVER .. "Communities/CommunityDirector/PNC_CommunityDirector_NPCSpawner.lua"
)

T.contains(entry, "PNC.CommunityDirector.Internal",
    "entry owns the internal namespace")
T.contains(entry, "PNC_CommunityDirector_Core",
    "entry loads core helpers")
T.contains(entry, "PNC_CommunityDirector_Generation",
    "entry loads generation orchestration")
T.contains(core, "function H.ResolveCommunity",
    "community lifecycle stays behind the internal boundary")
T.contains(sites, "function H.ResolveSite",
    "site selection stays behind the internal boundary")
T.contains(spawner, "function H.SpawnCommunityMembers",
    "NPC batch creation stays behind the internal boundary")
T.contains(generation, "function Director.GenerateForFaction",
    "public generation API remains available")
T.falsy(string.find(entry, "function Director.GenerateForFaction", 1, true),
    "entry contains wiring rather than implementation")
