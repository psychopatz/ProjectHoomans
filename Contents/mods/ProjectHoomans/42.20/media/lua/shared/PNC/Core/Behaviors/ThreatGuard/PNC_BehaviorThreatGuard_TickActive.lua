-- Active threat-guard state tick provider.

local ThreatGuard = PNC.BehaviorThreatGuard
local Internal = ThreatGuard.Internal
local H = Internal.ActiveTick
if type(H) ~= "table" then
    return ThreatGuard
end

local Common = H.Common
local RELEASE_GRACE_MS = H.RELEASE_GRACE_MS

function H.Run(record, zombie, state, now)
    local threatContext = H.ResolveContext(record)
    local target
    if not threatContext or not H.sameOwner(state, threatContext) then
        H.ClearState(record, zombie, "owner_changed")
        return false
    end
    target = H.RefreshTarget(record, state, threatContext, now)
    if target then
        state.lastThreatAt = now
        state.target = target
        if target.alertOnly == true then
            return H.AlertTarget(record, zombie, state, target)
        end
        if state.phase == "avoid" and not H.AttackEnabled(record) then
            return H.EnterAvoidance(
                record,
                zombie,
                state,
                target,
                threatContext
            )
        end
        if not H.AttackEnabled(record) then
            H.ClearState(record, zombie, "attack_disabled")
            return false
        end
        if not H.CanAttackTarget(record, target) then
            if H.EnterAvoidance(
                record,
                zombie,
                state,
                target,
                threatContext
            )
            then
                return true
            end
            return H.AlertTarget(record, zombie, state, target)
        end
        if not H.EngageTarget(record, zombie, target, threatContext) then
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
        state.phase = target.alertOnly == true and "alerted" or "engaged"
        record.activeBehavior = target.alertOnly == true
            and "CombatGuard:alerted" or "CombatGuard:engaged"
        return true
    end
    if now < (tonumber(state.lastThreatAt) or now) + RELEASE_GRACE_MS then
        if state.phase ~= "reacquiring" then
            H.LogTransition(
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
    H.ClearState(record, zombie, "threat_lost")
    return false
end

return ThreatGuard
