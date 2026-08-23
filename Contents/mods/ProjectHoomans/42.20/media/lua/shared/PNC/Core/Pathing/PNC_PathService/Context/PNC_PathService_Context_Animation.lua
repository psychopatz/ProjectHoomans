-- Moving and stationary visual presentation for PathService lanes.

PNC = PNC or {}
PNC.PathService = PNC.PathService or {}
PNC.PathService.Internal = PNC.PathService.Internal or {}

local Internal = PNC.PathService.Internal
local Core = Internal.Core
local Animation = Internal.Animation
local MotionHints = Internal.MotionHints

function Internal.setWalkAnim(zombie, record, mode, force)
    local lane = record and record.runtime and record.runtime.pathing or nil
    local profile = lane and lane.motionProfile or nil
    local moveAnim = profile and profile.moveAnim or "Walk"
    -- Engine paths must never pass through the fake-locomotion animator.
    -- Animation.Apply writes bMoving/setMoving and creates WalkTowardState;
    -- PathFindBehavior2 then owns path2 at the same time, which the engine
    -- rejects in IsoGameCharacter.doDeferredMovement.
    if lane
        and lane.navigationProvider == "engine_path"
        and Animation
        and Animation.SyncNativeLocomotionStyle
    then
        Animation.SyncNativeLocomotionStyle(zombie, record)
        return
    end
    -- BumpType is an exclusive special-action channel, not a locomotion
    -- transition channel. Starting a bump for every short movement request
    -- masked the walk cycle and made frequently refreshed follow goals glide.
    -- Explicit combat/traversal bumps remain owned by PNC.Animation.PlayBump.
    if Animation and Animation.Apply then
        Animation.Apply(zombie, record, moveAnim, profile, true)
    end
    if Animation and Animation.SyncLocomotion then
        Animation.SyncLocomotion(zombie, record)
    end
end

function Internal.applyHoldAnimation(zombie, record, lane)
    local healthState = record and record.health and tostring(record.health.state or "normal") or "normal"
    local attackAction = record and record.runtime and record.runtime.attackAction or nil
    local animationScene = record and record.runtime
        and record.runtime.animationScene or nil
    local profile = lane and lane.motionProfile or nil
    if not zombie or not record then
        return
    end
    if attackAction and Core.Now() < (tonumber(attackAction.finishAt) or 0) then
        return
    end
    if animationScene and animationScene.bump then
        -- AnimationScenes owns stationary presentation while a work/social
        -- scene is active. Applying the path lane's Idle pose here would
        -- replace Hammer/HammerLow immediately after they are requested.
        if lane and MotionHints and MotionHints.Clear then
            MotionHints.Clear(lane)
        end
        return
    end
    if lane and Core.Now() < (tonumber(lane.visualMovingUntil) or 0) then
        if Animation and Animation.Apply then
            Animation.Apply(zombie, record, lane.moveAnim or "Walk", lane.motionProfile, true)
        end
        if Animation and Animation.SyncLocomotion then
            Animation.SyncLocomotion(zombie, record)
        end
        return
    end
    if lane then
        if MotionHints and MotionHints.Clear then
            MotionHints.Clear(lane)
        end
    end
    if healthState == "incapacitated" and Animation and Animation.ApplyDowned then
        Animation.ApplyDowned(zombie, record, false)
        return
    end
    Animation.Apply(zombie, record, "Idle", profile, false)
end
