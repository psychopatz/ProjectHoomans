-- Formation and movement plan for live FollowOwner handoff.

PNC = PNC or {}
PNC.BehaviorCompanion = PNC.BehaviorCompanion or {}
PNC.BehaviorCompanion.Internal = PNC.BehaviorCompanion.Internal or {}

local Companion = PNC.BehaviorCompanion
local Internal = Companion.Internal
local H = Internal.FollowOwnerMovementPlan
if type(H) ~= "table" then
    return Companion
end

local Core = H.Core
local Const = H.Const
local Stealth = H.Stealth
local Common = H.Common

function H.Run(record, zombie, owner, ownerDist, followState, hazard, now)
    local slotTarget = Internal.ResolveSampledFollowSlot(
        record,
        owner,
        followState.ownerMoving == true,
        now
    )
    slotTarget = Internal.EnforceOwnerPersonalSpace(
        record,
        owner,
        slotTarget,
        ownerDist
    )
    local slotDist = slotTarget
        and Core.Distance(
            record.x,
            record.y,
            slotTarget.x,
            slotTarget.y
        )
        or ownerDist
    local moveTarget = Internal.ResolveHordeAwareFollowTarget(
        record,
        slotTarget,
        slotDist,
        hazard,
        now
    ) or slotTarget
    if moveTarget == slotTarget
        and slotDist <= (
            slotTarget and slotTarget.stopDistance or Const.FOLLOW_DISTANCE
        )
        and math.abs(
            (slotTarget and slotTarget.z or owner:getZ()) - record.z
        ) < 1
    then
        return Internal.HoldAndFaceOwner(
            record,
            zombie,
            owner,
            "formation_hold",
            record.runtime.stealthActive
                and "holding_follow_stealth"
                or "holding_follow_position",
            now
        )
    end
    Internal.SetFollowMode(record, "moving")
    record.activeBehavior = "FollowOwner:moving"
    local moveMode = Stealth
        and Stealth.ResolveFollowMoveMode
        and Stealth.ResolveFollowMoveMode(
            record,
            owner,
            ownerDist,
            slotDist,
            hazard.count
        )
        or (
            ownerDist >= (
                tonumber(Const.FOLLOW_RUN_DISTANCE) or 10
            )
            and "run"
            or "walk"
        )
    if not Internal.ShouldIssueFollowMove(
        record,
        moveTarget,
        moveMode,
        now
    ) then
        return true
    end
    Common.ClearCombatTarget(
        record,
        moveTarget and moveTarget.avoidance
            and "following_owner_horde_avoidance"
            or (
                moveMode == "sneak"
                and "following_owner_sneak"
                or ("following_owner_" .. tostring(moveMode))
            )
    )
    Common.MoveRecord(
        record,
        zombie,
        moveTarget and moveTarget.x or owner:getX(),
        moveTarget and moveTarget.y or owner:getY(),
        moveTarget and moveTarget.z or owner:getZ(),
        moveMode,
        moveTarget and moveTarget.stopDistance or Const.FOLLOW_DISTANCE,
        moveTarget and moveTarget.avoidance
            and "follow_owner_horde_avoidance"
            or (
                moveMode == "sneak"
                and "follow_owner_sneak"
                or ("follow_owner_" .. tostring(moveMode))
            )
    )
    return true
end

return Companion
