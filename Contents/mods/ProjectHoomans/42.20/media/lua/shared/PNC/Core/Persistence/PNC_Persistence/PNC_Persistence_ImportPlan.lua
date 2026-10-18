-- Read-only, source-preserving P0B import planning.

PNC = PNC or {}
PNC.Persistence = PNC.Persistence or {}

local Persistence = PNC.Persistence
local Const = PNC.Const or {}
local Identity = PNC.Identity
local Utils = require
    "PNC/Core/Persistence/PNC_Persistence/PNC_Persistence_ImportPlan_Utils"
local Source = require
    "PNC/Core/Persistence/PNC_Persistence/PNC_Persistence_ImportPlan_Source"
local ImportPlan = {}
local CURRENT_SCHEMA = tonumber(Const.PERSISTENCE_VERSION) or 16

local function rollbackRecord(sourceHash, status, reason, candidateHash)
    return {
        schemaVersion = 1,
        strategy = status == "ready"
            and "DISABLE_CANDIDATE_MAPPING"
            or "NO_WRITE_QUARANTINE",
        sourceHash = sourceHash,
        candidateHash = candidateHash,
        sourcePreserved = true,
        writesPerformed = false,
        reason = reason,
    }
end

local function validateCandidate(candidate, options, decisions)
    local codec = options and options.candidateCodec
    local serialized
    local restored
    local expectedHash
    local actualHash
    local ok
    if type(codec) ~= "table"
        or type(codec.serialize) ~= "function"
        or type(codec.deserialize) ~= "function"
    then
        Utils.AddDecision(decisions, "candidate.roundTrip", "quarantined",
            "candidate", "candidate_codec_missing")
        return nil
    end
    ok, serialized = pcall(codec.serialize, Utils.Copy(candidate))
    if not ok or serialized == nil then
        Utils.AddDecision(decisions, "candidate.serialize", "quarantined",
            "candidate", "candidate_serialize_failed")
        return nil
    end
    ok, restored = pcall(codec.deserialize, serialized)
    if not ok or type(restored) ~= "table" then
        Utils.AddDecision(decisions, "candidate.deserialize", "quarantined",
            "candidate", "candidate_deserialize_failed")
        return nil
    end
    expectedHash = Utils.Hash(candidate, Identity)
    actualHash = Utils.Hash(restored, Identity)
    if expectedHash ~= actualHash then
        Utils.AddDecision(decisions, "candidate.roundTrip", "quarantined",
            "candidate", "candidate_roundtrip_hash_mismatch")
        return nil
    end
    Utils.AddDecision(decisions, "candidate.roundTrip", "verified",
        "candidate", nil)
    return expectedHash, actualHash
end

function ImportPlan.Build(raw, options)
    options = type(options) == "table" and options or {}
    local decisions = {}
    local rawPayload = Utils.Copy(raw)
    local sourceHash = Utils.Hash(raw, Identity)
    local expectedVersion = tonumber(options.persistenceVersion)
        or CURRENT_SCHEMA
    local actualVersion = type(raw) == "table"
        and tonumber(raw.schemaVersion) or nil
    if type(raw) ~= "table" then
        Utils.AddDecision(decisions, "source", "rejected", "root",
            "malformed_record")
        return {
            status = "quarantined",
            reason = "malformed_record",
            sourceHash = sourceHash,
            rawPayload = rawPayload,
            decisions = decisions,
            rollback = rollbackRecord(sourceHash, "quarantined",
                "malformed_record"),
        }
    end
    if actualVersion ~= expectedVersion then
        Utils.AddDecision(decisions, "source.schemaVersion", "quarantined",
            "schemaVersion", "unsupported_schema")
        return {
            status = "quarantined",
            reason = "unsupported_schema",
            sourceHash = sourceHash,
            rawPayload = rawPayload,
            decisions = decisions,
            rollback = rollbackRecord(sourceHash, "quarantined",
                "unsupported_schema"),
        }
    end
    if type(raw.id) ~= "string" or raw.id == "" then
        Utils.AddDecision(decisions, "id", "rejected", "id",
            "actor_id_missing")
        return {
            status = "quarantined",
            reason = "actor_id_missing",
            sourceHash = sourceHash,
            rawPayload = rawPayload,
            decisions = decisions,
            rollback = rollbackRecord(sourceHash, "quarantined",
                "actor_id_missing"),
        }
    end
    local source = type(options.sourceSnapshot) == "table"
        and Utils.Copy(options.sourceSnapshot) or raw
    local buildOptions = {
        actorId = options.actorId,
        decisionSet = options.decisionSet,
        generatorVersion = options.generatorVersion,
        generatorProvenance = options.generatorProvenance,
        sourceRecordHash = sourceHash,
        sourceSnapshotHash = Utils.Hash(source, Identity),
    }
    local candidate = Source.Build(raw, source, buildOptions, decisions)
    local reason = Utils.FirstBlockingReason(decisions)
    if reason then
        return {
            status = "quarantined",
            reason = reason,
            sourceHash = sourceHash,
            rawPayload = rawPayload,
            decisions = decisions,
            rollback = rollbackRecord(sourceHash, "quarantined", reason),
        }
    end
    local candidateHash, candidateRoundTripHash = validateCandidate(
        candidate, options, decisions)
    reason = Utils.FirstBlockingReason(decisions)
    if reason then
        return {
            status = "quarantined",
            reason = reason,
            sourceHash = sourceHash,
            rawPayload = rawPayload,
            decisions = decisions,
            rollback = rollbackRecord(sourceHash, "quarantined", reason),
        }
    end
    return {
        status = "ready",
        sourceHash = sourceHash,
        rawPayload = rawPayload,
        decisions = decisions,
        candidate = candidate,
        candidateHash = candidateHash,
        candidateRoundTripHash = candidateRoundTripHash,
        rollback = rollbackRecord(sourceHash, "ready", nil,
            candidateHash),
    }
end

function ImportPlan.IsReady(plan)
    return type(plan) == "table" and plan.status == "ready"
end

function ImportPlan.Copy(value)
    return Utils.Copy(value)
end

function ImportPlan.Canonical(value)
    return Utils.Canonical(value)
end

Persistence.ImportPlan = ImportPlan
return ImportPlan
