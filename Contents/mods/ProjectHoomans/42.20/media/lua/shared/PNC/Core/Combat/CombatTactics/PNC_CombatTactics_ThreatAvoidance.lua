-- General threat avoidance and fallback reposition orchestration.

PNC = PNC or {}
PNC.CombatTactics = PNC.CombatTactics or {}

local Tactics = PNC.CombatTactics
Tactics.Internal = Tactics.Internal or {}

local Internal = Tactics.Internal
local Core = PNC.Core
local Const = PNC.Const
local Skills = PNC.Skills
local Stamina = PNC.Stamina

function Tactics.AvoidThreat(record, zombie, target, options)
    local state
    local now
    local staminaRatio
    local distance
    local mode
    local continued
    local continueReason
    local radius
    if not record or not target then return false, "avoid_target_missing" end
    options = type(options) == "table" and options or {}
    now = Core.Now()
    state = Internal.EnsureRetreatState(record)
    continued, continueReason =
        Internal.ContinueLockedRetreat(record, zombie, target, state, now)
    if continued then
        return true, state.reason or "companion_avoiding_threat"
    end
    if continueReason == "retreat_stalled"
        or now < (tonumber(state and state.retryAt) or 0)
    then
        return false, "retreat_stalled"
    end
    staminaRatio = Stamina and Stamina.GetRatio
        and Stamina.GetRatio(record) or 1
    distance = math.sqrt(tonumber(target.distSq) or Core.DistanceSq(
        record.x, record.y, target.x, target.y
    ))
    radius = tonumber(options.radius)
        or tonumber(Const.COMPANION_AVOID_THREAT_RADIUS)
        or 10
    if distance > radius then
        Internal.ClearActiveRetreat(record, state)
        state.retryAt = 0
        return false, "threat_outside_avoid_radius"
    end
    mode = staminaRatio > (tonumber(Const.COMBAT_RETREAT_STAMINA_RATIO) or 0.1)
        and "run" or "walk"
    return Internal.StartRetreat(
        record, zombie, target,
        tonumber(options.distance)
            or tonumber(Const.COMPANION_AVOID_THREAT_DISTANCE) or 5,
        tostring(options.mode or mode),
        tonumber(options.stopDistance) or 0.8,
        tonumber(options.lockMs)
            or tonumber(Const.COMPANION_AVOID_THREAT_LOCK_MS) or 750,
        tostring(options.reason or "companion_avoiding_threat"),
        options.recoveryMode
            or (
                staminaRatio
                    <= (tonumber(Const.COMBAT_RETREAT_STAMINA_RATIO) or 0.1)
                and "retreat" or nil
            )
    )
end

function Tactics.TryReposition(record, zombie, target, effectiveMode, reason, equipmentInfo)
    local aiming
    local dist
    local report
    local now
    local state
    if not record or not zombie or not target then return false, nil end
    if reason == "friendly_fire_risk" then
        return Tactics.RepositionForClearShot(record, zombie, target)
    end
    now = Core.Now()
    state = Internal.EnsureRetreatState(record)
    dist = math.sqrt(tonumber(target.distSq or 0) or 0)
    report = Internal.AssessThreat(record, target)
    if Internal.ContinueLockedRetreat(record, zombie, target, state, now) then
        return true, state.reason or "combat_retreat"
    end
    if Internal.TryNearMissRetreat(record, zombie, target, state, now, report) then
        return true, "near_miss_kite"
    end
    if Tactics.NeedsRecoveryRetreat(record)
        and report.pressureCount
            >= (tonumber(Const.COMBAT_TACTICAL_RETREAT_MIN_PRESSURE) or 2)
    then
        return Internal.StartRetreat(
            record, zombie, target,
            3.8 + math.min(report.pressureCount, 4) * 0.35,
            "walk", 0.8, Const.COMBAT_KITE_RETREAT_LOCK_MS,
            "recovering_stamina", "retreat"
        )
    end
    Internal.ClearActiveRetreat(record, state)
    if effectiveMode == "ranged" or effectiveMode == "mixed" then
        aiming = Skills and Skills.GetLevel
            and Skills.GetLevel(record, "Aiming") or 0
        if target.kind == "zombie"
            and dist < (tonumber(Const.RANGED_MIN_STANDOFF) or 2.2)
        then
            return Internal.StartRetreat(
                record, zombie, target,
                1.4 + math.min(aiming, 6) * 0.12,
                report.pressureCount >= 2 and "run" or "walk",
                0.25, Const.COMBAT_KITE_RETREAT_LOCK_MS,
                "maintaining_range", nil
            )
        end
        return false, nil
    end
    return false, nil
end

return Tactics
