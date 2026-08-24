local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "server", "PNC/")
local entry = T.read(ROOT .. "Social/PNC_SocialProfileService.lua")
local providers = ROOT .. "Social/SocialProfileService/"
local core = T.read(providers .. "PNC_SocialProfileService_Core.lua")
local players = T.read(providers .. "PNC_SocialProfileService_Players.lua")
local npcs = T.read(providers .. "PNC_SocialProfileService_NPCs.lua")
local mathApi = T.read(providers .. "PNC_SocialProfileService_Math.lua")

T.contains(entry, "PNC.SocialProfiles.Internal",
    "entry owns the internal namespace")
T.contains(core, "function H.ExtractTraitSet",
    "trait extraction stays behind the internal boundary")
T.contains(players, "function SocialProfiles.ResolvePlayerProfile",
    "player resolution remains available")
T.contains(npcs, "function SocialProfiles.EnsureNPCProfile",
    "NPC normalization remains available")
T.contains(mathApi, "function SocialProfiles.ModifySocialEvent",
    "social math facade remains available")
T.falsy(string.find(entry, "function SocialProfiles.ResolvePlayerProfile",
    1, true), "entry contains wiring rather than implementation")
