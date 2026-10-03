--[[
    PNC Combat Engagement

    Coordinates one live combat tick. Mode-specific handlers keep tactical
    arbitration, movement, and attack commitment out of BehaviorCombat.
]]

PNC = PNC or {}
PNC.CombatEngagement = PNC.CombatEngagement or {}

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
local Diagnostics = PNC.PerformanceScalingDiagnostics
local COMBAT_NAVIGATION = {
    navigationPolicy = "combat",
    navigationProvider = "engine_path",
}
local maintainRangedSpacing

local function logRangedDecision(context, attacked, reason, debugMode)
    local record
    local runtime
    local state
    local key
    local now
    local fields
    if not Diagnostics
        or Diagnostics.FirearmAuditEnabled ~= true
        or type(Diagnostics.LogFirearmAudit) ~= "function"
        or not context
        or not context.record
    then
        return false
    end
    record = context.record
    runtime = record.runtime or {}
    record.runtime = runtime
    state = runtime.firearmAuditRanged or {}
    runtime.firearmAuditRanged = state
    key = tostring(attacked == true) .. "|" .. tostring(reason or "")
    now = Core.Now()
    -- Failed tactical checks are sampled on reason changes or once per second;
    -- successful shots are always recorded because they are the pipeline entry.
    if attacked ~= true
        and state.key == key
        and (now - (tonumber(state.at) or 0)) < 1000
    then
        return false
    end
    state.key = key
    state.at = now
    fields = {
        "side=authority",
        "shotId=unassigned",
        "npc=" .. tostring(record.id or ""),
        "class=" .. tostring(record.tacticalClass or "unknown"),
        "faction=" .. tostring(record.affiliation
            and record.affiliation.factionID or ""),
        "hostility=" .. tostring(record.hostility
            and record.hostility.mode or ""),
        "decision=" .. tostring(attacked == true and "attack_started" or "blocked"),
        "reason=" .. tostring(reason or ""),
        "debugMode=" .. tostring(debugMode or ""),
        "distance=" .. tostring(context.distance or ""),
        "t=" .. tostring(now),
    }
    return Diagnostics.LogFirearmAudit("ranged_decision", fields)
end

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

local function prepareMeleeLane(context, reason)
    local switched
    local switchReason
    if context.mode ~= "mixed"
        or not Equipment
        or not Equipment.ActivateMeleeFallback
    then
        return false
    end
    switched, switchReason = Equipment.ActivateMeleeFallback(
        context.record,
        context.zombie,
        reason
    )
    if not switched then
        return false
    end
    context.equipment = Equipment.Describe(context.record)
    context.mode = context.equipment.combatModeResolved
    setDebug(
        context,
        switchReason or "switched_to_shove",
        "melee",
        switchReason == "switched_to_melee"
            and "melee_fallback"
            or "barehand_fallback"
    )
    return true
end

local function restoreMixedRanged(context)
    local runtime = context.record and context.record.runtime or nil
    local threshold
    local restored
    local reason
    if context.mode ~= "melee"
        or tostring(context.record.weaponMode or "") ~= "mixed"
        or not runtime
        or runtime.weaponFallbackTemporary ~= true
    then
        return false
    end
    if Combat and Combat.HasActiveAttack
        and Combat.HasActiveAttack(context.record, Core.Now())
    then
        return false
    end
    threshold = tonumber(runtime.weaponFallbackRange)
        or tonumber(Const.MIXED_MELEE_FALLBACK_RANGE)
        or 4.0
    if (tonumber(context.distance) or 0) <= threshold then
        return false
    end
    if not Equipment.RestoreRangedFallback then
        return false
    end
    restored, reason = Equipment.RestoreRangedFallback(
        context.record,
        context.zombie
    )
    if not restored then
        return false
    end
    context.equipment = Equipment.Describe(context.record)
    context.mode = context.equipment.combatModeResolved
    setDebug(context, reason or "switched_to_ranged", context.mode)
    return true
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

Internal = PNC.CombatEngagement.Internal
Internal.LogRangedDecision = logRangedDecision
Internal.SetDebug = setDebug
Internal.RefreshDistance = refreshDistance
Internal.HaltForAttack = haltForAttack
Internal.ClearRetreatFor = clearRetreatFor
Internal.LogBlocked = logBlocked
Internal.HoldRangedAim = holdRangedAim
Internal.HoldRangedAction = holdRangedAction
Internal.ActivateRangedFallback = activateRangedFallback
Internal.PrepareMeleeLane = prepareMeleeLane
Internal.RestoreMixedRanged = restoreMixedRanged
Internal.TryReposition = tryReposition
Internal.CombatNavigation = COMBAT_NAVIGATION

return Engagement
