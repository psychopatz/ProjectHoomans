local FILE =
    "Contents/mods/ProjectHoomans/42.20/media/lua/shared/"
        .. "PNC/Core/Factions/PNC_FactionNameGenerator.lua"

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. ": expected="
            .. tostring(expected) .. " actual="
            .. tostring(actual))
    end
end

PNC = {}
dofile(FILE)

local Generator = PNC.FactionNameGenerator
local settler = Generator.GenerateFactionName(
    "settler",
    "stable-seed"
)
equal(
    Generator.GenerateFactionName("settler", "stable-seed"),
    settler,
    "same seed is deterministic"
)
local looter = Generator.GenerateFactionName(
    "looter",
    "stable-seed"
)
assert(settler ~= looter,
    "archetypes should have distinct naming styles")
assert(string.find(settler, "Debug", 1, true) == nil,
    "generated name is not a debug timestamp")
assert(string.find(looter, "The ", 1, true) == 1,
    "looter name uses gang-style article")

local siteName = Generator.GenerateCommunityName(
    "trader",
    "Crossroads Exchange",
    "community-seed"
)
assert(string.find(siteName, "Crossroads Exchange", 1, true),
    "community name retains faction identity")

print("pnc_faction_name_generator_smoke: PASS")
