--[[
    PNC Native Passage: advance managed fence climbs.
]]

PNC = PNC or {}
PNC.ClientPresenceSync = PNC.ClientPresenceSync or {}
PNC.ClientPresenceSync.Internal =
    PNC.ClientPresenceSync.Internal or {}

local Sync = PNC.ClientPresenceSync
local Controller = Sync.Internal.NativePathController
local Passage = Controller.PassageInternal
local Shared = Passage.Shared
local Fence = Passage.FenceInternal

local TraversalAction = PNC.TraversalAction
local TraversalQuery = PNC.TraversalQuery
local Animation = PNC.Animation
local LiveBodyControl = PNC.LiveBodyControl

local logPassageEvent = Shared.LogPassageEvent
local finishPassageBump = Shared.FinishPassageBump
local traversalPhase = Shared.TraversalPhase
local bumpFinished = Shared.BumpFinished
local logState = Controller.LogState

local function updateFenceAction(body, state, now)
    local action = state and state.passageAction or nil
    if not action then return false, nil end
    if action.kind == "fence_climb" then
        local phase
        local observedPhase
        local progress
        local phaseStartedAt
        local crossPendingAt
        local startedCrossing
        observedPhase = traversalPhase(body)
        phase,
            progress,
            phaseStartedAt,
            crossPendingAt,
            startedCrossing = TraversalAction.Evaluate(
            action,
            now,
            observedPhase
        )
        action.phase = phase
        action.crossPendingAt = crossPendingAt
        Fence.LogPhase(
            state.snapshot,
            body,
            state,
            action,
            now,
            phase,
            observedPhase
        )
        if startedCrossing then
            action.crossingStartedAt = phaseStartedAt
            if Animation and Animation.PlayBump then
                Animation.PlayBump(
                    body,
                    state.snapshot,
                    action.endAnim,
                    {
                        sceneId = "native_fence_climb",
                        leaseUntil = action.finishAt,
                        keepManagedUseless = true,
                    }
                )
            elseif body.setBumpType then
                body:setBumpType(action.endAnim)
            end
        end
        local x = action.fromX + (action.toX - action.fromX) * progress
        local y = action.fromY + (action.toY - action.fromY) * progress
        if LiveBodyControl and LiveBodyControl.SetAuthoritativePosition then
            LiveBodyControl.SetAuthoritativePosition(body, x, y, action.toZ)
        end
        if body.setLx then body:setLx(x) end
        if body.setLy then body:setLy(y) end
        if not Fence.Crossed(body, action)
            or (not bumpFinished(body)
                and traversalPhase(body) ~= "finished"
                and now < action.finishAt)
        then
            Fence.HoldBody(body)
            state.lastProgressAt = now
            return true, "native_fence_climb"
        end
        finishPassageBump(body)
        logPassageEvent(
            state.snapshot,
            body,
            state,
            action,
            "complete",
            Fence.Crossed(body, action)
                and "crossed" or "same_side"
        )
        state.passageAction = nil
        state.requestKey = nil
        if Fence.Crossed(body, action) then
            state.fenceCooldownKey = action.fenceKey
            state.fenceCooldownUntil = now + Fence.Policy.CooldownMs
            state.failed = true
            state.retryAt = now
            return true, "native_fence_crossed"
        end
        -- A server correction or a failed local landing must not immediately
        -- select the same edge again. Hold the route briefly and let the
        -- authoritative position settle before retrying.
        state.fenceRetryKey = action.fenceKey
        state.fenceRetryAt = now + Fence.Policy.RetryBackoffMs
        state.failed = true
        state.retryAt = state.fenceRetryAt
        return true, "native_fence_same_side"
    end
    return false, nil
end

Passage.UpdateFenceAction = updateFenceAction
