PNC = PNC or {}
PNC.Animation = PNC.Animation or {}
PNC.Animation.Internal = PNC.Animation.Internal or {}

local Animation = PNC.Animation
local Internal = Animation.Internal
local Core = PNC.Core
local Const = PNC.Const or {}
local LiveBodyControl = PNC.LiveBodyControl
local LocomotionProfiles = PNC.LocomotionProfiles
local AnimationTrace = PNC.AnimationTrace

function Animation.SyncNativeLocomotionStyle(zombie, record)
    local runtime
    local navigation
    local path
    local profile
    local moveAnim
    local walkType
    local engineWalkType
    local animSpeed
    local actionState
    local nativeMoving
    local now
    local progressAt
    local progressFresh
    if not zombie then
        return
    end
    if Animation.IsBumpActionActive(zombie) then
        Internal.applyBumpLeaseBodyMode(zombie)
        return false
    end
    runtime = record and record.runtime or nil
    navigation = runtime and runtime.localNavigation or nil
    path = runtime and runtime.pathing or nil
    now = Core and Core.Now and Core.Now() or 0
    profile = path and path.motionProfile or nil
    moveAnim = profile and profile.moveAnim
        or path and path.moveAnim
        or "Walk"
    walkType = profile and profile.walkType
        or path and path.walkType
        or ""
    engineWalkType = profile and profile.engineWalkType
        or path and path.engineWalkType
        or walkType
    animSpeed = tonumber(
        profile and profile.animSpeed
            or path and path.animSpeed
    ) or 1.0
    actionState = Internal.getActionStateName(zombie)
    progressAt = tonumber(navigation and navigation.lastPhysicalProgressAt)
        or tonumber(path and path.lastPhysicalMoveAt)
        or 0
    progressFresh = progressAt > 0 and now - progressAt < math.max(
        250,
        tonumber(Const.CLIENT_NATIVE_MOVEMENT_LEASE_MS) or 750
    )
    nativeMoving = actionState ~= "bumped"
        and (
            zombie.isMoving and zombie:isMoving() == true
            or actionState == "climbfence"
            or actionState == "climbwindow"
            or actionState == "climbwall"
            or zombie.getPath2
                and zombie:getPath2() ~= nil
                and progressFresh
        )
    Internal.setPNCStateVars(
        zombie,
        record,
        profile and profile.moveAnim or moveAnim
    )
    if zombie.setVariable then
        zombie:setVariable("PNCMoveAnim", tostring(moveAnim or "Walk"))
        zombie:setVariable("PNCWalkType", tostring(walkType or ""))
        zombie:setVariable(
            "PNCEngineWalkType",
            tostring(engineWalkType or "")
        )
        zombie:setVariable("PNCAnimSpeed", animSpeed)
        zombie:setVariable(
            "PNCIsRunning",
            profile and profile.isRunning == true
                or path and path.isRunning == true
                or false
        )
        zombie:setVariable(
            "PNCIsCrawling",
            profile and profile.isCrawling == true
                or path and path.isCrawling == true
                or false
        )
        -- A published native goal is an intent, not proof of movement. Keep
        -- the run/walk selector idle while PathFindBehavior2 is dropped or
        -- waiting for a retry, otherwise the body loops Bob_Run against a
        -- wall with isMoving=false indefinitely.
        zombie:setVariable("PNCMoving", nativeMoving == true)
    end
    Internal.applyWalkType(zombie, engineWalkType, animSpeed)
    -- Manual Behavior2 movement follows Bandits' SP body mode: keep the
    -- IsoZombie useless so its normal Java update cannot concurrently consume
    -- path2 and force WalkTowardState. Client-delegated MP movement still
    -- requires a useful body because PathFindState is the movement owner.
    if navigation
        and navigation.controllerMode == "behavior2_move"
    then
        Internal.setManagedUseless(zombie, true, false)
    else
        Internal.setManagedUseless(zombie, false, true)
    end
end
