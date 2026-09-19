--[[
    PNC Native Passage: shared animation state and diagnostics.
]]

PNC = PNC or {}
PNC.ClientPresenceSync = PNC.ClientPresenceSync or {}
PNC.ClientPresenceSync.Internal =
    PNC.ClientPresenceSync.Internal or {}

local Sync = PNC.ClientPresenceSync
local Controller = Sync.Internal.NativePathController
local Passage = Controller.PassageInternal
local Shared = Passage.Shared or {}
Passage.Shared = Shared
local Core = PNC.Core
local LiveBodyControl = PNC.LiveBodyControl
local Animation = PNC.Animation

local function squareKey(square)
    if not square then return nil end
    return tostring(square:getX())
        .. ":" .. tostring(square:getY())
        .. ":" .. tostring(square:getZ())
end

local function logPassageEvent(snapshot, body, state, action, eventName,
    reason)
    local objectSquare
    local modData
    local actionState
    local contextState
    local bumpType
    if not Core or not Core.LogInfo then return end
    objectSquare = action and action.object
        and action.object.getSquare
        and action.object:getSquare() or nil
    modData = body and body.getModData and body:getModData() or nil
    actionState = body and body.getActionStateName
        and body:getActionStateName() or ""
    contextState = LiveBodyControl
        and LiveBodyControl.GetActionContextStateName
        and LiveBodyControl.GetActionContextStateName(body) or ""
    bumpType = body and body.getBumpType
        and body:getBumpType() or modData
        and modData.PNC_BumpRequestedType or ""
    Core.LogInfo(
        "[PNC][PATH] passage_" .. tostring(eventName or "event")
            .. " npc=" .. tostring(snapshot and snapshot.id or "nil")
            .. " kind=" .. tostring(action and action.kind or "")
            .. " key=" .. tostring(action and action.key or "")
            .. " objectSquare=" .. tostring(squareKey(objectSquare)
                or "nil")
            .. " from=" .. tostring(action and (
                action.fromX or action.startX) or "nil")
            .. "," .. tostring(action and (
                action.fromY or action.startY) or "nil")
            .. "," .. tostring(action and (
                action.fromZ or action.startZ) or "nil")
            .. " to=" .. tostring(action and (
                action.toX or action.endX) or "nil")
            .. "," .. tostring(action and (
                action.toY or action.endY) or "nil")
            .. "," .. tostring(action and (
                action.toZ or action.endZ) or "nil")
            .. " action=" .. tostring(actionState)
            .. " context=" .. tostring(contextState)
            .. " bump=" .. tostring(bumpType or "")
            .. " reason=" .. tostring(reason or "")
    )
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

local function objectBool(object, methodName)
    local method = object and object[methodName] or nil
    return type(method) == "function" and method(object) == true
end

Shared.SquareKey = squareKey
Shared.LogPassageEvent = logPassageEvent
Shared.FinishPassageBump = finishPassageBump
Shared.TraversalPhase = traversalPhase
Shared.BumpFinished = bumpFinished
Shared.ObjectBool = objectBool

Controller.FinishPassageBump = finishPassageBump
