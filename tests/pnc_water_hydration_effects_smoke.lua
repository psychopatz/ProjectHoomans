local T = require "tests/support/test"

T.addPackagePaths()

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local thirst = 0.80
local thirstSetCount = 0
local drinkCount = 0
local consumeCount = 0
local refillCount = 0
local refillResult = true
local eventCount = 0
local source = { key = "sink:combined", object = {} }
local container = { id = "bottle:1", type = "Base.EmptyBottle" }

PNC = {
    Core = { Now = function() return 1000 end },
    IndividualNeeds = {
        Get = function(_, needType)
            return needType == "thirst" and thirst or nil
        end,
        Set = function(_, needType, value)
            if needType ~= "thirst" then return nil end
            thirst = tonumber(value) or 0
            thirstSetCount = thirstSetCount + 1
            return thirst
        end,
        Commands = {
            ApplyDrink = function(_, relief)
                drinkCount = drinkCount + 1
                thirst = thirst - (tonumber(relief.thirst) or 0)
                return true
            end,
        },
    },
    WaterHydrationPolicy = {
        GetContext = function(_, options)
            if options and options.manualOverride == true then
                return { kind = "MANUAL_OVERRIDE", manualOverride = true }
            end
            return { kind = "HOME", baseId = "base:1" }
        end,
    },
    Inventory = {
        GetWaterContainer = function() return container end,
        IsRefillableWaterContainer = function(item)
            return item == container
        end,
    },
    NearbyWaterService = {
        DesiredLiters = function() return 1 end,
        Consume = function(_, foundSource, liters)
            T.equal(foundSource, source,
                "direct drinking consumes the resolved source")
            consumeCount = consumeCount + 1
            return true, liters, 0
        end,
        IsFillableFaucet = function() return true end,
    },
    WaterContainerService = {
        IsFillableFaucet = function() return true end,
        Refill = function(_, itemID, foundSource)
            T.equal(itemID, container.id,
                "combined hydration refills the selected bottle")
            T.equal(foundSource, source,
                "combined hydration reuses the consumed source")
            refillCount = refillCount + 1
            if not refillResult then return false, "WATER_REFILL_FAILED" end
            return true, 1, itemID
        end,
    },
}

local Events = require "PsychopatzCore/Events/PC_EventBus"
local EventTypes = require "PNC/Core/Events/PNC_EventDefinitions"
Events.subscribe(EventTypes.NPC_WATER_REFILL_DRANK, function()
    eventCount = eventCount + 1
end, "tests.water_hydration_effects")

local Effects = T.load("ProjectHoomans", "server",
    "PNC/Needs/NeedFacilityTriggers/PNC_NeedFacilityEffects.lua")
local record = {
    id = "npc:combined-water", alive = true,
    needs = { thirst = thirst },
    runtime = { facilityActivity = {
        capability = "survival.drink.world",
        resourceKind = "world_water",
        manualOverride = false,
    }},
}
local definition = { needEffect = "world_water", effectDelayMs = 0 }
local state = {
    resource = source, resourceKey = source.key,
    activityItemID = container.id,
    activityItemFullType = container.type,
}
local ok, complete, reason, amount = Effects.Tick(
    record, state, definition, 0, 1000)
T.truthy(ok and complete, "direct source drinking completes")
T.equal(reason, "NEED_COMPLETE", "combined hydration keeps the completion reason")
T.equal(amount, 1, "combined hydration reports consumed liters")
T.equal(consumeCount, 1, "direct drinking consumes water once")
T.equal(refillCount, 1, "direct drinking fills a carried bottle once")
T.equal(drinkCount, 0, "successful bottle fill avoids a second drink mutation")
T.equal(thirst, 0, "successful bottle fill clears thirst")
T.equal(thirstSetCount, 1, "combined hydration clears thirst once")
T.equal(eventCount, 1, "combined hydration emits one refill-drink event")
T.truthy(state.optionalBottleFill,
    "combined hydration records the optional bottle fill")

-- A refill failure must not roll back the already committed direct drink, and
-- it must fall back to ordinary thirst relief exactly once.
thirst = 0.80
thirstSetCount = 0
drinkCount = 0
refillResult = false
state = { resource = source, resourceKey = source.key }
ok, complete, reason = Effects.Tick(
    record, state, definition, 0, 1001)
T.truthy(ok and complete, "direct drinking survives optional fill failure")
T.equal(consumeCount, 2, "failed optional fill does not repeat direct drinking")
T.equal(refillCount, 2, "optional fill attempts one transaction")
T.equal(drinkCount, 1, "optional fill failure falls back to thirst relief")
T.near(thirst, 0.30, 0.000001,
    "optional fill failure preserves the direct drink relief")
T.falsy(state.optionalBottleFill,
    "optional fill failure is recorded without failing the drink")

-- Outside the authorized context, direct drinking remains available but the
-- opportunistic refill is skipped; only refill movement is location-gated.
PNC.WaterHydrationPolicy.GetContext = function()
    return nil, "WATER_LOCATION_REQUIRED"
end
thirst = 0.80
drinkCount = 0
refillResult = true
state = { resource = source, resourceKey = source.key }
ok, complete = Effects.Tick(record, state, definition, 0, 1002)
T.truthy(ok and complete, "direct drinking remains valid away from home")
T.equal(refillCount, 2, "unauthorized context skips bottle refill")
T.equal(drinkCount, 1, "unauthorized context uses ordinary thirst relief")

T.finish("pnc_water_hydration_effects_smoke")
