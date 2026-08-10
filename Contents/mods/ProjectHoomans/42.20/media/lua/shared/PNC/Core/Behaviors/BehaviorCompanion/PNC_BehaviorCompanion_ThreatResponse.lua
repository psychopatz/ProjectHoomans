-- Companion combat engagement, avoidance, and threat-scan throttling.

local Internal = PNC.BehaviorCompanion.Internal
local Const = PNC.Const
local Stealth = PNC.Stealth
local Common = PNC.BehaviorCommon
local Targeting = PNC.BehaviorTargeting
local BehaviorCombat = PNC.BehaviorCombat
local Perception = PNC.Perception
local CombatTactics = PNC.CombatTactics

local function targetWithinConstraint(target, constraint)
    local dx
    local dy
    local radius
    if type(constraint) ~= "table" then return true end
    if not target or target.x == nil or target.y == nil then return false end
    radius = math.max(0, tonumber(constraint.radius) or 0)
    dx = (tonumber(target.x) or 0) - (tonumber(constraint.x) or 0)
    dy = (tonumber(target.y) or 0) - (tonumber(constraint.y) or 0)
    return (dx * dx) + (dy * dy) <= radius * radius
end

local function tryEngageTarget(record, zombie, constraint)
    if tostring(record.attackType or Const.ATTACK_TYPE_AUTO or "auto")
        == tostring(Const.ATTACK_TYPE_NONE or "none")
    then
        return false
    end
    local target = Targeting.ResolveCompanionEngageTarget(record)
    if not target then
        return false
    end
    if not targetWithinConstraint(target, constraint) then
        Common.ClearCombatTarget(record, "target_outside_order_leash", zombie)
        return false
    end
    record.runtime.target = target
    if Stealth and Stealth.SuspendForCombat then
        Stealth.SuspendForCombat(record, "combat_target")
    else
        record.runtime.stealthActive = false
    end
    BehaviorCombat.TickEngage(record, zombie, target)
    return true
end

local function tryAvoidThreat(record, zombie)
    local threat
    local moved
    local reason
    if tostring(record.attackType or Const.ATTACK_TYPE_AUTO or "auto")
        ~= tostring(Const.ATTACK_TYPE_NONE or "none")
    then
        return false
    end
    Common.ClearCombatTarget(record, "attack_disabled", zombie)
    threat = Perception and Perception.ResolveCompanionTarget
        and Perception.ResolveCompanionTarget(record) or nil
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

function Internal.TryRespondToThreat(record, zombie, constraint)
    if tryAvoidThreat(record, zombie) then return true end
    return tryEngageTarget(record, zombie, constraint)
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
