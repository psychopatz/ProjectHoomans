-- Gathers the movement, traversal, attack, and scene context used by the
-- visual-state serializer. It does not define the network payload shape.

if not PNC or not PNC.Network
    or not PNC.Network.Internal
    or not PNC.Network.Internal.SnapshotParts
then return end

local Network = PNC.Network
local Parts = Network.Internal.SnapshotParts
local Core = PNC.Core
if not Parts.BuildVisualStateMotionContext then
    require "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_VisualState_MotionContext"
end

function Parts.BuildVisualStateContext(record)
    local runtime = record and record.runtime or nil
    local path = runtime and runtime.pathing or nil
    local navigation = runtime
        and runtime.localNavigation or nil
    local attack = runtime and runtime.attackAction or nil
    local scene = runtime and runtime.animationScene or nil
    local sceneDebug = runtime
        and runtime.animationSceneDebug or nil
    local now = Core.Now()
    local healthState = record and record.health
        and tostring(record.health.state or "normal") or "normal"
    if type(Parts.BuildVisualStateMotionContext) ~= "function" then
        return nil
    end
    local motion = Parts.BuildVisualStateMotionContext(
        record,
        path,
        navigation,
        attack,
        now
    )
    local moving = motion.moving
    local mode = motion.mode
    local walkType = motion.walkType
    local moveAnim = motion.moveAnim
    local engineWalkType = motion.engineWalkType
    local anim = motion.anim
    -- A composite scene remains authoritative during its short inter-step
    -- gap even though no bump selector is active in that interval.
    local sceneActive = scene ~= nil
    local specialActive = motion.specialActive
    local nativeTraversalActive = motion.nativeTraversalActive
    local nativeTraversalState = motion.nativeTraversalState
    local nativeMoveActive = motion.nativeMoveActive
    local attackActive = motion.attackActive
    local animSpeed = motion.animSpeed
    local profileKey = motion.profileKey
    local isRunning = motion.isRunning
    local isCrawling = motion.isCrawling
    local motionHint = motion.motionHint
    local travelDirX = motion.travelDirX
    local travelDirY = motion.travelDirY
    local facingDirX = motion.facingDirX
    local facingDirY = motion.facingDirY

    if healthState == "incapacitated" then
        walkType = moving
            and tostring(path and path.walkType or "Crawl") or ""
        moveAnim = moving
            and tostring(path and path.moveAnim or "Crawl") or ""
        engineWalkType = moving
            and tostring(path and path.engineWalkType or "") or ""
        anim = moving and moveAnim or "Downed"
        isCrawling = moving
        profileKey = moving
            and tostring(path and path.profileKey or "crawl") or "downed"
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
        path = path,
        navigation = navigation,
        attack = attack,
        scene = scene,
        sceneDebug = sceneDebug,
        moving = moving,
        mode = mode,
        walkType = walkType,
        moveAnim = moveAnim,
        engineWalkType = engineWalkType,
        anim = anim,
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
        sceneActive = sceneActive,
        specialActive = specialActive,
        nativeTraversalActive = nativeTraversalActive,
        nativeTraversalState = nativeTraversalState,
        nativeMoveActive = nativeMoveActive,
    }
end

return Parts
