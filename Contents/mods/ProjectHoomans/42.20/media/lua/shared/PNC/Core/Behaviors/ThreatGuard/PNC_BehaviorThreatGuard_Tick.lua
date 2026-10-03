-- Threat-guard tick provider.

PNC = PNC or {}
PNC.BehaviorThreatGuard = PNC.BehaviorThreatGuard or {}
PNC.BehaviorThreatGuard.Internal = PNC.BehaviorThreatGuard.Internal or {}

local ThreatGuard = PNC.BehaviorThreatGuard
local Internal = ThreatGuard.Internal
local H = Internal.Lifecycle
if type(H) ~= "table" then
    return ThreatGuard
end

local SCAN_MS = H.SCAN_MS
local nowValue = H.nowValue
local ActiveTick = Internal.ActiveTick

function ThreatGuard.Tick(record, zombie, now)
    local runtime = record and record.runtime or nil
    local state = runtime and runtime.threatGuard or nil
    local probe
    local threatContext
    local target
    now = nowValue(now)
    if not record or not runtime or not zombie then
        return false
    end
    if state and state.active == true then
        return ActiveTick.Run(record, zombie, state, now)
    end
    threatContext = Internal.ResolveContext(record)
    if not threatContext then return false end
    probe = {
        target = nil,
        nextScanAt = runtime.threatGuardNextScanAt or 0,
    }
    target = Internal.RefreshTarget(record, probe, threatContext, now)
    if not target then
        runtime.threatGuardNextScanAt = probe.nextScanAt
            or (now + SCAN_MS)
        return false
    end
    runtime.threatGuardNextScanAt = nil
    state = {
        active = true,
        source = threatContext.source,
        ownerKind = threatContext.ownerKind,
        token = threatContext.token,
        context = threatContext,
        enteredAt = now,
        lastThreatAt = now,
        phase = "acquiring",
        target = target,
    }
    runtime.threatGuard = state
    if Internal.Engage(record, zombie, state, target, threatContext) then
        return true
    end
    runtime.threatGuard = nil
    return false
end

return ThreatGuard
