-- Abstract follow-owner movement advance provider.

PNC = PNC or {}
PNC.BehaviorCompanion = PNC.BehaviorCompanion or {}
PNC.BehaviorCompanion.Internal = PNC.BehaviorCompanion.Internal or {}

local Companion = PNC.BehaviorCompanion
local Internal = Companion.Internal
local H = Internal.AbstractFollowOwnerMovementHandoff
if type(H) ~= "table" then
    return Companion
end

local Core = H.Core
local Const = H.Const
local Common = H.Common
local Audit = H.Audit
local Speed = H.Speed

function H.Advance(
    record,
    runtime,
    owner,
    targetX,
    targetY,
    targetZ,
    stopDistance,
    reason,
    ownerResolved,
    now,
    beforeX,
    beforeY,
    beforeZ,
    auditEnabled
)
    local distanceBefore = Core.Distance(
        beforeX,
        beforeY,
        targetX,
        targetY
    )
    local movementSpeed
    local catchupApplied
    local arrived = false
    local moved = false
    if Speed and Speed.Resolve then
        movementSpeed, catchupApplied = Speed.Resolve(
            owner,
            runtime,
            distanceBefore
        )
    else
        movementSpeed = tonumber(Const.ABSTRACT_TRAVEL_SPEED)
            or ((tonumber(Const.ABSTRACT_TRAVEL_STEP) or 5) / 3)
        catchupApplied = false
    end
    if distanceBefore <= stopDistance and beforeZ == targetZ then
        arrived = true
    else
        local accepted, moveReason = Common.MoveRecord(
            record,
            nil,
            targetX,
            targetY,
            targetZ,
            "walk",
            stopDistance,
            reason,
            nil,
            owner and movementSpeed or nil
        )
        -- A refused request (a stationary facility lease halts movement with
        -- sleep_hold/seated_hold) must not be reported as movement. Report the
        -- real displacement so a frozen follower is visible instead of silent.
        moved = accepted ~= false
            and (math.abs((tonumber(record.x) or beforeX) - beforeX) > 0.0001
                or math.abs((tonumber(record.y) or beforeY) - beforeY)
                    > 0.0001)
        if not moved and auditEnabled
            and Audit and Audit.LogHeld
        then
            Audit.LogHeld(record, runtime, moveReason, targetX, targetY)
        end
    end
    if auditEnabled and Audit and Audit.LogTick then
        Audit.LogTick(
            record,
            runtime,
            ownerResolved,
            now,
            beforeX,
            beforeY,
            beforeZ,
            targetX,
            targetY,
            targetZ,
            moved,
            arrived,
            movementSpeed,
            catchupApplied
        )
    end
    return true
end

return Companion
