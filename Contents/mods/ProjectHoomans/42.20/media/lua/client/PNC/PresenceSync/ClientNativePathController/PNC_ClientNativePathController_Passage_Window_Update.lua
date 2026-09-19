--[[
    PNC Native Passage: active window action progression.
]]

PNC = PNC or {}
PNC.ClientPresenceSync = PNC.ClientPresenceSync or {}
PNC.ClientPresenceSync.Internal =
    PNC.ClientPresenceSync.Internal or {}

local Sync = PNC.ClientPresenceSync
local Controller = Sync.Internal.NativePathController
local Passage = Controller.PassageInternal
local Shared = Passage.Shared
local Window = Passage.WindowInternal

local TraversalAction = PNC.TraversalAction
local TraversalQuery = PNC.TraversalQuery
local PathInternal = PNC.PathService
    and PNC.PathService.Internal or nil
local LiveBodyControl = PNC.LiveBodyControl
local Core = PNC.Core

local beginMovementLease = Controller.BeginMovementLease
local logState = Controller.LogState
local describeBody = Controller.DescribeBody
local RETRY_BASE_MS = Controller.RETRY_BASE_MS
local WINDOW_COOLDOWN_MS = Window.CooldownMs
local WINDOW_LANDING_BACKOFF_MS = Window.LandingBackoffMs

local logPassageEvent = Shared.LogPassageEvent
local finishPassageBump = Shared.FinishPassageBump
local traversalPhase = Shared.TraversalPhase
local bumpFinished = Shared.BumpFinished

local function updateWindowAction(body, state, now)
    local action = state and state.passageAction or nil
    if not action then return false, nil end
    if action.kind == "window_climb" then
        local phase
        local progress
        local landingBlocked = false
        local observedPhase = traversalPhase(body)
        phase, progress = TraversalAction.Evaluate(
            action,
            now,
            observedPhase
        )
        action.phase = phase
        local x = action.fromX + (action.toX - action.fromX) * progress
        local y = action.fromY + (action.toY - action.fromY) * progress
        if LiveBodyControl and LiveBodyControl.SetAuthoritativePosition then
            LiveBodyControl.SetAuthoritativePosition(body, x, y, action.toZ)
        end
        if body.setLx then body:setLx(x) end
        if body.setLy then body:setLy(y) end
        if progress < 1
            or (not bumpFinished(body)
                and traversalPhase(body) ~= "finished"
                and now < action.finishAt)
        then
            beginMovementLease(body, state, action.key, now)
            state.lastProgressAt = now
            return true, "native_window_climb"
        end
        if action.toSquare
            and TraversalQuery
            and TraversalQuery.CanTraverseAt
        then
            landingBlocked = not TraversalQuery.CanTraverseAt(
                action.toSquare:getX() + 0.5,
                action.toSquare:getY() + 0.5,
                action.toSquare:getZ()
            )
        end
        finishPassageBump(body)
        logPassageEvent(
            state.snapshot,
            body,
            state,
            action,
            "complete",
            landingBlocked and "landing_blocked" or "crossed"
        )
        state.passageAction = nil
        state.requestKey = nil
        state.failed = true
        state.retryAt = now + WINDOW_LANDING_BACKOFF_MS
        if landingBlocked then
            state.windowRetryObject = action.object
            state.windowRetryAt = state.retryAt
            if state.windowRepairLoggedObject ~= action.object
                and Core
                and Core.LogWarn
            then
                Core.LogWarn(
                    "[PNC][PATH] native_window_landing_repaired npc="
                        .. tostring(
                            state.snapshot and state.snapshot.id or "nil"
                        )
                        .. " "
                        .. describeBody(body)
                )
                state.windowRepairLoggedObject = action.object
            end
            logState(
                state.snapshot,
                "native_window_landing_repaired",
                describeBody(body)
            )
            return true, "native_window_landing_repaired"
        end
        if state.windowRepairLoggedObject == action.object then
            state.windowRepairLoggedObject = nil
        end
        state.windowCooldownObject = action.object
        state.windowCooldownUntil = now + WINDOW_COOLDOWN_MS
        return true, "native_window_crossed"
    end
    if action.applied ~= true
        and now >= (tonumber(action.impactAt) or now)
    then
        action.applied = true
        if PathInternal and PathInternal.smashWindowForNPC then
            PathInternal.smashWindowForNPC(body, action.object)
        elseif action.object and action.object.smashWindow then
            action.object:smashWindow()
        end
    end
    if now < (tonumber(action.finishAt) or now) then
        beginMovementLease(body, state, action.key, now)
        return true, "native_window_smash"
    end
    finishPassageBump(body)
    logPassageEvent(
        state.snapshot,
        body,
        state,
        action,
        "complete",
        "smashed"
    )
    state.passageAction = nil
    state.requestKey = nil
    state.failed = true
    state.retryAt = now + RETRY_BASE_MS
    return true, "native_window_smashed"
end

Passage.UpdateWindowAction = updateWindowAction
