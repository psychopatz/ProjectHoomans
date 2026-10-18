local T = require "tests/support/test"

-- The baseline loads the real Hoomans identity, appearance, inventory,
-- relationship, and persistence modules, including the read-only P0B planner.
T.load("tests/pnc_npc_foundation_parity_baseline_smoke.lua")

local ImportPlan = PNC.Persistence.ImportPlan
local Fixtures = require
    "tests/support/pnc_npc_foundation_import_plan_fixtures"
T.truthy(ImportPlan, "P0B import planner was not loaded")

-- Build a current persisted payload from a real record, then provide the
-- untouched source snapshot observed before the current serializer drops the
-- authored policy and complete voice fields.
local sourceRecord = Fixtures.PrepareSourceRecord("npc:p0b:plan", true)
T.truthy(PNC.Inventory.ApplyDelta(sourceRecord, {
    {
        op = "add",
        item = {
            id = "loot:p0b:plan",
            type = "Base.CustomLoot",
            stack = 1,
            container = "root",
            itemState = { modData = { source = "plan" } },
        },
    },
}, "p0b_import_plan_ready"), "ready source item mutation")
local rawPayload = PNC.Persistence.SerializeRecord(sourceRecord)
T.truthy(rawPayload, "current source payload")
T.truthy(PNC.Persistence.DeserializeRecord(rawPayload, sourceRecord.id),
    "current source round-trip")
local sourceSnapshot = ImportPlan.Copy(sourceRecord)
sourceSnapshot.schemaVersion = rawPayload.schemaVersion
T.equal(sourceSnapshot.inventory.template.generatorVersion,
    PNC.Const.GENERATOR_VERSION, "source generator version")
T.equal(sourceSnapshot.inventory.template.archetypeID,
    sourceSnapshot.identity.archetypeID, "source generator archetype")
T.equal(sourceSnapshot.inventory.template.seed,
    sourceSnapshot.identity.seed, "source generator seed")
T.truthy(sourceSnapshot.inventory.template.equipmentPoolID,
    "source generator equipment pool")
T.equal(sourceSnapshot.inventory.template.definitionRevision,
    sourceSnapshot.uniqueDefinitionVersion, "source definition revision")
local rawBefore = ImportPlan.Copy(rawPayload)
local sourceBefore = ImportPlan.Copy(sourceSnapshot)
local planOptions = {
    sourceSnapshot = sourceSnapshot,
    decisionSet = "p0b-import-plan-smoke",
    generatorProvenance = { definitionRevision = sourceRecord.uniqueDefinitionVersion },
    candidateCodec = Fixtures.CandidateCodec(),
}
local optionsBefore = ImportPlan.Copy(planOptions)

local ready = ImportPlan.Build(rawPayload, planOptions)
T.truthy(ImportPlan.IsReady(ready), "complete source snapshot was rejected")
T.equal(ready.candidate.schema, "PsychopatzCore.NPC",
    "canonical candidate schema")
T.equal(ready.candidate.schemaVersion, 1, "canonical candidate version")
T.equal(ready.candidate.actorId, "pnc:" .. sourceRecord.id,
    "stable actor mapping")
T.equal(ready.candidate.appearance.generator.restoration,
    "SEED_COMPATIBLE", "compatible generator restoration")
T.equal(ready.candidateHash, ready.candidateRoundTripHash,
    "candidate canonical hash changed across round-trip")
T.equal(ready.candidate.identity.survivor.voice.legacy,
    sourceRecord.identity.survivor.voice, "legacy voice copied")
T.equal(ready.candidate.identity.survivor.voice.prefix,
    sourceRecord.identity.survivor.voicePrefix, "voice prefix copied")
T.equal(ready.candidate.identity.survivor.voice.type,
    sourceRecord.identity.survivor.voiceType, "voice type copied")
T.equal(ready.candidate.identity.survivor.voice.pitch,
    sourceRecord.identity.survivor.voicePitch, "voice pitch copied")
T.truthy(Fixtures.EqualValue(
    ready.candidate.appearance.policy,
    sourceSnapshot.appearance
), "authored appearance policy changed")
T.truthy(Fixtures.EqualValue(
    ready.candidate.inventory.items,
    sourceSnapshot.inventory.items
), "personal inventory changed")
T.truthy(Fixtures.HasDecision(ready, "appearance.policy", "copied"),
    "appearance copy decision missing")
T.truthy(Fixtures.HasDecision(ready, "identity.voice", "copied"),
    "voice copy decision missing")
T.truthy(Fixtures.HasDecision(ready, "inventory.items", "copied"),
    "inventory copy decision missing")
T.truthy(Fixtures.HasDecision(ready, "appearance.generator", "verified"),
    "generator compatibility decision missing")
T.truthy(Fixtures.HasDecision(ready, "candidate.roundTrip", "verified"),
    "candidate round-trip decision missing")
T.truthy(ready.rollback and ready.rollback.sourcePreserved,
    "ready rollback source-preservation record missing")
T.falsy(ready.rollback and ready.rollback.writesPerformed,
    "ready planner performed a write")
T.equal(ready.rollback.strategy, "DISABLE_CANDIDATE_MAPPING",
    "ready rollback strategy changed")
T.truthy(Fixtures.EqualValue(rawPayload, rawBefore),
    "planner mutated the raw payload")
T.truthy(Fixtures.EqualValue(sourceSnapshot, sourceBefore),
    "planner mutated the source snapshot")
T.truthy(Fixtures.EqualValue(planOptions, optionsBefore),
    "planner mutated its options")

-- The versioned metadata codec now carries legacy-template identity exactly;
-- the planner accepts it only after the source item remains unchanged and the
-- copied metadata decision is present.
local legacyRecord = Fixtures.PrepareSourceRecord("npc:p0b:legacy", true)
T.truthy(PNC.Inventory.ApplyDelta(legacyRecord, {
    {
        op = "add",
        item = {
            id = "loot:p0b:legacy",
            type = "Base.CustomLoot",
            stack = 1,
            container = "root",
            legacyTemplateKey = "legacy:p0b:item",
            itemState = { modData = { source = "legacy" } },
        },
    },
}, "p0b_import_plan_legacy"), "legacy source item mutation")
local legacyPayload = PNC.Persistence.SerializeRecord(legacyRecord)
local legacySnapshot = ImportPlan.Copy(legacyRecord)
legacySnapshot.schemaVersion = legacyPayload.schemaVersion
local legacyPlan = ImportPlan.Build(legacyPayload, {
    sourceSnapshot = legacySnapshot,
    generatorProvenance = { definitionRevision = legacyRecord.uniqueDefinitionVersion },
    candidateCodec = Fixtures.CandidateCodec(),
})
T.equal(legacyPlan.status, "ready", "legacy item was not restored")
T.truthy(Fixtures.HasDecision(
    legacyPlan, "inventory.legacyTemplateKey", "copied"
), "legacy template decision missing")
T.equal(
    legacyPlan.candidate.inventory.items["loot:p0b:legacy"].legacyTemplateKey,
    "legacy:p0b:item", "legacy template candidate changed")
T.truthy(Fixtures.EqualValue(legacyPlan.rawPayload, legacyPayload),
    "legacy plan changed the source copy")
T.truthy(legacyPlan.rollback and legacyPlan.rollback.sourcePreserved,
    "legacy rollback source-preservation record missing")
T.equal(legacyPlan.rollback.strategy, "DISABLE_CANDIDATE_MAPPING",
    "legacy rollback strategy changed")

-- Unsupported schemas fail closed before any candidate is built.
local unsupported = ImportPlan.Copy(rawPayload)
unsupported.schemaVersion = tonumber(rawPayload.schemaVersion) - 1
local unsupportedBefore = ImportPlan.Copy(unsupported)
local unsupportedPlan = ImportPlan.Build(unsupported)
T.equal(unsupportedPlan.status, "quarantined",
    "unsupported schema was accepted")
T.equal(unsupportedPlan.reason, "unsupported_schema",
    "unsupported schema reason")
T.falsy(unsupportedPlan.candidate, "unsupported schema produced a candidate")
T.truthy(Fixtures.EqualValue(unsupported, unsupportedBefore),
    "unsupported source was mutated")
T.truthy(unsupportedPlan.rollback and unsupportedPlan.rollback.sourcePreserved,
    "unsupported rollback source-preservation record missing")
T.falsy(unsupportedPlan.rollback and unsupportedPlan.rollback.writesPerformed,
    "unsupported planner performed a write")

T.finish("pnc_npc_foundation_import_plan_smoke")
