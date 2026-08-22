local T = require "tests/support/test"

local FILE =
    T.path("ProjectHoomans", "shared", "")
        .. "PNC/Core/Factions/PNC_FactionNameGenerator.lua"

PNC = {}
T.load(FILE)

local Generator = PNC.FactionNameGenerator
local settler = Generator.GenerateFactionName(
    "settler",
    "stable-seed"
)
T.equal(
    Generator.GenerateFactionName("settler", "stable-seed"),
    settler,
    "same seed is deterministic"
)
local looter = Generator.GenerateFactionName(
    "looter",
    "stable-seed"
)
T.truthy(settler ~= looter,
    "archetypes should have distinct naming styles")
T.truthy(string.find(settler, "Debug", 1, true) == nil,
    "generated name is not a debug timestamp")
T.truthy(string.find(looter, "The ", 1, true) == 1,
    "looter name uses gang-style article")

local siteName = Generator.GenerateCommunityName(
    "trader",
    "Crossroads Exchange",
    "community-seed"
)
T.truthy(string.find(siteName, "Crossroads Exchange", 1, true),
    "community name retains faction identity")
T.finish("pnc_faction_name_generator_smoke")

T.finish("pnc_faction_name_generator_smoke")
