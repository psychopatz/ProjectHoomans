-- Shared record-state helpers and persistent runtime counters.

PNC = PNC or {}
PNC.BodyLifecycle = PNC.BodyLifecycle or {}

local Lifecycle = PNC.BodyLifecycle
Lifecycle.Internal = Lifecycle.Internal or {}

local Internal = Lifecycle.Internal
local Core = PNC.Core

Lifecycle.PendingCorpses = Lifecycle.PendingCorpses or {}
Lifecycle.NextAuditAt = Lifecycle.NextAuditAt or 0
Lifecycle.NextCorpseAuditAt = Lifecycle.NextCorpseAuditAt or 0
Lifecycle.CorpseAuditCursor = Lifecycle.CorpseAuditCursor or 1
Lifecycle.LastAudit = Lifecycle.LastAudit or {
    scanned = 0,
    removed = 0,
    rebound = 0,
    duplicates = 0,
    corpses = 0,
}

function Internal.registry()
    return PNC.Registry
end

function Internal.ensureRuntime(record)
    local now = Core.Now()
    record.runtime = record.runtime or {}
    record.runtime.lifecycle = record.runtime.lifecycle or {
        phase = record.presenceState or "unknown",
        bodyState = "missing",
        lastReason = "runtime_created",
        lastTransitionAt = now,
        lastAuditAt = 0,
        lastError = nil,
        corpseState = record.alive == false and "unresolved" or "none",
    }
    return record.runtime.lifecycle
end

function Internal.mark(record, phase, bodyState, reason, errorText)
    local state
    if not record then
        return
    end
    state = Internal.ensureRuntime(record)
    if phase and state.phase ~= phase then
        state.lastTransitionAt = Core.Now()
    end
    state.phase = phase or state.phase
    state.bodyState = bodyState or state.bodyState
    state.lastReason = reason or state.lastReason
    state.lastError = errorText
end

function Internal.noteCleanup(record, cleanupState, reason)
    local state
    if not record then
        return
    end
    state = Internal.ensureRuntime(record)
    state.lastCleanupState = cleanupState
    state.lastCleanupReason = reason
    state.lastCleanupAt = Core.Now()
end

function Internal.normalizeOnlineID(zombie)
    local value = zombie and zombie.getOnlineID and tonumber(zombie:getOnlineID()) or nil
    return value and value >= 0 and value or nil
end
