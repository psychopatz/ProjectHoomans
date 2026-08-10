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
    if state.owned == true then
        if behavior.cancel then
            behavior:cancel()
        end
        if behavior.reset then
            behavior:reset()
        end
    end
    -- The character wrapper enters PathFindState, the sole owner of
    -- PathFindBehavior2.update() and native passage traversal.
    body:pathToLocationF(goal.x, goal.y, goal.z)
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

