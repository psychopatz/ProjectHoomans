-- Focused Phase 1 Needs contract smoke test. Run with: lua tests/pnc_needs_foundation_smoke.lua
local function assertTrue(value, message)
    if not value then error(message or "expected true", 2) end
end
local function assertEqual(actual, expected, message)
    if actual ~= expected then error((message or "values differ") .. ": " .. tostring(actual) .. " ~= " .. tostring(expected), 2) end
end
local function assertNear(actual, expected, tolerance, message)
    if math.abs(actual - expected) > tolerance then
        error((message or "values not near") .. ": " .. tostring(actual)
            .. " ~= " .. tostring(expected), 2)
    end
end

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

local root = "Contents/mods/ProjectHoomans/42.20/media/lua/"
dofile(root .. "shared/PNC/Core/Needs/PNC_NeedsDefinitions.lua")
dofile(root .. "shared/PNC/Core/Events/PNC_EventDefinitions.lua")
dofile(root .. "shared/PNC/Core/Needs/PNC_NeedsStateCodec.lua")
dofile(root .. "shared/PNC/Core/Needs/PNC_PlayerNeedsModel.lua")
dofile(root .. "shared/PNC/Core/Needs/PNC_NeedsUtils.lua")
dofile(root .. "shared/PNC/Core/Base/PNC_Sandbox.lua")
dofile(root .. "server/PNC/Needs/PNC_NeedsRepository.lua")

local factions = {}
PNC.Factions = {
    Get = function(id) return factions[id] end,
    IsMobileGroup = function(faction) return faction and faction.mobile and faction.mobile.active == true end,
    SetNeeds = function(id, state) factions[id].needs = PNC.Core.DeepCopy(state); return true end,
    List = function() local output = {}; for _, faction in pairs(factions) do output[#output + 1] = faction end; return output end,
}
dofile(root .. "server/PNC/PNC_IndividualNeeds.lua")
dofile(root .. "server/PNC/PNC_GroupNeeds.lua")
dofile(root .. "server/PNC/Needs/PNC_NeedHealthConsequences.lua")
dofile(root .. "server/PNC/PNC_NeedsScheduler.lua")
PNC.CompanionCommands = { IsOwnedByPlayer = function(record) return record.recruited == true end }
PNC.Factions.GetPlayerFaction = function() return nil end
dofile(root .. "server/PNC/PNC_ColonyManagement.lua")
PNC.GroupNeeds.RegisterListener("level_changed", function(...) levelEvents[#levelEvents + 1] = { values = { ... } } end)

factions.small = { id = "small", name = "Small", mobile = { active = true }, memberIDs = { a = true, b = true } }
factions.large = { id = "large", name = "Large", mobile = { active = true }, memberIDs = { a = true, b = true, c = true, d = true, e = true, f = true, g = true, h = true, i = true, j = true } }
local small = PNC.GroupNeeds.Ensure("small")
assertTrue(small.hunger >= 0 and small.hunger <= 0.20,
    "group initialization range")
PNC.GroupNeeds.Set("small", "hunger", 0.20, "test")
PNC.GroupNeeds.Update("small", 6, "test")
assertTrue(PNC.GroupNeeds.Get("small", "hunger") > 0.20,
    "passive hunger increase")
local smallRate = PNC.GroupNeeds.GetRates("small").hunger
local largeRate = PNC.GroupNeeds.GetRates("large").hunger
assertTrue(largeRate > smallRate, "group size rate modifier")
PNC.GroupNeeds.SetDebugActivity("small", "resting")
assertTrue(PNC.GroupNeeds.GetRates("small").fatigue
    < PNC.NeedsDefinitions.GROUP_RATES_PER_HOUR.fatigue
        * PNC.NeedsUtils.GroupSizeModifier(2),
    "resting slows awake fatigue gain")
PNC.GroupNeeds.Set("small", "thirst", -10, "test")
assertEqual(PNC.GroupNeeds.Get("small", "thirst"), 0, "lower clamp")
PNC.GroupNeeds.Set("small", "thirst", 200, "test")
assertEqual(PNC.GroupNeeds.Get("small", "thirst"), 1, "upper clamp")
assertEqual(PNC.NeedsDefinitions.GetLevel("hunger", 0.44), "MODERATE",
    "vanilla hunger moodle level")
assertEqual(PNC.NeedsDefinitions.GetLevel("hunger", 0.15), "MINOR",
    "vanilla hunger threshold boundary")
PNC.GroupNeeds.Set("small", "thirst", 0.24, "test")
PNC.GroupNeeds.Set("small", "thirst", 0.26, "test")
assertEqual(levelEvents[#levelEvents].values[2], "thirst", "threshold listener")
local scavenged = PNC.GroupNeeds.DebugAbstractScavenge("small")
assertTrue(scavenged.hunger >= 0.20 and scavenged.thirst >= 0.20,
    "abstract scavenging restoration")

local npc = { id = "npc", recruited = true, vanillaTraits = {},
    vanillaTraitsAuthored = true }
local needs = PNC.IndividualNeeds.Ensure(npc)
assertEqual(needs.hunger, 0, "player-compatible individual initialization")
PNC.IndividualNeeds.Set(npc, "hunger", 0.20, "test")
PNC.IndividualNeeds.Update(npc, 1, "test")
assertTrue(PNC.IndividualNeeds.Get(npc, "hunger") > 0.20,
    "individual elapsed update")
local highThirst = { id = "high_thirst", recruited = true,
    vanillaTraits = { highthirst = true } }
local normal = { id = "normal", recruited = true, vanillaTraits = {},
    vanillaTraitsAuthored = true }
PNC.IndividualNeeds.Ensure(highThirst)
PNC.IndividualNeeds.Ensure(normal)
assertNear(PNC.IndividualNeeds.GetRates(normal).hunger, 0.0216, 0.000001,
    "owned hunger uses colony pacing")
assertNear(PNC.IndividualNeeds.GetRates(normal).thirst, 0.01728, 0.000001,
    "owned thirst uses colony pacing")
assertNear(PNC.IndividualNeeds.GetRates(normal).fatigue, 0.0268272, 0.000001,
    "owned fatigue uses colony pacing")
assertTrue(0.25 / PNC.IndividualNeeds.GetRates(normal).hunger > 11.5,
    "idle food threshold is not reached within a few game hours")
assertEqual(PNC.IndividualNeeds.GetRates(highThirst).thirst,
    PNC.IndividualNeeds.GetRates(normal).thirst * 2,
    "High Thirst vanilla multiplier")
local lowThirst = { id = "low_thirst", recruited = true,
    vanillaTraits = { "Base.LowThirst" } }
PNC.IndividualNeeds.Ensure(lowThirst)
assertEqual(PNC.IndividualNeeds.GetRates(lowThirst).thirst,
    PNC.IndividualNeeds.GetRates(normal).thirst * 0.5,
    "Low Thirst vanilla multiplier and namespaced trait normalization")
local hearty = { id = "hearty", recruited = true,
    vanillaTraits = { heartyappetite = true } }
PNC.IndividualNeeds.Ensure(hearty)
assertEqual(PNC.IndividualNeeds.GetRates(hearty).hunger,
    PNC.IndividualNeeds.GetRates(normal).hunger * 1.5,
    "Hearty Appetite vanilla multiplier")
local lightEater = { id = "light_eater", recruited = true,
    vanillaTraits = { lighteater = true } }
PNC.IndividualNeeds.Ensure(lightEater)
assertEqual(PNC.IndividualNeeds.GetRates(lightEater).hunger,
    PNC.IndividualNeeds.GetRates(normal).hunger * 0.75,
    "Light Eater vanilla multiplier")
local wakeful = { id = "wakeful", recruited = true,
    vanillaTraits = { needslesssleep = true } }
PNC.IndividualNeeds.Ensure(wakeful)
assertEqual(PNC.IndividualNeeds.GetRates(wakeful).fatigue,
    PNC.IndividualNeeds.GetRates(normal).fatigue * 0.7,
    "Wakeful vanilla multiplier")
local overweight = { id = "overweight", recruited = true,
    vanillaTraits = { overweight = true } }
PNC.IndividualNeeds.Ensure(overweight)
assertEqual(PNC.IndividualNeeds.GetRates(overweight).hunger,
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
    hunger = 0.90, thirst = 0.90, fatigue = 1,
})
PNC.IndividualNeeds.Update(starving, 1, "test_emergency_damage")
local expectedDamage = PNC.NeedHealthConsequences.DAMAGE_PER_WORLD_HOUR.hunger
    + PNC.NeedHealthConsequences.DAMAGE_PER_WORLD_HOUR.thirst
assertNear(starving.health.current, 100 - expectedDamage, 0.000001,
    "vanilla emergency hunger and thirst health damage")
local exhausted = { id = "exhausted", recruited = true, alive = true,
    vanillaTraits = {}, vanillaTraitsAuthored = true,
    health = { current = 100, max = 100, state = "normal" } }
PNC.IndividualNeeds.Ensure(exhausted, {
    hunger = 0, thirst = 0, fatigue = 1,
})
PNC.IndividualNeeds.Update(exhausted, 1, "test_fatigue_no_damage")
assertEqual(exhausted.health.current, 100,
    "vanilla fatigue does not directly damage health")
local canonical = PNC.NeedsUtils.NormalizeState({
    version = 1, hunger = 0.25, thirst = 0.80, fatigue = 1,
}, age)
assertEqual(canonical.hunger, 0.25, "canonical pressure is not migrated")
assertEqual(canonical.thirst, 0.80, "canonical thirst pressure")
PNC.Registry.Data[npc.id] = npc
local colonySnapshot = PNC.ColonyManagement.BuildSnapshot({})
assertEqual(#colonySnapshot.people, 1, "colony companion summary")
assertTrue(colonySnapshot.levels.hunger ~= nil, "colony need-level summary")

print("pnc_needs_foundation_smoke: OK")
