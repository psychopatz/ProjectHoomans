local T = require "tests/support/test"

T.load("tests/pnc_npc_foundation_parity_baseline_smoke.lua")

local ImportPlan = PNC.Persistence.ImportPlan
local Fixtures = require
    "tests/support/pnc_npc_foundation_import_plan_fixtures"

local sourceRecord = Fixtures.PrepareSourceRecord("npc:p0b:generator", true)
T.truthy(PNC.Inventory.ApplyDelta(sourceRecord, {
    {
        op = "add",
        item = {
            id = "loot:p0b:generator",
            type = "Base.CustomLoot",
            stack = 1,
            container = "root",
            itemState = { modData = { source = "generator" } },
        },
    },
}, "p0b_import_plan_generator"), "generator source item mutation")
local rawPayload = PNC.Persistence.SerializeRecord(sourceRecord)
local sourceSnapshot = ImportPlan.Copy(sourceRecord)
sourceSnapshot.schemaVersion = rawPayload.schemaVersion
local provenance = {
    definitionRevision = sourceRecord.uniqueDefinitionVersion,
}

local mismatchSnapshot = ImportPlan.Copy(sourceSnapshot)
mismatchSnapshot.inventory.template.generatorVersion =
    tonumber(PNC.Const.GENERATOR_VERSION) - 1
local mismatch = ImportPlan.Build(rawPayload, {
    sourceSnapshot = mismatchSnapshot,
    generatorProvenance = provenance,
    candidateCodec = Fixtures.CandidateCodec(),
})
T.truthy(ImportPlan.IsReady(mismatch),
    "exact source items did not receive generator fallback")
T.equal(mismatch.candidate.appearance.generator.restoration,
    "SOURCE_AUTHORITATIVE", "generator mismatch restoration mode")
T.equal(mismatch.candidateHash, mismatch.candidateRoundTripHash,
    "fallback candidate canonical hash changed")
T.truthy(Fixtures.HasDecision(
    mismatch, "appearance.generator", "projected",
    "generator_provenance_mismatch_source_authoritative"
), "generator mismatch fallback decision missing")

local seedOnlySnapshot = ImportPlan.Copy(sourceSnapshot)
seedOnlySnapshot.inventory.items = {}
seedOnlySnapshot.inventory.persistenceMode = "SEED_ONLY"
seedOnlySnapshot.inventory.template.generatorVersion =
    tonumber(PNC.Const.GENERATOR_VERSION) - 1
local seedOnlyPlan = ImportPlan.Build(rawPayload, {
    sourceSnapshot = seedOnlySnapshot,
    generatorProvenance = provenance,
})
T.equal(seedOnlyPlan.status, "quarantined",
    "seed-only generator mismatch was accepted")
T.equal(seedOnlyPlan.reason, "generator_provenance_mismatch",
    "seed-only generator mismatch reason")
T.falsy(seedOnlyPlan.candidate,
    "seed-only generator mismatch produced a candidate")

T.finish("pnc_npc_foundation_import_plan_generator_smoke")
