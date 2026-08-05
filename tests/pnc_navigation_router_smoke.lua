local FILE = "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/"
    .. "Pathing/PNC_NavigationRouter.lua"

local plannerCalls = 0
local plannerClears = 0
local plannerInvalidations = 0

PNC = {
    EnginePathPlanner = {
        GetSteeringTarget = function(_, _, target)
            plannerCalls = plannerCalls + 1
            return {
                x = target.x - 1,
                y = target.y,
                z = target.z,
                mode = target.mode,
                stopDistance = 0.35,
            }
        end,
        Clear = function()
            plannerClears = plannerClears + 1
        end,
        Invalidate = function(_, reason)
            assert(reason == "test_stall")
            plannerInvalidations = plannerInvalidations + 1
            return true
        end,
    },
}

dofile(FILE)

local combatRecord = {
    activeBehavior = "FollowOwner:moving",
    runtime = {
        target = { kind = "zombie" },
        combatBlockReason = "engaging_zombie",
    },
}
local policy, provider = PNC.NavigationRouter.Resolve(
    combatRecord,
    "investigating_last_seen"
)
assert(policy == "combat", "active combat did not select combat policy")
assert(provider == "engine_path",
    "combat policy did not select native engine pathing")
assert(plannerCalls == 0, "policy resolution invoked native planning")

local travelRecord = {
    activeBehavior = "Travel:en_route",
    runtime = {},
}
local travelPolicy
local travelProvider
local travelSpec
travelPolicy, travelProvider, travelSpec = PNC.NavigationRouter.Resolve(
    travelRecord,
    "journey:test"
)
assert(travelPolicy == "travel", "journey did not select travel policy")
assert(
    travelProvider == "engine_path",
    "travel policy did not select native engine planner"
)
local target = { x = 10, y = 4, z = 0, mode = "walk" }
local steering = PNC.NavigationRouter.GetSteeringTarget(
    travelRecord,
    {},
    target,
    travelPolicy,
    travelProvider,
    travelSpec
)
assert(plannerCalls == 1, "travel did not invoke native engine planner")
assert(steering.x == 9, "travel provider result was not returned")
assert(
    PNC.NavigationRouter.Invalidate(travelRecord, "test_stall"),
    "active route provider was not invalidated"
)
assert(plannerInvalidations == 1, "planner invalidation was not forwarded")

policy, provider = PNC.NavigationRouter.Resolve(
    travelRecord,
    "melee_kiting",
    { navigationPolicy = "combat" }
)
assert(policy == "combat" and provider == "engine_path")
assert(plannerClears == 1,
    "switching navigation policy did not clear the previous route")

local tacticalCalls = 0
assert(PNC.NavigationRouter.RegisterProvider("kite_test", {
    GetSteeringTarget = function(_, _, finalTarget)
        tacticalCalls = tacticalCalls + 1
        return finalTarget
    end,
}))
assert(PNC.NavigationRouter.RegisterPolicy("kite_test", {
    provider = "kite_test",
}))
local kiteSpec
policy, provider, kiteSpec = PNC.NavigationRouter.Resolve(
    combatRecord,
    "melee_kiting",
    { navigationPolicy = "kite_test" }
)
PNC.NavigationRouter.GetSteeringTarget(
    combatRecord,
    {},
    target,
    policy,
    provider,
    kiteSpec
)
assert(tacticalCalls == 1, "registered tactical provider was not routed")

print("pnc_navigation_router_smoke: ok")
