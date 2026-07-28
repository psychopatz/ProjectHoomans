--[[
    PNC Combat Engagement

    Coordinates one live combat tick. Mode-specific handlers keep tactical
    arbitration, movement, and attack commitment out of BehaviorCombat.
]]

PNC = PNC or {}
PNC.CombatEngagement = PNC.CombatEngagement or {}

local Engagement = PNC.CombatEngagement
local Core = PNC.Core
local Const = PNC.Const
local Combat = PNC.Combat
local Equipment = PNC.Equipment
local Tactics = PNC.CombatTactics
local Common = PNC.BehaviorCommon
local PathService = PNC.PathService
local COMBAT_NAVIGATION = {
    navigationPolicy = "combat",
    navigationProvider = "direct",
}

local function setDebug(context, reason, mode, weaponStatus)
    Common.SetCombatDebug(
        context.record,
        context.target,
        reason,
        mode or context.mode,
        weaponStatus or context.equipment.weaponStatus
    )
end

local function refreshDistance(context)
    local internal = Combat and Combat.Internal or nil
    if internal and internal.refreshTargetDistance then
        context.distance = internal.refreshTargetDistance(
            context.record,
            context.zombie,
            context.target
        )
    else
        context.distance = math.sqrt(
            tonumber(context.target and context.target.distSq) or 0
        )
    end
    return context.distance
end

local function haltForAttack(context, reason)
    Common.HaltMovement(
        context.record,
        context.zombie,
        reason or "committed_attack"
    )
end

local function clearRetreatFor(context)
    if Tactics and Tactics.ClearRetreatState then
        Tactics.ClearRetreatState(context.record)
    end
end

local function logBlocked(context, lane, reason)
    local runtime
    local state
    local key
    local now
    local repeatMs
    if not context.record then return end
    context.record.runtime = context.record.runtime or {}
    runtime = context.record.runtime
    state = runtime.combatBlockedLog or {}
    runtime.combatBlockedLog = state
    key = tostring(lane or "combat")
        .. "|" .. tostring(reason or "unknown")
    now = Core.Now()
    repeatMs = tonumber(Const.COMBAT_BLOCK_LOG_REPEAT_MS) or 5000
    if state.key == key
        and (now - (tonumber(state.at) or 0)) < repeatMs
    then
        return
    end
    state.key = key
    state.at = now
    Core.LogRecordDebug(
        context.record,
        "NPC " .. tostring(context.record.id)
            .. " " .. tostring(lane or "combat")
            .. " blocked=" .. tostring(reason)
    )
end

local function holdRangedAim(context)
    local timings = Combat
        and Combat.Internal
        and Combat.Internal.ATTACK_TIMINGS
        or nil
    local leaseMs = timings
        and timings.ranged
        and timings.ranged.duration
        or 620
    haltForAttack(context, "ranged_aim")
    if Combat and Combat.FaceTarget then
        Combat.FaceTarget(
            context.record,
            context.zombie,
            context.target,
            leaseMs,
            "ranged_aim"
        )
    end
end

local function holdRangedAction(context, reason, mode)
    if reason ~= "reload_started"
        and reason ~= "reloading"
        and reason ~= "aiming"
    then
        return false
    end
    holdRangedAim(context)
    setDebug(
        context,
        reason == "aiming"
            and "building_aim_confidence"
            or "reloading",
        mode
    )
    return true
end

local function activateRangedFallback(context, reason)
    local switched
    local fallbackReason
    if reason ~= "out_of_ammo" then return false end
    if Equipment and Equipment.ActivateMeleeFallback then
        switched, fallbackReason =
            Equipment.ActivateMeleeFallback(
                context.record,
                context.zombie
            )
    end
    if switched then
        clearRetreatFor(context)
        setDebug(
            context,
            fallbackReason or "switched_to_shove",
            "melee",
            fallbackReason == "switched_to_melee"
                and "melee_fallback"
                or "barehand_fallback"
        )
        return true
    end
    setDebug(context, fallbackReason or reason, "ranged")
    return false
end

local function tryReposition(context, mode, reason, fallbackReason)
    local moved
    local moveReason
    if not Tactics or not Tactics.TryReposition then
        return false
    end
    moved, moveReason = Tactics.TryReposition(
        context.record,
        context.zombie,
        context.target,
        mode,
        reason,
        context.equipment
    )
    if moved then
        setDebug(
            context,
            moveReason or fallbackReason or "combat_reposition",
            context.mode
        )
    end
    return moved
end

local function tryTacticalPrecheck(context)
    local moved
    local reason
    local action
    local attacked
    if not Tactics or not Tactics.PreAttackDecision then
        return false
    end
    moved, reason, action = Tactics.PreAttackDecision(
        context.record,
        context.zombie,
        context.target,
        context.mode,
        context.equipment
    )
    if moved then
        setDebug(context, reason or "combat_reposition")
        return true
    end
    if action ~= "shove" or not Combat.TryShove then
        return false
    end
    attacked, reason = Combat.TryShove(
        context.record,
        context.zombie,
        context.target,
        reason
    )
    if attacked then
        haltForAttack(context, "pressure_shove")
        setDebug(context, "pressure_shove", "melee")
        return true
    end
    return tryReposition(
        context,
        "melee",
        reason,
        "post_shove_retreat"
    )
end

local function moveToMelee(context, reason)
    local shouldApproach
    local stopDistance
    local approachMode
    local x = context.target.x
    local y = context.target.y
    local usingFormation = false
    if Tactics and Tactics.ResolveMeleeApproach then
        shouldApproach, stopDistance, approachMode =
            Tactics.ResolveMeleeApproach(
                context.record,
                context.distance
            )
    else
        shouldApproach = reason == "target_out_of_range"
        stopDistance = tonumber(Const.MELEE_APPROACH_STOP_DISTANCE)
            or 0.92
        approachMode = "run"
    end
    if reason ~= "target_out_of_range" and not shouldApproach then
        return false
    end
    if Tactics and Tactics.GetMeleeApproachPoint then
        x, y, usingFormation = Tactics.GetMeleeApproachPoint(
            context.record,
            context.target
        )
    end
    Common.MoveRecord(
        context.record,
        context.zombie,
        x,
        y,
        context.target.z,
        Common.ResolveCombatApproachMode(
            context.distance,
            approachMode or "run"
        ),
        usingFormation and 0.2
            or (
                stopDistance
                or tonumber(Const.MELEE_APPROACH_STOP_DISTANCE)
                or 0.92
            ),
        usingFormation
            and "closing_to_melee_slot"
            or "closing_to_melee",
        COMBAT_NAVIGATION
    )
    setDebug(
        context,
        usingFormation
            and "closing_to_melee_slot"
            or "closing_to_melee"
    )
    return true
end

local function handleMelee(context, debugMode, allowApproach)
    local attacked
    local reason
    attacked, reason = Combat.TryMelee(
        context.record,
        context.zombie,
        context.target
    )
    if attacked then
        clearRetreatFor(context)
        haltForAttack(context, "attacking_melee")
        setDebug(context, "attacking_melee", debugMode)
        return true
    end
    if allowApproach ~= false
        and reason == "target_out_of_range"
        and moveToMelee(context, reason)
    then
        return true
    end
    if tryReposition(
        context,
        "melee",
        reason,
        "melee_kiting"
    ) then
        return true
    end
    setDebug(context, reason, debugMode)
    logBlocked(context, debugMode .. " melee", reason)
    return true
end

local function moveToRangedRange(context, debugMode, stopFactor)
    Common.MoveRecord(
        context.record,
        context.zombie,
        context.target.x,
        context.target.y,
        context.target.z,
        Common.ResolveCombatApproachMode(
            context.distance,
            "run"
        ),
        (tonumber(Const.RANGED_RANGE) or 8.5)
            * (tonumber(stopFactor) or 0.8),
        "closing_to_range",
        COMBAT_NAVIGATION
    )
    setDebug(context, "closing_to_range", debugMode)
end

local function handleRanged(context, debugMode, stopFactor)
    local attacked
    local reason
    if context.distance <= (tonumber(Const.RANGED_RANGE) or 8.5) then
        holdRangedAim(context)
    end
    attacked, reason = Combat.TryRanged(
        context.record,
        context.zombie,
        context.target
    )
    if attacked then
        clearRetreatFor(context)
        haltForAttack(context, "attacking_ranged")
        setDebug(context, "attacking_ranged", debugMode)
        return true
    end
    if holdRangedAction(context, reason, debugMode) then
        return true
    end
    if activateRangedFallback(context, reason) then
        return true
    end
    if reason == "target_out_of_range" then
        moveToRangedRange(context, debugMode, stopFactor)
        return true
    end
    if tryReposition(
        context,
        "ranged",
        reason,
        "maintaining_range"
    ) then
        return true
    end
    setDebug(context, reason, debugMode)
    logBlocked(context, debugMode .. " ranged", reason)
    return true
end

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

local function maintainRangedSpacing(context)
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

local function maintainEmergencyStandoff(context)
    if context.mode ~= "ranged"
        or context.target.kind ~= "zombie"
        or context.distance
            >= (tonumber(Const.RANGED_MIN_STANDOFF) or 2.2)
    then
        return false
    end
    return tryReposition(
        context,
        "ranged",
        "target_too_close",
        "maintaining_range"
    )
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

    if Equipment.ApplyCombatState then
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
    if maintainRangedSpacing(context) then
        return true
    end
    if maintainEmergencyStandoff(context) then
        return true
    end
    if context.mode == "melee" then
        return handleMelee(context, "melee", true)
    end
    if context.mode == "ranged" then
        return handleRanged(context, "ranged", 0.8)
    end

    meleeCommitRange = (
        tonumber(Const.MELEE_RANGE) or 1.3
    ) + (
        tonumber(Const.MELEE_HIT_TOLERANCE) or 0.12
    )
    if context.distance <= meleeCommitRange then
        return handleMelee(context, "mixed", false)
    end
    return handleRanged(context, "mixed", 0.85)
end

return Engagement
