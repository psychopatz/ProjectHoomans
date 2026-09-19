-- Client-side best-effort hint enrichment for semantic action targets.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local ActionTargetHints = PNC.Semantics.DialogueInputActionTargetHints or {}
PNC.Semantics.DialogueInputActionTargetHints = ActionTargetHints

local function number(value)
    return tonumber(value)
end

local function copyActionWithTarget(actionIntent, target)
    local output = {}
    for key, value in pairs(actionIntent or {}) do output[key] = value end
    output.target = target
    return output
end

local function targetNeedsHint(target)
    if type(target) ~= "table" then return false end
    if number(target.x or target.targetX) ~= nil
        or number(target.y or target.targetY) ~= nil
        or target.targetID ~= nil or target.worldID ~= nil
    then
        return false
    end
    return target.unresolved == true
        or tostring(target.kind or "") == "phrase"
        or target.category ~= nil or target.concept ~= nil
end

function ActionTargetHints.AttachWorldTargetHint(
    actionIntent, context, worldTargetHints, audit)
    if actionIntent and actionIntent.target
        and actionIntent.target.kind == "camp_site"
    then
        return actionIntent
    end
    if type(worldTargetHints) ~= "table"
        or type(worldTargetHints.Resolve) ~= "function"
        or not targetNeedsHint(actionIntent and actionIntent.target)
    then
        return actionIntent
    end

    local target = actionIntent.target
    local hint, reason = worldTargetHints.Resolve(target, context)
    if not hint then
        audit("semantic.world_target.client_hint", {
            npcID = context.npcID,
            conversationID = context.conversationID,
            requestID = context.requestID,
            query = target.text or target.value or target.category
                or target.concept,
            reason = reason,
            attached = false,
        }, { requestID = context.requestID })
        return actionIntent
    end

    local targetCopy = {}
    for key, value in pairs(target) do targetCopy[key] = value end
    targetCopy.clientHint = hint
    audit("semantic.world_target.client_hint", {
        npcID = context.npcID,
        conversationID = context.conversationID,
        requestID = context.requestID,
        query = hint.query,
        kind = hint.kind,
        x = hint.x,
        y = hint.y,
        z = hint.z,
        score = hint.score,
        attached = true,
    }, { requestID = context.requestID })
    return copyActionWithTarget(actionIntent, targetCopy)
end

function ActionTargetHints.AttachCampSiteHint(
    actionIntent, context, campSite, campSiteHints, audit)
    local target = actionIntent and actionIntent.target
    local normalizedTarget = campSite and campSite.NormalizeTarget
        and campSite.NormalizeTarget(target) or target
    local normalizedAction = actionIntent
    local x = target and number(target.x or target.targetX)
    local y = target and number(target.y or target.targetY)
    if normalizedTarget ~= target then
        normalizedAction = copyActionWithTarget(actionIntent, normalizedTarget)
        target = normalizedTarget
        x = target and number(target.x or target.targetX)
        y = target and number(target.y or target.targetY)
    end
    if not actionIntent or actionIntent.action ~= "CAMP"
        or type(target) ~= "table"
        or target.kind ~= "camp_site"
        or x ~= nil or y ~= nil
        or target.siteID ~= nil or target.campfireID ~= nil
        or type(campSiteHints) ~= "table"
        or type(campSiteHints.Resolve) ~= "function"
    then
        return normalizedAction
    end

    local hint, reason = campSiteHints.Resolve(target, context)
    if not hint then
        audit("semantic.camp_site.client_hint", {
            npcID = context.npcID,
            conversationID = context.conversationID,
            requestID = context.requestID,
            scope = target.scope or target.siteScope,
            query = target.roomQuery or target.roomType or target.text,
            reason = reason,
            attached = false,
        }, { requestID = context.requestID })
        return normalizedAction
    end

    local targetCopy = {}
    for key, value in pairs(target) do targetCopy[key] = value end
    targetCopy.clientHint = hint
    audit("semantic.camp_site.client_hint", {
        npcID = context.npcID,
        conversationID = context.conversationID,
        requestID = context.requestID,
        scope = hint.scope or hint.siteScope,
        query = hint.query,
        siteID = hint.siteID,
        roomID = hint.roomID,
        roomType = hint.roomType,
        campfireID = hint.campfireID,
        x = hint.x,
        y = hint.y,
        score = hint.score,
        attached = true,
    }, { requestID = context.requestID })
    return copyActionWithTarget(normalizedAction, targetCopy)
end

return ActionTargetHints
