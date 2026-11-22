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
local dtOk, dtPolicyReg = pcall(require, "DTCommon/SocialPolicy/Registry")
if not dtOk then
    local savedPath = package.path
    package.path = "../DynamicTrading/Contents/mods/DTCommon/common/media/lua/shared/?.lua;" .. package.path
    dtOk, dtPolicyReg = pcall(require, "DTCommon/SocialPolicy/Registry")
    package.path = savedPath
end
if not dtOk or type(dtPolicyReg) ~= "table" then
    dtPolicyReg = {
        schema = "psychopatz.social-policy.runtime-plan.v1",
        owner = "DTCommon",
        package = "dynamic_trading.social_policy",
        events = {
            ["trade.fair_high_value"] = {
                id = "trade.fair_high_value",
                owner = "DTCommon",
                retentionClass = "LONG",
                salience = 145,
                decayPerDay = 0.03,
                consolidationFamily = "dt:trade:high_value",
                maxConsolidatedApproval = 25,
                maxConsolidatedRespect = 15,
                maxConsolidatedFamiliarity = 25,
                approvalDelta = 2,
                respectDelta = 1,
                familiarityDelta = 2,
            },
        },
        aliases = {},
    }
end
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

-- 5. Verify single persisted generic social authority (P10 / H7)
local p10Actor = assert(registry:Create({
    actorId = "actor:p10:single_auth",
    identitySeed = "p10-single-auth-seed",
    providerLease = { leaseID = "lease:p10:1", provider = "ProjectHoomans", owner = "ProjectHoomans" },
}))
local dtP10Social = assert(CoreActors.Social.RecordAuthorizedEvent(p10Actor.social, {
    targetKey = playerKey,
    eventID = "dt:trade:p10_1",
    type = "trade.fair_high_value",
    createdAt = 100,
    authority = "server",
    authorized = true,
}))
p10Actor = assert(registry:Commit(p10Actor.actorId, { social = dtP10Social }, p10Actor.revision))

local p10Record = assert(PNC.Types.NewRecord({
    id = "actor:p10:single_auth",
    coreActorID = "actor:p10:single_auth",
    displayName = "P10 Authority NPC",
    identitySeed = 731,
    archetypeID = "parity_merchant",
    tacticalClass = "neutral",
    x = 10,
    y = 20,
    z = 0,
    equipment = { worn = {}, attached = {} },
}))
PNC.Registry.Data = PNC.Registry.Data or {}
PNC.Registry.Data[p10Record.id] = p10Record
PNC.Registry.Get = function(id)
    if id == hoomansRecord.id then return hoomansRecord end
    return PNC.Registry.Data[tostring(id)]
end

local syncFromOk, syncFromErr = PNC.Persistence.CoreSocial.SyncFromCore(p10Record, PsychopatzCore)
T.truthy(syncFromOk, syncFromErr)

local baseOk, baseErr = PNC.Relationships.SetInitialBaseline(
    p10Record.id, playerKey, { approval = 5, respect = 3 }, 105
)
T.truthy(baseOk, baseErr)

local p10Added, p10AddErr = PNC.Relationships.AddMemory(p10Record.id, playerKey, {
    id = "hoomans:treated:p10_1",
    type = "treated_wound",
    aboutKey = playerKey,
    createdAt = 105,
    approvalEffect = 6,
    respectEffect = 4,
    strength = 1,
    decayPerDay = 0.05,
    retentionClass = "LONG",
})
T.truthy(p10Added, p10AddErr)

local bondOk, bondErr = PNC.Relationships.SetDurableBond(
    p10Record.id, playerKey, { class = "friend" }, 105, "relationship_milestone"
)
T.truthy(bondOk, bondErr)

local intOk, intErr = PNC.Relationships.RecordInteraction(p10Record.id, playerKey, {
    eventID = "p10:int:1",
    interactionType = "conversation",
    worldAgeHours = 105,
    applied = true,
})
T.truthy(intOk, intErr)

p10Record.social.morale = 17
p10Record.social.moraleBaseline = 4
p10Record.social.conduct.evidence = {
    {
        id = "conduct:p10:1",
        eventID = "social:p10:1",
        eventType = "treated_wound",
        actorKey = "npc:" .. p10Record.id,
        subjectKey = playerKey,
        createdAt = 105,
        lastEvaluatedAt = 105,
        effects = { compassion = 5 },
        strength = 1,
        decayPerDay = 0,
        permanent = true,
        visibility = "public",
        shareable = true,
    },
}
local syncP10Ok, syncP10Err = PNC.Persistence.CoreSocial.SyncToCore(p10Record, PsychopatzCore)
T.truthy(syncP10Ok, syncP10Err)

local coreActorAfterP10 = assert(registry:Get(p10Record.id))
local coreEncoded = assert(CoreActors.Persistence.EncodeActor(coreActorAfterP10))
local pncPayload = assert(PNC.Persistence.SerializeRecord(p10Record))

-- PNC save envelope keeps ONLY PNC-specific extensions; zero generic social graph!
T.equal(pncPayload.social.authority, "core", "PNC social envelope records core authority")
T.equal(pncPayload.social.coreSocialMigrationVersion, nil, "PNC social envelope omits retired migration version")
T.equal(pncPayload.social.relationships, nil, "PNC save payload omits generic relationships table")
T.equal(pncPayload.social.recentEventIDs, nil, "PNC save payload omits generic recentEventIDs")
T.equal(pncPayload.social.personality, nil, "PNC save payload omits generic personality")
T.equal(pncPayload.social.revision, nil, "PNC save payload omits generic social revision")
T.equal(pncPayload.social.morale, 17, "PNC save payload preserves morale")
T.equal(pncPayload.social.moraleBaseline, 4, "PNC save payload preserves moraleBaseline")
T.truthy(pncPayload.social.conduct and #pncPayload.social.conduct.evidence == 1,
    "PNC save payload preserves conduct evidence")
T.equal(pncPayload.social.conduct.scores, nil, "PNC save payload omits derived conduct scores")
T.equal(pncPayload.social.relationshipExtensions[playerKey].bond.class, "friend",
    "PNC save payload preserves durable bond extension")
T.equal(#pncPayload.social.relationshipExtensions[playerKey].interactionJournal, 1,
    "PNC save payload preserves interaction journal extension")

-- Core payload holds the single authoritative generic relationship and actor-level memoryBank
local coreP10Rel = coreEncoded.social.relationships[playerKey]
T.truthy(coreP10Rel, "Core actor social carries canonical directed relationship")
T.equal(coreP10Rel.baselineApproval, 5, "Core actor persists baselineApproval once")
T.equal(coreP10Rel.baselineRespect, 3, "Core actor persists baselineRespect once")
T.equal(coreP10Rel.memories, nil, "Core relationship omits embedded memories array")
local coreP10Memories = CoreActors.Social.GetMemoriesForTarget(coreEncoded.social, playerKey)
T.equal(#coreP10Memories, 2, "Core actor persists both DT and Hoomans memories once in memoryBank")

-- Strip ProjectHoomans extension from Core save and verify full reload reconstructs from Core + PNC envelope
local savedCoreActor = assert(registry:Get(p10Record.id))
savedCoreActor.social.extensions.ProjectHoomans = nil
savedCoreActor.social.relationships[playerKey].extensions.ProjectHoomans = nil
local savedCoreJson = assert(CoreActors.Persistence.SerializeRegistry({ savedCoreActor }, registry.revision))

local freshReg = CoreActors.NewRegistry()
T.truthy(freshReg:Load(savedCoreJson), "Reload stripped Core registry")
PsychopatzCore.Actors.DefaultRegistry = freshReg

local reloadedP10 = assert(PNC.Persistence.DeserializeRecord(pncPayload, p10Record.id))
T.truthy(reloadedP10.social, "Reloaded record reconstructs ephemeral runtime social view")
T.equal(reloadedP10.social.morale, 17, "Reloaded record restores PNC morale independently")
T.equal(reloadedP10.social.moraleBaseline, 4, "Reloaded record restores PNC moraleBaseline independently")
T.truthy(reloadedP10.social.conduct.scores and reloadedP10.social.conduct.scores.compassion > 0,
    "Reloaded record rebuilds conduct scores from PNC conduct evidence")
local reloadedRel = reloadedP10.social.relationships[playerKey]
T.truthy(reloadedRel, "Reloaded record reconstructs relationship view")
T.equal(reloadedRel.approval, coreP10Rel.approval, "Reloaded approval comes from Core authority")
T.equal(reloadedRel.baselineApproval, 5, "Reloaded baselineApproval comes from Core authority")
T.equal(#reloadedRel.memories, 2, "Reloaded memories come from Core authority")
T.equal(reloadedRel.bond.class, "friend", "Reloaded bond comes from PNC extension envelope")
T.equal(#reloadedRel.interactionJournal, 1, "Reloaded interactionJournal comes from PNC extension envelope")

PsychopatzCore.Actors.DefaultRegistry = registry

T.finish("pnc_portable_social_convergence_smoke")
