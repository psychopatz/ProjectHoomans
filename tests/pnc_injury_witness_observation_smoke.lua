local T = require "tests/support/test"
T.addPackagePaths()

local observer = { id = "neutral", name = "Casey", x = 0, y = 0, factionID = "neutral" }
local injured = { id = "injured", name = "Riley", x = 2, y = 0, factionID = "other",
    health = { body = { openWoundCount = 1 } } }
local liveBody = {}
local los, sent, delivery = true, 0, 1
local profile = {
    injuryRevision = 1, totalWoundCount = 1, woundCountBand = "single",
    woundLabel = "laceration", partToken = "arm", partId = "UpperArm_L", bodyRegion = "arm",
    selectedWound = { bodyPart = "UpperArm_L", woundType = "laceration", bleedingBand = "heavy" },
}
PNC = {
    Registry = { GetLiveZombie = function(id) if id == injured.id then return liveBody end end },
    Perception = { CanSeeWorldObject = function(_, target)
        T.equal(target, liveBody, "visibility accepts a live target, not a record")
        return los
    end },
    SpatialIndex = { QueryNPCs = function() return { observer, injured } end },
    Semantics = { CombatTargetCallouts = {
        ClassifyActorWoundProfile = function() return profile end,
    } },
}

local S = require "PNC/Semantics/PNC_SemanticCombatTargetCallouts_SituationQuery"
require "PNC/Semantics/PNC_SemanticCombatTargetCallouts_VisibleObservation"
S.ResolveSemanticLine = function(_, _, _, _, _, _, _, options) return options.replyRole end
S.DeliverBark = function()
    sent = sent + delivery
    return delivery
end
los = false
T.falsy(S.OnVisibleConditionObserved(observer, injured, 1), "obstructed witness stays silent")
los, delivery = true, 0
T.falsy(S.OnVisibleConditionObserved(observer, injured, 2), "rejected delivery does not advance history")
delivery = 1
T.truthy(S.OnInjuryEncounterCellChanged(observer, 3), "neutral NPC notices an injury on encounter")
T.equal(sent, 1, "an encounter delivers one Beat")
T.falsy(S.OnInjuryEncounterCellChanged(observer, 4), "unchanged injury stays silent")
profile.injuryRevision, profile.totalWoundCount, profile.woundCountBand = 2, 2, "multiple"
T.truthy(S.OnInjuryEncounterCellChanged(observer, 5), "new wounds can be noticed")
T.truthy(S.OnInjuryEncounterCellChanged(observer, 86400005), "an unchanged injury is eligible the next day")

profile.selectedWound = { bandaged = true, bandageDirty = true, woundType = "bite", ordinaryInfection = true }
profile.injuryRevision = 3
local ok, variant = S.OnVisibleConditionObserved(observer, injured, 86400006)
T.truthy(ok, "dirty dressing transition is visible")
T.equal(variant, "dirty_bandage", "a dressing does not reveal the bite or infection underneath")
T.falsy(S.ResolveObserverEpistemicPolicy({ skills = { FirstAid = 5 } }, injured, {}).canStatePreciseDiagnosis,
    "medical skill alone does not establish a diagnosis")

for i = 1, 12 do
    S.RecordWitnessObservation(observer, { id = "other-" .. i }, profile, 86400007)
end
T.truthy(S.EvaluateWitnessObservationGate(observer, injured, profile, 86400008), "oldest observation is evicted")
