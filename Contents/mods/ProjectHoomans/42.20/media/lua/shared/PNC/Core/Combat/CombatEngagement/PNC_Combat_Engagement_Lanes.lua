local Engagement = PNC.CombatEngagement
local Internal = Engagement.Internal
local Const = PNC.Const
local Combat = PNC.Combat
local Equipment = PNC.Equipment
local Tactics = PNC.CombatTactics
local Common = PNC.BehaviorCommon
local logRangedDecision = Internal.LogRangedDecision
local setDebug = Internal.SetDebug
local haltForAttack = Internal.HaltForAttack
local clearRetreatFor = Internal.ClearRetreatFor
local logBlocked = Internal.LogBlocked
local holdRangedAim = Internal.HoldRangedAim
local holdRangedAction = Internal.HoldRangedAction
local activateRangedFallback = Internal.ActivateRangedFallback
local prepareMeleeLane = Internal.PrepareMeleeLane
local tryReposition = Internal.TryReposition
local COMBAT_NAVIGATION = Internal.CombatNavigation
local maintainRangedSpacing = function(context)
    local handler = Internal.MaintainRangedSpacing
    return handler and handler(context) or false
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

Internal.TryTacticalPrecheck = tryTacticalPrecheck

local function moveToMelee(context, reason)
    local shouldApproach
    local stopDistance
    local approachMode
    local accepted
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
    accepted = Common.MoveRecord(
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
    if context.record.runtime
        and context.record.runtime.combatTactical
    then
        context.record.runtime.combatTactical.decision =
            usingFormation
                and "closing_to_melee_slot"
                or "closing_to_melee"
        context.record.runtime.combatTactical.approachDistance =
            context.distance
        context.record.runtime.combatTactical.approachAccepted =
            accepted ~= false
    end
    return accepted ~= false
end

local function handleMelee(context, debugMode, allowApproach)
    local attacked
    local reason
    local commitRange =
        tonumber(Const.MELEE_COMMIT_RANGE)
        or tonumber(Const.MELEE_APPROACH_STOP_DISTANCE)
        or 1.0
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
        -- Distance is authoritative even if another gate (cooldown, stamina,
        -- or a stale action lease) supplied the reason. Never claim the melee
        -- lane is handled while the target remains outside strike reach.
        and (
            reason == "target_out_of_range"
            or (tonumber(context.distance) or math.huge) > commitRange
        )
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

Internal.HandleMelee = handleMelee

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
    logRangedDecision(context, attacked, reason, debugMode)
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
    if debugMode == "mixed"
        and reason == "friendly_fire_risk"
        and context.distance
            <= (tonumber(Const.MIXED_MELEE_FALLBACK_RANGE) or 4.0)
    then
        clearRetreatFor(context)
        prepareMeleeLane(context, "friendly_fire_risk")
        return handleMelee(context, "mixed", true)
    end
    if reason == "target_out_of_range" then
        moveToRangedRange(context, debugMode, stopFactor)
        return true
    end
    -- Fire/aim arbitration comes first. Spacing is a cooldown recovery action,
    -- not a reason to replace every valid shot with another retreat path.
    if reason == "cooldown_active"
        and maintainRangedSpacing(context)
    then
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

Internal.HandleRanged = handleRanged

return Engagement
