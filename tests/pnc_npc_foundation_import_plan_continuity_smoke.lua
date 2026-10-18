local T = require "tests/support/test"

-- This test keeps the social and journey continuity contract separate from
-- the identity/appearance/inventory planner smoke while using the same real
-- Hoomans modules and deterministic candidate codec.
T.load("tests/pnc_npc_foundation_parity_baseline_smoke.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Travel/PNC_Travel.lua")

local ImportPlan = PNC.Persistence.ImportPlan
local Fixtures = require
    "tests/support/pnc_npc_foundation_import_plan_fixtures"
local sourceRecord, relationshipTarget =
    Fixtures.PrepareContinuitySourceRecord("npc:p0b:continuity")
local rawPayload = PNC.Persistence.SerializeRecord(sourceRecord)
local sourceSnapshot = ImportPlan.Copy(sourceRecord)
sourceSnapshot.schemaVersion = rawPayload.schemaVersion
local baseOptions = {
    sourceSnapshot = sourceSnapshot,
    generatorProvenance = {
        definitionRevision = sourceRecord.uniqueDefinitionVersion,
    },
    candidateCodec = Fixtures.CandidateCodec(),
}

local ready = ImportPlan.Build(rawPayload, baseOptions)
T.truthy(ImportPlan.IsReady(ready), "continuity source was rejected")
T.truthy(Fixtures.EqualValue(
    ready.candidate.relationships.personality,
    sourceSnapshot.social.personality
), "personality changed")
T.equal(ready.candidate.relationships.entries[relationshipTarget]
    .memories[1].id, "memory:p0b:friend", "relationship memory changed")
T.equal(ready.candidate.location.journey.journeyId,
    rawPayload.travel.journeyId, "journey identity changed")
T.equal(ready.candidate.location.journey.revision,
    rawPayload.travel.revision, "journey revision changed")
T.truthy(Fixtures.EqualValue(
    ready.candidate.location.journey.metadata,
    rawPayload.travel.metadata
), "journey metadata changed")
T.truthy(Fixtures.HasDecision(ready, "relationships.personality", "copied"),
    "personality copy decision missing")
T.truthy(Fixtures.HasDecision(ready, "relationships.memory", "copied"),
    "relationship memory decision missing")
T.truthy(Fixtures.HasDecision(ready, "location.journey", "copied"),
    "journey copy decision missing")
T.truthy(Fixtures.HasDecision(ready, "source.opaque", "projected",
    "canonical_mapping_deferred"),
    "deferred serialized roots were not surfaced")
T.truthy(ready.rollback and ready.rollback.sourcePreserved,
    "ready rollback source-preservation record missing")
T.falsy(ready.rollback and ready.rollback.writesPerformed,
    "ready planner performed a write")
T.equal(ready.rollback.strategy, "DISABLE_CANDIDATE_MAPPING",
    "ready rollback strategy changed")

local conflictSnapshot = ImportPlan.Copy(sourceSnapshot)
conflictSnapshot.travel.revision = conflictSnapshot.travel.revision + 1
local conflictPlan = ImportPlan.Build(rawPayload, {
    sourceSnapshot = conflictSnapshot,
    generatorProvenance = baseOptions.generatorProvenance,
    candidateCodec = Fixtures.CandidateCodec(),
})
T.equal(conflictPlan.status, "quarantined",
    "journey revision conflict was accepted")
T.equal(conflictPlan.reason, "journey_source_conflict",
    "journey conflict reason changed")
T.truthy(Fixtures.EqualValue(conflictPlan.rawPayload, rawPayload),
    "journey conflict changed the source copy")

local opaqueSnapshot = ImportPlan.Copy(sourceSnapshot)
opaqueSnapshot.travel.opaque = { owner = "future-provider", token = "keep" }
local opaquePlan = ImportPlan.Build(rawPayload, {
    sourceSnapshot = opaqueSnapshot,
    generatorProvenance = baseOptions.generatorProvenance,
    candidateCodec = Fixtures.CandidateCodec(),
})
T.equal(opaquePlan.status, "quarantined",
    "unsupported journey opaque field was accepted")
T.equal(opaquePlan.reason, "opaque_nested_field_not_serialized",
    "opaque journey reason changed")

-- Serialized roots without a bounded P0B adapter remain exact source data in
-- the candidate.  They are projected for later ownership work, never reset
-- to defaults or silently omitted from the migration ledger.
local deferredRaw = ImportPlan.Copy(rawPayload)
deferredRaw.semanticCognition = {
    schemaVersion = 7,
    opaque = { token = "retain-cognition" },
}
deferredRaw.futureRoot = { owner = "future-provider", value = 17 }
local deferredPlan = ImportPlan.Build(deferredRaw, {
    sourceSnapshot = sourceSnapshot,
    generatorProvenance = baseOptions.generatorProvenance,
    candidateCodec = Fixtures.CandidateCodec(),
})
T.equal(deferredPlan.status, "ready",
    "opaque serialized roots incorrectly blocked the read-only plan")
T.truthy(Fixtures.EqualValue(
    deferredPlan.candidate.source.opaque.semanticCognition,
    deferredRaw.semanticCognition
), "semantic cognition opaque source changed")
T.truthy(Fixtures.EqualValue(
    deferredPlan.candidate.source.opaque.futureRoot,
    deferredRaw.futureRoot
), "unknown serialized root was discarded")
T.truthy(Fixtures.HasDecision(
    deferredPlan, "source.opaque.semanticCognition", "projected",
    "canonical_mapping_deferred"
), "semantic cognition mapping decision missing")
T.truthy(Fixtures.HasDecision(
    deferredPlan, "source.opaque.futureRoot", "projected",
    "canonical_mapping_deferred"
), "unknown root mapping decision missing")

local unsupportedJourney = ImportPlan.Copy(rawPayload)
unsupportedJourney.travel.schemaVersion = 99
local unsupportedJourneyPlan = ImportPlan.Build(unsupportedJourney, {
    sourceSnapshot = sourceSnapshot,
    generatorProvenance = baseOptions.generatorProvenance,
    candidateCodec = Fixtures.CandidateCodec(),
})
T.equal(unsupportedJourneyPlan.status, "quarantined",
    "unsupported journey schema was accepted")
T.equal(unsupportedJourneyPlan.reason, "journey_schema_unsupported",
    "unsupported journey schema reason changed")

T.finish("pnc_npc_foundation_import_plan_continuity_smoke")
