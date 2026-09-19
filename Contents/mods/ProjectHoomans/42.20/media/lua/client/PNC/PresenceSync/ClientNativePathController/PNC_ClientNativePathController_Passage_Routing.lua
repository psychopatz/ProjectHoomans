--[[
    PNC Native Passage: route obstacle probes and attach controller API.
]]

PNC = PNC or {}
PNC.ClientPresenceSync = PNC.ClientPresenceSync or {}
PNC.ClientPresenceSync.Internal =
    PNC.ClientPresenceSync.Internal or {}

local Sync = PNC.ClientPresenceSync
local Internal = Sync.Internal
local Controller = Internal.NativePathController
local Passage = Controller.PassageInternal
local Shared = Passage.Shared

local TraversalQuery = PNC.TraversalQuery
local PathInternal = PNC.PathService
    and PNC.PathService.Internal or nil
local LiveBodyControl = PNC.LiveBodyControl

local clearOwnedPath = Controller.ClearOwnedPath
local logState = Controller.LogState
local describeBody = Controller.DescribeBody
local logPassageEvent = Shared.LogPassageEvent
local finishPassageBump = Shared.FinishPassageBump
local objectBool = Shared.ObjectBool
local PASSAGE_PROBE_COOLDOWN_MS =
    Controller.PASSAGE_PROBE_COOLDOWN_MS or 250
local PASSAGE_STALL_PROBE_MS =
    Controller.PASSAGE_STALL_PROBE_MS or 750

local function bodyMethodTrue(body, methodName)
    local method = body and body[methodName] or nil
    if type(method) == "function" then
        return method(body) == true
    end
    return method == true
end

local function shouldProbePassage(body, state, now)
    local nextProbeAt = tonumber(state and state.nextPassageProbeAt) or 0
    local lastProgressAt = tonumber(state and state.lastProgressAt) or now
    local newRequest = not state or state.requestKey == nil
    local collided = bodyMethodTrue(body, "isCollidedWithDoor")
        or bodyMethodTrue(body, "isCollidedThisFrame")
        or bodyMethodTrue(body, "isCollided")
    local stalled = state
        and state.owned == true
        and now - lastProgressAt >= PASSAGE_STALL_PROBE_MS
    if now < nextProbeAt
        or (not collided and not stalled and not newRequest)
    then
        return false
    end
    state.nextPassageProbeAt = now + PASSAGE_PROBE_COOLDOWN_MS
    return true
end

local function tryNativePassage(snapshot, body, state, goal, now)
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
    if state.windowRetryObject == object then
        if now < (tonumber(state.windowRetryAt) or 0) then
            return false, nil
        end
        state.windowRetryObject = nil
        state.windowRetryAt = nil
    end
    if state.windowCooldownObject == object then
        if now < (tonumber(state.windowCooldownUntil) or 0) then
            return true, "native_window_cooldown"
        end
        state.windowCooldownObject = nil
        state.windowCooldownUntil = nil
    end
    local fenceMatched, fenceHandled, fenceReason = Passage.TryFence(
        snapshot, body, state, passage, object, now
    )
    if fenceMatched then
        return fenceHandled, fenceReason
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
            logPassageEvent(
                snapshot,
                body,
                state,
                { kind = "door_open", object = object },
                "door_open",
                "opened"
            )
            logState(snapshot, "native_door_open", describeBody(body))
            return true, "native_door_open"
        end
        return false, "native_door_blocked"
    end
    return Passage.TryWindow(
        snapshot, body, state, passage, object, now
    )
end

local function updatePassageAction(body, state, now)
    local action = state and state.passageAction or nil
    if not action then return false, nil end
    if not Internal.IsLocalZombieController(body) then
        logPassageEvent(
            state.snapshot,
            body,
            state,
            action,
            "owner_changed",
            "nearest_client_changed"
        )
        finishPassageBump(body)
        state.passageAction = nil
        return false, "native_passage_owner_changed"
    end
    if LiveBodyControl and LiveBodyControl.ResetNativeMovementState then
        LiveBodyControl.ResetNativeMovementState(body)
    end
    if body.faceThisObject and action.object then
        body:faceThisObject(action.object)
    end
    if action.kind == "fence_climb" then
        return Passage.UpdateFenceAction(body, state, now)
    end
    return Passage.UpdateWindowAction(body, state, now)
end

Controller.ShouldProbePassage = shouldProbePassage
Controller.TryNativePassage = tryNativePassage
Controller.UpdatePassageAction = updatePassageAction
Controller.UpdateWindowSmash = updatePassageAction
