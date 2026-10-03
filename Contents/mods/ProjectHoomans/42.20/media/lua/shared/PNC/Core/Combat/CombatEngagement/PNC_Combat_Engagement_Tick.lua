local Engagement = PNC.CombatEngagement
local Internal = Engagement.Internal
local Core = PNC.Core
local Const = PNC.Const
local Combat = PNC.Combat
local Equipment = PNC.Equipment
local Tactics = PNC.CombatTactics
local Stance = PNC.CombatStance
local Defense = PNC.CombatDefense
local Common = PNC.BehaviorCommon
local PathService = PNC.PathService
local setDebug = Internal.SetDebug
local refreshDistance = Internal.RefreshDistance
local restoreMixedRanged = Internal.RestoreMixedRanged
local haltForAttack = Internal.HaltForAttack
local clearRetreatFor = Internal.ClearRetreatFor
local prepareMeleeLane = Internal.PrepareMeleeLane
local tryTacticalPrecheck = Internal.TryTacticalPrecheck
local handleMelee = Internal.HandleMelee
local handleRanged = Internal.HandleRanged
local COMBAT_NAVIGATION = Internal.CombatNavigation

local function investigateHiddenTarget(context)
    local reason = context.target.visible == false
        and "investigating_last_seen"
        or "approaching_visible_window"
    Common.MoveRecord(
        context.record,
        context.zombie,
        context.target.x,
        context.target.y,
        context.target.z,
        Common.ResolveCombatApproachMode(
            context.distance,
            "walk"
        ),
        0.75,
        reason,
        COMBAT_NAVIGATION
    )
    setDebug(context, reason)
end

maintainRangedSpacing = function(context)
    local moved
    local reason
    if context.mode ~= "ranged"
        and context.mode ~= "mixed"
    then
        return false
    end
    if not Tactics or not Tactics.MaintainRangedSpacing then
        return false
    end
    moved, reason = Tactics.MaintainRangedSpacing(
        context.record,
        context.zombie,
        context.target
    )
    if moved then
        setDebug(context, reason or "ranged_disengage")
    end
    return moved
end

function Engagement.Tick(record, zombie, target)
    local context
    local actionActive
    local actionReason
    local meleeCommitRange
    if not record or not zombie or not target then
        return false
    end
    record.runtime = record.runtime or {}
    context = {
        record = record,
        zombie = zombie,
        target = target,
        equipment = Equipment.Describe(record),
        previousWeaponStatus = record.runtime.weaponStatus,
    }
    context.mode = context.equipment.combatModeResolved
    refreshDistance(context)
    restoreMixedRanged(context)
    if Defense and Defense.Refresh then
        Defense.Refresh(record, zombie)
    end

    if Equipment.ApplyCombatState then
        -- Refresh the fighting-mode hold before presentation reads it, so a
        -- reload, a spacing reposition, or a target re-acquisition never
        -- re-holsters the weapon mid-fight.
        if Stance and Stance.Maintain then
            Stance.Maintain(record)
        end
        Equipment.ApplyCombatState(zombie, record, true)
    end
    setDebug(
        context,
        "engaging_" .. tostring(target.kind or "unknown")
    )
    if PathService
        and PathService.IsTraversalActive
        and PathService.IsTraversalActive(record, zombie)
    then
        setDebug(context, "traversal_active")
        return true
    end
    if context.equipment.weaponStatus
        ~= context.previousWeaponStatus
    then
        Core.LogRecordDebug(
            record,
            "NPC " .. tostring(record.id)
                .. " weapon state="
                .. tostring(context.equipment.weaponStatus)
        )
    end
    if Combat and Combat.PumpAttackAction then
        actionActive, actionReason =
            Combat.PumpAttackAction(record, zombie)
        if actionActive then
            haltForAttack(context, "committed_attack")
            setDebug(
                context,
                actionReason or "attack_in_progress"
            )
            return true
        end
    end

    refreshDistance(context)
    if tryTacticalPrecheck(context) then
        return true
    end
    if target.visible == false
        or target.visibilityKind == "clearthroughwindow"
    then
        investigateHiddenTarget(context)
        return true
    end
    -- Mixed loadouts commit to melee before ranged spacing arbitrates. The
    -- previous order always backed away from a close zombie and could never
    -- reach the later MELEE_COMMIT_RANGE branch.
    if context.mode == "mixed"
        and context.distance
            <= (tonumber(Const.MIXED_MELEE_SWITCH_RANGE) or 2.4)
    then
        clearRetreatFor(context)
        prepareMeleeLane(context, "mixed_close")
        return handleMelee(context, "mixed", true)
    end
    if context.mode == "melee" then
        return handleMelee(context, "melee", true)
    end
    if context.mode == "ranged" then
        return handleRanged(context, "ranged", 0.8)
    end

    meleeCommitRange =
        tonumber(Const.MELEE_COMMIT_RANGE)
        or tonumber(Const.MELEE_APPROACH_STOP_DISTANCE)
        or 1.0
    if context.distance <= meleeCommitRange then
        prepareMeleeLane(context, "mixed_close")
        return handleMelee(context, "mixed", false)
    end
    return handleRanged(context, "mixed", 0.85)
end

Internal.MaintainRangedSpacing = maintainRangedSpacing

return Engagement
