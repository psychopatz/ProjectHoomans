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

local nativeFishTypes = {}
for _, entry in ipairs(Fishing.DEFAULT_LOOT) do
    nativeFishTypes[entry.type] = true
    T.falsy(entry.type == "Base.FishFillet",
        "default fishing pool must not return fillets")
    T.falsy(entry.type == "Base.Crayfish",
        "default rod pool must not use fishing-net crayfish")
end
T.equal(#Fishing.DEFAULT_LOOT, 21,
    "default fishing pool mirrors the native fish count")

local seenNativeTypes = {}
for index = 1, 1000 do
    local spec = Fishing.SelectLoot({ id = "npc:default:" .. index }, {}, 1)
    T.truthy(nativeFishTypes[spec.type],
        "default fishing pool returned an unexpected item")
    seenNativeTypes[spec.type] = true
end
local seenCount = 0
for _ in pairs(seenNativeTypes) do seenCount = seenCount + 1 end
T.truthy(seenCount >= 10,
    "default fishing pool should produce varied native fish")

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
