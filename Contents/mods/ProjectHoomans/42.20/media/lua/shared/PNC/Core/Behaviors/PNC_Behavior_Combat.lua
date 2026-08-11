--[[
    PNC Behavior Combat

    Behavior-facing adapter for committed actions and the combat engagement
    controller. Tactical and mode-specific flow lives in CombatEngagement.
]]

PNC = PNC or {}
PNC.BehaviorCombat = PNC.BehaviorCombat or {}

local BehaviorCombat = PNC.BehaviorCombat
local Combat = PNC.Combat
local Equipment = PNC.Equipment
local Tactics = PNC.CombatTactics
local Common = PNC.BehaviorCommon
local Engagement = PNC.CombatEngagement

function BehaviorCombat.TickCommittedAction(record, zombie)
    local equipmentInfo
    local actionActive
    local reason
    local target
    local interrupt
    if PNC.LiveBodyControl and PNC.LiveBodyControl.IsGrounded
        and PNC.LiveBodyControl.IsGrounded(zombie)
    then
        if Combat and Combat.CancelAttackAction then
            Combat.CancelAttackAction(record, zombie, nil, "actor_grounded")
        end
        return false
    end
    if not Combat
        or not Combat.PumpAttackAction
        or not record
        or not record.runtime
        or not record.runtime.attackAction
    then
        return false
    end
    target = record.runtime.target
    equipmentInfo = Equipment.Describe(record)
    if Equipment.ApplyCombatState and zombie then
        Equipment.ApplyCombatState(zombie, record, true)
    end
    if Tactics
        and Tactics.ShouldInterruptReload
        and Combat.CancelAttackAction
    then
        interrupt, reason =
            Tactics.ShouldInterruptReload(record, target)
        if interrupt then
            Combat.CancelAttackAction(
                record,
                zombie,
                "reload",
                reason
            )
            Common.SetCombatDebug(
                record,
                target,
                reason or "reload_interrupted_by_pressure",
                equipmentInfo.combatModeResolved,
                equipmentInfo.weaponStatus
            )
            return false
        end
    end
    actionActive, reason = Combat.PumpAttackAction(record, zombie)
    if not actionActive then
        return false
    end
    Common.HaltMovement(record, zombie, "committed_attack")
    Common.SetCombatDebug(
        record,
        target,
        reason or "attack_in_progress",
        equipmentInfo.combatModeResolved,
        equipmentInfo.weaponStatus
    )
    return true
end

function BehaviorCombat.TickEngage(record, zombie, target)
    if PNC.LiveBodyControl and PNC.LiveBodyControl.IsGrounded
        and PNC.LiveBodyControl.IsGrounded(zombie)
    then
        if Combat and Combat.CancelAttackAction then
            Combat.CancelAttackAction(record, zombie, nil, "actor_grounded")
        end
        return true
    end
    local scene = record and record.runtime
        and record.runtime.animationScene or nil
    if scene and scene.blocking == true then
        return true
    end
    if PNC.AnimationScenes
        and PNC.AnimationScenes.Interrupt
    then
        PNC.AnimationScenes.Interrupt(
            record,
            zombie,
            "combat"
        )
    end
    if not Engagement or not Engagement.Tick then
        return false
    end
    return Engagement.Tick(record, zombie, target)
end

return BehaviorCombat
