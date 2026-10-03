-- Serializes the internal visual-state context into the public snapshot shape.

if not PNC or not PNC.Network
    or not PNC.Network.Internal
    or not PNC.Network.Internal.SnapshotParts
then return end

local Network = PNC.Network
local Parts = Network.Internal.SnapshotParts

local function buildAttackAudio(attack)
    local audio = attack and attack.audio or nil
    if type(audio) ~= "table" then return nil end
    return {
        sequence = audio.sequence,
        swingSound = audio.swingSound,
        voiceSuffix = audio.voiceSuffix,
        hitSequence = audio.hitSequence,
        hitSound = audio.hitSound,
    }
end

function Parts.BuildVisualStatePayload(context)
    context = type(context) == "table" and context or {}
    local path = context.path
    local navigation = context.navigation
    local attack = context.attack
    local scene = context.scene
    local sceneDebug = context.sceneDebug
    local moving = context.moving
    local mode = context.mode
    local walkType = context.walkType
    local moveAnim = context.moveAnim
    local engineWalkType = context.engineWalkType
    local anim = context.anim
    local attackActive = context.attackActive
    local animSpeed = context.animSpeed
    local isRunning = context.isRunning
    local isCrawling = context.isCrawling
    local profileKey = context.profileKey
    local motionHint = context.motionHint
    local travelDirX = context.travelDirX
    local travelDirY = context.travelDirY
    local facingDirX = context.facingDirX
    local facingDirY = context.facingDirY
    local sceneActive = context.sceneActive
    local specialActive = context.specialActive
    local nativeTraversalActive = context.nativeTraversalActive
    local nativeTraversalState = context.nativeTraversalState
    local nativeMoveActive = context.nativeMoveActive
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
        attackAudio = buildAttackAudio(attack),
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
        stationaryFacing = not moving and path
            and path.facingOwner == "behavior_idle" or false,
        specialActive = specialActive,
        specialAnim = specialActive and path and path.specialAnim or nil,
        specialFinishAt = specialActive
            and path and path.specialMoveUntil or 0,
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
            completedCount = sceneDebug.completedCount,
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
