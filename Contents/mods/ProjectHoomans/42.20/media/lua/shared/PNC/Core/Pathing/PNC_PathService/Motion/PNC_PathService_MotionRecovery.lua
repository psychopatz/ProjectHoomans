-- Motion provider: scripted body-state recovery while a move lane is active.

local Internal = PNC.PathService.Internal

local function prepareFakeBody(zombie, lane, now)
    if lane.navigationProvider ~= "engine_path"
        and Internal.FakeLocomotion
        and Internal.FakeLocomotion.PrepareBody
    then
        Internal.FakeLocomotion.PrepareBody(zombie, lane, now)
    end
end

function Internal.recoverScriptedBodyState(zombie, record, lane, now)
    local suppressed
    local suppressedState
    if Internal.LiveBodyControl
        and Internal.LiveBodyControl.SuppressZombieState
    then
        suppressed, suppressedState =
            Internal.LiveBodyControl.SuppressZombieState(zombie, lane, now)
    else
        suppressed = false
    end
    if suppressed then
        lane.lastActionState = Internal.getActionStateName(zombie)
        lane.recoveryCount = (tonumber(lane.recoveryCount) or 0) + 1
        lane.lastRecoveryReason = suppressedState or lane.lastActionState
        lane.lastRecoverAt = now
        prepareFakeBody(zombie, lane, now)
        if lane.ownerMode ~= "window_climb"
            and lane.ownerMode ~= "window_open"
            and lane.ownerMode ~= "window_smash"
            and lane.ownerMode ~= "fence_climb"
        then
            Internal.setWalkAnim(
                zombie,
                record,
                lane.resolvedMode or lane.mode or "walk",
                false
            )
        end
        if lane.lastSuppressedWarnState ~= suppressedState
            or (now - (tonumber(lane.lastSuppressedWarnAt) or 0)) >= 15000
        then
            lane.lastSuppressedWarnState = suppressedState
            lane.lastSuppressedWarnAt = now
            Internal.logMoveWarning(
                record,
                zombie,
                lane,
                "suppress_state",
                suppressedState or lane.lastActionState,
                "action=" .. tostring(suppressedState or lane.lastActionState)
            )
        end
        Internal.logMoveDebug(
            record,
            zombie,
            lane,
            "suppress_state",
            suppressedState or lane.lastActionState,
            "postAction=" .. tostring(lane.lastActionState)
        )
    else
        lane.lastSuppressedWarnState = nil
        lane.lastSuppressedWarnAt = nil
    end

    if not suppressed and Internal.tryRecoverNonLocomotionState then
        local recovered
        local recoveredState
        recovered, recoveredState = Internal.tryRecoverNonLocomotionState(
            record,
            zombie,
            lane,
            now
        )
        if recovered then
            lane.lastProgressAt = now
            lane.lastIssueAt = now
            lane.recoveryCount = (tonumber(lane.recoveryCount) or 0) + 1
            lane.lastRecoveryReason = recoveredState or lane.lastActionState
            lane.lastRecoverAt = now
            prepareFakeBody(zombie, lane, now)
            Internal.logMoveWarning(
                record,
                zombie,
                lane,
                "recover_nonlocomotion",
                recoveredState or "unknown",
                "action=" .. tostring(recoveredState or "unknown")
            )
            Internal.logMoveDebug(
                record,
                zombie,
                lane,
                "recover_nonlocomotion",
                recoveredState or "unknown",
                ""
            )
            return true, "recovering"
        end
    end
    return nil
end
