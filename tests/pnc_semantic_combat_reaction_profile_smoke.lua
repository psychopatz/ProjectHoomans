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
    local personality = nil
    if not spec.noPersonality then
        personality = {
            aggression = spec.aggression or 0.5,
            bravery = spec.bravery or 0.5,
            compassion = spec.compassion or 0.5,
            sociability = spec.sociability or 0.5,
            materialism = spec.materialism or 0.5,
            socialStyle = spec.socialStyle or "neutral",
        }
    end
    local record = {
        id = "npc",
        npcTraits = spec.traits or {},
        conditionStats = {
            panic = spec.panic or 0,
            stress = spec.stress or 0,
        },
        health = { current = 100, max = 100, state = "normal" },
        social = {
            personality = personality,
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
        temporaryDemeanor = spec.temporaryDemeanor,
    }), record
end

T.equal(build({ relationshipState = "enemy" }).combatReactionStyle,
    "cold", "enemy relationship wins reaction style")
T.equal(build({ relationshipState = "enemy", compassion = 0.9, traits = { pnc_friendly = true } }).combatReactionStyle,
    "cold", "enemy relationship is not overridden by compassion/friendly precedence")
T.equal(build({ panic = 80, bravery = 0.4 }).combatReactionStyle,
    "shaken", "panic and low bravery produce shaken response")
T.equal(build({ aggression = 0.9 }).combatReactionStyle,
    "aggressive", "high aggression produces aggressive response")
T.equal(build({
    noPersonality = true, traits = { pnc_berserker = true },
}).combatReactionStyle, "aggressive",
    "traits-only actor derives aggressive baseline once via DispositionProjection")
T.equal(build({
    traits = { pnc_berserker = true }, aggression = 0.2,
}).combatReactionStyle, "practical",
    "berserker trait does not override or double-count resolved numeric aggression")
T.equal(build({
    traits = { pnc_cowardly = true }, pressure = "horde",
    bravery = 0.8,
}).combatReactionStyle, "brave",
    "cowardly trait does not override resolved high numeric bravery")
T.equal(build({
    traits = { pnc_veteran = true }, bravery = 0.4,
}).combatReactionStyle, "practical",
    "veteran trait does not force brave when resolved numeric bravery disagrees")
T.equal(build({
    compassion = 0.9, relationshipState = "friend",
}).combatReactionStyle, "supportive",
    "compassion and warm relationship produce supportive response")
T.equal(build({ bravery = 0.9 }).combatReactionStyle,
    "brave", "high numeric bravery produces brave response without veteran trait")
T.equal(build({
    sociability = 0.25,
}).combatReactionStyle, "reserved",
    "low resolved sociability produces reserved response")

local modulated, modRecord = build({
    bravery = 0.72,
    temporaryDemeanor = { vigilanceFear = 45, confidencePressure = 40 },
})
T.equal(modulated.combatReactionStyle, "shaken",
    "temporaryDemeanor modulates effectiveDisposition into shaken style")
T.equal(modulated.allyWarnStyle, "shaken",
    "allyWarnStyle derives from the same resolved disposition projection")
T.equal(modRecord.social.personality.bravery, 0.72,
    "temporaryDemeanor modulation never mutates stored social.personality")

local practical = build({ pressure = "horde", nearbyCount = 9 })
T.equal(practical.combatReactionStyle, "practical",
    "neutral profile stays practical")
T.equal(practical.combatPressure, "horde", "pressure is projected")
T.equal(practical.nearbyZombieCount, 9, "nearby count is projected")
T.truthy(string.find(practical.nextAction, "surrounded", 1, true),
    "horde pressure changes grounded next action")
T.equal(practical.schema, "semantic.combat.reaction_profile.v1",
    "profile schema is bounded and explicit")
T.equal(practical.provenance.disposition, "DispositionProjection",
    "provenance records DispositionProjection ownership")

T.finish("pnc_semantic_combat_reaction_profile_smoke")
