local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "shared" },
})

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local record = {
    id = "npc:route", alive = true, runtime = {},
    x = 10, y = 12, z = 0,
    needs = { hunger = 0.65, thirst = 0.60, fatigue = 0.90 },
    health = { current = 60, max = 100, state = "normal" },
    conditionStats = { boredom = 65, stress = 0.4 },
}
local facilities = {
    sleep = { { id = "barracks" } },
    ["food.dine"] = { { id = "dining" } },
    ["health.recover"] = { { id = "hospital" } },
    recreation = { { id = "living" } },
}
local capacity = {}
local dirty = 0
local provider
local supplyCalls = 0
local atHome = true
local hasPersonalFood = true
local hasPersonalHydration = false
local consumedPersonalItem

PNC = {
    Const = { ORDER_FOLLOW = "follow", ORDER_CAMP = "camp" },
    NeedsDefinitions = { SUPPLY = {
        hunger = { trigger = 0.35, target = 0.10, resourceKind = "FOOD",
            priorityBase = 50 },
        thirst = { trigger = 0.25, target = 0.10,
            resourceKind = "HYDRATION", priorityBase = 55 },
        medical = { priorityBase = 80 },
    } },
    IndividualNeeds = {
        Get = function(target, needType) return target.needs[needType] end,
        Queries = { GetSleepIntent = function(target)
            if target.needs.fatigue < 0.72 then return nil end
            return { precedence = "CRITICAL_NEED", urgency = 0.9 }
        end },
        RegisterListener = function() end,
        Commands = {
            ApplyDrink = function(target, relief)
                target.needs.thirst = target.needs.thirst - relief.thirst
                return true
            end,
        },
    },
    Health = { Ensure = function(target) return target.health end },
    ConditionStats = { Ensure = function(target)
        return target.conditionStats
    end },
    Registry = {
        Get = function() return record end,
        GetLiveZombie = function() return nil end,
        MarkDirty = function() end,
    },
    HomeDutyService = {
        GetBase = function() return { id = "base" } end,
        IsAtHome = function() return atHome end,
    },
    CampResourceService = {
        FindWater = function()
            return { resourceKey = "camp:faucet" }, { x = 10.5, y = 12.5,
                z = 0 }, {}, { kind = "faucet" }
        end,
    },
    FacilityService = {
        ListByCapability = function(_, capability)
            return facilities[capability] or {}
        end,
        AcquireActivity = function(_, _, capability)
            return {
                ok = true, facilityId = "dining",
                componentId = "table:1", reservationId = "reservation:dining",
                resourceKind = "dining_surface",
                target = { x = 11, y = 13, z = 0,
                    sceneId = "survival.eat.inventory" },
            }
        end,
    },
    FacilityReservations = {
        ByID = {},
        HasCapacity = function(_, capability)
            return capacity[capability] ~= false
        end,
    },
    Tasking = {
        Diagnostics = { counters = { facilityLookups = 0 } },
        Events = {
            Emit = function() dirty = dirty + 1 end,
        },
        Commands = {
            RegisterProvider = function(_, value) provider = value end,
        },
    },
    TaskLeaseService = { ForNPC = function() return nil end },
    CompanionCommands = { IsCompanion = function() return true end },
    NPCSupplyService = {
        HasPersonalSupply = function(_, kind)
            if kind == "FOOD" then
                return hasPersonalFood,
                    hasPersonalFood and "Base.Chips" or nil,
                    hasPersonalFood and "food:chips" or nil
            end
            if kind == "HYDRATION" then
                return hasPersonalHydration,
                    hasPersonalHydration and "Base.WaterBottle" or nil,
                    hasPersonalHydration and "drink:1" or nil
            end
            return true
        end,
        ConsumePersonalItem = function(_, itemID, required, resourceKind)
            consumedPersonalItem = {
                itemID = itemID, required = required,
                resourceKind = resourceKind,
            }
            return true, "PERSONAL_ITEM_CONSUMED", {
                hunger = resourceKind == "FOOD" and required or 0,
                thirst = resourceKind == "HYDRATION" and required or 0,
            }
        end,
        Process = function()
            supplyCalls = supplyCalls + 1
            record.needs.hunger = 0.05
            return true, "fulfilled"
        end,
    },
}

local Triggers = T["load"]("ProjectHoomans", "server",
    "PNC/Needs/NeedFacilityTriggers/PNC_NeedFacilityTriggers.lua")
T["load"]("ProjectHoomans", "server", "PNC/Needs/PNC_NeedSupplyBridge.lua")

T.equal(provider, Triggers, "single provider owns all facility need routes")
local candidates = Triggers.GetCandidates(record.id)
T.equal(#candidates, 4, "all configured need routes produce candidates")
local homeFoodCandidate
for _, candidate in ipairs(candidates) do
    if candidate.sourceRef == "hunger" then homeFoodCandidate = candidate end
end
T.truthy(homeFoodCandidate, "resident hunger uses the home dining route")
local homeAssignment = Triggers.Assign(homeFoodCandidate)
T.equal(homeAssignment.resourceKind, "personal_food",
    "home dining carries the transactional food resource kind")
T.equal(homeAssignment.activityItemID, "food:chips",
    "home dining carries the exact selected food item")
T.equal(homeAssignment.activityItemFullType, "Base.Chips",
    "home dining carries the selected food type")
local homeStartOptions
PNC.FacilityJobs = {
    Start = function(_, _, _, options)
        homeStartOptions = options
        return true, "started"
    end,
}
PNC.TaskLeaseService.SetPhase = function() end
T.truthy(Triggers.Start({
    npcId = record.id, sourceRef = "hunger", capability = "food.dine",
    leaseId = "lease:home-food", executionMode = "ABSTRACT",
}, homeAssignment), "home dining starts through the shared activity service")
T.equal(homeStartOptions.resourceKind, "personal_food",
    "home dining start preserves the food transaction lane")
T.equal(homeStartOptions.activityItemID, "food:chips",
    "home dining start preserves the exact food item")
T.equal(homeStartOptions.activityItemFullType, "Base.Chips",
    "home dining start preserves the exact food type")

T.truthy(Triggers.PreferFacility(record, "hunger"),
    "dining is preferred while a table is available")
T.equal(dirty, 1, "facility preference schedules one task reevaluation")
local Events = require "PsychopatzCore/Events/PC_EventBus"
Events.emit(PNC.EventTypes.NPC_INVENTORY_CHANGED, record)
T.equal(dirty, 2,
    "personal inventory arrival did not wake need-task reevaluation")
PNC.NeedSupplyBridge.Evaluate(record, "FOOD")
T.equal(supplyCalls, 0,
    "dining preference does not bypass the inventory eating primitive")

capacity["food.dine"] = false
PNC.NeedSupplyBridge.Evaluate(record, "FOOD")
T.equal(supplyCalls, 1,
    "inventory eating remains the fallback when dining has no capacity")

record.needs.hunger = 0.65
local dining = {
    needEffect = "primitive", primitiveNeed = "hunger",
    effectDelayMs = 0,
}
local ok, complete = PNC.NeedFacilityEffects.Tick(
    record, { facilityId = "dining" }, dining, 0, 1000)
T.truthy(ok and complete,
    "dining completes through the same inventory eating primitive")
T.equal(supplyCalls, 2, "dining invokes inventory supply exactly once")

-- A live personal-food activity must commit the selected item itself rather
-- than falling back to a second, potentially different inventory selection.
record.needs.hunger = 0.65
consumedPersonalItem = nil
local exactFoodState = { activityItemID = "food:chips" }
local exactFoodDefinition = {
    needEffect = "primitive", primitiveNeed = "hunger", effectDelayMs = 0,
}
local exactFoodOK, exactFoodComplete, exactFoodReason, exactFoodValue =
    PNC.NeedFacilityEffects.Tick(
        record, exactFoodState, exactFoodDefinition, 0, 1000)
T.truthy(exactFoodOK and exactFoodComplete,
    "personal food effect completes after its delayed commit")
T.equal(exactFoodReason, "NEED_COMPLETE",
    "personal food effect reports completion")
T.equal(consumedPersonalItem.itemID, "food:chips",
    "personal food effect consumes the selected item")
T.equal(consumedPersonalItem.resourceKind, "FOOD",
    "personal food effect uses the food transaction lane")
T.near(consumedPersonalItem.required, 0.55, 0.000001,
    "personal food effect requests the hunger deficit")
T.near(exactFoodValue, 0.55, 0.000001,
    "personal food effect exposes the applied hunger relief")

record.runtime.facilityActivity = { activityItemID = "food:chips" }
consumedPersonalItem = nil
local runtimeFoodOK, runtimeFoodComplete = PNC.NeedFacilityEffects.Tick(
    record, {}, exactFoodDefinition, 0, 2000)
T.truthy(runtimeFoodOK and runtimeFoodComplete,
    "food effect can recover the selected item from activity runtime")
T.equal(consumedPersonalItem.itemID, "food:chips",
    "abstract-style food state uses the runtime item identity")
record.runtime.facilityActivity = nil

local healthDefinition = {
    needEffect = "health", recoveryPerGameHour = 0.20,
    completionThreshold = 0.98,
}
ok, complete = PNC.NeedFacilityEffects.Tick(
    record, {}, healthDefinition, 1, 1000)
T.truthy(ok, "hospital recovery effect applies")
T.equal(record.health.current, 80, "hospital restores health over time")
T.falsy(complete, "hospital continues until its completion threshold")

local recreationDefinition = {
    needEffect = "recreation", boredomReliefPerGameHour = 30,
    stressReliefPerGameHour = 0.10, completionThreshold = 15,
}
ok = PNC.NeedFacilityEffects.Tick(
    record, {}, recreationDefinition, 1, 1000)
T.truthy(ok, "living-room recreation effect applies")
T.equal(record.conditionStats.boredom, 35,
    "recreation reduces boredom independently of primitive needs")

local nearbyWater = {
    key = "Base.WaterBottle@10.5:10.5:0#1", x = 10.5, y = 10.5, z = 0,
    item = { getFluidContainer = function()
        return { getAmount = function() return 1 end }
    end },
}
PNC.NearbyWaterService = {
    Find = function() return nearbyWater end,
    Resolve = function() return nearbyWater end,
    DesiredLiters = function() return 0.8 end,
    Consume = function(_, _, liters) return true, liters, 0.2 end,
}
record.needs.thirst = 0.60
local residentNearbyCandidates = Triggers.GetCandidates(record.id)
local residentNearbyCandidate
for _, candidate in ipairs(residentNearbyCandidates) do
    if candidate.sourceRef == "world_hydration" then
        residentNearbyCandidate = candidate
    end
end
T.truthy(residentNearbyCandidate,
    "a resident can use a valid world water source")
record.orderSpec = { kind = "follow" }
local nearbyCandidates = Triggers.GetCandidates(record.id)
local nearbyCandidate
for _, candidate in ipairs(nearbyCandidates) do
    if candidate.sourceRef == "world_hydration" then nearbyCandidate = candidate end
end
T.truthy(nearbyCandidate,
    "a follower can use a valid world water source")
T.equal(nearbyCandidate.capability, "survival.drink.world",
    "world hydration uses the non-facility drink capability")
T.truthy(Triggers.PreferFacility(record, "hydration"),
    "nearby water is preferred for a follower")
local nearbyDefinition = { needEffect = "world_water", effectDelayMs = 0 }
ok, complete = PNC.NeedFacilityEffects.Tick(
    record, { resource = nearbyWater }, nearbyDefinition, 0, 1000)
T.truthy(ok and complete, "world water completes through the shared effect")
T.near(record.needs.thirst, 0.20, 0.000001,
    "world water applies proportional thirst relief")

-- FacilityJobs strips Java item/object handles before placing a resource in
-- runtime state. The effect commit must re-resolve that primitive descriptor;
-- otherwise the scene completes without consuming water or relieving thirst.
local liveWater = {
    key = "Base.WaterBottle@10.5:10.5:0#1", kind = "item",
    x = 10.5, y = 10.5, z = 0,
    item = { getFluidContainer = function()
        return { getAmount = function() return 1 end }
    end },
}
local resolveCalls = 0
local consumedEntry
PNC.NearbyWaterService = {
    Resolve = function()
        resolveCalls = resolveCalls + 1
        return liveWater
    end,
    DesiredLiters = function() return 0.8 end,
    Consume = function(_, entry, liters)
        consumedEntry = entry
        return true, liters, 0.2
    end,
}
record.needs.thirst = 0.60
local primitiveResource = {
    key = liveWater.key, kind = liveWater.kind,
    x = liveWater.x, y = liveWater.y, z = liveWater.z,
}
local hydrationState = {
    resource = primitiveResource,
    resourceKey = liveWater.key,
}
ok, complete = PNC.NeedFacilityEffects.Tick(
    record, hydrationState, nearbyDefinition, 0, 2000)
T.truthy(ok and complete,
    "world water rehydrates a stripped item descriptor at commit time")
T.equal(resolveCalls, 1, "world water resolves a live source once")
T.equal(consumedEntry, liveWater,
    "world water consumes the resolved live item rather than the descriptor")
T.equal(hydrationState.resource.item, nil,
    "world water keeps Java handles out of runtime descriptors")
T.near(record.needs.thirst, 0.20, 0.000001,
    "rehydrated world water applies thirst relief")
local retryNow = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
record.runtime.worldWaterRetryAt = retryNow + 60000
local cooldownCandidates = Triggers.GetCandidates(record.id)
local cooldownNearby
for _, candidate in ipairs(cooldownCandidates) do
    if candidate.sourceRef == "world_hydration" then cooldownNearby = candidate end
end
T.falsy(cooldownNearby,
    "failed world water commits suppress immediate task re-entry")
record.runtime.worldWaterRetryAt = nil

-- Personal hydration, including a dual-purpose food, bypasses a water route
-- and lets NeedSupplyBridge consume the carried item directly.
hasPersonalHydration = true
local supplyBeforePersonalHydration = supplyCalls
local wakeBeforePersonalHydration = dirty
record.needs.thirst = 0.60
T.truthy(Triggers.PreferFacility(record, "hydration"),
    "personal hydration schedules the inventory drink activity")
T.equal(dirty, wakeBeforePersonalHydration + 1,
    "personal hydration preference emitted one need wake")
local personalCandidate
for _, candidate in ipairs(Triggers.GetCandidates(record.id)) do
    if candidate.sourceRef == "personal_hydration" then
        personalCandidate = candidate
    end
end
T.truthy(personalCandidate,
    "personal hydration uses the inventory drink task lane")
T.equal(personalCandidate.capability, "survival.drink.inventory",
    "personal hydration resolves to the inventory drink capability")
local personalAssignment = Triggers.Assign(personalCandidate)
T.equal(personalAssignment.resourceKind, "personal_drink",
    "personal hydration carries the transactional resource kind")
T.equal(personalAssignment.activityItemFullType, "Base.WaterBottle",
    "personal hydration carries the selected bottle type")
PNC.NeedSupplyBridge.Evaluate(record, "HYDRATION")
T.equal(supplyCalls, supplyBeforePersonalHydration,
    "personal hydration task preference does not double-consume directly")
hasPersonalHydration = false

record.orderSpec = { kind = "follow" }
atHome = false
record.needs.hunger = 0.65
local beforeFollowFood = supplyCalls
T.truthy(Triggers.PreferFacility(record, "hunger"),
    "a free follower schedules a temporary personal-food action")
PNC.NeedSupplyBridge.Evaluate(record, "FOOD")
T.equal(supplyCalls, beforeFollowFood,
    "the needs scheduler does not consume follower food before its task")
local followerCandidates = Triggers.GetCandidates(record.id)
local followerFood
for _, candidate in ipairs(followerCandidates) do
    if candidate.sourceRef == "follower_food" then followerFood = candidate end
end
T.truthy(followerFood, "follower food uses the reusable need-task lane")
T.equal(followerFood.capability, "survival.eat.inventory",
    "follower food resolves to the personal eating capability")
local valid, validationReason = Triggers.Validate(followerFood)
T.truthy(valid, validationReason or "free follower food intent validates")
local followerAssignment = Triggers.Assign(followerFood)
T.equal(followerAssignment.activityItemID, "food:chips",
    "follower food carries the exact selected item ID")
T.equal(followerAssignment.activityItemFullType, "Base.Chips",
    "follower food carries the selected item type")
T.equal(followerAssignment.target.x, record.x,
    "follower food task is anchored at the NPC's current position")
local startedCapability
local startedOptions
PNC.FacilityJobs = { Start = function(_, _, capability, options)
    startedCapability, startedOptions = capability, options
    return true, "started"
end }
local started = Triggers.Start({
    npcId = record.id, sourceRef = "follower_food",
    leaseId = "lease:food", executionMode = "LIVE",
}, followerAssignment)
T.truthy(started, "follower food starts through FacilityJobs")
T.equal(startedCapability, "survival.eat.inventory",
    "follower food uses the reusable activity executor")
T.equal(startedOptions.taskLeaseId, "lease:food",
    "follower food preserves its task lease")
T.equal(startedOptions.activityItemID, "food:chips",
    "follower food passes the exact item ID to FacilityJobs")

-- Starting the activity swaps the visible order to facility_activity. The
-- previous follow order must still keep the away route valid until the scene
-- completes, otherwise Tasking cancels the lease and interrupts eating.
record.orderSpec = {
    kind = "facility_activity", capability = "survival.eat.inventory",
}
record.runtime.facilityActivity = {
    automatic = true, taskLeaseId = "lease:food",
    previousOrder = { kind = "follow" },
}
T.truthy(PNC.NeedFacilityAwayRoutes.IsFollowing(record),
    "facility eating preserves the follower context")
T.truthy(PNC.NeedFacilityAwayRoutes.IsAwayCompanion(record),
    "facility eating remains an away-companion activity")
local activeValid, activeReason = Triggers.Validate(followerFood)
T.truthy(activeValid, activeReason
    or "active follower eating remains valid")
T.truthy(Triggers.CanContinue({
    npcId = record.id, sourceRef = "follower_food",
    leaseId = "lease:food", capability = "survival.eat.inventory",
}), "active follower eating lease remains continuable")
record.runtime.facilityActivity = nil
record.orderSpec = { kind = "follow" }

hasPersonalFood = false
record.needs.hunger = 0.65
T.falsy(Triggers.PreferFacility(record, "hunger"),
    "an NPC without personal food never enters the eating scene")
local noFoodCandidate
for _, candidate in ipairs(Triggers.GetCandidates(record.id)) do
    if candidate.sourceRef == "follower_food" then noFoodCandidate = candidate end
end
T.falsy(noFoodCandidate,
    "the task provider omits follower eating when no food is available")
hasPersonalFood = true

record.orderSpec = { kind = "camp" }
record.needs.hunger = 0.65
record.needs.thirst = 0.60
local campCandidates = Triggers.GetCandidates(record.id)
local campFood
local campWater
for _, candidate in ipairs(campCandidates) do
    if candidate.sourceRef == "follower_food" then campFood = candidate end
    if candidate.sourceRef == "camp_water" then campWater = candidate end
end
T.truthy(campFood, "camp uses the reusable personal-food route")
T.truthy(campWater, "camp uses the captured Camp water route")
local beforeSchedulerWake = dirty
T.truthy(Triggers.WakeActionable(record),
    "the generic needs wake finds an actionable Camp need")
T.equal(dirty, beforeSchedulerWake + 1,
    "the generic needs wake emits one coalesced task reevaluation")

record.runtime.inCombatUntil = 2000
PNC.Core = { Now = function() return 1000 end }
T.falsy(Triggers.PreferFacility(record, "hunger"),
    "a recent combat lease blocks the follower eating task")
record.runtime.inCombatUntil = nil

record.runtime.target = { id = "zombie:target", kind = "zombie" }
local beforeCombatWater = supplyCalls
T.falsy(Triggers.PreferFacility(record, "hydration"),
    "active combat does not schedule a nearby-water movement task")
PNC.NeedSupplyBridge.Evaluate(record, "HYDRATION")
T.equal(supplyCalls, beforeCombatWater + 1,
    "combat remains active while hydration falls back to inventory")
record.runtime.target = nil

PNC.FacilityJobDefinitions = {
    Get = function(capability)
        if capability == "food.dine" then
            return { needEffect = "primitive" }
        end
        return nil
    end,
}
PNC.PathService = {
    GetMovementRecoveryState = function()
        return {
            active = true, watchable = true,
            lastProgressAt = 1200, provider = "engine_path",
        }
    end,
}
record.runtime.facilityActivity = {
    taskLeaseId = "lease:travel",
    capability = "food.dine",
    phase = "TRAVELLING",
    lastProgressAt = 1000,
}
local recovery = Triggers.GetRecoveryState({
    npcId = record.id, sourceRef = "hunger", leaseId = "lease:travel",
    capability = "food.dine", phase = "TRAVEL",
})
T.equal(recovery.phase, "TRAVEL",
    "NeedFacility did not preserve the PathService travel phase")
T.truthy(recovery.watchable,
    "NeedFacility did not consume the PathService movement watchdog")
T.equal(recovery.lastProgressAt, 1200,
    "NeedFacility did not use PathService movement progress")

PNC.PathService.GetMovementRecoveryState = function()
    return { active = false, watchable = false, lastProgressAt = 1200 }
end
recovery = Triggers.GetRecoveryState({
    npcId = record.id, sourceRef = "hunger", leaseId = "lease:travel",
    capability = "food.dine", phase = "TRAVEL",
})
T.truthy(recovery.watchable and recovery.timeoutMs == 15000,
    "an inactive PathService lane did not get a bounded recovery window")

record.runtime.facilityActivity.phase = "STARTING"
record.runtime.facilityActivity.lastProgressAt = 2000
recovery = Triggers.GetRecoveryState({
    npcId = record.id, sourceRef = "hunger", leaseId = "lease:travel",
    capability = "food.dine", phase = "WAITING",
})
T.truthy(recovery.watchable and recovery.timeoutMs == 15000,
    "NeedFacility scene startup did not have a bounded watchdog")
record.runtime.facilityActivity = nil

atHome = true
record.needs.fatigue = 0.90
record.runtime.manualActivityDisabled = "sleep"
T.falsy(Triggers.PreferFacility(record, "sleep"),
    "sleep stays disabled after the manual sleep toggle is turned off")
local suppressedSleep = false
for _, candidate in ipairs(Triggers.GetCandidates(record.id)) do
    if candidate.sourceRef == "sleep" then suppressedSleep = true end
end
T.falsy(suppressedSleep,
    "the fatigue provider does not immediately requeue disabled sleep")
record.runtime.manualActivityDisabled = nil

-- A refill lease must not survive a planner change after the destination was
-- filled. Only the explicit scene cleanup tick may continue without a current
-- refill plan; otherwise a full bottle re-enters the same scene forever.
local refillPlanValid = true
local refillContainer = { id = "route:bottle" }
PNC.Inventory = {
    GetWaterContainer = function() return refillContainer end,
    IsRefillableWaterContainer = function(item)
        return item == refillContainer
    end,
}
PNC.NearbyWaterService = {
    ResolveHydrationPlan = function(_, mode)
        if mode == "refill" then
            if refillPlanValid then
                return { action = "fill_container", sourceKey = "sink:route" }
            end
            return nil, "WATER_CONTAINER_FULL"
        end
        if not refillPlanValid then
            return { action = "drink_container", activityItemID = "route:bottle" }
        end
        return nil
    end,
    FindFillSource = function()
        return { key = "sink:route" }
    end,
}
local activeRefillRecord = {
    id = "npc:active-refill", runtime = {
        facilityActivity = { taskLeaseId = "lease:refill" },
    },
}
local activeRefillLease = { leaseId = "lease:refill" }
local refillRoute = PNC.NeedFacilityAwayRoutes.Get("water_refill")
T.truthy(refillRoute.CanContinue(activeRefillRecord, activeRefillLease),
    "an active refill remains valid while its shared plan is fillable")
refillPlanValid = false
T.falsy(refillRoute.CanContinue(activeRefillRecord, activeRefillLease),
    "a full destination invalidates the stale refill lease")
activeRefillRecord.runtime.facilityActivity.completionRequested = true
T.truthy(refillRoute.CanContinue(activeRefillRecord, activeRefillLease),
    "one cleanup tick remains allowed after refill completion or failure")

T.finish("pnc_need_facility_triggers_smoke")
