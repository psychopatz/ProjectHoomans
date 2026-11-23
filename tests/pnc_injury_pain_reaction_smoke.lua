local T = require "tests/support/test"
T.addPackagePaths({
    { "PsychopatzCore", "common" },
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "common_lua" },
})

isClient = function() return false end
isServer = function() return true end
PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.RuntimeRole = { AllowsServerCode = function() return true end }

PNC = {
    Core = { Now = function() return 0 end },
    Semantics = {},
}
require "PNC/Semantics/PNC_SemanticCombatTargetCallouts_SituationQuery"
local S = PNC.Semantics.CombatTargetCallouts
require "PNC/Semantics/PNC_SemanticCombatTargetCallouts_PainReaction"

local function prof(t, sev, region, pri)
    return {
        woundType = t, woundTierPriority = pri, isBite = t == "bite",
        physicalSeverityBand = sev, bodyRegion = region,
        selectedWound = { woundType = t, physicalSeverity = sev, bodyRegion = region },
    }
end
local function seed(rec, p, at)
    rec.runtime = {
        lastPainBeatAt = at, lastPainBeatPriority = p.woundTierPriority,
        lastPainBeatSeverityRank = 1, lastPainBeatRegion = p.bodyRegion,
    }
end

local rec = { id = "p1" }
local scratch = prof("scratch", "minor", "upper_limb", 1)
seed(rec, scratch, 1000)
T.equal(select(1, S.ShouldPreemptWoundCooldown(rec, scratch, 3000, 2500)), false, "repeat scratch within 2s suppressed")
T.equal(select(1, S.ShouldPreemptWoundCooldown(rec, prof("laceration", "severe", "upper_limb", 3), 3000, 2500)), true, "severe laceration preempts scratch cooldown")
T.equal(select(1, S.ShouldPreemptWoundCooldown(rec, prof("bullet", "moderate", "torso", 5), 3000, 2500)), true, "gunshot preempts minor cooldown")
T.equal(select(1, S.ShouldPreemptWoundCooldown(rec, prof("bite", "moderate", "upper_limb", 6), 3000, 2500)), true, "bite preempts minor cooldown")
T.equal(select(1, S.ShouldPreemptWoundCooldown(rec, scratch, 4000, 2500)), true, "cooldown expiry allows next pain beat")

T.equal(S.ResolvePainReactionVariant({}, prof("scratch", "minor", "upper_limb", 1)), "scratch_minor", "neutral scratch variant")
local nt = prof("bite", "severe", "upper_limb", 6); nt.salivaTransmissible = false
T.equal(S.ResolvePainReactionVariant({}, nt), "bite_non_transmissible", "non-transmissible bite variant")
local stoic = { disposition = { bravery = 0.9, confidence = 0.9, aggression = 0.2 } }
T.equal(S.ResolvePainReactionVariant(stoic, prof("bullet", "severe", "torso", 5)), "bullet_stoic", "stoic gunshot variant")
local multi = prof("laceration", "severe", "torso", 3); multi.woundCountBand = "multiple"
T.equal(S.ResolvePainReactionVariant({}, multi), "multiple_hits_severe", "multiple severe wounds variant")

T.finish("pnc_injury_pain_reaction_smoke")
