-- Per-tick processing for committed attacks and reloads.

local Combat = PNC.Combat
local Internal = Combat.Internal
local AttackExecution = Internal.AttackExecution
local Core = PNC.Core
local Firearms = PNC.Firearms

function Combat.PumpAttackAction(record, zombie)
    local now = Core.Now()
    local action = record and record.runtime and record.runtime.attackAction or nil
    local target
    if not action then
        return false, "no_attack"
    end
    if PNC.PathService and PNC.PathService.IsTraversalActive and PNC.PathService.IsTraversalActive(record, zombie) then
        -- Traversal owns its separate special-animation lane. Ending the
        -- combat action only publishes an inactive attack snapshot.
        Internal.finishAttackAction(record, zombie)
        return false, "attack_cancelled_for_traversal"
    end
    if not zombie or record.alive == false then
        Internal.finishAttackAction(record, zombie)
        return false, "attack_cleared"
    end

    if action.attackType == "reload" then
        target = AttackExecution.resolveActionTarget(action.target)
        if target then
            Internal.faceTarget(zombie, target, record, 120, "reload_followthrough")
        end
        if now >= (tonumber(action.finishAt) or 0) then
            if Firearms and Firearms.CompleteReload then
                action.lastResult, action.lastReason = Firearms.CompleteReload(record, zombie, action)
            else
                action.lastResult, action.lastReason = false, "firearm_service_unavailable"
            end
            Internal.finishAttackAction(record, zombie)
            return false, action.lastReason or "reload_finished"
        end
        return true, "reloading"
    end

    target = AttackExecution.resolveActionTarget(action.target)
    if not target then
        Internal.finishAttackAction(record, zombie)
        return false, "target_lost_or_dead"
    end
    if target
        and not AttackExecution.isActionTargetVisible(record, target)
        and not (action.attackType == "melee" and AttackExecution.isCommittedMeleeTargetInRange(zombie, target))
    then
        Internal.finishAttackAction(record, zombie)
        return false, "target_not_visible"
    end
    if target then
        Internal.faceTarget(zombie, target, record, 120, "attack_followthrough")
    end
    if (not action.hitDone) and now >= (tonumber(action.hitAt) or 0) then
        action.hitDone = true
        if action.attackType == "melee" and not AttackExecution.isCommittedMeleeTargetInRange(zombie, target) then
            action.lastResult = false
            action.lastReason = "target_out_of_range_at_hit"
        else
            action.lastResult, action.lastReason = Internal.applyAttackActionHit(record, zombie, action, target)
        end
        if action.lastResult ~= true and Core and Core.Log then
            Core.Log("WARN", "attack_hit_failed npc=" .. tostring(record and record.id or "nil") .. " reason=" .. tostring(action.lastReason or "unknown") .. " target=" .. tostring(target and target.kind or "nil"))
        end
    end

    if target == nil or now >= (tonumber(action.finishAt) or 0) then
        Internal.finishAttackAction(record, zombie)
        return false, action.lastReason or (target and "attack_finished" or "target_lost")
    end

    return true, action.attackType == "ranged" and "attack_anim_ranged" or "attack_anim_melee"
end
