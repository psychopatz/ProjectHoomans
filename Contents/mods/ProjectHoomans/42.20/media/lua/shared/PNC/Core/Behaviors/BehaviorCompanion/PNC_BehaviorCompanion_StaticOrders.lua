-- Guard-anchor and patrol-route order execution.

local Internal = PNC.BehaviorCompanion.Internal
local Core = PNC.Core
local Const = PNC.Const
local Common = PNC.BehaviorCommon

function Internal.TickGuardAnchor(record, zombie)
    local order = record.orderSpec or {}
    if Internal.TryRespondToThreat(record, zombie) then
        return true
    end
    Common.ClearCombatTarget(record, "guarding_anchor")
    Common.MoveRecord(
        record,
        zombie,
        tonumber(order.x) or record.anchorX,
        tonumber(order.y) or record.anchorY,
        tonumber(order.z) or record.anchorZ,
        "walk",
        Const.GUARD_RADIUS,
        "guard_anchor"
    )
    return true
end

function Internal.TickPatrolRoute(record, zombie)
    local order = record.orderSpec or {}
    local patrolPoints
    local point
    if Internal.TryRespondToThreat(record, zombie) then
        return true
    end
    patrolPoints = order.points or record.patrolPoints or {}
    if #patrolPoints <= 0 then
        Common.ClearCombatTarget(record, "patrol_missing_points")
        Common.MoveRecord(
            record,
            zombie,
            record.anchorX,
            record.anchorY,
            record.anchorZ,
            "walk",
            0.8,
            "patrol_missing_points"
        )
        return true
    end
    record.patrolIndex = record.patrolIndex or 1
    point = patrolPoints[record.patrolIndex]
    if point
        and Core.Distance(record.x, record.y, point.x, point.y)
            <= Const.PATROL_REACHED_DISTANCE
    then
        record.patrolIndex = record.patrolIndex + 1
        if record.patrolIndex > #patrolPoints then
            record.patrolIndex = 1
        end
        if PNC.Registry and PNC.Registry.MarkDirty then
            PNC.Registry.MarkDirty(record, "patrol")
        end
        point = patrolPoints[record.patrolIndex]
    end
    if point then
        Common.ClearCombatTarget(record, "patrolling")
        Common.MoveRecord(
            record,
            zombie,
            point.x,
            point.y,
            point.z,
            "walk",
            Const.PATROL_REACHED_DISTANCE,
            "patrol_route"
        )
    end
    return true
end
