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
        }
    end
    local source = type(options.sourceSnapshot) == "table"
        and Utils.Copy(options.sourceSnapshot) or raw
    local buildOptions = {
        actorId = options.actorId,
        decisionSet = options.decisionSet,
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
        }
    end
    return {
        status = "ready",
        sourceHash = sourceHash,
        rawPayload = rawPayload,
        decisions = decisions,
        candidate = candidate,
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
