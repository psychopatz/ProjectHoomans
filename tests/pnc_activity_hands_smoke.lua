local T = require "tests/support/test"

PNC = { Equipment = { Internal = {} } }

function getScriptManager()
    return {
        FindItem = function(_, fullType)
            return fullType ~= "Base.Invalid" and { fullType = fullType } or nil
        end,
    }
end

function instanceItem(fullType)
    return { fullType = fullType,
        getFullType = function(self) return self.fullType end }
end

T.load("ProjectHoomans", "shared", "PNC/Core/Equipment/PNC_Equipment_Items.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Equipment/PNC_Equipment/PNC_Equipment_ActivityHands.lua")

local body = { modData = {}, variables = {}, refreshes = 0 }
function body:getModData() return self.modData end
function body:setPrimaryHandItem(item) self.primary = item end
function body:setSecondaryHandItem(item) self.secondary = item end
function body:getPrimaryHandItem() return self.primary end
function body:getSecondaryHandItem() return self.secondary end
function body:resetEquippedHandsModels() self.refreshes = self.refreshes + 1 end
function body:setVariable(key, value) self.variables[key] = value end

local ok, reason = PNC.Equipment.ApplyActivityHands(body, {
    activityItemFullType = "Base.Apple",
    activityItemID = "food-1",
    hand = "primary",
})
T.truthy(ok, reason)
T.equal(body.primary.fullType, "Base.Apple", "primary activity item")
T.equal(body.secondary, nil, "food leaves secondary hand empty")
T.equal(body.variables.PNCActivityItem, "Base.Apple", "activity variable")
T.equal(body.modData.PNCActivityHandsItemID, "food-1",
    "activity hand latch keeps the exact item identity")

ok, reason = PNC.Equipment.ApplyActivityHands(body, {
    activityItemFullType = "Base.Apple",
    activityItemID = "food-1",
    hand = "primary",
})
T.truthy(ok, reason)
T.equal(body.refreshes, 1, "same activity item is latched")

ok, reason = PNC.Equipment.ApplyActivityHands(body, {})
T.falsy(ok, "an unresolved activity item is reported")
T.equal(reason, "activity_item_missing", "missing activity item reason")
T.equal(body.primary.fullType, "Base.Apple",
    "transient missing item does not clear the visible activity item")

ok, reason = PNC.Equipment.ApplyActivityHands(body, nil)
T.truthy(ok, reason)
T.equal(body.primary, nil, "activity item cleared")
T.equal(body.modData.PNCActivityHandsSignature, nil, "activity latch cleared")
T.equal(body.modData.PNCActivityHandsItemID, nil,
    "activity item identity clears with the visual latch")

local callErrorBody = { modData = {}, variables = {} }
function callErrorBody:getModData() return self.modData end
function callErrorBody:setPrimaryHandItem(item)
    self.primary = item
    error("simulated Kahlua return-frame failure")
end
function callErrorBody:setSecondaryHandItem(item) self.secondary = item end
function callErrorBody:getPrimaryHandItem() return self.primary end
function callErrorBody:getSecondaryHandItem() return self.secondary end
function callErrorBody:resetEquippedHandsModels() end
function callErrorBody:setVariable(key, value) self.variables[key] = value end
ok, reason = PNC.Equipment.ApplyActivityHands(callErrorBody, {
    activityItemFullType = "Base.Bread",
})
T.truthy(ok, reason)
T.equal(callErrorBody.primary.fullType, "Base.Bread",
    "a completed hand setter is accepted after a return-frame error")

ok, reason = PNC.Equipment.ApplyActivityHands(body, {
    activityItemFullType = "Base.Invalid",
})
T.falsy(ok, "invalid activity item rejected")
T.equal(reason, "invalid_full_type", "invalid activity item reason")

PNC.ClientPresenceSync = { Internal = {} }
PNC.Const = { PRESENCE_LIVE = "live" }
PNC.Animation = {}
PNC.Visuals = {}
PNC.Equipment = PNC.Equipment
T.load("ProjectHoomans", "client", "PNC/PresenceSync/PresenceVisuals/PNC_ClientPresenceVisuals_BodyPresentation.lua")

local resolve = PNC.ClientPresenceSync.Internal.ResolveActivityHands
local activity = resolve({
    actionInformation = {
        kind = "activity",
        capability = "food.dine",
        activityItemID = "food-1",
        activityItemFullType = "Base.Apple",
    },
    visualState = {
        sceneId = "survival.eat.inventory",
        sceneStartedAt = 10,
    },
})
T.equal(activity.source, "food", "food activity source")
T.equal(activity.activityItemFullType, "Base.Apple", "food activity item")
T.equal(activity.activityItemID, "food-1", "food activity item identity")

activity = resolve({
    actionInformation = {
        kind = "activity",
        capability = "survival.drink.inventory",
        activityItemID = "bottle-1",
        activityItemFullType = "Base.WaterBottle",
    },
    visualState = {
        sceneId = "survival.drink.inventory",
        sceneStartedAt = 15,
    },
})
T.equal(activity.source, "hydration", "inventory drink activity source")
T.equal(activity.activityItemID, "bottle-1",
    "inventory drink preserves the exact selected item")

activity = resolve({
    actionInformation = {
        kind = "activity",
        capability = "survival.fill.water",
        resourceKind = "water_refill",
        activityItemID = "bottle-2",
        activityItemFullType = "Base.WaterBottle",
    },
    visualState = {
        sceneActive = true,
        sceneId = "survival.fill.water",
        sceneStartedAt = 18,
    },
})
T.equal(activity.source, "water_refill", "water refill activity source")
T.equal(activity.activityItemID, "bottle-2",
    "water refill preserves the exact selected item")

activity = resolve({
    actionInformation = {
        kind = "activity",
        capability = "survival.drink.world",
        activityItemFullType = "Base.BucketWithWater",
    },
    visualState = {
        sceneId = "survival.drink.world",
        sceneStartedAt = 20,
    },
})
T.equal(activity.source, "world_water", "world water activity source")

activity = resolve({
    actionInformation = {
        kind = "treatment",
        phase = "bandaging",
        activityItemFullType = "Base.Bandage",
    },
    treatmentState = { phase = "bandaging", startedAt = 30 },
    visualState = {},
})
T.equal(activity.source, "self_treatment", "treatment activity source")
T.equal(activity.activityItemFullType, "Base.Bandage", "bandage item")

activity = resolve({
    actionInformation = { kind = "job:MedicalCare" },
    medicalCareState = {
        phase = "treating",
        bandageType = "Base.AlcoholBandage",
        startedAt = 40,
    },
    visualState = {},
})
T.equal(activity.source, "medical_care", "doctor activity source")
T.equal(activity.activityItemFullType, "Base.AlcoholBandage",
    "doctor bandage item")

activity = resolve({
    actionInformation = {
        kind = "activity",
        capability = "farm.work",
        activityItemFullType = "Base.CabbageSeed",
    },
    visualState = {
        sceneId = "facility.farm.work",
        sceneStartedAt = 42,
    },
})
T.equal(activity.source, "farming", "farming activity source")
T.equal(activity.activityItemFullType, "Base.CabbageSeed",
    "farming seed item")

T.falsy(resolve({
    actionInformation = {
        kind = "activity",
        capability = "farm.work",
        activityItemFullType = "Base.WateringCan",
    },
    visualState = { sceneId = "facility.farm.work.waiting" },
}), "farming work outside the farm scene does not claim an item")

activity = resolve({
    actionInformation = {
        kind = "activity",
        job = "Fishing",
        orderKind = "fishing",
        activityItemFullType = "Base.FishingRod",
    },
    visualState = {
        sceneId = "fishing.cast",
        sceneStartedAt = 44,
    },
})
T.equal(activity.source, "fishing", "fishing activity source")
T.equal(activity.activityItemFullType, "Base.FishingRod",
    "fishing rod item")

activity = resolve({
    actionInformation = {
        kind = "activity",
        job = "Scavenge",
        orderKind = "scavenge",
        phase = "LOOTING",
        activityItemFullType = "Base.CannedBeans",
    },
    visualState = {
        sceneId = "scavenge.loot_high",
        sceneStartedAt = 46,
    },
})
T.equal(activity.source, "scavenging", "scavenging activity source")
T.equal(activity.activityItemFullType, "Base.CannedBeans",
    "scavenging loot item")

T.falsy(resolve({
    actionInformation = {
        kind = "activity", job = "Scavenge", orderKind = "scavenge",
        activityItemFullType = "Base.CannedBeans",
    },
    visualState = { sceneId = "scavenge_search" },
}), "scavenging search movement does not claim loot")

T.falsy(resolve({
    actionInformation = {
        kind = "activity",
        job = "Fishing",
        orderKind = "fishing",
        activityItemFullType = "Base.FishingRod",
    },
    visualState = { sceneId = "fishing.cast.waiting" },
}), "fishing work outside the cast scene does not claim a rod")

activity = resolve({
    actionInformation = {
        kind = "work_order",
        operation = "CRAFT",
        activityItemFullType = "Base.Hammer",
    },
    visualState = {
        sceneId = "production.craft",
        sceneStartedAt = 45,
    },
})
T.equal(activity.source, "crafting", "crafting activity source")
T.equal(activity.activityItemFullType, "Base.Hammer",
    "crafting tool item")

activity = resolve({
    actionInformation = {
        kind = "work_order",
        operation = "DISASSEMBLE",
        activityItemFullType = "Base.Crate",
    },
    visualState = {
        sceneId = "production.disassemble",
        sceneStartedAt = 47,
    },
})
T.equal(activity.source, "disassembly", "disassembly activity source")
T.equal(activity.activityItemFullType, "Base.Crate",
    "disassembly specimen item")

T.falsy(resolve({
    actionInformation = {
        kind = "work_order",
        operation = "CRAFT",
        activityItemFullType = "Base.Hammer",
    },
    visualState = { sceneId = "production.craft.waiting" },
}), "crafting work outside the craft scene does not claim a tool")

activity = resolve({
    actionInformation = {
        kind = "work_order",
        operation = "BUILD_OBJECT",
        activityItemFullType = "Base.Hammer",
    },
    visualState = {
        sceneId = "production.construct",
        sceneStartedAt = 50,
    },
})
T.equal(activity.source, "construction", "construction activity source")
T.equal(activity.activityItemFullType, "Base.Hammer",
    "construction tool item")

T.falsy(resolve({
    actionInformation = {
        kind = "work_order",
        operation = "BUILD_OBJECT",
        activityItemFullType = "Base.Hammer",
    },
    visualState = { sceneId = "production.construct.waiting" },
}), "construction work outside the hammer scene does not claim a tool")

activity = resolve({
    actionInformation = {
        kind = "work_order",
        operation = "LUMBER",
        activityItemFullType = "Base.HandAxe",
    },
    visualState = {
        sceneId = "lumber.chop",
        sceneStartedAt = 60,
    },
})
T.equal(activity.source, "lumber", "lumber activity source")
T.equal(activity.activityItemFullType, "Base.HandAxe",
    "lumber tool item")

T.falsy(resolve({
    actionInformation = {
        kind = "activity",
        capability = "survival.drink.world",
        activityItemFullType = "Base.BucketWithWater",
    },
    visualState = { sceneId = "survival.drink.inventory" },
}), "world-water resolver does not claim an inventory scene")

local resolveDrinkSound = PNC.ClientPresenceSync.Internal.ResolveDrinkSound
local bottleDrink = {
    actionInformation = {
        capability = "survival.drink.inventory",
        activityItemFullType = "Base.WaterBottle",
    },
    visualState = {
        sceneActive = true, sceneId = "survival.drink.inventory",
        sceneStepId = "drink", sceneRevision = 1,
        scenePlaybackRevision = 1, sceneStepStartedAt = 100,
    },
}
T.equal(resolveDrinkSound(bottleDrink), "DrinkingFromBottlePlastic",
    "water bottle uses the plastic drinking SFX")
local faucetDrink = {
    actionInformation = {
        capability = "survival.drink.world", resourceKind = "faucet",
    },
    visualState = {
        sceneActive = true, sceneId = "survival.drink.world",
        sceneStepId = "drink", sceneRevision = 2,
        scenePlaybackRevision = 1, sceneStepStartedAt = 200,
    },
}
T.equal(resolveDrinkSound(faucetDrink), "DrinkingFromTap",
    "world faucet uses the tap drinking SFX")
local faucetFill = {
    actionInformation = {
        capability = "survival.fill.water", resourceKind = "water_refill",
        activityItemFullType = "Base.WaterBottle",
    },
    visualState = {
        sceneActive = true, sceneId = "survival.fill.water",
        sceneStepId = "fill", sceneRevision = 3,
        scenePlaybackRevision = 1, sceneStepStartedAt = 300,
    },
}
T.equal(resolveDrinkSound(faucetFill), "GetWaterFromTap",
    "water refill uses the tap fill SFX")
local sounds = {}
local stoppedSounds = {}
local emitter = {
    playSound = function(_, sound)
        sounds[#sounds + 1] = sound
        return #sounds
    end,
    stopSoundLocal = function(_, handle)
        stoppedSounds[#stoppedSounds + 1] = handle
    end,
}
local audioBody = {
    getEmitter = function() return emitter end,
}
local audioModData = {}
PNC.ClientPresenceSync.Internal.SyncDrinkSound(
    audioBody, bottleDrink, audioModData)
PNC.ClientPresenceSync.Internal.SyncDrinkSound(
    audioBody, bottleDrink, audioModData)
T.equal(#sounds, 1, "drink SFX is not replayed every presence snapshot")
T.equal(sounds[1], "DrinkingFromBottlePlastic",
    "drink SFX is sent through the body emitter")
PNC.ClientPresenceSync.Internal.SyncDrinkSound(
    audioBody,
    { visualState = { sceneActive = false } },
    audioModData)
T.equal(#stoppedSounds, 1,
    "drink SFX is stopped when the drink scene becomes inactive")
T.equal(audioModData.PNC_ClientDrinkSoundHandle, nil,
    "drink SFX handle is cleared after the scene stops")

T.finish("pnc_activity_hands_smoke")
