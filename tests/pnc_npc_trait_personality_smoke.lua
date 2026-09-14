local T = require "tests/support/test"

local Registry = T.load(
    "ProjectHoomans", "shared", "PNC/Core/Traits/PNC_NPCTraitRegistry.lua")
T.load(
    "ProjectHoomans", "shared", "PNC/Core/Traits/PNC_NPCTraitEffects.lua")
T.load(
    "ProjectHoomans", "shared", "PNC/Core/Traits/PNC_NPCTraitDefinitions.lua")

PNC.Identity = {
    NormalizeSeed = function(seed)
        return tonumber(seed) or 1
    end,
    Float = function()
        return 0.50
    end,
}

T.load(
    "ProjectHoomans", "shared",
    "PNC/Core/Relationships/PNC_SocialProfileConstants.lua")
local Generator = T.load(
    "ProjectHoomans", "shared",
    "PNC/Core/Relationships/PNC_SocialProfileGenerator.lua")

local base = Generator.Generate(1, "General", nil, {})
local friendly = Generator.Generate(1, "General", nil, {
    npcTraits = { pnc_friendly = true },
})

T.near(friendly.sociability, base.sociability + 0.12, 0.0001,
    "NPC trait modifies generated personality")
T.near(friendly.forgiveness, base.forgiveness + 0.10, 0.0001,
    "friendly trait contributes forgiveness")
T.equal(friendly.traitFingerprint, "pnc_friendly",
    "generated profile records trait fingerprint")
T.truthy(Registry.GetDefinition("pnc_friendly"),
    "canonical NPC trait resolves through registry")

T.finish("pnc_npc_trait_personality_smoke")
