-- Clear-shot strafing, ranged spacing, and general threat avoidance.

PNC = PNC or {}
PNC.CombatTactics = PNC.CombatTactics or {}

local Tactics = PNC.CombatTactics
Tactics.Internal = Tactics.Internal or {}

local Internal = Tactics.Internal
local Core = PNC.Core
local Const = PNC.Const
local Skills = PNC.Skills
local Stamina = PNC.Stamina
local TraversalQuery = PNC.TraversalQuery

function Tactics.RepositionForClearShot(record, zombie, target)
    local state
    local now
    local dx
    local dy
    local length
    local direction
    local distance
    local candidateX
    local candidateY
    local alternateX
    local alternateY
    local z
    if not record or not zombie or not target then return false, nil end
    now = Core.Now()
    state = Internal.EnsureRetreatState(record)
    if Internal.ContinueLockedRetreat(record, zombie, target, state, now) then
        return true, state.reason or "clearing_fire_lane"
    end
    dx = target.x - record.x
    dy = target.y - record.y
    length = math.sqrt((dx * dx) + (dy * dy))
    if length <= 0.001 then return false, "invalid_fire_lane" end
    direction = Internal.StableDirection(record.id) < math.pi and 1 or -1
    distance = tonumber(Const.RANGED_FIRE_LANE_STRAFE_DISTANCE) or 1.6
    candidateX = record.x + (-dy / length) * distance * direction
    candidateY = record.y + (dx / length) * distance * direction
    alternateX = record.x - (-dy / length) * distance * direction
    alternateY = record.y - (dx / length) * distance * direction
    z = target.z or record.z
    if TraversalQuery and TraversalQuery.CanOccupy
        and not TraversalQuery.CanOccupy(candidateX, candidateY, z)
    then
        candidateX = alternateX
        candidateY = alternateY
    end
    state.phase = "strafe"
    state.reason = "clearing_fire_lane"
    state.lockUntil = now
        + (tonumber(Const.RANGED_FIRE_LANE_LOCK_MS) or 500)
    state.goalX = candidateX
    state.goalY = candidateY
    state.goalZ = z
    state.goalMode = "walk"
    state.goalStopDistance = 0.25
    Internal.SetRetreatState(record, true, nil)
    Internal.RequestMove(
        record,
        zombie,
        candidateX,
        candidateY,
        z,
        "walk",
        0.25,
        "clearing_fire_lane"
    )
    return true, "clearing_fire_lane"
end

function Tactics.MaintainRangedSpacing(record, zombie, target)
    local state
    local now
    local dist
    local preferredMin
    local report
    local pressure
    local sourceX
    local sourceY
    local centroidCount
    local retreatDistance
    local mode
    local reason
    if not record or not zombie or not target then return false, nil end
    now = Core.Now()
    state = Internal.EnsureRetreatState(record)
    if Internal.ContinueLockedRetreat(record, zombie, target, state, now) then
        return true, state.reason or "ranged_disengage"
    end

    dist = math.sqrt(tonumber(target.distSq or 0) or 0)
    preferredMin = tonumber(Const.RANGED_PREFERRED_MIN_DISTANCE) or 5.0
    report = Internal.AssessThreat(record, target)
    pressure = target.kind == "zombie" and (
        report.pressureCount >= (tonumber(Const.RANGED_PRESSURE_COUNT) or 2)
        or report.hordeCount >= Const.COMBAT_HORDE_COUNT
        or (
            dist < preferredMin
            and report.targetCrowdCount >= Const.COMBAT_TARGET_CROWD_COUNT
        )
    )

    if dist >= preferredMin and not pressure then
        Internal.ClearActiveRetreat(record, state)
        return false, nil
    end

    if pressure then
        sourceX, sourceY, centroidCount = Internal.BuildZombieThreatCentroid(
            record,
            Const.COMBAT_HORDE_RADIUS
        )
    end
    retreatDistance = (tonumber(Const.RANGED_RETREAT_STEP) or 3.2)
        + math.max(0, preferredMin - dist)
        + math.min(tonumber(centroidCount) or 0, 5) * 0.2
    mode = pressure
        and report.staminaRatio > Const.COMBAT_RETREAT_STAMINA_RATIO
        and "run"
        or "walk"
    reason = pressure and "ranged_avoiding_horde" or "ranged_disengage"
    return Internal.StartRetreat(
        record,
        zombie,
        target,
        math.min(5.5, retreatDistance),
        mode,
        0.45,
        math.max(Const.COMBAT_KITE_RETREAT_LOCK_MS, 650),
        reason,
        report.staminaRatio <= Const.COMBAT_RETREAT_STAMINA_RATIO
            and "retreat"
            or nil,
        sourceX,
        sourceY,
        record.z
    )
end

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
        record.x,
        record.y,
        target.x,
        target.y
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
        record,
        zombie,
        target,
        tonumber(options.distance)
            or tonumber(Const.COMPANION_AVOID_THREAT_DISTANCE)
            or 5,
        tostring(options.mode or mode),
        tonumber(options.stopDistance) or 0.8,
        tonumber(options.lockMs)
            or tonumber(Const.COMPANION_AVOID_THREAT_LOCK_MS)
            or 750,
        tostring(options.reason or "companion_avoiding_threat"),
        options.recoveryMode
            or (
                staminaRatio
                    <= (tonumber(Const.COMBAT_RETREAT_STAMINA_RATIO) or 0.1)
                and "retreat"
                or nil
            )
    )
end

function Tactics.TryReposition(record, zombie, target, effectiveMode, reason, equipmentInfo)
    local aiming
    local dist
    local report
    local now
    local state

    if not record or not zombie or not target then
        return false, nil
    end
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
        and report.pressureCount >= (
            tonumber(Const.COMBAT_TACTICAL_RETREAT_MIN_PRESSURE) or 2
        )
    then
        return Internal.StartRetreat(
            record,
            zombie,
            target,
            3.8 + math.min(report.pressureCount, 4) * 0.35,
            "walk",
            0.8,
            Const.COMBAT_KITE_RETREAT_LOCK_MS,
            "recovering_stamina",
            "retreat"
        )
    end

    Internal.ClearActiveRetreat(record, state)

    if effectiveMode == "ranged" or effectiveMode == "mixed" then
        aiming = Skills and Skills.GetLevel and Skills.GetLevel(record, "Aiming") or 0
        if target.kind == "zombie" and dist < (tonumber(Const.RANGED_MIN_STANDOFF) or 2.2) then
            return Internal.StartRetreat(
                record,
                zombie,
                target,
                1.4 + math.min(aiming, 6) * 0.12,
                report.pressureCount >= 2 and "run" or "walk",
                0.25,
                Const.COMBAT_KITE_RETREAT_LOCK_MS,
                "maintaining_range",
                nil
            )
        end
        return false, nil
    end

    return false, nil
end

return Tactics
