local T = require "tests/support/test"

PNC = {
    Const = {
        FISHING_BASE_CATCH_CHANCE = 0.25,
        FISHING_SKILL_CATCH_BONUS = 0.05,
    },
    Skills = {
        GetLevel = function(_, skill)
            return skill == "Fishing" and 4 or 0
        end,
    },
}

local Fishing = T.load("ProjectHoomans", "shared",
    "PNC/Core/Fishing/PNC_Fishing.lua")
local zone = {
    id = "fishing:test",
    catchChance = 0.25,
    loot = {
        { type = "Test.Fish", weight = 1 },
    },
}
local record = { id = "npc:test" }

T.equal(Fishing.SkillLevel(record), 4, "fishing skill level")
T.near(Fishing.CatchChance(record, zone), 0.45, 0.000001,
    "skill affects catch chance")
T.equal(Fishing.UnitRoll("stable-seed"), Fishing.UnitRoll("stable-seed"),
    "roll is deterministic")
T.equal(Fishing.SelectLoot(record, zone, 1).type, "Test.Fish",
    "loot selection")
T.equal(Fishing.RequiredWorkPoints({}), 100, "default work points")
T.equal(Fishing.WorkPointsPerSecond({}), 5, "default work rate")

T.finish("pnc_fishing_resolver_smoke")
