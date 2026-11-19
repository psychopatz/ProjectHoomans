local T = require "tests/support/test"

T.load("tests/pnc_npc_foundation_parity_baseline_smoke.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Travel/PNC_Travel.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Relationships/PNC_RelationshipConstants.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Relationships/PNC_RelationshipTypes.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Relationships/PNC_RelationshipStates.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Relationships/PNC_RelationshipMath.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Relationships/PNC_SocialEventDefinitions.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Persistence/PNC_Persistence_CoreSocial.lua")
T.load("ProjectHoomans", "shared", "PNC/ConvoEngine/Interaction/Relations.lua")
T.load("ProjectHoomans", "shared", "PNC/ConvoEngine/Interaction/Evidence.lua")
T.load("ProjectHoomans", "shared", "PNC/Conversation/Memory/PNC_ConversationMemory.lua")
T.load("ProjectHoomans", "server", "PNC/Social/PNC_RelationshipService.lua")

local CoreActors = require "PsychopatzCore/Actors/PsychopatzActors"
local pncPolicyReg = require "PNC/SocialPolicy/Registry"
local dtPolicyReg = require "DTCommon/SocialPolicy/Registry"
CoreActors.SocialPolicy.RegisterRegistry(pncPolicyReg)
CoreActors.SocialPolicy.RegisterRegistry(dtPolicyReg)

-- 1. Verify CodeBuilder PNC/SocialPolicy registry synchronized into PNC.SocialEventDefinitions
T.equal(PNC.SocialEventDefinitions.treated_wound.targetMemory.retentionClass, "LONG",
    "CodeBuilder retentionClass hydrated on PNC_SocialEventDefinitions")
T.equal(PNC.SocialEventDefinitions.saved_from_incapacitation.targetMemory.salience, 245,
    "CodeBuilder salience hydrated on PNC_SocialEventDefinitions")

-- 2. Verify cross-adopter DT trade -> Hoomans Recalculate -> SyncToCore preservation
local registry = CoreActors.NewRegistry()
PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Actors = CoreActors
PsychopatzCore.Actors.DefaultRegistry = registry

local actor = assert(registry:Create({
    actorId = "actor:p4:shared_npc",
    identitySeed = "p4-shared-seed",
    providerLease = { leaseID = "lease:p4:1", provider = "ProjectHoomans", owner = "ProjectHoomans" },
}))

local playerKey = "player:sp_slot_1:char_p4"
local updatedSocial = assert(CoreActors.Social.RecordAuthorizedEvent(actor.social, {
    targetKey = playerKey,
    eventID = "dt:trade:p4_1",
    type = "trade.fair_high_value",
    createdAt = 100,
    authority = "server",
    authorized = true,
}))
actor = assert(registry:Commit(actor.actorId, { social = updatedSocial }, actor.revision))

local hoomansRecord = {
    id = "actor:p4:shared_npc",
    coreActorID = "actor:p4:shared_npc",
    alive = true,
    identitySeed = 42,
    archetypeID = "General",
    social = PNC.Persistence.CoreSocial.FromCoreSocial(actor.social),
}
PNC.Registry = PNC.Registry or {}
PNC.Registry.Get = function(id)
    if id == hoomansRecord.id then return hoomansRecord end
    return nil
end
PNC.Registry.MarkDirty = function() end
PNC.Core = PNC.Core or {}
PNC.Core.IsAuthority = function() return true end

local relBefore = assert(PNC.Relationships.Get(hoomansRecord.id, playerKey))
T.equal(relBefore.approval, 2, "DT fair_high_value approval preserved in Hoomans")
T.equal(relBefore.respect, 1, "DT fair_high_value respect preserved in Hoomans")

-- Hoomans recalculates relationship and adds a Hoomans memory
local recalcOk, recalcReason = PNC.Relationships.Recalculate(hoomansRecord.id, playerKey, 100)
T.truthy(recalcOk, recalcReason)
local recalculated = assert(PNC.Relationships.Get(hoomansRecord.id, playerKey))
T.equal(recalculated.approval, 2, "Recalculate preserves DT trade approval")
T.equal(recalculated.respect, 1, "Recalculate preserves DT trade respect")

local added, addReason = PNC.Relationships.AddMemory(hoomansRecord.id, playerKey, {
    id = "hoomans:treated:p4_1",
    type = "treated_wound",
    aboutKey = playerKey,
    createdAt = 105,
    approvalEffect = 4,
    respectEffect = 2,
    strength = 1,
    decayPerDay = 0.05,
    retentionClass = "LONG",
})
T.truthy(added, addReason)

local finalActor = assert(registry:Get(hoomansRecord.id))
local finalCoreRel = assert(CoreActors.Social.Get(finalActor.social, playerKey))
-- trade.fair_high_value (createdAt=100, decayPerDay=0.03) lazily decays over 5h to 2 * (1 - 0.03*5/24) = 1.9875 + 4 = 5.9875
T.truthy(math.abs(finalCoreRel.approval - 5.9875) < 0.001,
    "Core converges DT (+2 lazily decayed 5h) + Hoomans (+4) = 5.9875")
T.truthy(math.abs(finalCoreRel.respect - 2.99375) < 0.001,
    "Core converges DT (+1 lazily decayed 5h) + Hoomans (+2) = 2.99375")
T.equal(#finalCoreRel.memories, 2, "Both DT trade and Hoomans memories retained")
T.equal(finalCoreRel.baselineApproval, 0, "baselineApproval moved to first-class Core field")
T.equal(finalCoreRel.extensions.ProjectHoomans.baselineApproval, nil,
    "baselineApproval no longer duplicated in ProjectHoomans extension")

-- 3. Verify QuerySemanticEvidence surfaces BOTH Hoomans and DT trade memories via Core SocialPolicy
local evidenceRows = PNC.Relationships.QuerySemanticEvidence(
    hoomansRecord.id, playerKey, hoomansRecord.id, 106, {}
)
T.truthy(#evidenceRows >= 2, "QuerySemanticEvidence projects both Hoomans and DT memories")

-- 4. Verify EntityRef supports canonical actor keys while keeping malformed 2-segment player key rejected
T.truthy(PNC.EntityRef.Parse("actor:dt:world:7"), "EntityRef parses actor:*")
T.truthy(PNC.EntityRef.Parse("npc:colon:id"), "EntityRef parses colon npc:*")
T.equal(PNC.EntityRef.Parse("player:Patrick"), nil, "malformed 2-segment player key still rejected")

T.finish("pnc_portable_social_convergence_smoke")
