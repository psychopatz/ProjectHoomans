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
    ["water.drink"] = { { id = "water" } },
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

PNC = {
    Const = { ORDER_FOLLOW = "follow" },
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
        MarkDirty = function() end,
    },
    HomeDutyService = {
        GetBase = function() return { id = "base" } end,
        IsAtHome = function() return atHome end,
    },
    FacilityService = {
        ListByCapability = function(_, capability)
            return facilities[capability] or {}
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
            if kind == "FOOD" then return hasPersonalFood end
            if kind == "HYDRATION" then return hasPersonalHydration end
            return true
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
T.equal(#candidates, 5, "all configured need routes produce candidates")

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

facilities["water.drink"] = {}
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
    if candidate.sourceRef == "nearby_water" then
        residentNearbyCandidate = candidate
    end
end
T.falsy(residentNearbyCandidate,
    "a resident does not leave home for nearby water")
record.orderSpec = { kind = "follow" }
local nearbyCandidates = Triggers.GetCandidates(record.id)
local nearbyCandidate
for _, candidate in ipairs(nearbyCandidates) do
    if candidate.sourceRef == "nearby_water" then nearbyCandidate = candidate end
end
T.truthy(nearbyCandidate,
    "a follower can use nearby water when no spigot is available")
T.truthy(Triggers.PreferFacility(record, "hydration"),
    "nearby water is preferred for a follower")
local nearbyDefinition = { needEffect = "nearby_water", effectDelayMs = 0 }
ok, complete = PNC.NeedFacilityEffects.Tick(
    record, { resource = nearbyWater }, nearbyDefinition, 0, 1000)
T.truthy(ok and complete, "nearby water completes through the shared effect")
T.near(record.needs.thirst, 0.20, 0.000001,
    "nearby water applies proportional thirst relief")

-- Personal hydration, including a dual-purpose food, bypasses a water route
-- and lets NeedSupplyBridge consume the carried item directly.
hasPersonalHydration = true
local supplyBeforePersonalHydration = supplyCalls
T.falsy(Triggers.PreferFacility(record, "hydration"),
    "personal hydration still scheduled a water facility")
PNC.NeedSupplyBridge.Evaluate(record, "HYDRATION")
T.equal(supplyCalls, supplyBeforePersonalHydration + 1,
    "personal hydration did not fall back to the supply consumer")
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

record.runtime.inCombatUntil = 2000
PNC.Core = { Now = function() return 1000 end }
T.falsy(Triggers.PreferFacility(record, "hunger"),
    "a recent combat lease blocks the follower eating task")
record.runtime.inCombatUntil = nil

record.runtime.target = { id = "zombie:target" }
local beforeCombatWater = supplyCalls
T.falsy(Triggers.PreferFacility(record, "hydration"),
    "active combat does not schedule a nearby-water movement task")
PNC.NeedSupplyBridge.Evaluate(record, "HYDRATION")
T.equal(supplyCalls, beforeCombatWater + 1,
    "combat remains active while hydration falls back to inventory")
record.runtime.target = nil

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

T.finish("pnc_need_facility_triggers_smoke")
