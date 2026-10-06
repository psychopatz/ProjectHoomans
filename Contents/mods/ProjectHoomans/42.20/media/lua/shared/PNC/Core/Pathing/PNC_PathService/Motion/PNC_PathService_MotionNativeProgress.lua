-- Motion provider: progress accounting and watchdog policy for native engine paths.

local Internal = PNC.PathService.Internal
local Diagnostics = PNC.PerformanceScalingDiagnostics
local Const = PNC.Const or {}

local function isFollowOwnerLane(lane)
    if not lane then return false end
    if string.sub(tostring(lane.intentReason or ""), 1, 12)
        == "follow_owner"
    then
        return true
    end
    return tostring(lane.requestedOrder or "")
        == tostring(Const.ORDER_FOLLOW or "follow")
end

local function isCampAnchorLane(lane)
    if not lane then return false end
    if tostring(lane.intentReason or "") == "camp_anchor" then
        return true
    end
    return tostring(lane.requestedOrder or "") == tostring(
        Const.ORDER_CAMP or "camp"
    )
end

local function auditTraversal(record, eventName, zombie, lane, extra)
    local presence = PNC.Presence
    local presenceInternal = presence and presence.Internal or nil
    local fields
    if not presenceInternal or not presenceInternal.LogTraversal then
        return
    end
    fields = {
        "goal=" .. tostring(lane and lane.goal
            and Internal.describeGoal(lane.goal) or "nil"),
        "targetKind=" .. tostring(lane and lane.targetKind or "nil"),
        "targetValidation=" .. tostring(
            lane and lane.targetValidation or "nil"
        ),
        "ownerMode=" .. tostring(lane and lane.ownerMode or "nil"),
        "noProgress=" .. tostring(lane and lane.noProgressCount or 0),
    }
    for _, field in ipairs(extra or {}) do
        fields[#fields + 1] = tostring(field)
    end
    presenceInternal.LogTraversal(record, eventName, zombie, fields)
end

local function requestTraversalHandoff(record, zombie, lane, reason)
    -- Travel owns its elapsed-time handoff policy. FollowOwner also has a
    -- durable owner target and an existing range-based live/abstract policy;
    -- Presence owns the range-based live/abstract transition. Do not invoke
    -- it for a durable Travel journey, which has its own elapsed-time
    -- projection and handoff policy; FollowOwner is intentionally allowed
    -- through so a far/stalled live body can return to the existing abstract
    -- owner-follow lane instead of being converted to fake locomotion.
    if record and record.travel then
        return false
    end
    if PNC.Presence and PNC.Presence.RequestTraversalHandoff
        and PNC.Presence.RequestTraversalHandoff(record, reason)
    then
        auditTraversal(record, "handoff_requested", zombie, lane, {
            "reason=" .. tostring(reason or "movement_stall"),
            "lane=non_travel",
        })
        return true
    end
    return false
end

local function scheduleFollowNativeRepath(
    record,
    zombie,
    lane,
    now,
    reason,
    enginePlanner
)
    local goalRevision = tonumber(lane.goalRevision) or 0
    if lane.followNativeRecoveryGoalRevision ~= goalRevision then
        lane.followNativeRecoveryGoalRevision = goalRevision
        lane.followNativeRecoveryCount = 0
    end
    local retryCount = math.min(
        8,
        (tonumber(lane.followNativeRecoveryCount) or 0) + 1
    )
    local retryDelay = math.max(
        250,
        tonumber(Const.FOLLOW_PATH_BLOCKED_COOLDOWN_MS)
            or tonumber(Const.ENGINE_PATH_REPLAN_MS)
            or 1000
    )
    local planner = enginePlanner or PNC.EnginePathPlanner
    if planner and planner.Invalidate then
        planner.Invalidate(record, reason or "follow_native_repath", zombie)
    end
    lane.followNativeRecoveryCount = retryCount
    lane.lastNavigationInvalidatedAt = now
    lane.nativeBackoffUntil = now + retryDelay * math.min(4, retryCount)
    lane.ownerMode = "native_backoff"
    lane.lastRecoveryReason = "follow_native_repath"
    lane.lastRecoverAt = now
    lane.lastProgressAt = now
    lane.lastGoalProgressAt = now
    lane.noProgressCount = 0
    lane.nativeStallRecoveryCount = 0
    lane.blockReason = nil
    if Internal.clearNativeGoalBlock then
        Internal.clearNativeGoalBlock(lane)
    end
    if Diagnostics and type(Diagnostics.Increment) == "function" then
        Diagnostics.Increment("Pathing.Replans")
        Diagnostics.Increment("Pathing.Retries")
    end
    auditTraversal(record, "native_repath", zombie, lane, {
        "reason=" .. tostring(reason or "follow_native_repath"),
        "retry=" .. tostring(retryCount),
        "policy=follow_native_provider",
    })
    return true, "native_repath"
end

local function activateNativeFallback(record, lane, now, reason)
    local router = PNC.NavigationRouter
    local durationMs = math.max(
        1000,
        tonumber(Const.ENGINE_PATH_FALLBACK_COOLDOWN_MS)
            or tonumber(Const.NATIVE_STALL_BACKOFF_MS)
            or 5000
    )
    if router and router.ActivateFallback then
        router.ActivateFallback(record, reason, durationMs)
    end
    -- The current lane is already active. Drop only its native provider so
    -- the very next PathService pump can use the bounded scripted mover;
    -- tasking keeps the same lease and destination during recovery.
    lane.navigationProvider = nil
    lane.navigationPolicy = "fallback"
    lane.ownerMode = "fake_locomotion"
    lane.nativeBackoffUntil = 0
    lane.fallbackCount = (tonumber(lane.fallbackCount) or 0) + 1
    lane.recoveryCount = (tonumber(lane.recoveryCount) or 0) + 1
    lane.lastRecoveryReason = tostring(reason or "native_path_fallback")
    lane.lastRecoverAt = now
    if Diagnostics then
        Diagnostics.Increment("Pathing.NativeFallbacks")
    end
    auditTraversal(record, "native_fallback", nil, lane, {
        "reason=" .. tostring(reason or "native_path_fallback"),
    })
end

local function handleNativeFailure(
    record,
    zombie,
    lane,
    now,
    nativeState,
    enginePlanner
)
    lane.ownerMode = "engine_path_waiting"
    lane.lastStepAt = now
    lane.lastStepDistance = 0
    lane.lastStepLabel = nativeState
    if isFollowOwnerLane(lane) then
        -- A follow failure is a native-provider failure, not an order
        -- failure. Keep the engine_path provider and let its normal bounded
        -- retry acquire a fresh route. Activating the direct provider here
        -- made visible followers use fake locomotion after one transient
        -- Behavior2 failure.
        return scheduleFollowNativeRepath(
            record,
            zombie,
            lane,
            now,
            nativeState or "native_path_failed",
            enginePlanner
        )
    end
    if isCampAnchorLane(lane) then
        auditTraversal(record, "native_route_failed", zombie, lane, {
            "reason=" .. tostring(nativeState or "native_path_failed"),
            "policy=follow_or_camp_fallback",
        })
        -- Follow and camp are durable local movement commands. Native
        -- failure is a provider failure, not an order failure: keep the lane
        -- alive and give the scripted mover the same destination so it can
        -- approach/interact with a doorway or recover from stale engine
        -- ownership state.
        activateNativeFallback(
            record,
            lane,
            now,
            nativeState or "native_path_failed"
        )
        lane.lastProgressAt = now
        lane.lastGoalProgressAt = now
        lane.noProgressCount = 0
        if Internal.clearNativeGoalBlock then
            Internal.clearNativeGoalBlock(lane)
        end
        Internal.logMoveWarning(
            record,
            zombie,
            lane,
            "native_path_fallback",
            nativeState or "native_path_failed",
            "goal=" .. Internal.describeGoal(lane.goal)
        )
        return true, "native_path_fallback"
    end
    if Internal.noteNativeGoalFailure
        and Internal.noteNativeGoalFailure(lane, lane.goal, now)
    then
        if requestTraversalHandoff(
            record,
            zombie,
            lane,
            nativeState or "native_path_unreachable"
        ) then
            return true, "presence_handoff_requested"
        end
        Internal.logMoveWarning(
            record,
            zombie,
            lane,
            "native_goal_blocked",
            "failure_limit",
            "goal=" .. Internal.describeGoal(lane.goal)
        )
        return Internal.completeMove(
            zombie,
            record,
            lane,
            "blocked",
            "native_path_unreachable"
        )
    end
    if now >= (tonumber(lane.visualMovingUntil) or 0) then
        Internal.applyHoldAnimation(zombie, record, lane)
    end
    return true, nativeState
end

local function recordPhysicalStep(
    lane,
    now,
    fromX,
    fromY,
    fromZ,
    toX,
    toY,
    toZ,
    stepDistance
)
    if stepDistance <= 0.0001 then
        return
    end
    lane.lastPhysicalMoveAt = now
    lane.lastX = toX
    lane.lastY = toY
    lane.followNativeRecoveryCount = 0
    lane.followNativeRecoveryGoalRevision =
        tonumber(lane.goalRevision) or 0
    lane.nativeStallRecoveryCount = 0
    lane.nativeBackoffUntil = 0
    lane.visualMovingUntil = now + Internal.LOCOMOTION_VISUAL_LEASE_MS
    if Internal.MotionHints and Internal.MotionHints.Remember then
        Internal.MotionHints.Remember(
            lane,
            fromX,
            fromY,
            fromZ,
            toX,
            toY,
            toZ,
            now,
            {
                kind = "engine_path",
                profile = lane.motionProfile,
            }
        )
    end
end

local function recordGoalProgress(lane, now, goalDistance, goalProgress)
    if goalProgress >= 0.01 then
        lane.bestGoalDistance = goalDistance
        lane.lastProgressAt = now
        lane.lastGoalProgressAt = now
        lane.nonProgressStepCount = 0
        lane.noProgressCount = 0
        lane.blockReason = nil
    else
        lane.nonProgressStepCount =
            (tonumber(lane.nonProgressStepCount) or 0) + 1
    end
end

local function handleNativeTimeout(
    record,
    zombie,
    lane,
    enginePlanner,
    now,
    nativeTraversalState
)
    if nativeTraversalState ~= nil
        or now - (tonumber(lane.lastGoalProgressAt) or now)
            < Internal.PROGRESS_TIMEOUT_MS
    then
        return nil
    end
    lane.noProgressCount = (tonumber(lane.noProgressCount) or 0) + 1
    lane.blockReason = "native_no_goal_progress"
    auditTraversal(record, "native_progress_timeout", zombie, lane, {
        "reason=" .. tostring(lane.blockReason),
        "nativeState=" .. tostring(nativeTraversalState or "none"),
    })
    Internal.logMoveWarning(
        record,
        zombie,
        lane,
        "native_progress_timeout",
        lane.blockReason,
        "goal=" .. Internal.describeGoal(lane.goal)
    )
    if isFollowOwnerLane(lane) then
        -- Keep a stalled visible follower on the native provider. If it is
        -- outside the materialization radius, the existing Presence handoff
        -- owns the transition to abstract FollowOwner; nearby followers keep
        -- a bounded native replan and remain visible.
        if lane.followNativeRecoveryCount
            and tonumber(lane.followNativeRecoveryCount) >= 2
            and requestTraversalHandoff(
                record,
                zombie,
                lane,
                "native_progress_timeout"
            )
        then
            return true, "presence_handoff_requested"
        end
        return scheduleFollowNativeRepath(
            record,
            zombie,
            lane,
            now,
            "native_progress_timeout",
            enginePlanner
        )
    end
    if lane.noProgressCount >= 3 then
        if enginePlanner.Invalidate then
            enginePlanner.Invalidate(
                record,
                "native_progress_timeout",
                zombie
            )
        end
        lane.lastNavigationInvalidatedAt = now
        if requestTraversalHandoff(
            record,
            zombie,
            lane,
            "native_progress_timeout"
        ) then
            return true, "presence_handoff_requested"
        end
        return Internal.completeMove(
            zombie,
            record,
            lane,
            "blocked",
            "native_progress_timeout"
        )
    end
    if lane.noProgressCount >= 2 then
        lane.nativeStallRecoveryCount =
            (tonumber(lane.nativeStallRecoveryCount) or 0) + 1
        if lane.nativeStallRecoveryCount >= 3 then
            if enginePlanner.Invalidate then
                enginePlanner.Invalidate(
                    record,
                    "native_progress_timeout",
                    zombie
                )
            end
            lane.lastNavigationInvalidatedAt = now
            if requestTraversalHandoff(
                record,
                zombie,
                lane,
                "native_stall_backoff_exhausted"
            ) then
                return true, "presence_handoff_requested"
            end
            return Internal.completeMove(
                zombie,
                record,
                lane,
                "blocked",
                "native_progress_timeout"
            )
        end
        lane.nativeBackoffUntil = now + math.max(
            1000,
            tonumber(Const.NATIVE_STALL_BACKOFF_MS) or 5000
        )
        lane.ownerMode = "native_backoff"
        lane.lastRecoveryReason = "native_stall_backoff"
        lane.lastRecoverAt = now
        if Diagnostics then
            Diagnostics.Increment("Pathing.StallBackoffs")
        end
        if enginePlanner.Invalidate then
            enginePlanner.Invalidate(
                record,
                "native_path_fallback",
                zombie
            )
        end
        lane.lastNavigationInvalidatedAt = now
        activateNativeFallback(
            record,
            lane,
            now,
            "native_stall_backoff"
        )
        return true, "native_path_fallback"
    end
    if enginePlanner.Invalidate then
        enginePlanner.Invalidate(
            record,
            "native_progress_timeout",
            zombie
        )
    end
    lane.lastNavigationInvalidatedAt = now
    lane.lastGoalProgressAt = now
    if Diagnostics then
        Diagnostics.Increment("Pathing.Replans")
        Diagnostics.Increment("Pathing.Retries")
    end
    return true, "native_repath"
end

-- A route request can be valid but not actionable yet because its destination
-- chunk is not materialized. Keep this in the shared path supervisor so
-- fishing, travel, work, and follow all receive the same bounded behavior.
function Internal.handleNativeTargetReadinessWait(
    record,
    zombie,
    lane,
    navigation,
    now
)
    local startedAt = tonumber(
        navigation and navigation.targetReadinessWaitStartedAt
    )
    local timeoutMs = math.max(
        1000,
        tonumber(Const.ENGINE_PATH_TARGET_READINESS_TIMEOUT_MS) or 6000
    )
    if not startedAt then
        return true, "target_readiness_waiting"
    end
    lane.ownerMode = "engine_path_waiting"
    lane.blockReason = navigation.lastPlanReason
        or "target_chunk_unloaded"
    lane.lastIssueAt = now
    if now - startedAt < timeoutMs then
        return true, "target_readiness_waiting"
    end
    auditTraversal(record, "target_readiness_timeout", zombie, lane, {
        "reason=" .. tostring(lane.blockReason),
        "waitMs=" .. tostring(now - startedAt),
    })
    if requestTraversalHandoff(
        record,
        zombie,
        lane,
        lane.blockReason or "target_chunk_unloaded"
    ) then
        return true, "presence_handoff_requested"
    end
    -- Travel has its own durable journey watchdog, which will consume the
    -- lack of physical progress. Do not complete that journey as blocked here.
    navigation.targetReadinessWaitStartedAt = now
    navigation.plannedAt = now
    return true, "target_readiness_retry"
end

function Internal.recordNativeMove(
    record,
    zombie,
    lane,
    navigation,
    enginePlanner,
    now,
    nativeState,
    fromX,
    fromY,
    fromZ
)
    local toX = zombie:getX()
    local toY = zombie:getY()
    local toZ = zombie:getZ()
    local dx = toX - fromX
    local dy = toY - fromY
    local stepDistance = math.sqrt((dx * dx) + (dy * dy))
    local goalDistance = Internal.Core.Distance(
        toX,
        toY,
        lane.goal.x,
        lane.goal.y
    )
    local bestGoalDistance = tonumber(lane.bestGoalDistance)
        or goalDistance
    local goalProgress = bestGoalDistance - goalDistance
    if lane.bestGoalDistance == nil then
        lane.bestGoalDistance = goalDistance
    end
    if lane.lastGoalProgressAt == nil then
        lane.lastGoalProgressAt = tonumber(lane.lastProgressAt) or now
    end
    if nativeState == "engine_path_failed"
        or nativeState == "engine_path_timeout"
    then
        return handleNativeFailure(
            record, zombie, lane, now, nativeState, enginePlanner
        )
    end

    local nativeTraversalState = navigation
        and navigation.nativeTraversalState or nil
    lane.ownerMode = nativeTraversalState
        and "engine_traversal" or "engine_path"
    lane.lastIssueAt = now
    lane.lastStepAt = now
    lane.lastStepDistance = stepDistance
    lane.lastStepLabel = nativeState
    lane.goalDistance = goalDistance
    lane.lastProgressDelta = goalProgress
    recordPhysicalStep(
        lane,
        now,
        fromX,
        fromY,
        fromZ,
        toX,
        toY,
        toZ,
        stepDistance
    )
    if stepDistance > 0.0001
        and PNC.Presence
        and PNC.Presence.ClearTraversalHandoff
    then
        PNC.Presence.ClearTraversalHandoff(record, "native_progress")
    end
    recordGoalProgress(lane, now, goalDistance, goalProgress)
    if Internal.syncRecordPosition then
        Internal.syncRecordPosition(record, zombie)
    end
    if Internal.isAtGoal(zombie, lane.goal, lane.stopDistance) then
        return Internal.completeMove(
            zombie, record, lane, "arrived", nativeState
        )
    end
    local handled, state = Internal.tryNativeStallPassage(
        record,
        zombie,
        lane,
        enginePlanner,
        now,
        nativeTraversalState
    )
    if handled then
        return handled, state
    end
    handled, state = handleNativeTimeout(
        record,
        zombie,
        lane,
        enginePlanner,
        now,
        nativeTraversalState
    )
    if handled then
        return handled, state
    end
    return true, nativeState
end
