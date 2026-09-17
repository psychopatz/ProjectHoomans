local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "shared" },
})

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local atHome = true
local baseID = "base:1"
local camped = false
local record = {
    id = "npc:water-policy", alive = true,
    x = 5, y = 5, z = 0,
    orderSpec = { kind = "follow" },
}

PNC = {
    Const = { ORDER_FOLLOW = "follow", ORDER_CAMP = "camp" },
    NearbyWaterService = {},
    NearbyResourceLocator = {},
    NeedFacilityAwayRoutes = {
        IsCampContext = function() return camped end,
    },
    HomeDutyService = {
        GetBase = function() return { id = baseID } end,
        IsAtHome = function() return atHome end,
        IsWithinHome = function(_, _, x)
            return tonumber(x) and tonumber(x) <= 10
        end,
    },
    CampResourceService = {
        IsWithinCamp = function(_, _, target)
            return target and tonumber(target.x) and target.x <= 20
        end,
    },
}

T.load("ProjectHoomans", "server",
    "PNC/World/NearbyWaterService/PNC_NearbyWaterService_Core.lua")

local Policy = PNC.WaterHydrationPolicy
local context = Policy.GetContext(record)
T.equal(context.kind, "HOME", "home is an automatic refill context")
T.equal(context.baseId, "base:1", "home context preserves the base identity")

atHome = false
context = Policy.GetContext(record)
T.falsy(context, "an away follower has no automatic refill context")
local _, awayReason = Policy.GetContext(record)
T.equal(awayReason, "WATER_LOCATION_REQUIRED",
    "away refill reports the location policy reason")

camped = true
context = Policy.GetContext(record)
T.equal(context.kind, "CAMP", "camp is an automatic refill context")

camped = false
local manualContext = Policy.GetContext(record, { manualOverride = true })
T.equal(manualContext.kind, "MANUAL_OVERRIDE",
    "manual refill bypasses the location policy")
T.truthy(Policy.IsManualOverride({ manual = true,
    resourceKind = "water_refill" }),
    "legacy manual refill activities remain authorized")
T.falsy(Policy.IsManualOverride({ manual = true,
    resourceKind = "personal_food" }),
    "manual non-water activities do not bypass water policy")

atHome = true
context = Policy.GetContext(record)
local source = { x = 5, y = 5, z = 0 }
local target = { x = 30, y = 30, z = 0 }
local approaches = {
    { x = 30, y = 31, z = 0 },
    { x = 6, y = 5, z = 0 },
}
local selected, filtered = Policy.RestrictTargets(
    record, context, source, target, approaches)
T.equal(selected.x, 6,
    "automatic refills choose an approach that stays inside home")
T.equal(#filtered, 1,
    "automatic refill movement drops out-of-context approaches")

local outsideSource = { x = 30, y = 30, z = 0 }
local _, _, sourceReason = Policy.RestrictTargets(
    record, context, outsideSource, source, { source })
T.equal(sourceReason, "WATER_SOURCE_OUTSIDE_ALLOWED_CONTEXT",
    "automatic refill rejects a source outside home")

local manualTarget, manualApproaches = Policy.RestrictTargets(
    record, manualContext, outsideSource, target, approaches)
T.equal(manualTarget, target,
    "manual refill preserves the requested target")
T.equal(manualApproaches, approaches,
    "manual refill preserves all approach candidates")

local allowed, allowedReason = Policy.AllowsActivity(record, {
    waterContextKind = "HOME",
})
T.truthy(allowed, "an activity remains valid in its authorized context")
T.equal(allowedReason, "HOME", "activity validation reports its context")

atHome = false
allowed, allowedReason = Policy.AllowsActivity(record, {
    waterContextKind = "HOME",
})
T.falsy(allowed, "a home refill stops after leaving home")
T.equal(allowedReason, "WATER_LOCATION_REQUIRED",
    "context loss has a precise failure reason")
allowed = Policy.AllowsActivity(record, { waterContextKind = "HOME",
    manualOverride = true })
T.truthy(allowed, "manual activity remains valid after leaving home")

camped = true
allowed, allowedReason = Policy.AllowsActivity(record, {
    waterContextKind = "HOME",
})
T.falsy(allowed, "a home activity cannot silently become a camp activity")
T.equal(allowedReason, "WATER_CONTEXT_CHANGED",
    "context changes are rejected instead of retargeting the activity")

camped = false
atHome = true
baseID = "base:2"
allowed, allowedReason = Policy.AllowsActivity(record, {
    waterContextKind = "HOME", waterBaseId = "base:1",
})
T.falsy(allowed, "a home activity cannot silently change base")
T.equal(allowedReason, "WATER_CONTEXT_CHANGED",
    "base changes invalidate the captured home refill context")

T.finish("pnc_water_hydration_policy_smoke")
