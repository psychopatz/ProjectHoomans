-- Smoke test for unified World-Hour Needs + Anchor-Slope DeterministicStat engine:
--   1. PNC.DeterministicStat (Anchor/Evaluate/Bake/Shift, HorizonNeed, food/drink conversion, weight)
--   2. PNC.WorldHourNeeds (0-byte non-colonist pseudo-needs, mutation-only persistence, 0.88 cap,
--      18h off-screen forage wrap, stamina & stress bake-on-transition anchors)
--   3. PNC.NeedsStateCodec V3 (compact 9-slot encoding with fuelHours + weight, zero macro bloat)
--   4. PNC.IndividualNeeds (actor-agnostic Get/Satisfy for non-colonists + recruitment promotion)
--   5. StrangerEncounters micro-aid satisfaction wiring into WorldHourNeeds

local T = require "tests/support/test"

T.addPackagePaths()

local worldAgeH = 100.0
local nowMsVal = 10000

getGameTime = function()
    return { getWorldAgeHours = function() return worldAgeH end }
end

PNC = PNC or {}
PNC.Const = { PRESENCE_LIVE = "live" }
PNC.Core = {
    Now = function() return nowMsVal end,
    NowWorldAgeHours = function() return worldAgeH end,
    IsAuthority = function() return true end,
}
PNC.NeedsUtils = {
    WorldAgeHours = function() return worldAgeH end,
}

local Stat = T.load(T.path("ProjectHoomans", "shared", "PNC/Core/Needs/PNC_DeterministicStat.lua"))
local WorldNeeds = T.load(T.path("ProjectHoomans", "shared", "PNC/Core/Needs/PNC_WorldHourNeeds.lua"))
T.load(T.path("ProjectHoomans", "shared", "PNC/Core/Needs/PNC_NeedsSchema.lua"))
local Codec = PNC.NeedsStateCodec

-- 1. DeterministicStat anchor-slope primitives
local a = Stat.Anchor(1.0, 1000, -0.0001, 0, 1)
T.truthy(math.abs(Stat.Evaluate(a, 1000, 0, 1) - 1.0) < 0.0001, "evaluate at t0 returns v0")
T.truthy(math.abs(Stat.Evaluate(a, 6000, 0, 1) - 0.5) < 0.0001, "evaluate after 5000ms at -0.0001/ms is 0.5")

-- Bake-on-transition: switch from drain to regen at t=6000
local baked = Stat.Bake(a, 6000, 0.0002, 0, 1)
T.truthy(math.abs(baked - 0.5) < 0.0001, "bake returns current evaluated value")
T.equal(a.t, 6000, "bake stamps new timestamp")
T.truthy(math.abs(Stat.Evaluate(a, 7500, 0, 1) - 0.8) < 0.0001, "new slope applies cleanly after bake")

-- Discrete shift (e.g. melee swing cost)
local shifted = Stat.Shift(a, 7500, -0.3, 0, 1)
T.truthy(math.abs(shifted - 0.5) < 0.0001, "shift subtracts discrete delta at evaluated timestamp")

-- HorizonNeed & NeedToHorizon round-trip
local needAt0, surplus0 = Stat.HorizonNeed(105, 100, 24, 1)
T.equal(needAt0, 0, "positive fuel horizon yields 0 hunger")
T.equal(surplus0, 5, "positive fuel horizon reports surplus hours")
local needAt12 = Stat.HorizonNeed(100, 112, 24, 1)
T.truthy(math.abs(needAt12 - 0.5) < 0.0001, "12h past horizon over 24h burn yields 0.5 need")
local backH = Stat.NeedToHorizon(0.5, 112, 24)
T.truthy(math.abs(backH - 100) < 0.0001, "NeedToHorizon inverts HorizonNeed")

-- Vanilla PZ food/drink conversion
local fuelH = Stat.CaloriesToFuelHours(1000, -0.50)
T.truthy(fuelH > 6 and fuelH < 14, "1000 kcal / -50 hunger meal converts to reasonable world-hours of fuel")
local waterH = Stat.ThirstToWaterHours(-0.50)
T.truthy(math.abs(waterH - 6.0) < 0.001, "-0.50 thirst converts to 6h hydration")

-- Deterministic weight evolution from world-hour fuel surplus/deficit
local wGain = Stat.EvaluateWeightFromFuelHours(80, 30, 24, false, false, 35, 200)
local wLoss = Stat.EvaluateWeightFromFuelHours(80, -30, 24, false, false, 35, 200)
local wFlat = Stat.EvaluateWeightFromFuelHours(80, 0, 24, false, false, 35, 200)
T.truthy(wGain > 80.5, "sustained fuel surplus increases weight")
T.truthy(wLoss < 79.5, "sustained fuel deficit decreases weight")
T.equal(wFlat, 80, "neutral fuel balance keeps weight steady")

-- 2. WorldHourNeeds: 0-byte non-colonist pseudo-needs + mutation-only persistence
local roamer = { id = "roamer_alpha", factionID = "strangers" }
local h1 = WorldNeeds.GetPseudoNeed(roamer, "hunger", 100)
local h2 = WorldNeeds.GetPseudoNeed(roamer, "hunger", 100)
T.equal(h1, h2, "untouched non-colonist pseudo-need is deterministic")
T.equal(roamer.pseudoNeeds, nil, "reading untouched non-colonist allocates 0 bytes of ModData")
T.truthy(h1 >= 0 and h1 <= 0.88, "non-colonist pseudo-need stays within [0, 0.88]")

-- Feed roamer a meal descriptor -> allocates only pseudoNeeds.fedH
local okFeed, afterFeed = WorldNeeds.SatisfyPseudoNeed(roamer, "hunger", { calories = 1200, hungerChange = -0.60 }, 100)
T.truthy(okFeed, "SatisfyPseudoNeed succeeds for hunger")
T.truthy(type(roamer.pseudoNeeds) == "table" and type(roamer.pseudoNeeds.fedH) == "number",
    "mutating hunger stores only fedH timestamp")
T.equal(roamer.pseudoNeeds.drankH, nil, "mutating hunger does not allocate drankH")
T.truthy(afterFeed < h1 or afterFeed == 0, "feeding lowers hunger need")

-- After 24h (> 18h off-screen forage cycle), roamer wraps back to non-lethal bounded cycle
local muchLater = WorldNeeds.GetPseudoNeed(roamer, "hunger", 200)
T.truthy(muchLater >= 0 and muchLater <= 0.88, "off-screen forage wrap prevents lethal starvation")

-- Actor-agnostic stamina & stress anchors
T.equal(WorldNeeds.GetStamina(roamer, 10000), 1, "untouched stamina defaults to 1")
WorldNeeds.SetStaminaRate(roamer, -0.0001, 10000)
T.truthy(math.abs(WorldNeeds.GetStamina(roamer, 14000) - 0.6) < 0.0001, "stamina drains deterministically while sprinting")
WorldNeeds.ConsumeStamina(roamer, 0.2, 14000)
T.truthy(math.abs(WorldNeeds.GetStamina(roamer, 14000) - 0.4) < 0.0001, "discrete stamina cost applies immediately")

WorldNeeds.AddStress(roamer, 0.6, 100)
T.truthy(math.abs(WorldNeeds.GetStress(roamer, 100) - 0.6) < 0.0001, "stress spike registers at t0")
T.truthy(WorldNeeds.GetStress(roamer, 105) < 0.25, "stress decays deterministically over world hours")

-- 3. NeedsStateCodec V3 round-trip (9 compact slots, fuelHours + weight, zero macro bloat)
T.equal(Codec.VERSION, 3, "NeedsStateCodec version must be 3")
local encoded = Codec.Encode({
    npc1 = {
        needs = { hunger = 0.25, thirst = 0.40, fatigue = 0.15 },
        hungerOverflow = 0.05,
        nutrition = { fuelHours = 18.5, weight = 78.4 },
        morale = { conditions = { fed = { value = 0.2, days = 2 } }, lastDay = 4 },
    },
}, worldAgeH)
T.equal(encoded.v, 3, "V3 payload version is 3")
T.equal(#encoded.n.npc1, 9, "V3 packed needs tuple must have 9 slots")
local decodedAll, decodedAt = Codec.Decode(encoded)
T.equal(decodedAt, worldAgeH, "V3 decode preserves shared timestamp")
local decoded = decodedAll.npc1
T.truthy(math.abs(decoded.needs.hunger - 0.25) < 0.005, "V3 decode preserves hunger")
T.truthy(math.abs(decoded.needs.thirst - 0.40) < 0.005, "V3 decode preserves thirst")
T.truthy(math.abs(decoded.nutrition.fuelHours - 18.5) < 0.15, "V3 decode preserves fuelHours")
T.truthy(math.abs(decoded.nutrition.weight - 78.4) < 0.15, "V3 decode preserves weight")
T.equal(decoded.nutrition.carbohydrates, 0, "V3 decode zeroes legacy carbohydrates")
T.truthy(decoded.nutrition.calories > 1400, "V3 decode derives display calories from fuelHours")

-- 4. IndividualNeeds actor-agnostic Get/Satisfy + recruitment promotion
package.preload["PsychopatzCore/Events/PC_EventBus"] = function()
    return { emit = function() end }
end
ModData = { values = {}, getOrCreate = function(key)
    ModData.values[key] = ModData.values[key] or {}
    return ModData.values[key]
end }
SandboxVars = { ProjectHoomans = { PlayerOwnedNPCNutritionMode = 2 } }
PNC.Registry = PNC.Registry or { Data = {}, MarkDirty = function() end }
PNC.Identity = PNC.Identity or { MixSeed = function() return 1 end }
T.load(T.path("ProjectHoomans", "shared", "PNC/Core/Events/PNC_EventDefinitions.lua"))
T.load(T.path("ProjectHoomans", "shared", "PNC/Core/Needs/PNC_NeedsDefinitions.lua"))
T.load(T.path("ProjectHoomans", "shared", "PNC/Core/Needs/PNC_PlayerNeedsModel.lua"))
T.load(T.path("ProjectHoomans", "shared", "PNC/Core/Needs/PNC_NeedsUtils.lua"))
T.load(T.path("ProjectHoomans", "shared", "PNC/Core/Base/PNC_Sandbox.lua"))
T.load(T.path("ProjectHoomans", "server", "PNC/Needs/PNC_NeedsRepository.lua"))
T.load(T.path("ProjectHoomans", "server", "PNC/Needs/PNC_IndividualNeeds.lua"))

local Needs = PNC.IndividualNeeds
local strangerRec = { id = "stranger_recruit", alive = true, factionID = "nomads" } -- not player-owned
local sHunger = Needs.Get(strangerRec, "hunger")
T.truthy(type(sHunger) == "number" and sHunger >= 0 and sHunger <= 0.88,
    "IndividualNeeds.Get transparently evaluates non-colonist pseudo-needs")
T.equal(strangerRec.pseudoNeeds, nil, "IndividualNeeds.Get does not allocate ModData on untouched non-colonist")

local satOk = Needs.Satisfy(strangerRec, "hunger", 0.5, "ration")
T.truthy(satOk, "IndividualNeeds.Satisfy works for non-colonists")
T.truthy(type(strangerRec.pseudoNeeds) == "table" and strangerRec.pseudoNeeds.fedH ~= nil,
    "IndividualNeeds.Satisfy records pseudoNeeds.fedH for non-colonists")

-- Promote stranger to player colonist: Needs.Ensure migrates pseudoNeeds and clears it
strangerRec.recruited = true
strangerRec.vanillaTraits = {}
strangerRec.vanillaTraitsAuthored = true
PNC.Registry.Data[strangerRec.id] = strangerRec
local promoted = Needs.Ensure(strangerRec)
T.truthy(type(promoted) == "table" and type(promoted.hunger) == "number",
    "Needs.Ensure initializes colonist needs table on recruitment")
T.equal(strangerRec.pseudoNeeds, nil, "Needs.Ensure clears pseudoNeeds after promoting to colonist")

-- 5. StrangerEncounters micro-aid satisfies WorldHourNeeds on ACCEPT
PNC.Semantics = PNC.Semantics or {}
PNC.Semantics.DialogueBeats = PNC.Semantics.DialogueBeats or {}
local Beats = PNC.Semantics.DialogueBeats
local emittedBeats = {}
Beats.RegisterHook = function() end
Beats.Emit = function(ev, payload)
    emittedBeats[#emittedBeats + 1] = { eventName = ev, payload = payload }
    return true, "aid_thread"
end
PNC.Semantics.ConversationDirector = {
    EvaluateCandidate = function() return true end,
    SelectSuggestionForNPC = function() return { speechAct = "ACCEPT" } end,
    MarkSpoken = function() end,
}
T.load(T.path("ProjectHoomans", "shared", "PNC/Semantics/PNC_ActorReference.lua"))
T.load(T.path("ProjectHoomans", "server", "PNC/Semantics/Beats/PNC_SemanticBeats_StrangerEncounters.lua"))
Beats.ResetStrangerEncountersRuntime()

local hungryDrifter = {
    id = "drifter_aid", name = "Owen", factionID = "drifters",
    socialStyle = "warm", x = 10, y = 10, z = 0, alive = true,
}
local helperNpc = {
    id = "helper_aid", name = "Nora", factionID = "settlers",
    socialStyle = "warm", x = 12, y = 10, z = 0, alive = true,
}
-- Force hungryDrifter to be hungry (0.75) and hydrated (0.0) at worldAgeH = 100
hungryDrifter.pseudoNeeds = { fedH = 82, drankH = 105 }
local beforeAid = WorldNeeds.GetPseudoNeed(hungryDrifter, "hunger", 100)
T.truthy(beforeAid >= 0.70, "drifter starts hungry before micro-aid")

local okAid = Beats.TryCrossFactionEncounter({
    { teamKey = "drifters", members = { hungryDrifter } },
    { teamKey = "settlers", members = { helperNpc } },
}, 50000, { cooldownScale = 1.0 }, false)
T.truthy(okAid == true and #emittedBeats == 1, "hungry drifter emits stranger encounter")
T.equal(emittedBeats[1].eventName, "ambient.stranger_aid", "event must be ambient.stranger_aid")
local afterAid = WorldNeeds.GetPseudoNeed(hungryDrifter, "hunger", 100)
T.truthy(afterAid < beforeAid, "ACCEPT on ambient.stranger_aid must satisfy stranger hunger via WorldHourNeeds")

T.finish("pnc_world_hour_needs_smoke")
