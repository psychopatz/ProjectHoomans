local T = require "tests/support/test"

T.load("tests/pnc_npc_foundation_parity_baseline_smoke.lua")
T.load(
    "ProjectHoomans",
    "common_lua",
    "PNC/Conversation/Definitions/Memory/00_PNC_ConversationMemoryDefinitions.lua"
)
local Fixtures = require
    "tests/support/pnc_npc_foundation_import_plan_fixtures"
local ImportPlan = PNC.Persistence.ImportPlan
local CoreMigration = PNC.Persistence.CoreMigration
local Actors = require "PsychopatzCore/Actors/PsychopatzActors"

local sourceRecord = Fixtures.PrepareSourceRecord("npc:p3:merchant")
local rawPayload = PNC.Persistence.SerializeRecord(sourceRecord)
local sourceSnapshot = ImportPlan.Copy(sourceRecord)
sourceSnapshot.schemaVersion = rawPayload.schemaVersion
local options = {
    sourceSnapshot = sourceSnapshot,
    generatorProvenance = {
        definitionRevision = sourceRecord.uniqueDefinitionVersion,
        policyHash = PNC.Persistence.ImportPlan.Canonical(
            sourceRecord.appearance),
    },
    candidateCodec = Fixtures.CandidateCodec(),
    decisionSet = "p3-smoke",
}
local plan = CoreMigration.BuildPlan(rawPayload, options)
T.truthy(ImportPlan.IsReady(plan), "supported source plan was not ready")
local registry = Actors.NewRegistry()
local store = Actors.Migration.NewStore()
local imported = CoreMigration.Import(plan, PsychopatzCore, store, {
    registry = registry,
    decisionSet = "p3-smoke",
})
T.equal(imported.status, "imported", "source candidate import")
T.truthy(imported.sourcePreserved, "source preservation marker")
local actor = registry:Get(imported.actorId)
T.truthy(actor, "imported actor missing")
T.equal(actor.source.provider, "ProjectHoomans", "source owner")
T.equal(actor.source.sourceRecordHash, imported.sourceHash,
    "source hash mapping")
T.equal(actor.identity.identitySeed, sourceRecord.identitySeed,
    "source identity seed")
T.truthy(actor.persona and actor.persona.backstory,
    "portable backstory persona missing")
T.truthy(actor.persona.backstory.selections.hometown,
    "portable hometown selection missing")
T.falsy(actor.persona.backstory.biography,
    "portable backstory stored resolved prose")
T.truthy(actor.personalInventory, "imported personal inventory")
T.truthy(actor.social, "imported social state")
T.truthy(actor.world, "imported location state")

local retried = CoreMigration.Import(plan, PsychopatzCore, store, {
    registry = registry,
    decisionSet = "p3-smoke",
})
T.equal(retried.status, "already_imported", "idempotent retry")
T.equal(registry:Count(), 1, "idempotent retry duplicated actor")

local conflictRaw = ImportPlan.Copy(rawPayload)
conflictRaw.displayName = "Conflict Source"
local conflictSnapshot = ImportPlan.Copy(sourceSnapshot)
conflictSnapshot.displayName = "Conflict Source"
local conflictPlan = CoreMigration.BuildPlan(conflictRaw, {
    sourceSnapshot = conflictSnapshot,
    generatorProvenance = options.generatorProvenance,
    candidateCodec = Fixtures.CandidateCodec(),
})
local conflict = CoreMigration.Import(conflictPlan, PsychopatzCore, store, {
    registry = registry,
})
T.equal(conflict.status, "quarantined", "source conflict was accepted")
T.equal(conflict.reason, "identity_conflict", "source conflict reason")
T.truthy(Fixtures.EqualValue(conflict.rawPayload, conflictRaw),
    "conflict source copy changed")

local originalRaw = ImportPlan.Copy(rawPayload)
T.truthy(CoreMigration.Rollback(imported, PsychopatzCore, store, {
    registry = registry,
}),
    "candidate rollback")
T.equal(registry:Count(), 0, "rollback retained actor")
T.truthy(Fixtures.EqualValue(rawPayload, originalRaw),
    "rollback changed source payload")
T.truthy(store.disabled[imported.mappingKey], "rollback disabled mapping")

local retriedAfterRollback = CoreMigration.Import(plan, PsychopatzCore, store, {
    registry = registry,
})
T.equal(retriedAfterRollback.status, "imported",
    "rollback did not permit safe retry")

local malformed = CoreMigration.Import({ status = "quarantined",
    reason = "unsupported_schema" }, PsychopatzCore, store, {
    registry = registry,
})
T.equal(malformed.status, "quarantined", "malformed plan wrote state")

T.finish("pnc_npc_foundation_core_migration_smoke")
