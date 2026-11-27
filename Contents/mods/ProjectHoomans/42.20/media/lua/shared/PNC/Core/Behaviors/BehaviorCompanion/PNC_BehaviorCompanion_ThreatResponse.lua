-- Companion combat engagement, avoidance, and threat-scan throttling.

local Internal = PNC.BehaviorCompanion.Internal
local Const = PNC.Const
local Stealth = PNC.Stealth
local Common = PNC.BehaviorCommon
local Targeting = PNC.BehaviorTargeting
local BehaviorCombat = PNC.BehaviorCombat
local Perception = PNC.Perception
local CombatTactics = PNC.CombatTactics
local EncounterIntent = PNC.Semantics
    and PNC.Semantics.CombatEncounterIntent or nil

local function targetWithinConstraint(target, constraint)
    local dx
    local dy
    local radius
    if target and target.immediateSelfDefense == true then return true end
    if type(constraint) ~= "table" then return true end
    if not target or target.x == nil or target.y == nil then return false end
    radius = math.max(0, tonumber(constraint.radius) or 0)
    if target.groupAlert == true then
        radius = math.max(
            radius,
            tonumber(target.alertRadius) or radius
        )
    end
    dx = (tonumber(target.x) or 0) - (tonumber(constraint.x) or 0)
    dy = (tonumber(target.y) or 0) - (tonumber(constraint.y) or 0)
    return (dx * dx) + (dy * dy) <= radius * radius
end

function Internal.EngageResolvedTarget(record, zombie, target, constraint)
    if not target then return false end
    if not targetWithinConstraint(target, constraint) then
        Common.ClearCombatTarget(record, "target_outside_order_leash", zombie)
        return false
    end
    if not Common.SetCombatTarget(record, target, "companion_threat") then
        return false
    end
    if Stealth and Stealth.SuspendForCombat then
        Stealth.SuspendForCombat(record, "combat_target")
    else
        record.runtime.stealthActive = false
    end
    return BehaviorCombat.TickEngage(record, zombie, target) ~= false
end

function Internal.ResolveThreatTarget(record, constraint, options)
    local target
    if options and options.areaDefense == true
        and Targeting.ResolveRoamingEngageTarget
    then
        target = Targeting.ResolveRoamingEngageTarget(
            record,
            constraint and constraint.radius
        )
    elseif Targeting.ResolveCompanionProtectionTarget then
        target = Targeting.ResolveCompanionProtectionTarget(
            record,
            options and options.ownerEngaged == true
        )
    else
        target = Targeting.ResolveCompanionEngageTarget(record)
    end
    if not target or not targetWithinConstraint(target, constraint) then
        return nil
    end
    return target
end

local function tryEngageTarget(record, zombie, constraint, options)
    if tostring(record.attackType or Const.ATTACK_TYPE_AUTO or "auto")
        == tostring(Const.ATTACK_TYPE_NONE or "none")
    then
        return false
    end
    local target = Internal.ResolveThreatTarget(record, constraint, options)
    return Internal.EngageResolvedTarget(record, zombie, target, constraint)
end

local function tryAvoidThreat(record, zombie, options, forced)
    local threat
    local moved
    local reason
    if forced ~= true
        and tostring(record.attackType or Const.ATTACK_TYPE_AUTO or "auto")
            ~= tostring(Const.ATTACK_TYPE_NONE or "none")
    then
        return false
    end
    Common.ClearCombatTarget(
        record,
        forced == true and "encounter_avoid" or "attack_disabled",
        zombie
    )
    threat = Perception and Perception.ResolveCompanionProtectionTarget
        and Perception.ResolveCompanionProtectionTarget(
            record,
            options and options.ownerEngaged == true
        ) or nil
    if not threat or not CombatTactics or not CombatTactics.AvoidThreat then
        return false
    end
    moved, reason = CombatTactics.AvoidThreat(record, zombie, threat)
    if moved then
        record.activeBehavior = "AvoidThreat:no_attack"
        Common.SetCombatDebug(
            record,
            nil,
            reason or "companion_avoiding_threat",
            "none",
            "holstered"
        )
        return true
    end
    return false
end

local function isNoAttackMode(record)
    return tostring(record and record.attackType or Const.ATTACK_TYPE_AUTO or "auto")
        == tostring(Const.ATTACK_TYPE_NONE or "none")
end

local function targetDistSq(record, target)
    if target and tonumber(target.distSq) ~= nil then
        return tonumber(target.distSq)
    end
    if not record or not target or target.x == nil or target.y == nil then
        return math.huge
    end
    local dx = (tonumber(target.x) or 0) - (tonumber(record.x) or 0)
    local dy = (tonumber(target.y) or 0) - (tonumber(record.y) or 0)
    return (dx * dx) + (dy * dy)
end

function Internal.TryPushNearbyThreat(record, zombie, now)
    local timestamp = now or (PNC.Core and PNC.Core.Now and PNC.Core.Now()) or 0
    local shoveRange = tonumber(Const.COMBAT_SHOVE_RANGE) or 1.35
    local shoveRangeSq = shoveRange * shoveRange
    local target = Perception and Perception.ResolveRecentAttacker
        and Perception.ResolveRecentAttacker(record, timestamp) or nil
    if target and target.kind ~= "zombie" then
        target = nil
    end
    if not target and Perception and Perception.FindImmediateZombieThreat then
        target = Perception.FindImmediateZombieThreat(record)
    end
    if not target or target.kind ~= "zombie" then
        return false
    end
    if targetDistSq(record, target) > shoveRangeSq then
        return false
    end
    if not PNC.Combat or type(PNC.Combat.TryShove) ~= "function" then
        return false
    end
    local shoved = PNC.Combat.TryShove(
        record,
        zombie,
        target,
        "follow_no_attack_shove"
    )
    if shoved == true then
        record.activeBehavior = "FollowOwner:push_threat"
        Common.SetCombatDebug(
            record,
            target,
            "follow_no_attack_shove",
            "none",
            "shove"
        )
        return true
    end
    return false
end

function Internal.TryRespondToThreat(record, zombie, constraint, options)
    local encounterIntent
    if EncounterIntent
        and type(EncounterIntent.ObserveOwnerEngaged) == "function"
    then
        encounterIntent = EncounterIntent.ObserveOwnerEngaged(
            record,
            options and options.ownerEngaged == true,
            PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
        )
    elseif EncounterIntent
        and type(EncounterIntent.IntentFor) == "function"
    then
        encounterIntent = EncounterIntent.IntentFor(record)
    end
    if encounterIntent == "avoid" then
        return tryAvoidThreat(record, zombie, options, true)
    end
    if encounterIntent == "hold" or encounterIntent == "undecided" then
        Common.ClearCombatTarget(record, "encounter_" .. encounterIntent, zombie)
        return false
    end
    if isNoAttackMode(record) then
        Common.ClearCombatTarget(record, "attack_disabled", zombie)
        return Internal.TryPushNearbyThreat(record, zombie)
    end
    return tryEngageTarget(record, zombie, constraint, options)
end

function Internal.TryRespondToImmediateThreat(record, zombie)
    local now = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
    if isNoAttackMode(record) then
        Common.ClearCombatTarget(record, "attack_disabled", zombie)
        return Internal.TryPushNearbyThreat(record, zombie, now)
    end
    local target = Perception and Perception.ResolveRecentAttacker
        and Perception.ResolveRecentAttacker(record, now) or nil
    if not target and Perception and Perception.FindImmediateZombieThreat then
        target = Perception.FindImmediateZombieThreat(record)
    end
    if not target then return false end
    target.immediateSelfDefense = true
    return Internal.EngageResolvedTarget(record, zombie, target, nil)
end

function Internal.ShouldScanFollowThreat(record, now, active)
    local runtime = record.runtime or {}
    local state
    local interval = active
        and (tonumber(Const.FOLLOW_THREAT_ACTIVE_SCAN_MS) or 150)
        or (tonumber(Const.FOLLOW_THREAT_IDLE_SCAN_MS) or 500)
    record.runtime = runtime
    state = Internal.GetFollowState(record)
    if runtime.target ~= nil then return true end
    if now < (tonumber(state.nextThreatScanAt) or 0) then
        return false
    end
    state.nextThreatScanAt = now + interval
    return true
end
