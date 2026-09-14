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

local function canFightThroughTravelConversation(record, scene)
    local runtime = record and record.runtime or nil
    local lease = runtime and runtime.conversationLease or nil
    return scene
        and scene.id == "social.conversation"
        and scene.blocking == true
        and lease
        and lease.travelHold == true
        and runtime.threatGuard ~= nil
end

local function releaseBlockingCombatScene(record, zombie, scene)
    local runtime = record and record.runtime or nil
    local remaining
    if not runtime or not scene then return true end
    if PNC.AnimationScenes and PNC.AnimationScenes.Interrupt then
        PNC.AnimationScenes.Interrupt(record, zombie, "combat")
    end
    remaining = runtime.animationScene
    if remaining == scene
        and remaining.blocking == true
        and PNC.AnimationScenes
        and PNC.AnimationScenes.Stop
    then
        PNC.AnimationScenes.Stop(record, zombie, "combat_force_stop")
        remaining = runtime.animationScene
    end
    return not remaining or remaining.blocking ~= true
end

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
        and Tactics.ShouldInterruptAttackForRetreat
        and Combat.CancelAttackAction
    then
        interrupt, reason =
            Tactics.ShouldInterruptAttackForRetreat(record)
        if interrupt then
            Combat.CancelAttackAction(
                record,
                zombie,
                nil,
                reason or "combat_retreat"
            )
            Common.SetCombatDebug(
                record,
                target,
                reason or "combat_retreat",
                equipmentInfo.combatModeResolved,
                equipmentInfo.weaponStatus
            )
            return false
        end
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
    local travelConversationCombat = canFightThroughTravelConversation(
        record,
        scene
    )
    if scene and scene.blocking == true and not travelConversationCombat then
        if not releaseBlockingCombatScene(record, zombie, scene) then
            if Common and Common.SetCombatDebug then
                Common.SetCombatDebug(
                    record,
                    target,
                    "combat_scene_blocked"
                )
            end
            return false
        end
        if record.runtime
            and record.runtime.facilityActivity
            and record.runtime.facilityActivity.sleepWakePending == true
        then
            if Common and Common.SetCombatDebug then
                Common.SetCombatDebug(
                    record,
                    target,
                    "combat_waiting_sleep_wake"
                )
            end
            return false
        end
    end
    if not travelConversationCombat
        and PNC.AnimationScenes
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
