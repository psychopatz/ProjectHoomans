-- Native engine-path failure circuit breaker for repeated goals.

PNC = PNC or {}
PNC.PathService = PNC.PathService or {}
PNC.PathService.Internal = PNC.PathService.Internal or {}

local Internal = PNC.PathService.Internal
local Const = PNC.Const or {}

function Internal.clearNativeGoalBlock(lane)
    if not lane then return end
    lane.nativeFailureCount = 0
    lane.nativeFailureGoalX = nil
    lane.nativeFailureGoalY = nil
    lane.nativeFailureGoalZ = nil
    lane.nativeBlockedGoalX = nil
    lane.nativeBlockedGoalY = nil
    lane.nativeBlockedGoalZ = nil
    lane.nativeBlockedUntil = 0
end

local function nativeGoalDistance(lane, goal, prefix)
    local x = tonumber(lane[prefix .. "X"])
    local y = tonumber(lane[prefix .. "Y"])
    local z = tonumber(lane[prefix .. "Z"])
    if x == nil or y == nil or not goal then return math.huge end
    local dx = (tonumber(goal.x) or 0) - x
    local dy = (tonumber(goal.y) or 0) - y
    local dz = (tonumber(goal.z) or 0) - (z or 0)
    return math.sqrt((dx * dx) + (dy * dy) + (dz * dz))
end

function Internal.isNativeGoalBlocked(lane, goal, now)
    if not lane or lane.nativeBlockedGoalX == nil then return false end
    now = tonumber(now) or Internal.Core.Now()
    local changeDistance = math.max(
        0.5,
        tonumber(Const.ENGINE_PATH_BLOCKED_GOAL_CHANGE_DISTANCE) or 1.5
    )
    if now >= (tonumber(lane.nativeBlockedUntil) or 0)
        or nativeGoalDistance(lane, goal, "nativeBlockedGoal")
            >= changeDistance
    then
        Internal.clearNativeGoalBlock(lane)
        return false
    end
    return true
end

function Internal.noteNativeGoalFailure(lane, goal, now)
    if not lane or not goal then return false end
    now = tonumber(now) or Internal.Core.Now()
    local changeDistance = math.max(
        0.5,
        tonumber(Const.ENGINE_PATH_BLOCKED_GOAL_CHANGE_DISTANCE) or 1.5
    )
    if nativeGoalDistance(lane, goal, "nativeFailureGoal")
        >= changeDistance
    then
        lane.nativeFailureCount = 0
    end
    lane.nativeFailureGoalX = tonumber(goal.x)
    lane.nativeFailureGoalY = tonumber(goal.y)
    lane.nativeFailureGoalZ = tonumber(goal.z)
    lane.nativeFailureCount =
        (tonumber(lane.nativeFailureCount) or 0) + 1
    local failureLimit = tonumber(Const.ENGINE_PATH_FAILURE_LIMIT) or 2
    local followGoal = string.sub(tostring(lane.intentReason or ""), 1, 12)
        == "follow_owner"
    if followGoal then
        failureLimit = 1
    end
    if lane.nativeFailureCount < math.max(
        1,
        math.floor(failureLimit)
    ) then
        return false
    end
    lane.nativeBlockedGoalX = lane.nativeFailureGoalX
    lane.nativeBlockedGoalY = lane.nativeFailureGoalY
    lane.nativeBlockedGoalZ = lane.nativeFailureGoalZ
    local blockedCooldown = followGoal
        and (tonumber(Const.FOLLOW_PATH_BLOCKED_COOLDOWN_MS) or 1200)
        or (tonumber(Const.ENGINE_PATH_BLOCKED_GOAL_COOLDOWN_MS) or 10000)
    lane.nativeBlockedUntil = now + math.max(1000, blockedCooldown)
    return true
end
