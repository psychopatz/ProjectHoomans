-- Friendly-fire lanes, aim confidence, and reload interruption.

PNC = PNC or {}
PNC.CombatTactics = PNC.CombatTactics or {}

local Tactics = PNC.CombatTactics
Tactics.Internal = Tactics.Internal or {}

local Internal = Tactics.Internal
local Core = PNC.Core
local Const = PNC.Const
local Skills = PNC.Skills
local Spatial = PNC.SpatialIndex

function Tactics.IsFriendlyFireSafe(record, target)
    local now
    local targetKey
    local cached
    local distance
    local midpointX
    local midpointY
    local corridor = tonumber(Const.RANGED_FRIENDLY_FIRE_CORRIDOR) or 0.62
    local candidates
    local other
    local players
    local player
    local i
    local unsafeKind
    local unsafeID
    local unsafeX
    local unsafeY
    local unsafeZ
    if not record or not target or target.x == nil or target.y == nil then
        return false, "invalid_fire_lane"
    end
    record.runtime = record.runtime or {}
    now = Core.Now()
    targetKey = tostring(target.kind or "") .. ":"
        .. tostring(target.id or target.zombieId or target.onlineID or "")
    cached = record.runtime.combatFireLane
    if cached
        and cached.targetKey == targetKey
        and now < (tonumber(cached.expiresAt) or 0)
        and Core.DistanceSq(cached.shooterX, cached.shooterY, record.x, record.y)
            <= 0.04
        and Core.DistanceSq(cached.targetX, cached.targetY, target.x, target.y)
            <= 0.04
    then
        return cached.safe == true,
            cached.safe == true and "fire_lane_clear" or "friendly_fire_risk"
    end
    distance = math.sqrt(Core.DistanceSq(record.x, record.y, target.x, target.y))
    midpointX = (record.x + target.x) * 0.5
    midpointY = (record.y + target.y) * 0.5

    candidates = Spatial and Spatial.QueryNPCs
        and Spatial.QueryNPCs(midpointX, midpointY, distance * 0.5 + corridor)
        or {}
    for i = 1, #candidates do
        other = candidates[i]
        if Internal.IsProtectedNPC(record, other, target)
            and math.abs((tonumber(other.z) or record.z) - record.z) < 1
            and Internal.PointNearSegment(
                tonumber(other.x) or 0,
                tonumber(other.y) or 0,
                record.x,
                record.y,
                target.x,
                target.y,
                corridor
            )
        then
            unsafeKind = "npc"
            unsafeID = other.id
            unsafeX = other.x
            unsafeY = other.y
            unsafeZ = other.z
            break
        end
    end

    if not unsafeKind then
        players = Spatial and Spatial.QueryPlayers
            and Spatial.QueryPlayers(
                midpointX,
                midpointY,
                distance * 0.5 + corridor
            ) or {}
        for i = 1, #players do
            player = players[i]
            if player
                and player ~= target.player
                and not (
                    target.kind == "player"
                    and target.onlineID ~= nil
                    and player.getOnlineID
                    and tonumber(player:getOnlineID()) == tonumber(target.onlineID)
                )
                and math.abs(player:getZ() - record.z) < 1
                and Internal.PointNearSegment(
                    player:getX(),
                    player:getY(),
                    record.x,
                    record.y,
                    target.x,
                    target.y,
                    corridor
                )
            then
                unsafeKind = "player"
                unsafeID = player.getOnlineID and player:getOnlineID() or nil
                unsafeX = player:getX()
                unsafeY = player:getY()
                unsafeZ = player:getZ()
                break
            end
        end
    end

    record.runtime.combatFireLane = {
        targetKey = targetKey,
        safe = unsafeKind == nil,
        blockerKind = unsafeKind,
        blockerID = unsafeID,
        blockerX = unsafeX,
        blockerY = unsafeY,
        blockerZ = unsafeZ,
        shooterX = record.x,
        shooterY = record.y,
        targetX = target.x,
        targetY = target.y,
        checkedAt = now,
        expiresAt = now + (tonumber(Const.RANGED_FIRE_LANE_CACHE_MS) or 120),
    }
    if unsafeKind then
        return false, "friendly_fire_risk"
    end
    return true, "fire_lane_clear"
end

function Tactics.CanTakeRangedShot(record, target)
    local now
    local state
    local targetKey
    local aiming
    local dist
    local report
    local settleMs
    local moveTolerance
    local progress
    local confidence
    local safe
    local reason
    if not record or not target then return false, "no_target" end
    safe, reason = Tactics.IsFriendlyFireSafe(record, target)
    if not safe then return false, reason end

    record.runtime = record.runtime or {}
    now = Core.Now()
    state = record.runtime.combatAim or {}
    record.runtime.combatAim = state
    targetKey = tostring(target.kind or "") .. ":"
        .. tostring(target.id or target.zombieId or target.onlineID or "")
    moveTolerance = tonumber(Const.RANGED_AIM_MOVE_TOLERANCE) or 0.35
    if state.targetKey ~= targetKey
        or state.shooterX == nil
        or Core.DistanceSq(state.shooterX, state.shooterY, record.x, record.y)
            > moveTolerance * moveTolerance
        or state.targetX == nil
        or Core.DistanceSq(state.targetX, state.targetY, target.x, target.y)
            > (moveTolerance * 1.5) ^ 2
    then
        state.targetKey = targetKey
        state.startedAt = now
        state.shooterX = record.x
        state.shooterY = record.y
        state.targetX = target.x
        state.targetY = target.y
    end

    aiming = Skills and Skills.GetLevel and Skills.GetLevel(record, "Aiming") or 0
    dist = math.sqrt(tonumber(target.distSq)
        or Core.DistanceSq(record.x, record.y, target.x, target.y))
    report = Internal.AssessThreat(record, target)
    settleMs = (tonumber(Const.RANGED_AIM_BASE_MS) or 460)
        - math.min(aiming, 10)
            * (tonumber(Const.RANGED_AIM_SKILL_REDUCTION_MS) or 32)
        + dist * (tonumber(Const.RANGED_AIM_DISTANCE_PENALTY_MS) or 22)
        + math.min(report.visiblePressureCount, 4)
            * (tonumber(Const.RANGED_AIM_PRESSURE_PENALTY_MS) or 65)
    settleMs = math.max(
        tonumber(Const.RANGED_AIM_MIN_MS) or 140,
        math.min(900, settleMs)
    )
    state.readyAt = (tonumber(state.startedAt) or now) + settleMs
    progress = math.max(0, math.min(
        1,
        (now - (tonumber(state.startedAt) or now)) / math.max(1, settleMs)
    ))
    confidence = 0.42
        + math.min(aiming, 10) * 0.045
        + progress * 0.42
        - math.min(0.18, dist / math.max(1, Const.RANGED_RANGE) * 0.18)
        - math.min(report.visiblePressureCount, 4) * 0.035
    state.confidence = math.max(0, math.min(1, confidence))
    state.settleMs = settleMs
    if now < state.readyAt or state.confidence < 0.54 then
        return false, "aiming"
    end
    return true, "aim_confident"
end

function Tactics.MarkRangedShot(record)
    local state = record and record.runtime and record.runtime.combatAim or nil
    if not state then return end
    state.startedAt = Core.Now()
    state.shooterX = record.x
    state.shooterY = record.y
    state.confidence = 0
end

function Tactics.ShouldInterruptReload(record, target)
    local action = record and record.runtime and record.runtime.attackAction or nil
    local report
    local dist
    if not action or action.attackType ~= "reload" then
        return false, nil
    end
    report = Internal.AssessThreat(record, target)
    dist = target and math.sqrt(tonumber(target.distSq)
        or Core.DistanceSq(record.x, record.y, target.x, target.y))
        or math.huge
    if dist <= (tonumber(Const.RANGED_RELOAD_BREAK_DISTANCE) or 2.35)
        or report.surroundedCount >= 1
        or report.visiblePressureCount
            >= (tonumber(Const.RANGED_RELOAD_BREAK_PRESSURE_COUNT) or 2)
    then
        return true, "reload_interrupted_by_pressure"
    end
    return false, nil
end

return Tactics
