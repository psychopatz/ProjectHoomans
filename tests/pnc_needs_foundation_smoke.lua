-- Focused Phase 1 Needs contract smoke test. Run with: lua tests/pnc_needs_foundation_smoke.lua
local function assertTrue(value, message)
    if not value then error(message or "expected true", 2) end
end
local function assertEqual(actual, expected, message)
    if actual ~= expected then error((message or "values differ") .. ": " .. tostring(actual) .. " ~= " .. tostring(expected), 2) end
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
local age = 10
getGameTime = function() return { getWorldAgeHours = function() return age end } end
isClient = function() return false end
isServer = function() return true end
local levelEvents = {}

local root = "Contents/mods/ProjectHoomans/42.20/media/lua/"
dofile(root .. "shared/PNC/Core/Needs/PNC_NeedsDefinitions.lua")
dofile(root .. "shared/PNC/Core/Needs/PNC_NeedsUtils.lua")

local factions = {}
PNC.Factions = {
    Get = function(id) return factions[id] end,
    IsMobileGroup = function(faction) return faction and faction.mobile and faction.mobile.active == true end,
    SetNeeds = function(id, state) factions[id].needs = PNC.Core.DeepCopy(state); return true end,
    List = function() local output = {}; for _, faction in pairs(factions) do output[#output + 1] = faction end; return output end,
}
dofile(root .. "server/PNC/PNC_IndividualNeeds.lua")
dofile(root .. "server/PNC/PNC_GroupNeeds.lua")
dofile(root .. "server/PNC/PNC_NeedsScheduler.lua")
PNC.CompanionCommands = { IsOwnedByPlayer = function(record) return record.recruited == true end }
PNC.Factions.GetPlayerFaction = function() return nil end
dofile(root .. "server/PNC/PNC_ColonyManagement.lua")
PNC.GroupNeeds.RegisterListener("level_changed", function(...) levelEvents[#levelEvents + 1] = { values = { ... } } end)

factions.small = { id = "small", name = "Small", mobile = { active = true }, memberIDs = { a = true, b = true } }
factions.large = { id = "large", name = "Large", mobile = { active = true }, memberIDs = { a = true, b = true, c = true, d = true, e = true, f = true, g = true, h = true, i = true, j = true } }
local small = PNC.GroupNeeds.Ensure("small")
assertTrue(small.hunger >= 70 and small.hunger <= 100, "group initialization range")
PNC.GroupNeeds.Set("small", "hunger", 60, "test")
PNC.GroupNeeds.Update("small", 6, "test")
assertTrue(PNC.GroupNeeds.Get("small", "hunger") < 60, "passive depletion")
local smallRate = PNC.GroupNeeds.GetRates("small").hunger
local largeRate = PNC.GroupNeeds.GetRates("large").hunger
assertTrue(largeRate > smallRate, "group size rate modifier")
PNC.GroupNeeds.Set("small", "fatigue", 20, "test")
PNC.GroupNeeds.SetDebugActivity("small", "resting")
PNC.GroupNeeds.Update("small", 1, "test")
assertTrue(PNC.GroupNeeds.Get("small", "fatigue") > 20, "rest recovers reserve")
PNC.GroupNeeds.Set("small", "hydration", -10, "test")
assertEqual(PNC.GroupNeeds.Get("small", "hydration"), 0, "lower clamp")
PNC.GroupNeeds.Set("small", "hydration", 200, "test")
assertEqual(PNC.GroupNeeds.Get("small", "hydration"), 100, "upper clamp")
assertEqual(PNC.NeedsDefinitions.GetLevel(49), "LOW", "condition level")
PNC.GroupNeeds.Set("small", "hydration", 51, "test")
PNC.GroupNeeds.Set("small", "hydration", 49, "test")
assertEqual(levelEvents[#levelEvents].values[2], "hydration", "threshold listener")
local scavenged = PNC.GroupNeeds.DebugAbstractScavenge("small")
assertTrue(scavenged.hunger >= 20 and scavenged.hydration >= 20, "abstract scavenging restoration")

local npc = { id = "npc", recruited = true }
local needs = PNC.IndividualNeeds.Ensure(npc)
assertTrue(needs.hunger >= 80 and needs.hunger <= 100, "individual lazy initialization")
PNC.IndividualNeeds.Set(npc, "hunger", 50, "test")
PNC.IndividualNeeds.Update(npc, 1, "test")
assertTrue(PNC.IndividualNeeds.Get(npc, "hunger") < 50, "individual elapsed update")
PNC.Registry.Data[npc.id] = npc
local colonySnapshot = PNC.ColonyManagement.BuildSnapshot({})
assertEqual(#colonySnapshot.people, 1, "colony companion summary")
assertTrue(colonySnapshot.levels.hunger ~= nil, "colony need-level summary")

print("pnc_needs_foundation_smoke: OK")
