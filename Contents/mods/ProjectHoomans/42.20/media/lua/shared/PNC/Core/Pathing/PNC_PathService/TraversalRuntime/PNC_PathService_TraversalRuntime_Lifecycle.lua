-- Traversal action acquisition and release.

PNC = PNC or {}
PNC.PathService = PNC.PathService or {}
PNC.PathService.Internal = PNC.PathService.Internal or {}

local Internal = PNC.PathService.Internal
local Runtime = Internal.TraversalRuntime
local Animation = PNC.Animation
local LiveBodyControl = PNC.LiveBodyControl
local TraversalAction = PNC.TraversalAction

function Internal.clearTraversalAction(zombie, lane, reason)
    if not lane then return end
    if Animation and Animation.FinishBump then
        Animation.FinishBump(zombie, true)
    end
    Runtime.resetTraversalVariables(zombie)
    lane.traversalAction = nil
    lane.specialMoveUntil = 0
    lane.specialAnim = nil
    lane.ownerMode = "fake_locomotion"
    lane.lastTraversalFinishReason = reason or "completed"
    if lane.lastSpecialActionKey then
        lane.lastSpecialActionAt = Internal.Core.Now()
    end
end

function Internal.beginTraversalAction(zombie, record, lane, spec)
    local now
    local hardTimeoutMs
    if LiveBodyControl
        and LiveBodyControl.IsMultiplayer
        and LiveBodyControl.IsMultiplayer()
    then
        return false
    end
    if not zombie or not record or not lane or type(spec) ~= "table" then
        return false
    end
    if PNC.EnginePathPlanner and PNC.EnginePathPlanner.Invalidate then
        PNC.EnginePathPlanner.Invalidate(
            record,
            "scripted_" .. tostring(spec.kind or "traversal"),
            zombie
        )
    end
    now = Internal.Core.Now()
    lane.traversalAction = TraversalAction.Create(
        spec,
        now,
        zombie:getX(),
        zombie:getY(),
        zombie:getZ()
    )
    hardTimeoutMs = lane.traversalAction.hardFinishAt - now
    lane.specialMoveUntil = now + hardTimeoutMs
    lane.specialAnim = lane.traversalAction.anim
    lane.ownerMode = lane.traversalAction.kind
    lane.lastProgressAt = now
    lane.lastIssueAt = now
    Runtime.resetTraversalVariables(zombie)
    if zombie.setVariable then
        zombie:setVariable(Runtime.KIND_VARIABLE, lane.traversalAction.kind)
    end
    if zombie.setTarget then zombie:setTarget(nil) end
    if zombie.setPath2 then zombie:setPath2(nil) end
    if LiveBodyControl and LiveBodyControl.SetManagedBodyUseless then
        LiveBodyControl.SetManagedBodyUseless(zombie, true)
    end
    if zombie.setRunning then zombie:setRunning(false) end
    if LiveBodyControl and LiveBodyControl.SuppressZombieState then
        LiveBodyControl.SuppressZombieState(zombie, lane, now)
    end
    Runtime.resetEngineTraversalVariables(zombie, lane.traversalAction.kind)
    if Internal.applyFacingLocation then
        Internal.applyFacingLocation(
            zombie,
            lane,
            lane.traversalAction.endX,
            lane.traversalAction.endY,
            now,
            "traversal",
            true
        )
    end
    if Animation and Animation.PlayBump then
        Animation.PlayBump(
            zombie,
            record,
            lane.traversalAction.twoPhase
                and lane.traversalAction.startAnim
                or lane.traversalAction.anim,
            {
                keepManagedUseless = true,
                leaseUntil = lane.traversalAction.hardFinishAt,
            }
        )
    elseif zombie.setBumpType then
        zombie:setBumpType(lane.traversalAction.anim)
    end
    if Internal.MotionHints and Internal.MotionHints.Remember then
        Internal.MotionHints.Remember(
            lane,
            lane.traversalAction.startX,
            lane.traversalAction.startY,
            lane.traversalAction.startZ,
            lane.traversalAction.endX,
            lane.traversalAction.endY,
            lane.traversalAction.endZ,
            now,
            {
                durationMs = lane.traversalAction.travelDurationMs,
                kind = lane.traversalAction.kind,
                profile = lane.motionProfile,
            }
        )
    end
    return true
end
