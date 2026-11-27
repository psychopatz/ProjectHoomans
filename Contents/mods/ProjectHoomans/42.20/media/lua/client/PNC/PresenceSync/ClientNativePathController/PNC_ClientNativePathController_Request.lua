--[[
    PNC Client Native Path Controller: engine request submission
]]

PNC = PNC or {}
PNC.ClientPresenceSync = PNC.ClientPresenceSync or {}
PNC.ClientPresenceSync.Internal =
    PNC.ClientPresenceSync.Internal or {}

local Internal = PNC.ClientPresenceSync.Internal
Internal.NativePathController =
    Internal.NativePathController or {}
local Controller = Internal.NativePathController
local beginMovementLease = Controller.BeginMovementLease
local logState = Controller.LogState
local describeBody = Controller.DescribeBody

local function canSeamlessRetarget(body, state, behavior)
    if state.owned ~= true or state.failed == true or not behavior then
        return false
    end
    if type(behavior.hasStartedMoving) ~= "function"
        or behavior:hasStartedMoving() ~= true
    then
        return false
    end
    if type(behavior.getIsCancelled) == "function"
        and behavior:getIsCancelled() == true
    then
        return false
    end
    if body.getCurrentState and ZombieIdleState
        and type(ZombieIdleState.instance) == "function"
        and body:getCurrentState() == ZombieIdleState.instance()
    then
        return false
    end
    return true
end

local function submitPathRequest(
    snapshot,
    body,
    state,
    goal,
    key,
    behavior,
    now
)
    local shouldRequest =
        state.requestKey ~= key
        or (
            state.failed == true
            and now >= (tonumber(state.retryAt) or 0)
        )
    if not shouldRequest then
        return false
    end
    local seamless = canSeamlessRetarget(body, state, behavior)
    if state.owned == true and not seamless then
        if behavior.cancel then
            behavior:cancel()
        end
        if behavior.reset then
            behavior:reset()
        end
    end
    -- Prefer direct Behavior2 + PathFindState when available so MP goal
    -- updates bypass IsoZombie.allowRepathDelay and retarget seamlessly
    -- without cancelling mid-stride. Fall back to body:pathToLocationF when
    -- PathFindState or behavior.pathToLocationF is unavailable.
    local pathState = PathFindState and type(PathFindState.instance) == "function"
        and PathFindState.instance() or nil
    if behavior and type(behavior.pathToLocationF) == "function"
        and pathState ~= nil and type(body.changeState) == "function"
    then
        behavior:pathToLocationF(goal.x, goal.y, goal.z)
        if body.setVariable then
            body:setVariable("bPathfind", true)
        end
        if not (body.getCurrentState and body:getCurrentState() == pathState) then
            body:changeState(pathState)
        end
    else
        body:pathToLocationF(goal.x, goal.y, goal.z)
    end
    if state.requestKey ~= key then
        state.retries = 0
    else
        state.retries =
            (tonumber(state.retries) or 0) + 1
    end
    state.requestKey = key
    state.owned = true
    state.completed = false
    state.failed = false
    state.startedAt = now
    state.lastProgressAt = now
    state.nextPassageProbeAt = now
    state.lastX = body:getX()
    state.lastY = body:getY()
    state.lastZ = body:getZ()
    beginMovementLease(body, state, key, now)
    logState(
        snapshot,
        "native_controller_start",
        "goal=" .. tostring(goal.x)
            .. "," .. tostring(goal.y)
            .. "," .. tostring(goal.z)
            .. " revision=" .. tostring(goal.revision)
            .. " retry=" .. tostring(state.retries)
            .. describeBody(body)
    )
    return true
end

Controller.SubmitPathRequest = submitPathRequest
