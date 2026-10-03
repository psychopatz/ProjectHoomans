-- Gathers path, facing, native traversal, and motion-hint state for visual
-- serialization. Health, scene, and attack overlays remain in the coordinator.

if not PNC or not PNC.Network
    or not PNC.Network.Internal
    or not PNC.Network.Internal.SnapshotParts
then return end

local Network = PNC.Network
local Parts = Network.Internal.SnapshotParts
local MotionHints = PNC.MotionHints

function Parts.BuildVisualStateMotionContext(
    record,
    path,
    navigation,
    attack,
    now
)
    local pathIntentMoving = path and (
        path.phase == "requested"
        or path.phase == "active"
    ) or false
    local fakeLocomotion = path
        and path.ownerMode == "fake_locomotion"
        or false
    local moving = path and (
        now < (tonumber(path.visualMovingUntil) or 0)
        or (pathIntentMoving and not fakeLocomotion)
    ) or false
    local mode = moving
        and tostring(path.resolvedMode or path.mode or "walk") or nil
    local walkType = moving and tostring(path.walkType or "") or ""
    local moveAnim = moving and tostring(path.moveAnim or "") or ""
    local engineWalkType = moving
        and tostring(path.engineWalkType or "") or ""
    local specialActive = path ~= nil
        and now < (tonumber(path.specialMoveUntil) or 0)
    local nativeTraversalState = navigation
        and navigation.nativeTraversalState or nil
    local nativeTraversalActive = nativeTraversalState ~= nil
    -- A native climb/fence action already owns the zombie action graph.
    -- Publishing an overlapping attack bump makes clients replace ClimbWindow
    -- with the combat selector midway through traversal.
    local attackActive = not nativeTraversalActive
        and attack ~= nil
        and now < (tonumber(attack.finishAt) or 0)
    local nativeMoveActive = moving
        and navigation
        and navigation.nativeActive == true
        and navigation.clientDelegated == true
        or false
    local animSpeed = path and tonumber(path.animSpeed) or 1.0
    local profileKey = path and tostring(path.profileKey or "") or ""
    local isRunning = path and path.isRunning == true or false
    local isCrawling = path and path.isCrawling == true or false
    local motionHint = path and MotionHints
        and MotionHints.BuildNetworkHint
        and MotionHints.BuildNetworkHint(record, path, now) or nil
    local travelDirX = tonumber(motionHint and motionHint.dirX)
        or tonumber(path and path.lastFacingDirX)
    local travelDirY = tonumber(motionHint and motionHint.dirY)
        or tonumber(path and path.lastFacingDirY)
    local travelLen = travelDirX and travelDirY
        and math.sqrt((travelDirX * travelDirX)
            + (travelDirY * travelDirY)) or 0
    local facingDirX = tonumber(path and path.lastFacingDirX)
    local facingDirY = tonumber(path and path.lastFacingDirY)
    if travelLen > 0.0001 then
        travelDirX = travelDirX / travelLen
        travelDirY = travelDirY / travelLen
    else
        travelDirX = nil
        travelDirY = nil
    end
    return {
        moving = moving,
        mode = mode,
        walkType = walkType,
        moveAnim = moveAnim,
        engineWalkType = engineWalkType,
        anim = "Idle",
        attackActive = attackActive,
        animSpeed = animSpeed,
        isRunning = isRunning,
        isCrawling = isCrawling,
        profileKey = profileKey,
        motionHint = motionHint,
        travelDirX = travelDirX,
        travelDirY = travelDirY,
        facingDirX = facingDirX,
        facingDirY = facingDirY,
        specialActive = specialActive,
        nativeTraversalActive = nativeTraversalActive,
        nativeTraversalState = nativeTraversalState,
        nativeMoveActive = nativeMoveActive,
    }
end

return Parts
