-- Motion provider: scripted passage ownership and cooldown handling.

local Internal = PNC.PathService.Internal

local function setPassageOwner(lane, interactType, now)
    if interactType == "door_open" then
        lane.ownerMode = "door_open"
        lane.specialMoveUntil = now + 180
        lane.specialAnim = nil
    elseif interactType == "window_open" then
        lane.ownerMode = "window_open"
        lane.specialMoveUntil = now + 250
        lane.specialAnim = nil
    elseif interactType == "window_smash" then
        lane.ownerMode = "window_smash"
    elseif interactType == "fence_climb" then
        lane.ownerMode = "fence_climb"
        if lane.vanillaFenceAction then
            lane.specialMoveUntil =
                tonumber(lane.vanillaFenceAction.finishAt)
                or now
        end
    else
        lane.ownerMode = "window_climb"
    end
end

local function tryPassage(zombie, record, lane, goal)
    return Internal.tryDoorOrWindowInteraction(
        zombie,
        record,
        lane,
        goal.x,
        goal.y,
        goal.z
    )
end

function Internal.updateScriptedSpecialMove(zombie, record, lane, now)
    if Internal.Animation
        and Internal.Animation.PumpBumpRelease
        and Internal.Animation.PumpBumpRelease(zombie, now)
    then
        lane.lastProgressAt = now
        lane.lastIssueAt = now
        lane.ownerMode = "bump_release"
        return true, "bump_release"
    elseif lane.ownerMode == "bump_release" then
        lane.ownerMode = "fake_locomotion"
    end
    if Internal.refreshTraversalMemory then
        Internal.refreshTraversalMemory(lane, zombie)
    end
    if lane.vanillaFenceAction
        and Internal.updateVanillaFenceAction
    then
        local fenceActive
        local fenceState
        fenceActive, fenceState = Internal.updateVanillaFenceAction(
            zombie, record, lane, now
        )
        if fenceActive then
            Internal.logMoveDebug(
                record,
                zombie,
                lane,
                "special_progress",
                fenceState or lane.ownerMode,
                ""
            )
            return true, fenceState or lane.ownerMode
        end
    end
    if lane.traversalAction and Internal.updateTraversalAction then
        local traversalActive
        local traversalState
        traversalActive, traversalState = Internal.updateTraversalAction(
            zombie,
            record,
            lane,
            now
        )
        if traversalActive then
            Internal.logMoveDebug(
                record,
                zombie,
                lane,
                "special_progress",
                traversalState or lane.ownerMode,
                ""
            )
            return true, traversalState or lane.ownerMode
        end
        if traversalState == "completed" then
            Internal.logMoveDebug(
                record,
                zombie,
                lane,
                "special_complete",
                lane.lastTraversalFinishReason or "completed",
                ""
            )
            return true, "traversal_completed"
        end
    end
    local specialOwner = lane.ownerMode == "window_climb"
        or lane.ownerMode == "window_open"
        or lane.ownerMode == "window_smash"
        or lane.ownerMode == "door_open"
        or lane.ownerMode == "fence_climb"
    if specialOwner
        and now < (tonumber(lane.specialMoveUntil) or 0)
    then
        lane.lastProgressAt = now
        lane.lastIssueAt = now
        Internal.logMoveDebug(
            record,
            zombie,
            lane,
            "special_cooldown",
            lane.ownerMode,
            ""
        )
        return true, lane.ownerMode
    end
    return nil
end

function Internal.tryImmediateScriptedPassage(
    zombie,
    record,
    lane,
    goal,
    now
)
    if not Internal.tryDoorOrWindowInteraction then
        return nil
    end
    local label
    if lane.blockedStepToX ~= nil
        or Internal.hasClosedPassageToward
            and Internal.hasClosedPassageToward(
                zombie, goal.x, goal.y, goal.z
            )
    then
        label = "passage_interact"
    elseif Internal.isDoorCollision
        and Internal.isDoorCollision(zombie)
    then
        label = "collision_interact"
    else
        return nil
    end
    local interacted, interactType = tryPassage(
        zombie, record, lane, goal
    )
    if not interacted then
        return nil
    end
    if Internal.clearBlockedStep then
        Internal.clearBlockedStep(lane)
    end
    lane.lastIssueAt = now
    lane.lastProgressAt = now
    lane.noProgressCount = 0
    lane.lastStepAt = now
    lane.lastX = zombie:getX()
    lane.lastY = zombie:getY()
    setPassageOwner(lane, interactType, now)
    Internal.logMoveDebug(
        record,
        zombie,
        lane,
        label,
        interactType or "door_or_window",
        ""
    )
    return true, interactType or "interact"
end

function Internal.tryAdoptScriptedPassage(zombie, record, lane, goal, now)
    if (lane.lastActionState ~= "climbfence"
            and lane.lastActionState ~= "climbwindow")
        or not Internal.tryDoorOrWindowInteraction
    then
        return nil
    end
    local interacted, interactType = tryPassage(
        zombie, record, lane, goal
    )
    if not interacted then
        return nil
    end
    if Internal.clearBlockedStep then
        Internal.clearBlockedStep(lane)
    end
    lane.lastIssueAt = now
    lane.noProgressCount = 0
    if interactType == "fence_climb" then
        lane.ownerMode = "fence_climb"
    elseif interactType == "window_climb" then
        lane.ownerMode = "window_climb"
    elseif interactType == "door_open" then
        lane.ownerMode = "door_open"
    elseif interactType == "window_open" then
        lane.ownerMode = "window_open"
    elseif interactType == "window_smash" then
        lane.ownerMode = "window_smash"
    end
    Internal.logMoveDebug(
        record,
        zombie,
        lane,
        "adopt_traversal",
        interactType or lane.lastActionState,
        ""
    )
    return true, interactType or "traversal"
end

function Internal.tryStalledScriptedPassage(
    zombie,
    record,
    lane,
    goal,
    now,
    stepResult
)
    if stepResult == "throttle" then
        return nil
    end
    local blocked = stepResult == "blocked"
        or stepResult == "interaction_blocked"
        or stepResult == "stalled"
    if not blocked
        and (now - (tonumber(lane.lastProgressAt) or 0))
            < Internal.INTERACTION_STALL_MS
    then
        return nil
    end
    local interacted, interactType = tryPassage(
        zombie, record, lane, goal
    )
    if interacted then
        lane.lastIssueAt = now
        lane.lastProgressAt = now
        lane.noProgressCount = 0
        lane.lastStepAt = now
        lane.lastX = zombie:getX()
        lane.lastY = zombie:getY()
        setPassageOwner(lane, interactType, now)
        Internal.logMoveDebug(
            record,
            zombie,
            lane,
            "interact",
            interactType or "door_or_window",
            ""
        )
        return true, interactType or "interact"
    end
    if blocked then
        Internal.logMoveDebug(
            record,
            zombie,
            lane,
            "interact_rejected",
            stepResult,
            "goal=" .. Internal.describeGoal(goal)
        )
    end
    return nil
end
