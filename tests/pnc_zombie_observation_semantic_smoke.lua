local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
})

local now = 1000
local countCalls = 0
local hordeCalls = 0

PNC = {
    Const = {
        ZOMBIE_TARGET_RADIUS = 12,
        COMBAT_HORDE_RADIUS = 5.5,
        COMBAT_HORDE_COUNT = 4,
        ZOMBIE_OBSERVATION_CACHE_MS = 750,
    },
    Core = {
        Now = function() return now end,
    },
    Perception = {
        CountZombiesInFrame = function(_, radius)
            countCalls = countCalls + 1
            if radius <= 5.5 then return 8 end
            return 11
        end,
    },
    SocialEventHooks = {
        ObserveZombieHorde = function(_, count, threshold, observedAt, source)
            hordeCalls = hordeCalls + 1
            T.equal(count, 8, "ambient horde count")
            T.equal(threshold, 4, "ambient horde threshold")
            T.equal(observedAt, now, "ambient horde timestamp")
            T.equal(source, "ambient", "ambient horde source")
            return true, "event"
        end,
    },
}

local Observation = T.load(
    "ProjectHoomans", "shared",
    "PNC/Core/Perception/PNC_ZombieObservation.lua"
)

T.equal(Observation.Classify(0).band, "none", "zero band")
T.equal(Observation.Classify(2).band, "few", "few band")
T.equal(Observation.Classify(5).band, "several", "several band")
T.equal(Observation.Classify(8).band, "horde", "horde band")
T.equal(Observation.Classify(14).band, "massive_horde", "massive horde band")

local record = {
    id = "npc:test",
    alive = true,
    presenceState = "live",
    x = 10, y = 20, z = 0,
    runtime = {},
}
local first = Observation.ObserveRecord(record, now)
T.equal(first.nearbyCount, 11, "nearby count")
T.equal(first.hordeCount, 8, "horde count")
T.equal(first.band, "horde", "runtime band")
T.truthy(first.tacticalHorde, "tactical horde")
T.equal(countCalls, 2, "one frame supports two bounded radius counts")
T.equal(hordeCalls, 1, "horde episode emitted once")

local second = Observation.ObserveRecord(record, now + 100)
T.equal(second, first, "cache returns same runtime observation")
T.equal(countCalls, 2, "cache avoids new perception counts")
T.equal(hordeCalls, 1, "cache avoids repeated horde event")

now = 2000
local third = Observation.ObserveRecord(record, now)
T.truthy(third ~= first, "expired observation refreshed")
T.equal(countCalls, 4, "refresh performs bounded counts only")
T.equal(hordeCalls, 2, "new ambient observation may re-enter hook")

T.finish("pnc_zombie_observation_semantic_smoke")
