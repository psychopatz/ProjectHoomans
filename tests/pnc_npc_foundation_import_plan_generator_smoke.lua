local T = require "tests/support/test"

T.load("tests/pnc_npc_foundation_parity_baseline_smoke.lua")

local ImportPlan = PNC.Persistence.ImportPlan
local Fixtures = require
    "tests/support/pnc_npc_foundation_import_plan_fixtures"
local Utils = require
    "PNC/Core/Persistence/PNC_Persistence/PNC_Persistence_ImportPlan_Utils"

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
local rawBefore = ImportPlan.Copy(rawPayload)
local sourceBefore = ImportPlan.Copy(sourceSnapshot)
local provenance = {
    definitionRevision = sourceRecord.uniqueDefinitionVersion,
    policyHash = Utils.Hash(sourceRecord.appearance, PNC.Identity),
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

local definitionMismatchSnapshot = ImportPlan.Copy(sourceSnapshot)
definitionMismatchSnapshot.inventory.template.definitionRevision =
    tonumber(provenance.definitionRevision) - 1
local definitionMismatch = ImportPlan.Build(rawPayload, {
    sourceSnapshot = definitionMismatchSnapshot,
    generatorProvenance = provenance,
    candidateCodec = Fixtures.CandidateCodec(),
})
T.truthy(ImportPlan.IsReady(definitionMismatch),
    "exact source items did not survive definition mismatch")
T.equal(definitionMismatch.candidate.appearance.generator.restoration,
    "SOURCE_AUTHORITATIVE", "definition mismatch restoration mode")
T.equal(definitionMismatch.candidateHash,
    definitionMismatch.candidateRoundTripHash,
    "definition fallback candidate canonical hash changed")
T.truthy(Fixtures.HasDecision(
    definitionMismatch, "appearance.generator", "projected",
    "generator_provenance_mismatch_source_authoritative"
), "definition mismatch fallback decision missing")

local missingPolicySnapshot = ImportPlan.Copy(sourceSnapshot)
missingPolicySnapshot.inventory.items = {}
missingPolicySnapshot.inventory.persistenceMode = "SEED_ONLY"
local missingPolicyPlan = ImportPlan.Build(rawPayload, {
    sourceSnapshot = missingPolicySnapshot,
    generatorProvenance = {
        definitionRevision = provenance.definitionRevision,
    },
    candidateCodec = Fixtures.CandidateCodec(),
})
T.equal(missingPolicyPlan.status, "quarantined",
    "seed-only replay ignored missing policy provenance")
T.equal(missingPolicyPlan.reason, "generator_provenance_incomplete",
    "missing seed-only policy provenance reason")
T.falsy(missingPolicyPlan.candidate,
    "missing seed-only policy provenance produced a candidate")

local policyMismatchSnapshot = ImportPlan.Copy(sourceSnapshot)
policyMismatchSnapshot.inventory.items = {}
policyMismatchSnapshot.inventory.persistenceMode = "SEED_ONLY"
local policyMismatchPlan = ImportPlan.Build(rawPayload, {
    sourceSnapshot = policyMismatchSnapshot,
    generatorProvenance = {
        definitionRevision = provenance.definitionRevision,
        policyHash = provenance.policyHash .. ":mismatch",
    },
    candidateCodec = Fixtures.CandidateCodec(),
})
T.equal(policyMismatchPlan.status, "quarantined",
    "seed-only policy mismatch was accepted")
T.equal(policyMismatchPlan.reason, "generator_provenance_mismatch",
    "seed-only policy mismatch reason")
T.falsy(policyMismatchPlan.candidate,
    "seed-only policy mismatch produced a candidate")

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
T.truthy(Fixtures.EqualValue(rawPayload, rawBefore),
    "generator plans mutated the raw payload")
T.truthy(Fixtures.EqualValue(sourceSnapshot, sourceBefore),
    "generator plans mutated the source snapshot")

T.finish("pnc_npc_foundation_import_plan_generator_smoke")
