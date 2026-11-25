-- Unified Watchdog core for actor poses, committed actions, orders, and tasks.

PNC = PNC or {}
PNC.Watchdog = PNC.Watchdog or {}

local Watchdog = PNC.Watchdog
local Core = PNC.Core
local MAX_RECENT_EVENTS = 32
local WARN_THROTTLE_MS = 10000

Watchdog.Diagnostics = Watchdog.Diagnostics or {
    counters = {},
    recent = {},
    lastEvent = nil,
}

local warnLogAt = {}

function Watchdog.Record(domain, npcId, reason, outcome)
    local now = Core and Core.Now and Core.Now() or 0
    local diag = Watchdog.Diagnostics
    local counters = diag.counters
    local domainKey = tostring(domain or "unknown")
    local reasonKey = tostring(reason or "unknown")
    local outcomeKey = tostring(outcome or "recovered")
    counters.total = (counters.total or 0) + 1
    counters[domainKey] = (counters[domainKey] or 0) + 1
    local entry = {
        domain = domainKey,
        npcId = npcId and tostring(npcId) or nil,
        reason = reasonKey,
        outcome = outcomeKey,
        at = now,
    }
    diag.lastEvent = entry
    diag.recent[#diag.recent + 1] = entry
    while #diag.recent > MAX_RECENT_EVENTS do
        table.remove(diag.recent, 1)
    end
    local logKey = domainKey .. "|" .. tostring(npcId or "nil") .. "|" .. reasonKey
    if (now - (tonumber(warnLogAt[logKey]) or 0)) >= WARN_THROTTLE_MS then
        warnLogAt[logKey] = now
        if Core and Core.LogWarn then
            Core.LogWarn(
                "watchdog domain=" .. domainKey
                    .. " npc=" .. tostring(npcId or "nil")
                    .. " reason=" .. reasonKey
                    .. " outcome=" .. outcomeKey
            )
        end
    end
    return entry
end

function Watchdog.IsDeadlineStale(startedAt, finishAt, now, graceMs, capMs)
    startedAt = tonumber(startedAt) or now
    finishAt = tonumber(finishAt) or 0
    graceMs = tonumber(graceMs) or 1000
    capMs = tonumber(capMs) or 10000
    if finishAt > 0 then
        return now >= finishAt + graceMs
    end
    return (now - startedAt) >= capMs
end

-- Shared normalization contract for all Tasking recovery providers so invalid
-- or orphaned provider state can never silently fall through as unwatchable.
function Watchdog.NormalizeTaskSnapshot(snapshot, lease)
    if type(snapshot) ~= "table" then return nil end
    if snapshot.invalid == true then
        snapshot.watchable = true
        snapshot.forceRecovery = true
        snapshot.recoveryReason = snapshot.recoveryReason
            or (tostring(lease and lease.sourceDomain or "task") .. "_state_invalid")
    end
    return snapshot
end

function Watchdog.GetDiagnostics()
    return Watchdog.Diagnostics
end

require "PNC/Core/Watchdog/PNC_Watchdog_Pose"
require "PNC/Core/Watchdog/PNC_Watchdog_Actions"

-- Single actor-side watchdog entry point called once per tick from BehaviorSystem
-- preflight. Runs committed-action deadlines, orphaned body-pose recovery, and
-- direct-order movement recovery in deterministic order.
function Watchdog.AuditActor(record, zombie, now)
    if not record or record.alive == false then return false end
    now = tonumber(now) or (Core and Core.Now and Core.Now()) or 0
    if Watchdog.RecoverCommittedActions
        and Watchdog.RecoverCommittedActions(record, zombie, now)
    then
        return true
    end
    if Watchdog.RecoverBodyPose
        and Watchdog.RecoverBodyPose(record, zombie, now)
    then
        return true
    end
    local OrderSystem = PNC.OrderSystem
    if OrderSystem and OrderSystem.RecoverStalled
        and OrderSystem.RecoverStalled(record, zombie, now)
    then
        if Watchdog.RecoverBodyPose then
            Watchdog.RecoverBodyPose(record, zombie, now)
        end
        return true
    end
    return false
end

return Watchdog
