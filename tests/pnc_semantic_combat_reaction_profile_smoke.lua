local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
})

local styleVariant = "neutral"
PNC = {
    Semantics = {
        SpeechStyleContext = {
            Resolve = function()
                return { variant = styleVariant }
            end,
        },
    },
    NPCTraitContext = {
        Collect = function(record)
            return record.npcTraits or {}
        end,
    },
}

local Profile = T.load(
    "ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticCombatReactionProfile.lua"
)

local function build(spec)
    spec = spec or {}
    local record = {
        id = "npc",
        npcTraits = spec.traits or {},
        conditionStats = {
            panic = spec.panic or 0,
            stress = spec.stress or 0,
        },
        health = { current = 100, max = 100, state = "normal" },
        social = {
            personality = {
                aggression = spec.aggression or 0.5,
                bravery = spec.bravery or 0.5,
                compassion = spec.compassion or 0.5,
                socialStyle = spec.socialStyle or "neutral",
            },
            relationships = {
                ["player:p1"] = {
                    state = spec.relationshipState or "unknown",
                    approval = spec.approval or 0,
                    familiarity = spec.familiarity or 0,
                },
            },
        },
        runtime = {
            zombieObservation = {
                band = spec.pressure or "few",
                nearbyCount = spec.nearbyCount or 2,
            },
        },
    }
    styleVariant = spec.speechVariant or "neutral"
    return Profile.Build(record, "player:p1", {
        role = spec.role or "witness",
        actorKind = spec.actorKind or "player",
    })
end

T.equal(build({ relationshipState = "enemy" }).combatReactionStyle,
    "cold", "enemy relationship wins reaction style")
T.equal(build({ panic = 80, bravery = 0.4 }).combatReactionStyle,
    "shaken", "panic and low bravery produce shaken response")
T.equal(build({ aggression = 0.9 }).combatReactionStyle,
    "aggressive", "high aggression produces aggressive response")
T.equal(build({
    traits = { pnc_berserker = true }, aggression = 0.2,
}).combatReactionStyle, "aggressive",
    "berserker trait directly biases aggressive reaction")
T.equal(build({
    traits = { pnc_cowardly = true }, pressure = "horde",
    bravery = 0.8,
}).combatReactionStyle, "shaken",
    "cowardly trait reacts as shaken under dangerous pressure")
T.equal(build({
    traits = { pnc_veteran = true }, bravery = 0.4,
}).combatReactionStyle, "brave",
    "veteran trait directly biases brave reaction")
T.equal(build({
    compassion = 0.9, relationshipState = "friend",
}).combatReactionStyle, "supportive",
    "compassion and warm relationship produce supportive response")
T.equal(build({ bravery = 0.9 }).combatReactionStyle,
    "brave", "high bravery produces brave response")
T.equal(build({
    traits = { pnc_reserved = true }, speechVariant = "terse",
}).combatReactionStyle, "reserved",
    "reserved trait/speech projection produces reserved response")
local practical = build({ pressure = "horde", nearbyCount = 9 })
T.equal(practical.combatReactionStyle, "practical",
    "neutral profile stays practical")
T.equal(practical.combatPressure, "horde", "pressure is projected")
T.equal(practical.nearbyZombieCount, 9, "nearby count is projected")
T.truthy(string.find(practical.nextAction, "surrounded", 1, true),
    "horde pressure changes grounded next action")
T.equal(practical.schema, "semantic.combat.reaction_profile.v1",
    "profile schema is bounded and explicit")

T.finish("pnc_semantic_combat_reaction_profile_smoke")
