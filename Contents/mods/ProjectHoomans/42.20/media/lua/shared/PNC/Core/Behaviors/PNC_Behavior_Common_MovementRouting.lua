-- Live movement route handoff for the shared behavior helper.
-- Keep scene interruption and navigation steering together so a movement tick
-- cannot update one ownership layer while leaving the other on stale state.
PNC = PNC or {}
PNC.BehaviorCommon = PNC.BehaviorCommon or {}

local Common = PNC.BehaviorCommon
local H = Common.Internal and Common.Internal.MovementRouting
if type(H) ~= "table" then return Common end

local NavigationRouter = H.NavigationRouter

local function closeEnough(left, right, tolerance)
    left, right = tonumber(left), tonumber(right)
    return left ~= nil and right ~= nil
        and math.abs(left - right) <= (tonumber(tolerance) or 0.2)
end

local function sameMoveTarget(record, x, y, z, mode, stopDistance)
    local intent = record and record.runtime
        and record.runtime.moveIntent or nil
    if not intent or intent.kind ~= "move" then return false end
    return closeEnough(intent.finalX or intent.x, x)
        and closeEnough(intent.finalY or intent.y, y)
        and closeEnough(intent.finalZ or intent.z, z, 0.05)
        and tostring(intent.mode or "walk") == tostring(mode or "walk")
        and closeEnough(intent.stopDistance or 0.7, stopDistance or 0.7,
            0.05)
end

local function shouldInterruptScene(record, x, y, z, mode, stopDistance)
    local runtime = record and record.runtime or nil
    local scene = runtime and runtime.animationScene or nil
    local intent = runtime and runtime.moveIntent or nil
    if not scene then return false end
    if not sameMoveTarget(record, x, y, z, mode, stopDistance) then
        return true
    end
    -- A scene started after the last identical movement intent (for example a
    -- combat/action bump) still needs one interruption. Once that transition
    -- has happened, repeated movement ticks must not reset the scene again.
    return tonumber(scene.startedAt) ~= nil
        and tonumber(intent and intent.updatedAt) ~= nil
        and tonumber(scene.startedAt) > tonumber(intent.updatedAt)
end

function H.Apply(
    record,
    zombie,
    finalX,
    finalY,
    finalZ,
    mode,
    stopDistance,
    moveReason,
    navigationOptions,
    controlOwner
)
    local tx = finalX
    local ty = finalY
    local tz = finalZ
    local policyName
    local providerName
    local policy
    local steeringTarget
    local intentNavigation = navigationOptions
    if shouldInterruptScene(record, finalX, finalY, finalZ, mode,
        stopDistance)
        and PNC.AnimationScenes
        and PNC.AnimationScenes.Interrupt
    then
        PNC.AnimationScenes.Interrupt(
            record,
            zombie,
            "movement"
        )
    end
    if NavigationRouter and NavigationRouter.Resolve then
        policyName, providerName, policy = NavigationRouter.Resolve(
            record,
            moveReason,
            navigationOptions,
            zombie
        )
        -- The direct route is allocation-free. This is the normal combat
        -- and kiting path, where goals can change on every behavior tick.
        if providerName ~= NavigationRouter.DIRECT_PROVIDER
            and NavigationRouter.GetSteeringTarget
        then
            steeringTarget = NavigationRouter.GetSteeringTarget(
                record,
                zombie,
                {
                    x = finalX,
                    y = finalY,
                    z = finalZ,
                    mode = mode,
                    stopDistance = stopDistance,
                },
                policyName,
                providerName,
                policy,
                controlOwner
            )
            if steeringTarget then
                tx = steeringTarget.x
                ty = steeringTarget.y
                tz = steeringTarget.z
                mode = steeringTarget.mode or mode
                stopDistance = steeringTarget.stopDistance
                    or stopDistance
            end
        end
            if providerName ~= NavigationRouter.DIRECT_PROVIDER then
            intentNavigation = {
                navigationPolicy = policyName,
                navigationProvider = providerName,
                finalX = finalX,
                finalY = finalY,
                finalZ = finalZ,
                targetKind = navigationOptions
                    and navigationOptions.targetKind or nil,
                targetValidation = navigationOptions
                    and navigationOptions.targetValidation or nil,
                targetWaterX = navigationOptions
                    and navigationOptions.targetWaterX or nil,
                targetWaterY = navigationOptions
                    and navigationOptions.targetWaterY or nil,
                targetWaterZ = navigationOptions
                    and navigationOptions.targetWaterZ or nil,
                waypointIndex = steeringTarget
                    and steeringTarget.waypointIndex or nil,
                steeringIndex = steeringTarget
                    and steeringTarget.steeringIndex or nil,
                steeringKind = steeringTarget
                    and steeringTarget.steeringKind or nil,
            }
        end
    end
    return tx, ty, tz, mode, stopDistance, intentNavigation
end

return Common
