-- Catch-up speed policy for abstract follow-owner movement.

PNC = PNC or {}
PNC.BehaviorCompanion = PNC.BehaviorCompanion or {}
PNC.BehaviorCompanion.Internal = PNC.BehaviorCompanion.Internal or {}

local Companion = PNC.BehaviorCompanion
local H = Companion.Internal.AbstractFollowOwnerMovementSpeed
if type(H) ~= "table" then
    return Companion
end

local Const = H.Const

function H.Resolve(owner, runtime, distanceBefore)
    local movementSpeed = tonumber(Const.ABSTRACT_TRAVEL_SPEED)
        or ((tonumber(Const.ABSTRACT_TRAVEL_STEP) or 5) / 3)
    local catchupApplied = false
    if owner then
        local maxFollowSpeed = tonumber(Const.ABSTRACT_FOLLOW_CATCHUP_SPEED)
            or movementSpeed
        local catchupStartDistance = tonumber(Const.FOLLOW_RUN_DISTANCE) or 10
        local catchupRampDistance = math.max(1, catchupStartDistance * 2)
        if distanceBefore > catchupStartDistance
            and maxFollowSpeed > movementSpeed
        then
            local catchupBlend = math.min(
                1,
                (distanceBefore - catchupStartDistance)
                    / catchupRampDistance
            )
            movementSpeed = movementSpeed
                + ((maxFollowSpeed - movementSpeed) * catchupBlend)
            catchupApplied = movementSpeed > (
                tonumber(Const.ABSTRACT_TRAVEL_SPEED) or 0
            )
        end
        -- A teleport can leave the follower hundreds of tiles behind. The flat
        -- catch-up cap would take minutes to close that, so past a long-range
        -- separation close a bounded fraction of the remaining gap per tick.
        -- The speed is derived from the tick's real elapsed time and stays
        -- under a hard ceiling, so the follower converges without overshooting.
        local longRangeDistance = tonumber(
            Const.ABSTRACT_FOLLOW_LONG_RANGE_DISTANCE) or 64
        if distanceBefore > longRangeDistance then
            local elapsedSeconds = math.max(
                0.001,
                (tonumber(runtime.abstractStepElapsedMs)
                    or tonumber(Const.TICK_ABSTRACT_MS) or 3000) / 1000
            )
            local closeFraction = tonumber(
                Const.ABSTRACT_FOLLOW_LONG_RANGE_CLOSE) or 0.35
            local longRangeCap = tonumber(
                Const.ABSTRACT_FOLLOW_LONG_RANGE_SPEED) or 80
            movementSpeed = math.max(
                movementSpeed,
                math.min(
                    (distanceBefore * closeFraction) / elapsedSeconds,
                    longRangeCap
                )
            )
            catchupApplied = true
        end
    end
    return movementSpeed, catchupApplied
end

return Companion
