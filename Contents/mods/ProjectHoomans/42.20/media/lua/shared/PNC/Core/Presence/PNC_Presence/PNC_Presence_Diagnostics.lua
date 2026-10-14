-- Opt-in diagnostics for abstract/live presence decisions.
--
-- This reuses the centrally persisted PresenceTraversalAudit setting. The
-- normal path is a single boolean check; no record snapshot or field table is
-- built while the channel is disabled.

local Presence = PNC.Presence
local Internal = Presence.Internal
local Diagnostics = PNC.PerformanceScalingDiagnostics
local Core = PNC.Core

local Audit = Internal.PresenceDiagnostics or {}
Internal.PresenceDiagnostics = Audit

local function enabled()
    return Diagnostics
        and Diagnostics.IsPresenceTraversalAuditEnabled
        and Diagnostics.IsPresenceTraversalAuditEnabled() == true
end

local function now()
    if Core and type(Core.Now) == "function" then
        return tonumber(Core.Now()) or 0
    end
    return 0
end

local function shouldLog(record, key, at)
    local runtime = record.runtime or {}
    local lastKey = runtime.presenceDecisionAuditKey
    local lastAt = tonumber(runtime.presenceDecisionAuditAt) or 0
    if lastKey == key and at - lastAt < 1000 then
        return false
    end
    runtime.presenceDecisionAuditKey = key
    runtime.presenceDecisionAuditAt = at
    record.runtime = runtime
    return true
end

function Audit.LogDecision(record, decision, reason, nearest, extra)
    local runtime
    local at
    local key
    local fields
    if not enabled() or type(record) ~= "table" then return false end

    runtime = record.runtime or {}
    at = now()
    key = tostring(record.presenceState or "nil") .. "|"
        .. tostring(decision or "unknown") .. "|"
        .. tostring(reason or "unknown") .. "|"
        .. tostring(runtime.vehiclePassenger
            and runtime.vehiclePassenger.active == true) .. "|"
        .. tostring(runtime.hardAbstract == true) .. "|"
        .. tostring(runtime.forceLive == true)
    if not shouldLog(record, key, at) then return false end

    fields = {
        "decision=" .. tostring(decision or "unknown"),
        "reason=" .. tostring(reason or "unknown"),
        "nearestDistSq=" .. tostring(nearest and nearest.distSq or "nil"),
        "indexed=" .. tostring(extra and extra.indexed or runtime
            .presenceInterestIndexed or "unknown"),
        "fallback=" .. tostring(extra and extra.fallback ~= nil
            and extra.fallback == true
            or runtime.presenceInterestFallback == true),
        "interestSource=" .. tostring(runtime.presenceInterestSource
            or "unknown"),
        "schedulerDueAt=" .. tostring(extra and extra.schedulerDueAt or "nil"),
        "vehiclePassenger=" .. tostring(runtime.vehiclePassenger
            and runtime.vehiclePassenger.active == true),
        "hardAbstract=" .. tostring(runtime.hardAbstract == true),
        "forceLive=" .. tostring(runtime.forceLive == true),
        "retryAt=" .. tostring(runtime.materializeRetryAt or "nil"),
    }
    return Diagnostics.LogPresenceTraversal(
        "materialization_decision",
        fields
    )
end

function Audit.LogMaterializeGate(record, gate, detail)
    local runtime
    local lifecycle
    local at
    local key
    if not enabled() or type(record) ~= "table" then return false end

    runtime = record.runtime or {}
    lifecycle = runtime.lifecycle or {}
    at = now()
    key = tostring(record.id or "nil") .. "|"
        .. tostring(gate or "unknown") .. "|"
        .. tostring(detail or "unknown") .. "|"
        .. tostring(runtime.materializeRetryAt or "nil")
    if runtime.materializeGateAuditKey == key
        and at - (tonumber(runtime.materializeGateAuditAt) or 0) < 1000
    then
        return false
    end
    runtime.materializeGateAuditKey = key
    runtime.materializeGateAuditAt = at
    record.runtime = runtime

    return Diagnostics.LogPresenceTraversal("materialization_gate", {
        "npc=" .. tostring(record.id or "nil"),
        "gate=" .. tostring(gate or "unknown"),
        "detail=" .. tostring(detail or "unknown"),
        "presence=" .. tostring(record.presenceState or "nil"),
        "lifecyclePhase=" .. tostring(lifecycle.phase or "nil"),
        "lifecycleError=" .. tostring(lifecycle.lastError or "nil"),
        "bodyLease=" .. tostring(runtime.bodyLease or "nil"),
        "retryAt=" .. tostring(runtime.materializeRetryAt or "nil"),
        "vehiclePassenger=" .. tostring(runtime.vehiclePassenger
            and runtime.vehiclePassenger.active == true),
        "hardAbstract=" .. tostring(runtime.hardAbstract == true),
        "forceLive=" .. tostring(runtime.forceLive == true),
    })
end

function Audit.LogInterest(nowValue, playerCount, queryCount, fallback, count)
    local at
    local key
    if not enabled() then return false end
    at = tonumber(nowValue) or now()
    key = tostring(playerCount or 0) .. "|"
        .. tostring(queryCount or 0) .. "|"
        .. tostring(fallback == true) .. "|"
        .. tostring(count or 0)
    if Audit.LastInterestKey == key
        and at - (tonumber(Audit.LastInterestAt) or 0) < 1000
    then
        return false
    end
    Audit.LastInterestKey = key
    Audit.LastInterestAt = at
    return Diagnostics.LogPresenceTraversal("materialization_interest", {
        "players=" .. tostring(playerCount or 0),
        "indexedResults=" .. tostring(queryCount or 0),
        "registryFallback=" .. tostring(fallback == true),
        "candidates=" .. tostring(count or 0),
    })
end

return Audit
