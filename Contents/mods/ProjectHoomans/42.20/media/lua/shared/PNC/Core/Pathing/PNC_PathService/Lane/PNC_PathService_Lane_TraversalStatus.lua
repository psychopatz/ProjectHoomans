-- Public traversal-ownership query for the active movement lane.

PNC = PNC or {}
PNC.PathService = PNC.PathService or {}
PNC.PathService.Internal = PNC.PathService.Internal or {}

local PathService = PNC.PathService

local TRAVERSAL_OWNER_MODES = {
    door_open = true,
    fence_climb = true,
    window_climb = true,
    window_open = true,
}

local function latestProgressAt(lane, fallback)
    local latest = tonumber(fallback) or 0
    local value = tonumber(lane and lane.lastProgressAt)
    if value and value > latest then latest = value end
    value = tonumber(lane and lane.lastGoalProgressAt)
    if value and value > latest then latest = value end
    value = tonumber(lane and lane.lastPhysicalMoveAt)
    if value and value > latest then latest = value end
    return latest
end

function PathService.IsTraversalActive(record, zombie)
    local lane = record and record.runtime and record.runtime.pathing or nil
    local modData
    local actionState
    if lane and lane.traversalAction then
        return true, lane.traversalAction.kind or lane.ownerMode or "traversal"
    end
    if lane and TRAVERSAL_OWNER_MODES[tostring(lane.ownerMode or "")] then
        return true, lane.ownerMode
    end
    modData = zombie and zombie.getModData and zombie:getModData() or nil
    if modData and modData.PNC_BumpReleasePending == true and lane and lane.lastTraversalKind then
        return true, "traversal_release"
    end
    actionState = zombie and zombie.getActionStateName and string.lower(tostring(zombie:getActionStateName() or "")) or ""
    if actionState == "climbfence" or actionState == "climbwindow" then
        return true, actionState
    end
    return false, nil
end

-- Tasking and facility jobs may observe movement liveness, but they must not
-- mutate the movement lane or invent a second path watchdog. PathService is
-- the sole owner of this snapshot: its progress clock is based on physical
-- movement/goal progress, while an active passage remains owned by the
-- traversal state machine until its own hard deadline.
function PathService.GetMovementRecoveryState(record, zombie, now)
    local runtime = record and record.runtime or nil
    local lane = runtime and runtime.pathing or nil
    local traversalActive
    local traversalKind
    local traversal
    local navigation
    local navigationRouter
    local nativeFallback
    local hardFinishAt
    local active
    local watchable
    now = tonumber(now)
        or PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
    if not lane then
        return {
            active = false,
            phase = "idle",
            watchable = false,
        }
    end

    navigation = runtime and runtime.localNavigation or nil
    navigationRouter = runtime and runtime.navigationRouter or nil
    nativeFallback = PNC.NavigationRouter
        and PNC.NavigationRouter.IsFallbackActive
        and PNC.NavigationRouter.IsFallbackActive(record, now)
        or false
    traversalActive, traversalKind = PathService.IsTraversalActive(
        record, zombie)
    traversal = lane.traversalAction or lane.vanillaFenceAction
    hardFinishAt = traversal and tonumber(traversal.hardFinishAt
        or traversal.finishAt) or 0
    if not traversalActive and navigation
        and navigation.nativeTraversalState ~= nil
    then
        traversalActive = true
        traversalKind = "native_"
            .. tostring(navigation.nativeTraversalState)
        hardFinishAt = (tonumber(navigation.nativeTraversalStartedAt) or now)
            + math.max(1000, tonumber(PNC.Const
                and PNC.Const.ENGINE_PATH_TRAVERSAL_TIMEOUT_MS) or 3000)
    end
    active = lane.phase == "active" or lane.phase == "requested"
        or lane.pendingGoal ~= nil
    watchable = active
    local nativeBackoffUntil = tonumber(lane.nativeBackoffUntil) or 0
    local nativeBackoff = nativeBackoffUntil > now
    if nativeBackoff then
        -- A bounded native retry window is an intentional recovery state;
        -- tasking must observe it without competing to cancel the lease.
        watchable = false
    end
    if nativeFallback then
        -- Native recovery owns the lease while the active lane transfers to
        -- scripted locomotion. Needs/tasking may observe this state, but must
        -- not cancel and recreate the same destination during the handoff.
        watchable = false
    end
    if traversalActive and hardFinishAt > now then
        -- Door/window/fence passage is a legitimate in-flight owner. The
        -- movement pump will finish or hard-timeout it; task recovery must
        -- not cancel the need while that owner is still inside its contract.
        watchable = false
    end

    return {
        active = active,
        phase = lane.phase or "idle",
        provider = lane.navigationProvider or "unknown",
        ownerMode = lane.ownerMode or "idle",
        nativeStallRecoveryCount =
            tonumber(lane.nativeStallRecoveryCount) or 0,
        nativeBackoff = nativeBackoff,
        nativeBackoffUntil = nativeBackoffUntil > 0
            and nativeBackoffUntil or nil,
        nativeFallback = nativeFallback,
        fallbackUntil = nativeFallback and navigationRouter
            and tonumber(navigationRouter.fallbackUntil) or nil,
        fallbackReason = nativeFallback and navigationRouter
            and navigationRouter.fallbackReason or nil,
        traversal = traversalActive == true,
        traversalKind = traversalKind,
        hardFinishAt = hardFinishAt > 0 and hardFinishAt or nil,
        forceRecovery = traversalActive == true
            and hardFinishAt > 0 and now >= hardFinishAt or false,
        watchable = watchable,
        lastProgressAt = latestProgressAt(lane, lane.startedAt),
        goalDistance = lane.goalDistance,
        lastProgressReason = lane.lastStepLabel
            or lane.blockReason
            or lane.ownerMode,
    }
end
