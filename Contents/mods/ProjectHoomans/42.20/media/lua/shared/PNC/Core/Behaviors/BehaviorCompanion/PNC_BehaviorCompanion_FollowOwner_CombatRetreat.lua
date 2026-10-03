-- Locked combat-retreat ownership for live FollowOwner ticks.

PNC = PNC or {}
PNC.BehaviorCompanion = PNC.BehaviorCompanion or {}
PNC.BehaviorCompanion.Internal = PNC.BehaviorCompanion.Internal or {}

local Companion = PNC.BehaviorCompanion
local H = Companion.Internal.FollowOwnerCombatRetreat
if type(H) ~= "table" then
    return Companion
end

local Const = H.Const
local CombatTactics = H.CombatTactics
local BehaviorCombat = H.BehaviorCombat
local SetFollowMode = H.SetFollowMode

function H.TryHandle(record, zombie, now)
    local retreatState
    local retreatWasActive
    local retreatContinued
    local retreatReason
    local combatTarget

    if not CombatTactics
        or not CombatTactics.Internal
        or not CombatTactics.Internal.EnsureRetreatState
    then
        return false, nil
    end
    retreatState = CombatTactics.Internal.EnsureRetreatState(record)
    retreatWasActive = retreatState and retreatState.phase == "retreat"
    if not retreatWasActive then
        return false, retreatState
    end

    combatTarget = record.runtime and record.runtime.target or nil
    retreatContinued, retreatReason =
        CombatTactics.Internal.ContinueLockedRetreat(
            record,
            zombie,
            combatTarget,
            retreatState,
            now
        )
    if retreatContinued then
        SetFollowMode(record, "combat_retreat")
        return true, retreatState
    end
    if retreatReason == "retreat_complete"
        or retreatReason == "retreat_safe_radius"
    then
        if combatTarget and combatTarget.kind == "zombie"
            and BehaviorCombat and BehaviorCombat.TickEngage
            and tostring(record.attackType or Const.ATTACK_TYPE_AUTO)
                ~= tostring(Const.ATTACK_TYPE_NONE or "none")
        then
            BehaviorCombat.TickEngage(record, zombie, combatTarget)
            SetFollowMode(record, "combat")
            return true, retreatState
        end
    end
    return false, retreatState
end

return Companion
