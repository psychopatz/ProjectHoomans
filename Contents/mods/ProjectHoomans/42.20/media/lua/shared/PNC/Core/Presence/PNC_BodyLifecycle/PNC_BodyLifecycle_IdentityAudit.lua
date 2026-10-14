-- Behavior-neutral body identity probe.
--
-- This module exists to identify the Build 42 restore boundary. It never
-- removes, moves, stamps, or otherwise mutates a body. It is centrally gated
-- by ProjectHoomans.BodyIdentityAudit and is intentionally cheap when the
-- setting is disabled.

PNC = PNC or {}
PNC.BodyLifecycle = PNC.BodyLifecycle or {}
PNC.BodyLifecycle.Internal = PNC.BodyLifecycle.Internal or {}

local Lifecycle = PNC.BodyLifecycle
local Internal = Lifecycle.Internal
local Core = PNC.Core

Lifecycle.IdentityAudit = Lifecycle.IdentityAudit or {
    sequence = 0,
    entries = {},
    order = {},
    maxEntries = 256,
    sampleIntervalMs = 250,
}

local Audit = Lifecycle.IdentityAudit

local function diagnostics()
    return PNC.PerformanceScalingDiagnostics
end

function Audit.IsEnabled()
    local channel = diagnostics()
    if channel and channel.IsBodyIdentityAuditEnabled then
        return channel.IsBodyIdentityAuditEnabled() == true
    end
    return channel and channel.BodyIdentityAuditEnabled == true
end

local function now()
    if Core and Core.Now then
        return tonumber(Core.Now()) or 0
    end
    if getTimestampMs then
        return tonumber(getTimestampMs()) or 0
    end
    return 0
end

local function createEntry(zombie)
    Audit.sequence = (tonumber(Audit.sequence) or 0) + 1
    local entry = {
        body = zombie,
        auditID = "bodyAudit_" .. tostring(Audit.sequence),
        lastAt = 0,
        lastSignature = nil,
        closed = false,
    }
    Audit.entries[zombie] = entry
    Audit.order[#Audit.order + 1] = entry
    while #Audit.order > (tonumber(Audit.maxEntries) or 256) do
        local oldest = table.remove(Audit.order, 1)
        if oldest and oldest.body
            and Audit.entries[oldest.body] == oldest
        then
            Audit.entries[oldest.body] = nil
        end
    end
    return entry
end

local function entryFor(zombie)
    local entry = Audit.entries[zombie]
    if not entry or entry.closed == true then
        entry = createEntry(zombie)
    end
    return entry
end

require "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_IdentityAudit_Snapshot"

function Audit.Capture(zombie, source, recordID, force)
    local entry
    local snapshot
    local currentSignature
    local currentAt
    if not Audit.IsEnabled() or not zombie then
        return false
    end
    entry = entryFor(zombie)
    currentAt = now()
    if force ~= true
        and (currentAt - (tonumber(entry.lastAt) or 0))
            < (tonumber(Audit.sampleIntervalMs) or 250)
    then
        return false
    end
    snapshot = Audit.ReadSnapshot(zombie, entry)
    currentSignature = Audit.Signature(snapshot)
    if force ~= true and entry.lastSignature == currentSignature then
        entry.lastAt = currentAt
        return false
    end
    entry.lastAt = currentAt
    entry.lastSignature = currentSignature
    Audit.Emit(snapshot, source, recordID)
    return true
end

function Audit.RecordRemoval(zombie, source, recordID, reason, removed)
    local entry
    local snapshot
    if not Audit.IsEnabled() or not zombie then
        return false
    end
    entry = entryFor(zombie)
    snapshot = Audit.ReadSnapshot(zombie, entry)
    entry.lastAt = now()
    entry.lastSignature = Audit.Signature(snapshot)
    Audit.Emit(snapshot, source or "removal_result", recordID, {
        "removed=" .. tostring(removed == true),
        "reason=" .. tostring(reason),
    })
    if removed == true then
        entry.closed = true
    end
    return true
end

require "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_IdentityAudit_Events"

return Audit
