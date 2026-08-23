local Trace = PNC.AnimationTrace
local Internal = Trace.Internal

local function textMethod(object, methodName)
    local method = object and object[methodName] or nil
    if not method then return "" end
    return tostring(method(object) or "")
end

local function boolMethod(object, methodName)
    local method = object and object[methodName] or nil
    return method and method(object) == true or false
end

local function variableText(body, name)
    if body and body.getVariableString then
        return tostring(body:getVariableString(name) or "")
    end
    return ""
end

local function variableBoolean(body, name)
    return body and body.getVariableBoolean
        and body:getVariableBoolean(name) == true or false
end

local function primaryItemType(body)
    local item = body and body.getPrimaryHandItem
        and body:getPrimaryHandItem() or nil
    if not item then return "" end
    if item.getFullType then return tostring(item:getFullType() or "") end
    if item.getType then return tostring(item:getType() or "") end
    return tostring(item)
end

function Internal.TopologyName()
    if isClient and isClient() == true then return "client" end
    if isServer and isServer() == true then return "server" end
    return "singleplayer"
end

function Internal.Capture(body, event, now)
    local modData = body and body.getModData and body:getModData() or nil
    return {
        at = now,
        event = tostring(event or "sample"),
        bump = textMethod(body, "getBumpType"),
        bumpVariable = variableText(body, "BumpType"),
        bumped = boolMethod(body, "isBumped"),
        bumpStaggered = boolMethod(body, "isBumpStaggered"),
        bumpDone = boolMethod(body, "isBumpDone"),
        bumpDoneVariable = variableBoolean(body, "BumpDone"),
        animFinished = variableBoolean(body, "BumpAnimFinished"),
        action = textMethod(body, "getActionStateName"),
        actionCurrent = textMethod(body, "getCurrentActionContextStateName"),
        actionPrevious = textMethod(body, "getPreviousActionContextStateName"),
        javaState = textMethod(body, "getCurrentStateName"),
        animationState = textMethod(body, "getAnimationStateName"),
        pncActor = variableBoolean(body, "PNCActor"),
        moving = boolMethod(body, "isMoving"),
        sneaking = boolMethod(body, "isSneaking"),
        useless = boolMethod(body, "isUseless"),
        localBody = boolMethod(body, "isLocal"),
        path2 = body and body.getPath2 and body:getPath2() ~= nil or false,
        primary = primaryItemType(body),
        lease = modData and modData.PNC_BumpActionLease == true or false,
        releasePending = modData
            and modData.PNC_BumpReleasePending == true or false,
    }
end

function Internal.StateSignature(sample)
    return table.concat({
        sample.bump, sample.bumpVariable, tostring(sample.bumped),
        tostring(sample.bumpStaggered), tostring(sample.bumpDone),
        tostring(sample.bumpDoneVariable), tostring(sample.animFinished),
        sample.action, sample.actionCurrent, sample.actionPrevious,
        sample.javaState, sample.animationState, tostring(sample.pncActor),
        tostring(sample.moving), tostring(sample.sneaking),
        tostring(sample.useless), tostring(sample.localBody),
        tostring(sample.path2), sample.primary, tostring(sample.lease),
        tostring(sample.releasePending),
    }, "|")
end

return Trace
