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

PNC = {
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
        IsAtHome = function() return true end,
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
        Commands = {
            RegisterProvider = function(_, value) provider = value end,
            MarkDirty = function() dirty = dirty + 1 end,
        },
    },
    TaskLeaseService = { ForNPC = function() return nil end },
    CompanionCommands = { IsCompanion = function() return true end },
    NPCSupplyService = { Process = function()
        supplyCalls = supplyCalls + 1
        record.needs.hunger = 0.05
        return true, "fulfilled"
    end },
}

local Triggers = T.load("ProjectHoomans", "server",
    "PNC/Needs/NeedFacilityTriggers/PNC_NeedFacilityTriggers.lua")
T.load("ProjectHoomans", "server", "PNC/Needs/PNC_NeedSupplyBridge.lua")

T.equal(provider, Triggers, "single provider owns all facility need routes")
local candidates = Triggers.GetCandidates(record.id)
T.equal(#candidates, 5, "all configured need routes produce candidates")

T.truthy(Triggers.PreferFacility(record, "hunger"),
    "dining is preferred while a table is available")
T.equal(dirty, 1, "facility preference schedules one task reevaluation")
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

T.finish("pnc_need_facility_triggers_smoke")
