local T = require "tests/support/test"

local randomValue = 100000
ZombRand = function(maximum)
    randomValue = randomValue + 1
    return randomValue % maximum
end

PNC = {
    Core = {},
    Registry = { Loaded = true, Data = {} },
}
T.load("ProjectHoomans", "shared", "PNC/Core/Identity/PNC_Identity.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Identity/PNC_Identity_ID.lua")

local identity = {
    displayName = "Thurman Hawk",
    survivor = { forename = "Thurman", surname = "Hawk" },
}
local first = PNC.Identity.GenerateNPCID(identity, "seed")
local suffix = string.match(first, "_([0-9A-Z]+)$")
T.truthy(string.match(first, "^npcThurmanHawk_[0-9A-Z]+$"),
    "readable NPC ID shape")
T.equal(#suffix, 4, "readable NPC suffix length")

PNC.Registry.Data[first] = {}
local second = PNC.Identity.GenerateNPCID(identity, "seed")
T.truthy(second ~= first, "NPC ID collision was not rejected")

PNC.Const = { MODDATA_NPC_PREFIX = "PNC_npc" }
PNC.Persistence = { Reset = {} }
PNC.Registry = { Loaded = true, Data = {}, Internal = {} }
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Registry/PNC_Registry/PNC_Registry_StorageCore.lua"
)
T.equal(
    PNC.Registry.StorageKeyForID("npcThurmanHawk_7K4Q"),
    "PNC_npcThurmanHawk_7K4Q",
    "readable NPC ModData key"
)
T.equal(
    PNC.Registry.StorageKeyForID("custom"),
    "PNC_npc_custom",
    "explicit NPC IDs remain in the NPC namespace"
)

T.finish("pnc_readable_npc_id_smoke")
