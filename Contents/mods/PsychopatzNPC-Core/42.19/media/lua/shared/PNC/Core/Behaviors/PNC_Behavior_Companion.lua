--[[
    PNC Behavior Companion
    Owns companion job handlers such as follow, guard, and patrol so those
    rules stay isolated from hostile roaming and combat internals.
]]

PNC = PNC or {}
PNC.BehaviorCompanion = PNC.BehaviorCompanion or {}

local Companion = PNC.BehaviorCompanion
local Core = PNC.Core
local Const = PNC.Const
local Stealth = PNC.Stealth
local Animation = PNC.Animation
local Common = PNC.BehaviorCommon
local Targeting = PNC.BehaviorTargeting
local BehaviorCombat = PNC.BehaviorCombat
local Registry = PNC.Registry

local function normalizeDirection(dx, dy)
    local len = math.sqrt((dx * dx) + (dy * dy))
    if len <= 0.0001 then
        return nil, nil
    end
    return dx / len, dy / len
end

local function resolveOwnerForward(owner)
    local forward
    local fx
    local fy
    if not owner or not owner.getForwardDirection then
        return 0, 1
    end
    forward = owner:getForwardDirection()
    fx = forward and tonumber(forward:getX()) or 0
    fy = forward and tonumber(forward:getY()) or 0
    fx, fy = normalizeDirection(fx, fy)
    if fx and fy then
        return fx, fy
    end
    return 0, 1
end

local function isSameFollowGroup(record, other)
    local otherOrder
    local otherOwnerID
    local recordOwnerID
    if not record or not other or other.alive == false then
        return false
    end
    otherOrder = other.orderSpec or {}
    if tostring(otherOrder.kind or "") ~= Const.ORDER_FOLLOW then
        return false
    end
    otherOwnerID = tonumber(other.ownerOnlineID)
    recordOwnerID = tonumber(record.ownerOnlineID)
    if otherOwnerID ~= nil and recordOwnerID ~= nil then
        return otherOwnerID == recordOwnerID
    end
    return tostring(other.ownerUsername or "") == tostring(record.ownerUsername or "")
end

local function sortFollowerRecords(a, b)
    return tostring(a and a.id or "") < tostring(b and b.id or "")
end

local function resolveFollowSlot(record, owner)
    local followers = {}
    local i
    local slotIndex = 0
    local fx
    local fy
    local rightX
    local rightY
    local backX
    local backY
    local pairIndex
    local side
    local lateral
    local trailing
    if not owner then
        return nil
    end
    if Registry and Registry.ForEach then
        Registry.ForEach(function(other)
            if isSameFollowGroup(record, other) then
                followers[#followers + 1] = other
            end
        end)
    end
    table.sort(followers, sortFollowerRecords)
    for i = 1, #followers do
        if followers[i].id == record.id then
            slotIndex = i - 1
            break
        end
    end
    fx, fy = resolveOwnerForward(owner)
    rightX = -fy
    rightY = fx
    backX = -fx
    backY = -fy
    if #followers <= 1 then
        lateral = 0
        trailing = tonumber(Const.FOLLOW_SLOT_DISTANCE) or 1.5
    else
        pairIndex = math.floor(slotIndex / 2)
        side = (slotIndex % 2 == 0) and -1 or 1
        lateral = side * ((tonumber(Const.FOLLOW_SLOT_LATERAL) or 0.95) + (pairIndex * (tonumber(Const.FOLLOW_SLOT_ROW_LATERAL) or 0.2)))
        trailing = (tonumber(Const.FOLLOW_SLOT_DISTANCE) or 1.5) + (pairIndex * (tonumber(Const.FOLLOW_SLOT_ROW_DISTANCE) or 0.75))
    end
    return {
        x = owner:getX() + (backX * trailing) + (rightX * lateral),
        y = owner:getY() + (backY * trailing) + (rightY * lateral),
        z = owner:getZ(),
        stopDistance = tonumber(Const.FOLLOW_SLOT_STOP_DISTANCE) or 0.65,
    }
end

function Companion.Tick(record, zombie, job)
    local owner
    local ownerDist
    local slotTarget
    local slotDist
    local target
    local patrolPoints
    local point
    local moveMode
    local order = record.orderSpec or {}

    if job == "FollowOwner" then
        owner = Common.GetOwner(record)
        if Stealth and Stealth.UpdateFollowState then
            Stealth.UpdateFollowState(record, owner)
        end
        target = Targeting.ResolveCompanionEngageTarget(record)
        if target then
            record.runtime.target = target
            BehaviorCombat.TickEngage(record, zombie, target)
            return true
        end
        if owner then
            record.ownerUsername = owner:getUsername()
            record.ownerOnlineID = owner:getOnlineID()
            slotTarget = resolveFollowSlot(record, owner)
            ownerDist = Core.Distance(record.x, record.y, owner:getX(), owner:getY())
            slotDist = slotTarget and Core.Distance(record.x, record.y, slotTarget.x, slotTarget.y) or ownerDist
            if slotDist <= (slotTarget and slotTarget.stopDistance or Const.FOLLOW_DISTANCE)
                and math.abs((slotTarget and slotTarget.z or owner:getZ()) - record.z) < 1
            then
                Common.ClearCombatTarget(record, record.runtime.stealthActive and "holding_follow_stealth" or "holding_follow_position")
                if zombie then
                    Common.HaltMovement(record, zombie, "follow_hold")
                    Animation.Apply(zombie, record, "Idle")
                end
                return true
            end
            moveMode = Stealth and Stealth.ResolveFollowMoveMode and Stealth.ResolveFollowMoveMode(record, owner, ownerDist)
                or (ownerDist >= Const.FOLLOW_RUN_DISTANCE and "run" or "walk")
            Common.ClearCombatTarget(record, moveMode == "sneak" and "following_owner_sneak" or ("following_owner_" .. tostring(moveMode)))
            Common.MoveRecord(
                record,
                zombie,
                slotTarget and slotTarget.x or owner:getX(),
                slotTarget and slotTarget.y or owner:getY(),
                slotTarget and slotTarget.z or owner:getZ(),
                moveMode,
                slotTarget and slotTarget.stopDistance or Const.FOLLOW_DISTANCE,
                moveMode == "sneak" and "follow_owner_sneak" or ("follow_owner_" .. tostring(moveMode))
            )
            return true
        end
        if Stealth and Stealth.Clear then
            Stealth.Clear(record, "owner_missing")
        end
        Common.ClearCombatTarget(record, "owner_missing_return_anchor")
        Common.MoveRecord(record, zombie, record.anchorX, record.anchorY, record.anchorZ, "walk", 0.8, "owner_missing_return_anchor")
        return true
    end

    if job == "GuardAnchor" then
        target = Targeting.ResolveCompanionEngageTarget(record)
        if target then
            record.runtime.target = target
            BehaviorCombat.TickEngage(record, zombie, target)
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

    if job == "PatrolRoute" then
        target = Targeting.ResolveCompanionEngageTarget(record)
        if target then
            record.runtime.target = target
            BehaviorCombat.TickEngage(record, zombie, target)
            return true
        end
        patrolPoints = order.points or record.patrolPoints or {}
        if #patrolPoints <= 0 then
            Common.ClearCombatTarget(record, "patrol_missing_points")
            Common.MoveRecord(record, zombie, record.anchorX, record.anchorY, record.anchorZ, "walk", 0.8, "patrol_missing_points")
            return true
        end
        record.patrolIndex = record.patrolIndex or 1
        point = patrolPoints[record.patrolIndex]
        if point then
            if Core.Distance(record.x, record.y, point.x, point.y) <= Const.PATROL_REACHED_DISTANCE then
                record.patrolIndex = record.patrolIndex + 1
                if record.patrolIndex > #patrolPoints then
                    record.patrolIndex = 1
                end
                point = patrolPoints[record.patrolIndex]
            end
            if point then
                Common.ClearCombatTarget(record, "patrolling")
                Common.MoveRecord(record, zombie, point.x, point.y, point.z, "walk", Const.PATROL_REACHED_DISTANCE, "patrol_route")
            end
        end
        return true
    end

    return false
end
