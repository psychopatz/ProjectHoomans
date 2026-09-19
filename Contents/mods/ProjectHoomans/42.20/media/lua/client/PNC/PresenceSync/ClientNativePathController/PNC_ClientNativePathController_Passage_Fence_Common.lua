--[[
    PNC Native Passage: shared fence traversal geometry and diagnostics.
]]

PNC = PNC or {}
PNC.ClientPresenceSync = PNC.ClientPresenceSync or {}
PNC.ClientPresenceSync.Internal =
    PNC.ClientPresenceSync.Internal or {}

local Sync = PNC.ClientPresenceSync
local Controller = Sync.Internal.NativePathController
local Passage = Controller.PassageInternal
local Shared = Passage.Shared

local TraversalQuery = PNC.TraversalQuery
local LiveBodyControl = PNC.LiveBodyControl
local Core = PNC.Core
local logState = Controller.LogState
local squareKey = Shared.SquareKey

local Fence = Passage.FenceInternal or {}
Passage.FenceInternal = Fence
Fence.Policy = {
    ClimbUpMs = 700,
    ClimbCrossMs = 560,
    TallClimbFinishMs = 900,
    RetryBackoffMs = 900,
    CooldownMs = 900,
}

local function holdFenceBody(body)
    if LiveBodyControl and LiveBodyControl.SetManagedBodyUseless then
        LiveBodyControl.SetManagedBodyUseless(body, true, false)
    end
end

local function fenceVariableString(body, name)
    if body and body.getVariableString then
        return tostring(body:getVariableString(name) or "")
    end
    return ""
end

local function fenceVariableBoolean(body, name)
    return body and body.getVariableBoolean
        and body:getVariableBoolean(name) == true or false
end

local function fenceDebugExtra(body, action, now, phase, observedPhase)
    local bumpType = body and body.getBumpType
        and tostring(body:getBumpType() or "")
        or fenceVariableString(body, "BumpType")
    local actionState = body and body.getActionStateName
        and string.lower(tostring(body:getActionStateName() or ""))
        or ""
    return "phase=" .. tostring(phase or "")
        .. " observed=" .. tostring(observedPhase or "")
        .. " action=" .. tostring(actionState)
        .. " bump=" .. tostring(bumpType)
        .. " finished=" .. tostring(
            fenceVariableBoolean(body, "BumpAnimFinished")
        )
        .. " elapsedMs=" .. tostring(
            (tonumber(now) or 0)
                - (tonumber(action and action.startedAt) or now or 0)
        )
        .. " pos=" .. tostring(body and body:getX() or "nil")
        .. "," .. tostring(body and body:getY() or "nil")
        .. " target=" .. tostring(action and action.toX or "nil")
        .. "," .. tostring(action and action.toY or "nil")
end

local function logFencePhase(snapshot, body, state, action, now, phase, observedPhase)
    if not state or state.fenceDebugPhase == phase then return end
    state.fenceDebugPhase = phase
    logState(
        snapshot,
        "native_fence_phase",
        fenceDebugExtra(body, action, now, phase, observedPhase)
    )
    if phase == "cross_pending"
        and tostring(observedPhase or "") ~= "transfer"
        and not state.fenceDebugTimerFallbackLogged
    then
        state.fenceDebugTimerFallbackLogged = true
        if Core and Core.LogWarn then
            Core.LogWarn(
                "[PNC][FENCE_DEBUG] timer fallback npc="
                    .. tostring(snapshot and snapshot.id or "nil")
                    .. " "
                    .. fenceDebugExtra(
                        body, action, now, phase, observedPhase
                    )
            )
        end
    end
end

local function actionStateName(body)
    if not body or not body.getActionStateName then return "" end
    return string.lower(tostring(body:getActionStateName() or ""))
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

Fence.HoldBody = holdFenceBody
Fence.LogPhase = logFencePhase
Fence.ActionStateName = actionStateName
Fence.Key = fenceKey
Fence.Crossed = fenceCrossed
