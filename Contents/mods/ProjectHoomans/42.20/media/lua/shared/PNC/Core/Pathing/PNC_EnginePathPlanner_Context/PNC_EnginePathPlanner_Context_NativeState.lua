PNC = PNC or {}
PNC.EnginePathPlanner = PNC.EnginePathPlanner or {}
PNC.EnginePathPlanner.Internal = PNC.EnginePathPlanner.Internal or {}

local Internal = PNC.EnginePathPlanner.Internal

function Internal.GetPathBehavior(body)
    return body and body.getPathFindBehavior2
        and body:getPathFindBehavior2() or nil
end

-- Match ZAMove.onWorking's collision gate. A manual Behavior2 owner must not
-- advance another frame after contact; PathService gets that frame to adopt
-- the door/window/fence into its safe scripted traversal lane.
function Internal.IsBodyCollided(body)
    if not body then return false end
    local collidedWithDoor = body.isCollidedWithDoor
    if type(collidedWithDoor) == "function"
        and collidedWithDoor(body) == true
    then
        return true
    end
    local collidedThisFrame = body.isCollidedThisFrame
    if type(collidedThisFrame) == "function"
        and collidedThisFrame(body) == true
    then
        return true
    end
    local collided = body.isCollided
    return type(collided) == "function"
        and collided(body) == true
        or collided == true
end

function Internal.GetNativeTraversalState(body)
    local state = body and body.getActionStateName
        and string.lower(tostring(body:getActionStateName() or ""))
        or ""
    if state == "climbfence"
        or state == "climbwindow"
        or state == "climbwall"
    then
        return state
    end
    return nil
end

function Internal.GetNativeMovementState(body)
    local state = body and body.getActionStateName
        and string.lower(tostring(body:getActionStateName() or ""))
        or ""
    if state == "pathfind" then return state end
    return Internal.GetNativeTraversalState(body)
end

function Internal.IsAtRequestGoal(body, navigation)
    if not body or not navigation then return false end
    local requestZ = tonumber(navigation.requestZ) or body:getZ()
    if math.abs(body:getZ() - requestZ) >= 0.5 then return false end
    local dx = (tonumber(navigation.requestX) or body:getX()) - body:getX()
    local dy = (tonumber(navigation.requestY) or body:getY()) - body:getY()
    local stopDistance = math.max(
        0.1,
        tonumber(navigation.requestStopDistance) or 0.7
    )
    return (dx * dx) + (dy * dy) <= stopDistance * stopDistance
end

function Internal.ResultMatches(result, name)
    if BehaviorResult and BehaviorResult[name] ~= nil then
        return result == BehaviorResult[name]
    end
    local value = tostring(result or "")
    return value == name or value == ("BehaviorResult." .. name)
end

return Internal
