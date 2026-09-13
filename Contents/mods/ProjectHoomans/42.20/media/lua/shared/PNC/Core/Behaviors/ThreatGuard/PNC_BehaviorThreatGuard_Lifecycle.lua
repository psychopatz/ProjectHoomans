-- Threat-guard ownership lifecycle and resumable passive behavior handoff.

local ThreatGuard = PNC.BehaviorThreatGuard
local Internal = ThreatGuard.Internal
local Core = PNC.Core
local Common = PNC.BehaviorCommon

local SCAN_MS = Internal.SCAN_MS
local RELEASE_GRACE_MS = Internal.RELEASE_GRACE_MS

local function nowValue(value)
    return tonumber(value) or Core.Now()
end

local function sameOwner(state, threatContext)
    return state and state.token == threatContext.token
end

function ThreatGuard.IsActive(record)
    local runtime = record and record.runtime or nil
    return runtime and runtime.threatGuard
        and runtime.threatGuard.active == true or false
end

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
    threatContext = Internal.ResolveContext(record)
    if state and state.active == true then
        if not threatContext or not sameOwner(state, threatContext) then
            Internal.ClearState(record, zombie, "owner_changed")
            return false
        end
        target = Internal.RefreshTarget(record, state, threatContext, now)
        if target then
            state.lastThreatAt = now
            state.target = target
            if state.phase == "avoid" and not Internal.AttackEnabled(record) then
                return Internal.EnterAvoidance(
                    record,
                    zombie,
                    state,
                    target,
                    threatContext
                )
            end
            if not Internal.AttackEnabled(record) then
                Internal.ClearState(record, zombie, "attack_disabled")
                return false
            end
            if not Internal.EngageTarget(record, zombie, target, threatContext) then
                Common.ClearCombatTarget(
                    record,
                    "threat_guard_reengage_failed",
                    zombie
                )
                state.target = nil
                state.phase = "reacquiring"
                record.activeBehavior = "CombatGuard:reacquiring"
                return true
            end
            state.phase = "engaged"
            record.activeBehavior = "CombatGuard:engaged"
            return true
        end
        if now < (tonumber(state.lastThreatAt) or now)
            + RELEASE_GRACE_MS
        then
            if state.phase ~= "reacquiring" then
                Internal.LogTransition(
                    "reacquiring",
                    record,
                    zombie,
                    state,
                    nil,
                    "target_lost"
                )
                if Common and Common.HaltMovement then
                    Common.HaltMovement(
                        record,
                        zombie,
                        "threat_guard_reacquiring"
                    )
                end
            end
            state.phase = "reacquiring"
            record.activeBehavior = "CombatGuard:reacquiring"
            return true
        end
        Internal.ClearState(record, zombie, "threat_lost")
        return false
    end
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
