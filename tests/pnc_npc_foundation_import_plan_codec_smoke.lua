local T = require "tests/support/test"

T.load("tests/pnc_npc_foundation_parity_baseline_smoke.lua")

local ImportPlan = PNC.Persistence.ImportPlan
local Fixtures = require
    "tests/support/pnc_npc_foundation_import_plan_fixtures"

local sourceRecord = Fixtures.PrepareSourceRecord("npc:p0b:codec", true)
T.truthy(PNC.Inventory.ApplyDelta(sourceRecord, {
    {
        op = "add",
        item = {
            id = "loot:p0b:codec",
            type = "Base.CustomLoot",
            stack = 1,
            container = "root",
            itemState = { modData = { source = "codec" } },
        },
    },
}, "p0b_import_plan_codec"), "codec source item mutation")
local rawPayload = PNC.Persistence.SerializeRecord(sourceRecord)
local sourceSnapshot = ImportPlan.Copy(sourceRecord)
sourceSnapshot.schemaVersion = rawPayload.schemaVersion
local options = {
    sourceSnapshot = sourceSnapshot,
    generatorProvenance = {
        definitionRevision = sourceRecord.uniqueDefinitionVersion,
    },
}

local missingCodec = ImportPlan.Build(rawPayload, options)
T.equal(missingCodec.status, "quarantined",
    "missing candidate codec was accepted")
T.equal(missingCodec.reason, "candidate_codec_missing",
    "missing candidate codec reason")

local mismatch = ImportPlan.Copy(options)
mismatch.candidateCodec = {
    serialize = function()
        return "different-candidate"
    end,
    deserialize = function()
        return { schema = "PsychopatzCore.NPC", schemaVersion = 1 }
    end,
}
local hashMismatch = ImportPlan.Build(rawPayload, mismatch)
T.equal(hashMismatch.status, "quarantined",
    "candidate hash mismatch was accepted")
T.equal(hashMismatch.reason, "candidate_roundtrip_hash_mismatch",
    "candidate hash mismatch reason")

T.finish("pnc_npc_foundation_import_plan_codec_smoke")
