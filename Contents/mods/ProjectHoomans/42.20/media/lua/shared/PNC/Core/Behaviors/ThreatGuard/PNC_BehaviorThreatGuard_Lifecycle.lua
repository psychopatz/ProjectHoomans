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

Internal.Lifecycle = {
    Core = Core,
    Common = Common,
    SCAN_MS = SCAN_MS,
    RELEASE_GRACE_MS = RELEASE_GRACE_MS,
    nowValue = nowValue,
    sameOwner = sameOwner,
}
Internal.ActiveTick = {
    Common = Common,
    RELEASE_GRACE_MS = RELEASE_GRACE_MS,
    sameOwner = sameOwner,
    ResolveContext = Internal.ResolveContext,
    ClearState = Internal.ClearState,
    RefreshTarget = Internal.RefreshTarget,
    AlertTarget = Internal.AlertTarget,
    AttackEnabled = Internal.AttackEnabled,
    EnterAvoidance = Internal.EnterAvoidance,
    CanAttackTarget = Internal.CanAttackTarget,
    EngageTarget = Internal.EngageTarget,
    LogTransition = Internal.LogTransition,
}
require "PNC/Core/Behaviors/ThreatGuard/PNC_BehaviorThreatGuard_TickActive"
require "PNC/Core/Behaviors/ThreatGuard/PNC_BehaviorThreatGuard_Tick"

return ThreatGuard
