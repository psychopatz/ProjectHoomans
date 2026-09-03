local T = require "tests/support/test"

local FILE = T.path("ProjectHoomans", "shared", "PNC/Core/")
    .. "Pathing/PNC_NavigationRouter.lua"

local plannerCalls = 0
local plannerClears = 0
local plannerInvalidations = 0
local routerNow = 0

PNC = {
    Core = { Now = function() return routerNow end },
    EnginePathPlanner = {
        CanUseNativePath = function(body)
            if body and body.nativeUnsafe == true then
                return false, "native_behavior_unavailable"
            end
            return true
        end,
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
            T.truthy(reason == "test_stall")
            plannerInvalidations = plannerInvalidations + 1
            return true
        end,
    },
}

T.load(FILE)

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
T.truthy(policy == "combat", "active combat did not select combat policy")
T.truthy(provider == "engine_path",
    "combat policy did not select native engine pathing")
T.truthy(plannerCalls == 0, "policy resolution invoked native planning")

local unsafeRecord = { runtime = {} }
local unsafePolicy, unsafeProvider = PNC.NavigationRouter.Resolve(
    unsafeRecord,
    "follow_owner",
    nil,
    { nativeUnsafe = true }
)
T.truthy(unsafePolicy == "local" and unsafeProvider == "engine_path",
    "body without a native behavior escaped unified native ownership")
T.truthy(unsafeRecord.runtime.navigationRouter.lastFallbackReason
        == "native_behavior_unavailable",
    "router did not retain native fallback reason")

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
T.truthy(travelPolicy == "travel", "journey did not select travel policy")
T.truthy(
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
T.truthy(plannerCalls == 1, "travel did not invoke native engine planner")
T.truthy(steering.x == 9, "travel provider result was not returned")
T.truthy(
    PNC.NavigationRouter.Invalidate(travelRecord, "test_stall"),
    "active route provider was not invalidated"
)
T.truthy(plannerInvalidations == 1, "planner invalidation was not forwarded")

policy, provider = PNC.NavigationRouter.Resolve(
    travelRecord,
    "melee_kiting",
    { navigationPolicy = "combat" }
)
T.truthy(policy == "combat" and provider == "engine_path")
T.truthy(plannerClears == 1,
    "switching navigation policy did not clear the previous route")

T.truthy(PNC.NavigationRouter.ActivateFallback(
    travelRecord,
    "native_stall_backoff",
    2000
), "native stall did not activate bounded fallback")
policy, provider = PNC.NavigationRouter.Resolve(
    travelRecord,
    "journey:test",
    { navigationPolicy = "travel" }
)
T.truthy(policy == "fallback" and provider == "direct",
    "active native fallback did not take the direct scripted lane")
T.truthy(PNC.NavigationRouter.IsFallbackActive(travelRecord, 1000),
    "native fallback expired before its bounded cooldown")
T.falsy(PNC.NavigationRouter.IsFallbackActive(travelRecord, 3000),
    "native fallback did not expire")
routerNow = 3000
policy, provider = PNC.NavigationRouter.Resolve(
    travelRecord,
    "journey:test",
    { navigationPolicy = "travel" }
)
T.truthy(policy == "travel" and provider == "engine_path",
    "expired native fallback did not restore native policy")

local tacticalCalls = 0
T.truthy(PNC.NavigationRouter.RegisterProvider("kite_test", {
    GetSteeringTarget = function(_, _, finalTarget)
        tacticalCalls = tacticalCalls + 1
        return finalTarget
    end,
}))
T.truthy(PNC.NavigationRouter.RegisterPolicy("kite_test", {
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
T.truthy(tacticalCalls == 1, "registered tactical provider was not routed")
T.finish("pnc_navigation_router_smoke")

T.finish("pnc_navigation_router_smoke")
