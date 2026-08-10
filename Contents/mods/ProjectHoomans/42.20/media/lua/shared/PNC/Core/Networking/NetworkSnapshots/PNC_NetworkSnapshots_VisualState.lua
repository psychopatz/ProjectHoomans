--[[
    PNC Network Snapshots - Visual State
    Serializes movement, animation, scene, and native traversal state.
]]

local Network = PNC.Network
local Parts = Network.Internal.SnapshotParts
local Core = PNC.Core
local MotionHints = PNC.MotionHints

function Parts.BuildVisualState(record)
    local runtime = record and record.runtime or nil
    local path = runtime and runtime.pathing or nil
    local navigation = runtime
        and runtime.localNavigation or nil
    local attack = runtime and runtime.attackAction or nil
    local scene = runtime and runtime.animationScene or nil
    local sceneDebug = runtime
        and runtime.animationSceneDebug or nil
    local now = Core.Now()
    local healthState = record and record.health and tostring(record.health.state or "normal") or "normal"
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
    local mode = moving and tostring(path.resolvedMode or path.mode or "walk") or nil
    local walkType = moving and tostring(path.walkType or "") or ""
    local moveAnim = moving and tostring(path.moveAnim or "") or ""
    local engineWalkType = moving and tostring(path.engineWalkType or "") or ""
    local anim = "Idle"
    -- A composite scene remains authoritative during its short inter-step
    -- gap even though no bump selector is active in that interval.
    local sceneActive = scene ~= nil
    local specialActive = path ~= nil and now < (tonumber(path.specialMoveUntil) or 0)
    local nativeTraversalState = navigation
        and navigation.nativeTraversalState or nil
    local nativeTraversalActive =
        nativeTraversalState ~= nil
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
    local motionHint = path and MotionHints and MotionHints.BuildNetworkHint and MotionHints.BuildNetworkHint(record, path, now) or nil
    local travelDirX = tonumber(motionHint and motionHint.dirX) or tonumber(path and path.lastFacingDirX)
    local travelDirY = tonumber(motionHint and motionHint.dirY) or tonumber(path and path.lastFacingDirY)
    local travelLen = travelDirX and travelDirY and math.sqrt((travelDirX * travelDirX) + (travelDirY * travelDirY)) or 0
    local facingDirX = tonumber(path and path.lastFacingDirX)
    local facingDirY = tonumber(path and path.lastFacingDirY)

    if travelLen > 0.0001 then
        travelDirX = travelDirX / travelLen
        travelDirY = travelDirY / travelLen
    else
        travelDirX = nil
        travelDirY = nil
    end

    if healthState == "incapacitated" then
        walkType = moving and tostring(path and path.walkType or "Crawl") or ""
        moveAnim = moving and tostring(path and path.moveAnim or "Crawl") or ""
        engineWalkType = moving and tostring(path and path.engineWalkType or "") or ""
        anim = moving and moveAnim or "Downed"
        isCrawling = moving
        profileKey = moving and tostring(path and path.profileKey or "crawl") or "downed"
    elseif moving then
        anim = moveAnim ~= "" and moveAnim or "Walk"
    end

    if specialActive and path and path.specialAnim then
        anim = tostring(path.specialAnim)
        moving = false
        walkType = ""
        moveAnim = ""
        engineWalkType = ""
    end

    if sceneActive and scene and scene.bump then
        anim = tostring(scene.bump)
        moving = false
        walkType = ""
        moveAnim = ""
        engineWalkType = ""
    end

    if attackActive and attack and attack.anim then
        anim = tostring(attack.anim)
    end

    return {
        moving = moving,
        mode = mode,
        walkType = walkType,
        moveAnim = moveAnim,
        engineWalkType = engineWalkType,
        anim = anim,
        attackActive = attackActive,
        attackAnim = attack and attack.anim or nil,
        attackStartedAt = attack and attack.startedAt or 0,
        attackHitAt = attack and attack.hitAt or 0,
        attackFinishAt = attack and attack.finishAt or 0,
        animSpeed = animSpeed,
        isRunning = isRunning,
        isCrawling = isCrawling,
        profileKey = profileKey,
        motionHint = motionHint,
        travelDirX = travelDirX,
        travelDirY = travelDirY,
        facingDirX = facingDirX,
        facingDirY = facingDirY,
        facingOwner = path and path.facingOwner or nil,
        stationaryFacing = not moving and path and path.facingOwner == "behavior_idle" or false,
        specialActive = specialActive,
        specialAnim = specialActive and path and path.specialAnim or nil,
        specialFinishAt = specialActive and path and path.specialMoveUntil or 0,
        sceneActive = sceneActive,
        sceneId = sceneActive and scene and scene.id or nil,
        sceneBump = sceneActive and scene and scene.bump or nil,
        sceneRevision = sceneActive
            and scene and scene.revision or 0,
        scenePlaybackRevision = sceneActive
            and scene and scene.playbackRevision or 0,
        sceneStartedAt = sceneActive
            and scene and scene.startedAt or 0,
        sceneStepStartedAt = sceneActive
            and scene and scene.stepStartedAt or 0,
        sceneFinishAt = sceneActive
            and scene and scene.finishAt or 0,
        sceneNextStepAt = sceneActive
            and scene and scene.nextStepAt or 0,
        sceneStepId = sceneActive
            and scene and scene.stepId or nil,
        sceneStepPosition = sceneActive
            and scene and scene.stepPosition or 0,
        sceneStepCount = sceneActive
            and scene and scene.sequenceLength or 0,
        sceneSequenceIteration = sceneActive
            and scene and scene.sequenceIteration or 0,
        sceneRepeatMode = sceneActive
            and scene and scene.repeatMode or "once",
        sceneSequenceLoop = sceneActive
            and scene and scene.repeatMode == "loop" or false,
        sceneLoop = sceneActive
            and scene and scene.loop == true or false,
        sceneBlocking = sceneActive
            and scene and scene.blocking == true or false,
        scenePriority = sceneActive
            and scene and scene.priority or 0,
        sceneDebug = sceneDebug and {
            active = sceneDebug.active == true,
            mode = sceneDebug.mode,
            pool = sceneDebug.pool,
            gapMs = sceneDebug.gapMs,
            nextAt = sceneDebug.nextAt,
            lastSceneId = sceneDebug.lastSceneId,
            completedCount =
                sceneDebug.completedCount,
            lastError = sceneDebug.lastError,
        } or nil,
        nativeTraversalActive = nativeTraversalActive,
        nativeTraversalState = nativeTraversalState,
        nativeMoveActive = nativeMoveActive,
        nativeMoveX = nativeMoveActive
            and navigation.requestX or nil,
        nativeMoveY = nativeMoveActive
            and navigation.requestY or nil,
        nativeMoveZ = nativeMoveActive
            and navigation.requestZ or nil,
        nativeMoveStopDistance = nativeMoveActive
            and navigation.requestStopDistance or nil,
        nativeMoveRevision = nativeMoveActive
            and navigation.requestRevision or 0,
    }
end

return Parts
