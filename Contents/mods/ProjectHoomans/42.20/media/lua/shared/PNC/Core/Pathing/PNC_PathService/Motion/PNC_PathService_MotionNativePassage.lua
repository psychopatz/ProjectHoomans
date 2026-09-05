-- Motion provider: passage recovery for the native engine-path executor.

local Internal = PNC.PathService.Internal

local function shouldProbeNativePassage(zombie, lane, now)
    local blocked = lane and lane.blockedStepToX ~= nil
    local collided = Internal.isDoorCollision
        and Internal.isDoorCollision(zombie) or false
    local fresh = lane and lane.nextPassageProbeAt == nil
    local stalled = lane
        and now - (tonumber(lane.lastGoalProgressAt) or now)
            >= Internal.INTERACTION_STALL_MS
    if not blocked and not collided and not fresh and not stalled then
        return false
    end
    return not Internal.PassageProbeAllowed
        or Internal.PassageProbeAllowed(lane, now)
end

function Internal.tryNativeAdjacentPassage(
    record,
    zombie,
    lane,
    enginePlanner,
    now
)
    local closedPassage
    local passage
    if not lane.goal or not Internal.hasClosedPassageToward
        or not Internal.tryDoorOrWindowInteraction
    then
        return nil
    end
    if not shouldProbeNativePassage(zombie, lane, now) then
        return nil
    end
    closedPassage, passage = Internal.hasClosedPassageToward(
        zombie,
        lane.goal.x,
        lane.goal.y,
        lane.goal.z
    )
    if not closedPassage then return nil end
    local interacted, kind = Internal.tryDoorOrWindowInteraction(
        zombie,
        record,
        lane,
        lane.goal.x,
        lane.goal.y,
        lane.goal.z,
        passage
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
    lane.nativeStallRecoveryCount = 0
    lane.nativeBackoffUntil = 0
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
    if Internal.PassageProbeAllowed
        and not Internal.PassageProbeAllowed(lane, now)
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
    lane.nativeStallRecoveryCount = 0
    lane.nativeBackoffUntil = 0
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
