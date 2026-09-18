-- Shared actor-control policy.
--
-- Puppet Opera is a temporary presentation owner.  The owner is enforced at
-- the movement and locomotion write boundaries, not only in the behavior
-- coordinator, so a later scheduler or native-path callback cannot replace a
-- scene with an idle/walk state.  Combat, vehicles, traversal, and grounded
-- recovery are explicit safety owners and retain priority.

PNC = PNC or {}
PNC.ActorControl = PNC.ActorControl or {}

local Control = PNC.ActorControl
local OVERRIDE_KEY = "puppetOperaOverride"
local LEASE_KEY = "puppetOperaLease"
local MOVEMENT_KEY = "puppetOperaMovement"

local function text(value)
    return tostring(value or "")
end

local function runtimeOf(record)
    return record and record.runtime or nil
end

local function leaseOf(record)
    local runtime = runtimeOf(record)
    if not runtime then return nil end
    return runtime[OVERRIDE_KEY] or runtime[LEASE_KEY]
end

local function ownerParts(owner)
    if type(owner) == "table" then
        return text(owner.kind or owner.ownerKind), text(
            owner.sessionId or owner.ownerSessionId
                or owner.puppetOperaSessionId
        )
    end
    return text(owner), ""
end

function Control.GetLease(record)
    return leaseOf(record)
end

function Control.GetSessionID(record)
    local lease = leaseOf(record)
    return lease and text(lease.sessionId) or ""
end

function Control.IsPuppetOwned(record)
    return leaseOf(record) ~= nil
        and Control.GetSessionID(record) ~= ""
end

function Control.IsOwned(record, sessionID)
    local expected = text(sessionID)
    return expected ~= ""
        and Control.GetSessionID(record) == expected
end

function Control.MakeOwner(sessionID)
    return {
        kind = "puppet_opera",
        sessionId = text(sessionID),
    }
end

function Control.ResolveOwner(owner, reason)
    local kind
    local sessionID
    local value
    if owner ~= nil then
        kind, sessionID = ownerParts(owner)
        if kind ~= "" then
            if string.sub(kind, 1, 13) == "puppet_opera:" then
                sessionID = string.sub(kind, 14)
                kind = "puppet_opera"
            end
            return {
                kind = kind,
                sessionId = sessionID ~= "" and sessionID or nil,
            }
        end
    end

    value = string.lower(text(reason))
    if string.find(value, "combat", 1, true)
        or string.find(value, "attack", 1, true)
        or string.find(value, "threat", 1, true)
    then
        return { kind = "combat" }
    end
    if string.find(value, "vehicle", 1, true)
        or string.find(value, "boarding", 1, true)
        or string.find(value, "disembark", 1, true)
    then
        return { kind = "vehicle" }
    end
    if string.find(value, "dead", 1, true)
        or string.find(value, "ground", 1, true)
        or string.find(value, "ragdoll", 1, true)
        or string.find(value, "getup", 1, true)
        or string.find(value, "passage", 1, true)
        or string.find(value, "traversal", 1, true)
        or string.find(value, "climb", 1, true)
        or string.find(value, "incap", 1, true)
    then
        return { kind = "safety" }
    end
    return nil
end

local function privileged(owner, options)
    local kind = ownerParts(owner)
    if type(options) == "table" then
        if options.hardSafety == true or options.allowSafety == true then
            return true
        end
        if options.allowCombat == true and kind == "combat" then
            return true
        end
        if options.allowVehicle == true and kind == "vehicle" then
            return true
        end
    end
    return kind == "combat"
        or kind == "vehicle"
        or kind == "safety"
        or kind == "traversal"
end

local function ownerMatches(owner, sessionID)
    local kind, ownerSessionID = ownerParts(owner)
    return kind == "puppet_opera"
        and ownerSessionID ~= ""
        and ownerSessionID == text(sessionID)
end

function Control.CanPump(record)
    local lease = leaseOf(record)
    local runtime = runtimeOf(record)
    local claim = runtime and runtime[MOVEMENT_KEY] or nil
    local intent = runtime and runtime.moveIntent or nil
    local sessionID = lease and text(lease.sessionId) or ""
    local intentSessionID = intent and text(
        intent.puppetOperaSessionId or intent.ownerSessionId
    ) or ""
    if not lease or sessionID == "" then return true end
    if not claim or text(claim.sessionId) ~= sessionID then return false end
    if not intent or intent.kind ~= "move" then return false end
    if intentSessionID ~= sessionID then return false end
    return string.sub(text(intent.reason), 1, 13) == "puppet_opera:"
end

function Control.NoteBlocked(record, lane, reason)
    local runtime = runtimeOf(record)
    local diagnostics
    if not runtime then return end
    diagnostics = runtime.puppetOperaDiagnostics
    if not diagnostics then
        diagnostics = {}
        runtime.puppetOperaDiagnostics = diagnostics
    end
    diagnostics.lastBlockedLane = text(lane)
    diagnostics.lastBlockedReason = text(reason)
    diagnostics.blockCount = (tonumber(diagnostics.blockCount) or 0) + 1
    diagnostics.lastBlockedAt = PNC.Core and PNC.Core.Now
        and PNC.Core.Now() or nil
end

function Control.CanWrite(record, owner, lane, options)
    local lease = leaseOf(record)
    local sessionID
    local resolvedOwner
    local reason
    if not lease or text(lease.sessionId) == "" then return true end
    options = type(options) == "table" and options or {}
    resolvedOwner = Control.ResolveOwner(owner, options.reason)
    sessionID = text(lease.sessionId)
    if ownerMatches(resolvedOwner, sessionID)
        or privileged(resolvedOwner, options)
    then
        return true
    end
    if options.allowPuppetMovement == true and Control.CanPump(record) then
        return true
    end
    reason = "puppet_opera_writer_blocked:" .. text(lane)
    Control.NoteBlocked(record, lane, reason)
    return false, reason
end

function Control.GetDiagnostics(record)
    local runtime = runtimeOf(record)
    return runtime and runtime.puppetOperaDiagnostics or nil
end

return Control
