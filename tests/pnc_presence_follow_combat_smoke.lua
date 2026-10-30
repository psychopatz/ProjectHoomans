local T = require "tests/support/test"
T.addPackagePaths()

local SHARED = T.path("ProjectHoomans", "shared", "")
local nearestDistSq = 400

PNC = {
    Core = { Now = function() return 100 end },
    Const = {
        ORDER_FOLLOW = "follow",
        PRESENCE_LIVE = "live",
        PRESENCE_ABSTRACT = "abstract",
        ABSTRACT_DISTANCE = 10,
    },
    BehaviorCommon = {},
    Presence = { Internal = {
        FindNearestPlayer = function()
            return { distSq = nearestDistSq }
        end,
    } },
}

T.load(SHARED .. "PNC/Core/Behaviors/PNC_Behavior_Common.lua")
T.load(SHARED .. "PNC/Core/Presence/PNC_Presence/PNC_Presence_Decisions.lua")

local Decisions = PNC.Presence
local followCombat = {
    orderSpec = { kind = "follow" },
    presenceState = "live",
    runtime = {
        target = { kind = "zombie", zombieId = 11 },
        followState = { mode = "combat" },
    },
}
local followMoving = {
    orderSpec = { kind = "follow" },
    presenceState = "live",
    runtime = {
        target = { kind = "zombie", zombieId = 11 },
        followState = { mode = "moving" },
    },
}
local workCombat = {
    orderSpec = { kind = "work" },
    presenceState = "live",
    runtime = {
        target = { kind = "zombie", zombieId = 11 },
        followState = { mode = "combat" },
    },
}

T.equal(
    Decisions.ShouldAbstract(followCombat),
    true,
    "active follow combat may cross the abstract distance boundary"
)
T.equal(
    Decisions.ShouldAbstract(followMoving),
    true,
    "stale follow target bypassed the hard live-body envelope"
)
T.equal(
    Decisions.ShouldAbstract(workCombat),
    true,
    "non-follow combat bypassed the hard live-body envelope"
)

nearestDistSq = 25
T.equal(
    Decisions.ShouldAbstract(followMoving),
    false,
    "near follow target lost live-body protection"
)
T.equal(
    Decisions.ShouldAbstract(workCombat),
    false,
    "near non-follow combat lost live-body protection"
)

return T.finish("pnc_presence_follow_combat_smoke")
