local T = require "tests/support/test"

local now = 1000
local queryCalls = 0
local candidates = { { id = "zombie" } }

PNC = {
    Const = {
        PERCEPTION_CANDIDATE_CACHE_MS = 100,
        PERCEPTION_CANDIDATE_CACHE_MAX = 8,
    },
    Core = {
        Now = function() return now end,
        DistanceSq = function(x1, y1, x2, y2)
            local dx = x2 - x1
            local dy = y2 - y1
            return (dx * dx) + (dy * dy)
        end,
    },
    SpatialIndex = {
        QueryZombies = function()
            queryCalls = queryCalls + 1
            return candidates
        end,
    },
    Registry = {},
    Relationships = {},
    Stealth = {},
}

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Perception/PNC_Perception.lua"
)

local first = PNC.Perception.GetZombieCandidatesAt(
    0, 0, 0, 6, "follow:owner", 150, 3, now
)
local second = PNC.Perception.GetZombieCandidatesAt(
    2, 0, 0, 6, "follow:owner", 150, 3, now + 1
)
T.truthy(first == second, "nearby perception candidates were not reused")
T.equal(queryCalls, 1, "nearby perception candidates repeated the query")

now = 1151
PNC.Perception.GetZombieCandidatesAt(
    2, 0, 0, 6, "follow:owner", 150, 3, now
)
T.equal(queryCalls, 2, "expired perception candidates were not refreshed")

PNC.Perception.GetZombieCandidatesAt(
    2, 0, 0, 6, "defense:npc", 150, 0, now
)
T.equal(queryCalls, 3, "independent perception scopes shared stale data")

T.finish("pnc_perception_candidate_cache_smoke")
