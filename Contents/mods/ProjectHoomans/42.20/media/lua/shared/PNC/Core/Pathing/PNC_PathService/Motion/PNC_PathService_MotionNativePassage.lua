-- Motion provider: passage recovery for the native engine-path executor.

local Internal = PNC.PathService.Internal

function Internal.tryNativeAdjacentPassage(
    record,
    zombie,
    lane,
    enginePlanner,
    now
)
    if not lane.goal
        or not Internal.hasClosedPassageToward
        or not Internal.hasClosedPassageToward(
            zombie,
            lane.goal.x,
            lane.goal.y,
            lane.goal.z
        )
        or not Internal.tryDoorOrWindowInteraction
    then
        return nil
    end
    local interacted, kind = Internal.tryDoorOrWindowInteraction(
        zombie,
        record,
        lane,
        lane.goal.x,
        lane.goal.y,
        lane.goal.z
    )
    if not interacted then
        return nil
    end
    if Internal.clearBlockedStep then
        Internal.clearBlockedStep(lane)
    end
    if enginePlanner.Invalidate then
        enginePlanner.Invalidate(
            record,
            "native_" .. tostring(kind),
            zombie
        )
    end
    lane.ownerMode = kind or "passage_interact"
    lane.lastProgressAt = now
    lane.lastIssueAt = now
    Internal.logMoveDebug(
        record,
        zombie,
        lane,
        "native_passage_interact",
        kind or "passage",
        ""
    )
    return true, kind or "passage_interact"
end

function Internal.tryNativeStallPassage(
    record,
    zombie,
    lane,
    enginePlanner,
    now,
    nativeTraversalState
)
    if nativeTraversalState ~= nil
        or now - (tonumber(lane.lastGoalProgressAt) or now)
            < Internal.INTERACTION_STALL_MS
        or not Internal.tryDoorOrWindowInteraction
    then
        return nil
    end
    local interacted, kind = Internal.tryDoorOrWindowInteraction(
        zombie,
        record,
        lane,
        lane.goal.x,
        lane.goal.y,
        lane.goal.z
    )
    if not interacted then
        return nil
    end
    if Internal.clearBlockedStep then
        Internal.clearBlockedStep(lane)
    end
    if enginePlanner.Invalidate then
        enginePlanner.Invalidate(
            record,
            "native_stall_" .. tostring(kind),
            zombie
        )
    end
    lane.ownerMode = kind or "passage_interact"
    lane.lastProgressAt = now
    lane.lastGoalProgressAt = now
    lane.noProgressCount = 0
    Internal.logMoveWarning(
        record,
        zombie,
        lane,
        "native_stall_recovery",
        kind or "passage",
        "goal=" .. Internal.describeGoal(lane.goal)
    )
    return true, kind or "passage_interact"
end
