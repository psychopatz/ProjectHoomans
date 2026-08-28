local T = require "tests/support/test"

-- Focused Phase 1 Needs contract smoke test. Run with: lua tests/pnc_needs_foundation_smoke.lua

PNC = {
    Core = {
        DeepCopy = function(value)
            local output = {}; for key, entry in pairs(value or {}) do output[key] = type(entry) == "table" and PNC.Core.DeepCopy(entry) or entry end; return output
        end,
        Now = function() return 0 end,
    },
    Identity = { MixSeed = function(seed) return #tostring(seed) * 17 end },
    Registry = { Data = {}, MarkDirty = function() end },
}
local emitted = {}
package.preload["PsychopatzCore/Events/PC_EventBus"] = function()
    return { emit = function(...) emitted[#emitted + 1] = { ... } end }
end
ModData = { values = {}, getOrCreate = function(key)
    ModData.values[key] = ModData.values[key] or {}; return ModData.values[key]
end }
SandboxVars = { ProjectHoomans = {} }
local age = 10
getGameTime = function() return { getWorldAgeHours = function() return age end } end
isClient = function() return false end
isServer = function() return true end
local levelEvents = {}

local root = T.path("ProjectHoomans", "root", "")
T.load(root .. "shared/PNC/Core/Needs/PNC_NeedsDefinitions.lua")
T.load(root .. "shared/PNC/Core/Events/PNC_EventDefinitions.lua")
T.load(root .. "shared/PNC/Core/Needs/PNC_NeedsStateCodec.lua")
T.load(root .. "shared/PNC/Core/Needs/PNC_PlayerNeedsModel.lua")
T.load(root .. "shared/PNC/Core/Needs/PNC_NeedsUtils.lua")
T.load(root .. "shared/PNC/Core/Base/PNC_Sandbox.lua")
T.load(root .. "server/PNC/Needs/PNC_NeedsRepository.lua")

local factions = {}
PNC.Factions = {
    Get = function(id) return factions[id] end,
    IsMobileGroup = function(faction) return faction and faction.mobile and faction.mobile.active == true end,
    SetNeeds = function(id, state) factions[id].needs = PNC.Core.DeepCopy(state); return true end,
    List = function() local output = {}; for _, faction in pairs(factions) do output[#output + 1] = faction end; return output end,
}
T.load(root .. "server/PNC/Needs/PNC_IndividualNeeds.lua")
T.load(root .. "server/PNC/Needs/PNC_GroupNeeds.lua")
T.load(root .. "server/PNC/Needs/PNC_NeedHealthConsequences.lua")
T.load(root .. "server/PNC/Needs/PNC_NeedsScheduler.lua")
PNC.CompanionCommands = { IsOwnedByPlayer = function(record) return record.recruited == true end }
PNC.Factions.GetPlayerFaction = function() return nil end
T.load(root .. "server/PNC/Colony/PNC_ColonyManagement.lua")
PNC.GroupNeeds.RegisterListener("level_changed", function(...) levelEvents[#levelEvents + 1] = { values = { ... } } end)

factions.small = { id = "small", name = "Small", mobile = { active = true }, memberIDs = { a = true, b = true } }
factions.large = { id = "large", name = "Large", mobile = { active = true }, memberIDs = { a = true, b = true, c = true, d = true, e = true, f = true, g = true, h = true, i = true, j = true } }
local small = PNC.GroupNeeds.Ensure("small")
T.truthy(small.hunger >= 0 and small.hunger <= 0.20,
    "group initialization range")
PNC.GroupNeeds.Set("small", "hunger", 0.20, "test")
PNC.GroupNeeds.Update("small", 6, "test")
T.truthy(PNC.GroupNeeds.Get("small", "hunger") > 0.20,
    "passive hunger increase")
local smallRate = PNC.GroupNeeds.GetRates("small").hunger
local largeRate = PNC.GroupNeeds.GetRates("large").hunger
T.truthy(largeRate > smallRate, "group size rate modifier")
PNC.GroupNeeds.SetDebugActivity("small", "resting")
T.truthy(PNC.GroupNeeds.GetRates("small").fatigue
    < PNC.NeedsDefinitions.GROUP_RATES_PER_HOUR.fatigue
        * PNC.NeedsUtils.GroupSizeModifier(2),
    "resting slows awake fatigue gain")
PNC.GroupNeeds.Set("small", "thirst", -10, "test")
T.equal(PNC.GroupNeeds.Get("small", "thirst"), 0, "lower clamp")
PNC.GroupNeeds.Set("small", "thirst", 200, "test")
T.equal(PNC.GroupNeeds.Get("small", "thirst"), 1, "upper clamp")
T.equal(PNC.NeedsDefinitions.GetLevel("hunger", 0.44), "MODERATE",
    "vanilla hunger moodle level")
T.equal(PNC.NeedsDefinitions.GetLevel("hunger", 0.15), "MINOR",
    "vanilla hunger threshold boundary")
PNC.GroupNeeds.Set("small", "thirst", 0.24, "test")
PNC.GroupNeeds.Set("small", "thirst", 0.26, "test")
T.equal(levelEvents[#levelEvents].values[2], "thirst", "threshold listener")
local scavenged = PNC.GroupNeeds.DebugAbstractScavenge("small")
T.truthy(scavenged.hunger >= 0.20 and scavenged.thirst >= 0.20,
    "abstract scavenging restoration")

local npc = { id = "npc", recruited = true, vanillaTraits = {},
    vanillaTraitsAuthored = true }
local needs = PNC.IndividualNeeds.Ensure(npc)
T.equal(needs.hunger, 0, "player-compatible individual initialization")
PNC.IndividualNeeds.Set(npc, "hunger", 0.20, "test")
PNC.IndividualNeeds.Update(npc, 1, "test")
T.truthy(PNC.IndividualNeeds.Get(npc, "hunger") > 0.20,
    "individual elapsed update")
local highThirst = { id = "high_thirst", recruited = true,
    vanillaTraits = { highthirst = true } }
local normal = { id = "normal", recruited = true, vanillaTraits = {},
    vanillaTraitsAuthored = true }
PNC.IndividualNeeds.Ensure(highThirst)
PNC.IndividualNeeds.Ensure(normal)
T.near(PNC.IndividualNeeds.GetRates(normal).hunger, 0.0216, 0.000001, "owned hunger uses colony pacing")
T.near(PNC.IndividualNeeds.GetRates(normal).thirst, 0.01728, 0.000001, "owned thirst uses colony pacing")
T.near(PNC.IndividualNeeds.GetRates(normal).fatigue, 0.0268272, 0.000001, "owned fatigue uses colony pacing")
T.truthy(0.25 / PNC.IndividualNeeds.GetRates(normal).hunger > 11.5,
    "idle food threshold is not reached within a few game hours")
T.equal(PNC.IndividualNeeds.GetRates(highThirst).thirst,
    PNC.IndividualNeeds.GetRates(normal).thirst * 2,
    "High Thirst vanilla multiplier")
local lowThirst = { id = "low_thirst", recruited = true,
    vanillaTraits = { "Base.LowThirst" } }
PNC.IndividualNeeds.Ensure(lowThirst)
T.equal(PNC.IndividualNeeds.GetRates(lowThirst).thirst,
    PNC.IndividualNeeds.GetRates(normal).thirst * 0.5,
    "Low Thirst vanilla multiplier and namespaced trait normalization")
local hearty = { id = "hearty", recruited = true,
    vanillaTraits = { heartyappetite = true } }
PNC.IndividualNeeds.Ensure(hearty)
T.equal(PNC.IndividualNeeds.GetRates(hearty).hunger,
    PNC.IndividualNeeds.GetRates(normal).hunger * 1.5,
    "Hearty Appetite vanilla multiplier")
local lightEater = { id = "light_eater", recruited = true,
    vanillaTraits = { lighteater = true } }
PNC.IndividualNeeds.Ensure(lightEater)
T.equal(PNC.IndividualNeeds.GetRates(lightEater).hunger,
    PNC.IndividualNeeds.GetRates(normal).hunger * 0.75,
    "Light Eater vanilla multiplier")
local wakeful = { id = "wakeful", recruited = true,
    vanillaTraits = { needslesssleep = true } }
PNC.IndividualNeeds.Ensure(wakeful)
T.equal(PNC.IndividualNeeds.GetRates(wakeful).fatigue,
    PNC.IndividualNeeds.GetRates(normal).fatigue * 0.7,
    "Wakeful vanilla multiplier")
local overweight = { id = "overweight", recruited = true,
    vanillaTraits = { overweight = true } }
PNC.IndividualNeeds.Ensure(overweight)
T.equal(PNC.IndividualNeeds.GetRates(overweight).hunger,
    PNC.IndividualNeeds.GetRates(normal).hunger,
    "Overweight does not alter vanilla hunger stat")
local starving = { id = "starving", recruited = true, alive = true,
    vanillaTraits = {}, vanillaTraitsAuthored = true,
    health = { current = 100, max = 100, state = "normal" } }
PNC.Health = {
    ApplyDamage = function(record, _, event)
        record.health.current = record.health.current - event.amount
        return true
    end,
}
PNC.IndividualNeeds.Ensure(starving, {
    hunger = 1, thirst = 1, fatigue = 1,
})
PNC.IndividualNeeds.Update(starving, 5, "test_starvation_build")
T.equal(starving.health.current, 100,
    "whole-body ailment buildup does not damage early")
T.near(starving.health.body.wholeBodyAilments.starvation.severity,
    0.5, 0.000001, "starvation buildup is persistent")
T.near(starving.health.body.wholeBodyAilments.dehydration.severity,
    0.5, 0.000001, "dehydration buildup is persistent")
PNC.IndividualNeeds.Update(starving, 5, "test_starvation_onset")
T.equal(starving.health.current, 100,
    "damage starts after the whole-body ailment reaches 100%")
T.near(starving.health.body.wholeBodyAilments.starvation.severity,
    1, 0.000001, "starvation ailment reaches full severity")
T.near(starving.health.body.wholeBodyAilments.dehydration.severity,
    1, 0.000001, "dehydration ailment reaches full severity")
PNC.IndividualNeeds.Update(starving, 1, "test_emergency_damage")
local expectedDamage = PNC.NeedHealthConsequences.DAMAGE_PER_WORLD_HOUR.hunger
    + PNC.NeedHealthConsequences.DAMAGE_PER_WORLD_HOUR.thirst
T.near(starving.health.current, 100 - expectedDamage, 0.000001, "vanilla emergency hunger and thirst health damage")
PNC.IndividualNeeds.Set(starving, "hunger", 0, "test_starvation_cured")
PNC.IndividualNeeds.Set(starving, "thirst", 0, "test_dehydration_cured")
PNC.IndividualNeeds.Update(starving, 5, "test_whole_body_recovery")
T.equal(starving.health.body.wholeBodyAilments.starvation, nil,
    "resolved hunger removes starvation from the body")
T.equal(starving.health.body.wholeBodyAilments.dehydration, nil,
    "resolved thirst removes dehydration from the body")
local exhausted = { id = "exhausted", recruited = true, alive = true,
    vanillaTraits = {}, vanillaTraitsAuthored = true,
    health = { current = 100, max = 100, state = "normal" } }
PNC.IndividualNeeds.Ensure(exhausted, {
    hunger = 0, thirst = 0, fatigue = 1,
})
PNC.IndividualNeeds.Update(exhausted, 1, "test_fatigue_no_damage")
T.equal(exhausted.health.current, 100,
    "vanilla fatigue does not directly damage health")
local canonical = PNC.NeedsUtils.NormalizeState({
    version = 1, hunger = 0.25, thirst = 0.80, fatigue = 1,
}, age)
T.equal(canonical.hunger, 0.25, "canonical pressure is not migrated")
T.equal(canonical.thirst, 0.80, "canonical thirst pressure")
PNC.Registry.Data[npc.id] = npc
local colonySnapshot = PNC.ColonyManagement.BuildSnapshot({})
T.equal(#colonySnapshot.people, 1, "colony companion summary")
T.truthy(colonySnapshot.levels.hunger ~= nil, "colony need-level summary")
T.finish("pnc_needs_foundation_smoke")

T.finish("pnc_needs_foundation_smoke")
