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
local TraversalAction = PNC.TraversalAction
local TraversalQuery = PNC.TraversalQuery
local TraversalProfiles = PNC.TraversalProfiles
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
local FENCE_CLIMB_UP_MS = 700
local FENCE_CLIMB_CROSS_MS = 560
local FENCE_TALL_CLIMB_FINISH_MS = 900
local FENCE_RETRY_BACKOFF_MS = 900
local FENCE_COOLDOWN_MS = 900
local VANILLA_FENCE_TIMEOUT_MS = 4000
local VANILLA_FENCE_START_GRACE_MS = 300
local function objectBool(object, methodName)
    local method = object and object[methodName] or nil
    return type(method) == "function" and method(object) == true
end

local function actionStateName(body)
    if not body or not body.getActionStateName then return "" end
    return string.lower(tostring(body:getActionStateName() or ""))
end

local function fenceDirection(fromSquare, toSquare)
    local dx = toSquare and fromSquare
        and toSquare:getX() - fromSquare:getX() or 0
    local dy = toSquare and fromSquare
        and toSquare:getY() - fromSquare:getY() or 0
    if not IsoDirections then return nil end
    if dx > 0 then return IsoDirections.E end
    if dx < 0 then return IsoDirections.W end
    if dy > 0 then return IsoDirections.S end
    if dy < 0 then return IsoDirections.N end
    return nil
end

local function squareKey(square)
    if not square then return nil end
    return tostring(square:getX())
        .. ":" .. tostring(square:getY())
        .. ":" .. tostring(square:getZ())
end

local function fenceKey(object, passage)
    local objectSquare = object and object.getSquare
        and object:getSquare() or nil
    local fromSquare = passage and passage.fromSquare or nil
    local toSquare = passage and passage.toSquare or nil
    if objectSquare then
        return "fence:" .. squareKey(objectSquare)
    end
    if fromSquare and toSquare then
        local fromKey = squareKey(fromSquare)
        local toKey = squareKey(toSquare)
        if tostring(fromKey) < tostring(toKey) then
            return "fence:" .. tostring(fromKey) .. ">" .. tostring(toKey)
        end
        return "fence:" .. tostring(toKey) .. ">" .. tostring(fromKey)
    end
    return "fence:unknown"
end

local function fenceCrossed(body, action)
    if TraversalQuery and TraversalQuery.IsFenceCrossed then
        return TraversalQuery.IsFenceCrossed(
            body and body:getX() or nil,
            body and body:getY() or nil,
            body and body:getZ() or nil,
            action and action.fromSquare or nil,
            action and action.toSquare or nil
        )
    end
    return body ~= nil
        and action ~= nil
        and action.toSquare ~= nil
        and math.floor(body:getX()) == action.toSquare:getX()
        and math.floor(body:getY()) == action.toSquare:getY()
        and math.floor(body:getZ()) == action.toSquare:getZ()
end

local function finishPassageBump(body)
    if Animation and Animation.FinishBump then
        Animation.FinishBump(body, true)
    elseif body and body.setVariable then
        body:setVariable("BumpAnimFinished", true)
    end
end

local function traversalPhase(body)
    if body and body.getVariableString then
        return string.lower(tostring(
            body:getVariableString("PNCTraversalPhase") or ""
        ))
    end
    return ""
end

local function bumpFinished(body)
    if body and body.getVariableBoolean
        and body:getVariableBoolean("BumpAnimFinished") == true
    then
        return true
    end
    if body and body.getVariableString then
        local value = string.lower(tostring(
            body:getVariableString("BumpAnimFinished") or ""
        ))
        return value == "true" or value == "1"
    end
    return false
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
        local phase
        local progress
        local phaseStartedAt
        local crossPendingAt
        local startedCrossing
        phase,
            progress,
            phaseStartedAt,
            crossPendingAt,
            startedCrossing = TraversalAction.Evaluate(
                action,
                now,
                traversalPhase(body)
            )
        action.phase = phase
        action.crossPendingAt = crossPendingAt
        if startedCrossing then
            action.crossingStartedAt = phaseStartedAt
            if Animation and Animation.PlayBump then
                Animation.PlayBump(
                    body,
                    state.snapshot,
                    action.endAnim,
                    {
                        sceneId = "native_fence_climb",
                        leaseUntil = action.finishAt,
                        keepManagedUseless = false,
                    }
                )
            elseif body.setBumpType then
                body:setBumpType(action.endAnim)
            end
        end
        local x = action.fromX + (action.toX - action.fromX) * progress
        local y = action.fromY + (action.toY - action.fromY) * progress
        if LiveBodyControl and LiveBodyControl.SetAuthoritativePosition then
            LiveBodyControl.SetAuthoritativePosition(body, x, y, action.toZ)
        end
        if body.setLx then body:setLx(x) end
        if body.setLy then body:setLy(y) end
        if not fenceCrossed(body, action)
            or (not bumpFinished(body)
                and traversalPhase(body) ~= "finished"
                and now < action.finishAt)
        then
            beginMovementLease(body, state, action.key, now)
            return true, "native_fence_climb"
        end
        finishPassageBump(body)
        state.passageAction = nil
        state.requestKey = nil
        if fenceCrossed(body, action) then
            state.fenceCooldownKey = action.fenceKey
            state.fenceCooldownUntil = now + FENCE_COOLDOWN_MS
            state.failed = true
            state.retryAt = now
            return true, "native_fence_crossed"
        end
        -- A server correction or a failed local landing must not immediately
        -- select the same edge again. Hold the route briefly and let the
        -- authoritative position settle before retrying.
        state.fenceRetryKey = action.fenceKey
        state.fenceRetryAt = now + FENCE_RETRY_BACKOFF_MS
        state.failed = true
        state.retryAt = state.fenceRetryAt
        return true, "native_fence_same_side"
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

local function enterVanillaFenceState(body, direction)
    local result
    if body and body.climbOverFence then
        result = body:climbOverFence(direction)
        if result ~= false then
            if actionStateName(body) == "climbfence" then
                return true
            end
            -- EventClimbFence is normally consumed immediately. Give the
            -- engine a direct state fallback when a managed zombie has not
            -- got an active action context on this frame.
        end
    end
    if ClimbOverFenceState
        and ClimbOverFenceState.instance
        and body
        and body.changeState
    then
        local climbState = ClimbOverFenceState.instance()
        if climbState and climbState.setParams then
            climbState:setParams(body, direction)
            body:changeState(climbState)
            return true
        end
    end
    return result ~= false and body ~= nil
end

local function updateVanillaFenceClimb(body, state, now)
    local action = state and state.forcedTraversalAction or nil
    local actionState
    local crossed
    if not action then return false, nil end
    actionState = actionStateName(body)
    crossed = fenceCrossed(body, action)
    if crossed then
        clearOwnedPath(body, state)
        state.forcedTraversalAction = nil
        state.forcedTraversalState = nil
        state.forcedTraversalUntil = nil
        state.requestKey = nil
        state.fenceCooldownKey = action.fenceKey
        state.fenceCooldownUntil = now + FENCE_COOLDOWN_MS
        state.failed = true
        state.retryAt = now
        return true, "native_fence_vanilla_crossed"
    end
    if actionState == "climbfence"
        and now < (tonumber(action.finishAt) or now)
    then
        beginMovementLease(body, state, action.key, now)
        return true, "native_fence_vanilla"
    end
    if now < (tonumber(action.startGraceUntil) or now) then
        beginMovementLease(body, state, action.key, now)
        return true, "native_fence_vanilla_starting"
    end
    if actionState == "climbfence"
        and LiveBodyControl
        and LiveBodyControl.SuppressZombieState
    then
        LiveBodyControl.SuppressZombieState(body, state, now)
    end
    clearOwnedPath(body, state)
    state.forcedTraversalAction = nil
    state.forcedTraversalState = nil
    state.forcedTraversalUntil = nil
    state.requestKey = nil
    state.fenceRetryKey = action.fenceKey
    state.fenceRetryAt = now + FENCE_RETRY_BACKOFF_MS
    state.failed = true
    state.retryAt = state.fenceRetryAt
    return true, "native_fence_vanilla_same_side"
end

local function startVanillaFenceClimb(
    snapshot, body, state, passage, object, fromSquare, now
)
    local direction = fenceDirection(fromSquare, passage.toSquare)
    if not direction then
        return false, "native_fence_direction_unavailable"
    end
    if not enterVanillaFenceState(body, direction) then
        return false, "native_fence_state_unavailable"
    end
    local key = "fence_vanilla:"
        .. tostring(snapshot and snapshot.id or "npc")
        .. ":" .. tostring(now)
    local fenceAction = {
        kind = "fence_climb_vanilla",
        key = key,
        object = object,
        fromSquare = fromSquare,
        toSquare = passage.toSquare,
        fenceKey = fenceKey(object, passage),
        startedAt = now,
        startGraceUntil = now + VANILLA_FENCE_START_GRACE_MS,
        finishAt = now + VANILLA_FENCE_TIMEOUT_MS,
    }
    if LiveBodyControl and LiveBodyControl.SetManagedBodyUseless then
        LiveBodyControl.SetManagedBodyUseless(body, false, true)
    end
    state.forcedTraversalAction = fenceAction
    state.forcedTraversalState = "climbfence"
    state.forcedTraversalUntil = fenceAction.finishAt
    state.requestKey = nil
    beginMovementLease(body, state, key, now)
    logState(snapshot, "native_fence_vanilla_start", describeBody(body))
    return true, "native_fence_vanilla"
end

local function startFenceClimb(snapshot, body, state, passage, object, now)
    local toSquare = passage and passage.toSquare or nil
    local fromSquare = passage and passage.fromSquare or nil
    local profile
    local tall
    local upDuration
    local crossingDuration
    local finishHold
    local finishDuration
    local transferX
    local transferY
    if not toSquare then return false, nil end
    if not fromSquare and body.getSquare then
        fromSquare = body:getSquare()
    end
    if TraversalQuery and TraversalQuery.IsFenceApproachReady
        and not TraversalQuery.IsFenceApproachReady(
            body:getX(),
            body:getY(),
            fromSquare,
            toSquare,
            passage.dirX,
            passage.dirY
        )
    then
        return false, "native_fence_not_ready"
    end
    if TraversalQuery and TraversalQuery.CanTraverseAt
        and not TraversalQuery.CanTraverseAt(
            toSquare:getX() + 0.5,
            toSquare:getY() + 0.5,
            toSquare:getZ()
        )
    then
        return false, "native_fence_landing_blocked"
    end
    if not TraversalQuery
        or not TraversalQuery.GetFenceTransferPoint
    then
        return false, "native_fence_geometry_unavailable"
    end
    transferX, transferY = TraversalQuery.GetFenceTransferPoint(
        fromSquare,
        toSquare,
        body:getX(),
        body:getY()
    )
    if transferX == nil or transferY == nil then
        return false, "native_fence_geometry_invalid"
    end
    _, tall = TraversalQuery.IsFence(object)
    profile = TraversalProfiles
        and TraversalProfiles.Resolve
        and TraversalProfiles.Resolve(
            "fence_climb",
            {
                body = body,
                snapshot = snapshot,
                state = state,
                obstacle = object,
                tall = tall == true,
            },
            tall == true and "tall" or "low"
        ) or {}
    upDuration = tonumber(profile.upDurationMs) or FENCE_CLIMB_UP_MS
    crossingDuration = tonumber(profile.crossingDurationMs)
        or FENCE_CLIMB_CROSS_MS
    finishHold = tonumber(profile.finishHoldMs) or 320
    finishDuration = tall == true
        and (tonumber(profile.travelDurationMs)
            or FENCE_TALL_CLIMB_FINISH_MS)
        or upDuration + crossingDuration + finishHold
    clearOwnedPath(body, state)
    -- PathFindBehavior2 may have entered vanilla ClimbOverFenceState on the
    -- collision frame before this controller observed the passage. Reset that
    -- state before installing the PNC bump scene; NPCs do not own player
    -- BodyDamage, so allowing the vanilla state to finish can throw in its
    -- fall-after-vault check.
    if LiveBodyControl and LiveBodyControl.SuppressZombieState then
        LiveBodyControl.SuppressZombieState(body, state, now)
    end
    local key = "fence_climb:"
        .. tostring(snapshot and snapshot.id or "npc")
        .. ":" .. tostring(now)
    state.passageAction = {
        kind = "fence_climb", key = key, object = object,
        startedAt = now,
        finishAt = now + finishDuration,
        finishHoldMs = finishHold,
        twoPhase = tall ~= true,
        phase = tall and "single" or "up",
        travelDurationMs = tall
            and (tonumber(profile.travelDurationMs)
                or FENCE_TALL_CLIMB_FINISH_MS)
            or nil,
        upDurationMs = tall and nil or upDuration,
        upFinishAt = tall and nil or now + upDuration,
        crossingDurationMs = tall and nil or crossingDuration,
        startAnim = tall and nil
            or profile.startAnim or "PNC_LegacyClimbFenceStart",
        endAnim = tall and nil
            or profile.endAnim or "PNC_LegacyClimbFenceEnd",
        fromX = body:getX(), fromY = body:getY(),
        fromSquare = fromSquare,
        toSquare = toSquare,
        fenceKey = fenceKey(object, passage),
        toX = transferX,
        toY = transferY,
        toZ = toSquare:getZ(),
    }
    if body.faceThisObject then body:faceThisObject(object) end
    if Animation and Animation.PlayBump then
        Animation.PlayBump(body, snapshot,
            tall and "PNC_ClimbFenceTall"
                or "PNC_LegacyClimbFenceStart", {
                sceneId = "native_fence_climb",
                leaseUntil = state.passageAction.finishAt,
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
    state.forcedTraversalState = "climbwindow"
    state.forcedTraversalAction = nil
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
        local key = fenceKey(object, passage)
        if state.fenceRetryKey == key
            and now < (tonumber(state.fenceRetryAt) or 0)
        then
            clearOwnedPath(body, state)
            return true, "native_fence_retry_wait"
        end
        if state.fenceRetryKey == key then
            state.fenceRetryKey = nil
            state.fenceRetryAt = nil
        end
        if state.fenceCooldownKey == key
            and now < (tonumber(state.fenceCooldownUntil) or 0)
        then
            clearOwnedPath(body, state)
            return true, "native_fence_cooldown"
        end
        if state.fenceCooldownKey == key then
            state.fenceCooldownKey = nil
            state.fenceCooldownUntil = nil
        end
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
Controller.UpdateVanillaFenceClimb = updateVanillaFenceClimb
Controller.TryNativePassage = tryNativePassage
