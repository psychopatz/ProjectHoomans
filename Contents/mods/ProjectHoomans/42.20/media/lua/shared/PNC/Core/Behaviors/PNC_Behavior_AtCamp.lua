-- Stable idle behavior for colonists assigned to remain at a temporary camp.
-- Camp is a durable anchor order; survival activities temporarily replace it
-- with facility_activity and restore it when the activity ends.

PNC = PNC or {}
PNC.BehaviorAtCamp = PNC.BehaviorAtCamp or {}

local AtCamp = PNC.BehaviorAtCamp
local Common = PNC.BehaviorCommon
local Animation = PNC.Animation
local Const = PNC.Const
local Core = PNC.Core

local function isWithinCamp(record, zombie, anchorX, anchorY, anchorZ, radius)
    local distance = Core.Distance(record.x, record.y, anchorX, anchorY)
    local query = PNC.TraversalQuery
    local anchorSquare
    local bodySquare
    local anchorIndoor
    local bodyIndoor
    if distance > radius then return false end
    if not zombie or not query
        or not query.GetSquare
        or not query.GetInteriorState
    then
        return true
    end

    anchorSquare = query.GetSquare(anchorX, anchorY, anchorZ)
    anchorIndoor = query.GetInteriorState(anchorSquare)
    if anchorIndoor ~= true then
        return true
    end

    bodySquare = zombie.getCurrentSquare
        and zombie:getCurrentSquare() or nil
    bodyIndoor = query.GetInteriorState(bodySquare)
    -- An indoor camp is not complete while the body is still outside, even
    -- when the Euclidean camp radius overlaps the exterior side of a wall.
    return bodyIndoor ~= false
end

local function normalize(record, spec)
    spec = type(spec) == "table" and spec or {}
    return {
        kind = Const.ORDER_CAMP or "camp",
        x = tonumber(spec.x) or tonumber(record and record.x)
            or tonumber(record and record.anchorX),
        y = tonumber(spec.y) or tonumber(record and record.y)
            or tonumber(record and record.anchorY),
        z = tonumber(spec.z) or tonumber(record and record.z)
            or tonumber(record and record.anchorZ) or 0,
        radius = math.max(0.5, tonumber(spec.radius)
            or tonumber(Const.CAMP_RADIUS) or 3),
        campId = tostring(spec.campId or "camp:" .. tostring(record and record.id or "")),
        resourceRadius = math.max(1, math.min(24, tonumber(spec.resourceRadius)
            or tonumber(Const.CAMP_RESOURCE_RADIUS) or 12)),
    }
end

function AtCamp.Tick(record, zombie)
    local Companion = PNC.BehaviorCompanion
    local order = record.orderSpec or {}
    local anchorX = tonumber(order.x) or record.anchorX or record.x
    local anchorY = tonumber(order.y) or record.anchorY or record.y
    local anchorZ = tonumber(order.z) or record.anchorZ or record.z or 0
    local radius = math.max(0.5, tonumber(order.radius)
        or tonumber(Const.CAMP_RADIUS) or 3)
    local engaged = Companion and Companion.Internal
        and Companion.Internal.TryRespondToThreat
        and Companion.Internal.TryRespondToThreat(
            record,
            zombie,
            {
                x = anchorX,
                y = anchorY,
                z = anchorZ,
                radius = tonumber(Const.CAMP_ENGAGE_RADIUS) or radius,
            },
            { areaDefense = true }
        )
    if engaged then
        record.activeBehavior = "AtCamp:combat"
        return true
    end

    if not isWithinCamp(
        record, zombie, anchorX, anchorY, anchorZ, radius
    ) then
        record.activeBehavior = "AtCamp:returning"
        Common.ClearCombatTarget(record, "returning_to_camp", zombie)
        Common.MoveRecord(
            record,
            zombie,
            anchorX,
            anchorY,
            anchorZ,
            "walk",
            math.max(tonumber(Const.CAMP_STOP_DISTANCE) or 0.45, radius),
            "camp_anchor"
        )
        return true
    end

    record.activeBehavior = "AtCamp"
    if PNC.NavigationRouter and PNC.NavigationRouter.Clear then
        PNC.NavigationRouter.Clear(record)
    end
    Common.ClearCombatTarget(record, "at_camp", zombie)
    Common.HaltMovement(record, zombie, "at_camp")
    if zombie and Animation and Animation.Apply then
        Animation.Apply(zombie, record, "Idle")
    end
    return true
end

if PNC.OrderSystem and PNC.OrderSystem.RegisterNormalizer then
    PNC.OrderSystem.RegisterNormalizer(Const.ORDER_CAMP or "camp", normalize)
end
if PNC.JobSystem and PNC.JobSystem.RegisterOrder then
    PNC.JobSystem.RegisterOrder(
        Const.ORDER_CAMP or "camp",
        Const.JOB_AT_CAMP or "AtCamp"
    )
end
if PNC.BehaviorRegistry and PNC.BehaviorRegistry.Register then
    PNC.BehaviorRegistry.Register(
        Const.JOB_AT_CAMP or "AtCamp",
        AtCamp.Tick
    )
end

return AtCamp
