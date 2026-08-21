--[[
    PNC Client Native Path Controller: door, window, and forced-climb recovery
]]

PNC = PNC or {}
PNC.ClientPresenceSync = PNC.ClientPresenceSync or {}
PNC.ClientPresenceSync.Internal =
    PNC.ClientPresenceSync.Internal or {}

local Sync = PNC.ClientPresenceSync
local Internal = Sync.Internal
Internal.NativePathController =
    Internal.NativePathController or {}
local Controller = Internal.NativePathController
local TraversalQuery = PNC.TraversalQuery
local PathInternal = PNC.PathService
    and PNC.PathService.Internal or nil
local Animation = PNC.Animation
local LiveBodyControl = PNC.LiveBodyControl
local clearOwnedPath = Controller.ClearOwnedPath
local beginMovementLease = Controller.BeginMovementLease
local logState = Controller.LogState
local describeBody = Controller.DescribeBody
local STALL_TIMEOUT_MS = Controller.STALL_TIMEOUT_MS
local RETRY_BASE_MS = Controller.RETRY_BASE_MS
local WINDOW_SMASH_IMPACT_MS =
    Controller.WINDOW_SMASH_IMPACT_MS
local WINDOW_SMASH_FINISH_MS =
    Controller.WINDOW_SMASH_FINISH_MS
local FENCE_CLIMB_FINISH_MS = 900

local function objectBool(object, methodName)
    local method = object and object[methodName] or nil
    return type(method) == "function" and method(object) == true
end

local function finishPassageBump(body)
    if Animation and Animation.FinishBump then
        Animation.FinishBump(body, true)
    elseif body and body.setVariable then
        body:setVariable("BumpAnimFinished", true)
    end
end

local function updateWindowSmash(body, state, now)
    local action = state and state.passageAction or nil
    if not action then return false, nil end
    if not Internal.IsLocalZombieController(body) then
        finishPassageBump(body)
        state.passageAction = nil
        return false, "native_passage_owner_changed"
    end
    if body.faceThisObject and action.object then
        body:faceThisObject(action.object)
    end
    if action.kind == "fence_climb" then
        local duration = math.max(1, action.finishAt - action.startedAt)
        local progress = math.max(0, math.min(1,
            (now - action.startedAt) / duration))
        local x = action.fromX + (action.toX - action.fromX) * progress
        local y = action.fromY + (action.toY - action.fromY) * progress
        if LiveBodyControl and LiveBodyControl.SetAuthoritativePosition then
            LiveBodyControl.SetAuthoritativePosition(body, x, y, action.toZ)
        end
        if body.setLx then body:setLx(x) end
        if body.setLy then body:setLy(y) end
        if now < action.finishAt then
            beginMovementLease(body, state, action.key, now)
            return true, "native_fence_climb"
        end
        finishPassageBump(body)
        state.passageAction = nil
        state.requestKey = nil
        state.failed = true
        state.retryAt = now + RETRY_BASE_MS
        return true, "native_fence_crossed"
    end
    if action.applied ~= true
        and now >= (tonumber(action.impactAt) or now)
    then
        action.applied = true
        if PathInternal and PathInternal.smashWindowForNPC then
            PathInternal.smashWindowForNPC(body, action.object)
        elseif action.object and action.object.smashWindow then
            action.object:smashWindow()
        end
    end
    if now < (tonumber(action.finishAt) or now) then
        beginMovementLease(body, state, action.key, now)
        return true, "native_window_smash"
    end
    finishPassageBump(body)
    state.passageAction = nil
    state.requestKey = nil
    state.failed = true
    state.retryAt = now + RETRY_BASE_MS
    return true, "native_window_smashed"
end

local function startFenceClimb(snapshot, body, state, passage, object, now)
    local toSquare = passage and passage.toSquare or nil
    if not toSquare then return false, nil end
    local _, tall = TraversalQuery.IsFence(object)
    clearOwnedPath(body, state)
    local key = "fence_climb:"
        .. tostring(snapshot and snapshot.id or "npc")
        .. ":" .. tostring(now)
    state.passageAction = {
        kind = "fence_climb", key = key, object = object,
        startedAt = now, finishAt = now + FENCE_CLIMB_FINISH_MS,
        fromX = body:getX(), fromY = body:getY(),
        toX = toSquare:getX() + 0.5,
        toY = toSquare:getY() + 0.5,
        toZ = toSquare:getZ(),
    }
    if body.faceThisObject then body:faceThisObject(object) end
    if Animation and Animation.PlayBump then
        Animation.PlayBump(body, snapshot,
            tall and "PNC_ClimbFenceTall" or "PNC_ClimbFence", {
                sceneId = "native_fence_climb",
                leaseUntil = now + FENCE_CLIMB_FINISH_MS,
                keepManagedUseless = false,
            })
    end
    beginMovementLease(body, state, key, now)
    logState(snapshot, "native_fence_climb_start", describeBody(body))
    return true, "native_fence_climb"
end

local function startWindowSmash(
    snapshot,
    body,
    state,
    object,
    now
)
    clearOwnedPath(body, state)
    local key = "window_smash:"
        .. tostring(snapshot and snapshot.id or "npc")
        .. ":" .. tostring(now)
    state.passageAction = {
        kind = "window_smash",
        key = key,
        object = object,
        startedAt = now,
        impactAt = now + WINDOW_SMASH_IMPACT_MS,
        finishAt = now + WINDOW_SMASH_FINISH_MS,
        applied = false,
    }
    state.lastProgressAt = now
    if body.faceThisObject then
        body:faceThisObject(object)
    end
    if Animation and Animation.PlayBump then
        Animation.PlayBump(
            body,
            snapshot,
            "PNC_WindowSmash",
            {
                sceneId = "native_window_smash",
                leaseUntil = now + WINDOW_SMASH_FINISH_MS,
                keepManagedUseless = false,
            }
        )
    elseif body.setBumpType then
        body:setBumpType("PNC_WindowSmash")
    end
    beginMovementLease(body, state, key, now)
    logState(snapshot, "native_window_smash_start", describeBody(body))
    return true, "native_window_smash"
end

local function forceWindowClimb(
    snapshot,
    body,
    state,
    object,
    now
)
    if not ClimbThroughWindowState
        or not ClimbThroughWindowState.instance
        or not body.changeState
    then
        return false, nil
    end
    local climbState = ClimbThroughWindowState.instance()
    if not climbState or not climbState.setParams then
        return false, nil
    end
    clearOwnedPath(body, state)
    climbState:setParams(body, object)
    body:changeState(climbState)
    if body.setBumpType then
        body:setBumpType("ClimbWindow")
    end
    state.forcedTraversalUntil = now + STALL_TIMEOUT_MS
    state.requestKey = nil
    beginMovementLease(
        body,
        state,
        "window_climb:" .. tostring(now),
        now
    )
    logState(snapshot, "native_window_climb_forced", describeBody(body))
    return true, "native_window_climb"
end

local function tryNativePassage(
    snapshot,
    body,
    state,
    goal,
    now
)
    if not TraversalQuery
        or not TraversalQuery.FindPassageToward
        or not PathInternal
    then
        return false, nil
    end
    local passage = TraversalQuery.FindPassageToward(
        body,
        goal.x,
        goal.y,
        goal.z
    )
    local object = passage and passage.object or nil
    if not object then return false, nil end
    if TraversalQuery.IsFence
        and TraversalQuery.IsFence(object) == true
    then
        return startFenceClimb(snapshot, body, state, passage, object, now)
    end
    if TraversalQuery.IsDoor
        and TraversalQuery.IsDoor(object)
        and not objectBool(object, "IsOpen")
        and not objectBool(object, "isOpen")
    then
        if PathInternal.openDoorForNPC(body, object) then
            clearOwnedPath(body, state)
            state.failed = true
            state.retryAt = now + 180
            logState(snapshot, "native_door_open", describeBody(body))
            return true, "native_door_open"
        end
        return false, "native_door_blocked"
    end
    if not TraversalQuery.IsWindow
        or not TraversalQuery.IsWindow(object)
    then
        return false, nil
    end
    local open = objectBool(object, "IsOpen")
        or objectBool(object, "isOpen")
    local smashed = objectBool(object, "isSmashed")
        or objectBool(object, "IsSmashed")
    if not open and not smashed then
        if PathInternal.openWindowForNPC(body, object) then
            clearOwnedPath(body, state)
            state.failed = true
            state.retryAt = now + 250
            logState(snapshot, "native_window_open", describeBody(body))
            return true, "native_window_open"
        end
        return startWindowSmash(
            snapshot,
            body,
            state,
            object,
            now
        )
    end
    if object.canClimbThrough
        and object:canClimbThrough(body)
    then
        -- Never hand an equipped managed IsoZombie back to vanilla between
        -- detecting a climbable window and entering the climb state. In B42
        -- multiplayer, IsoGameCharacter.climbThroughWindow() calls
        -- dropHeavyItems(), which emits player-only packets and casts this
        -- locally controlled IsoZombie to IsoPlayer. Entering the already
        -- parameterized state directly preserves the native climb animation
        -- without invoking that unsafe packet path.
        return forceWindowClimb(
            snapshot,
            body,
            state,
            object,
            now
        )
    end
    return false, nil
end


Controller.FinishPassageBump = finishPassageBump
Controller.UpdateWindowSmash = updateWindowSmash
Controller.TryNativePassage = tryNativePassage
