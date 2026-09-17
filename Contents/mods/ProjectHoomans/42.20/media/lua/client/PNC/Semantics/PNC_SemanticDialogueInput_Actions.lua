-- Side-effect boundary for semantic dialogue actions.
-- Known movement actions use the existing authoritative command transport;
-- task actions use only explicitly registered domain transports.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

require "PNC/Semantics/PNC_SemanticDiagnostics"
require "PNC/Semantics/PNC_SemanticWorldTargetHints"
require "PNC/Semantics/PNC_SemanticCampSiteHints"

local Input = PNC.Semantics.DialogueInput or {}
PNC.Semantics.DialogueInput = Input

local Internal = Input.Internal or {}
Input.Internal = Internal
local CommandAdapter = PNC.Semantics.CommandAdapter
local TaskAdapter = PNC.Semantics.TaskAdapter
local InventoryQueryAdapter = PNC.Semantics.InventoryQueryAdapter
local Diagnostics = PNC.Semantics.SemanticDiagnostics
local WorldTargetHints = PNC.Semantics.ClientWorldTargetHints
local CampSiteHints = PNC.Semantics.ClientCampSiteHints

local function number(value)
    return tonumber(value)
end

local function audit(eventName, data, options)
    if not Diagnostics
        or type(Diagnostics.IsEnabled) ~= "function"
        or Diagnostics.IsEnabled() ~= true
    then
        return false
    end
    return Diagnostics.Record(eventName, data, options)
end

local function actionContext(view, result, value)
    local spec = view and view.spec or {}
    local session = view and view.session
    local group = view and view.groupConversation
    local actorID = session and session.characterUUID
    local recipientID = spec.npcID
    local lifecycle = spec.context
        and spec.context.conversationLifecycleState or nil
    local origin
    local selectionOrigin = spec.context and spec.context.player
        or getSpecificPlayer and getSpecificPlayer(0) or nil
    local registry = PNC.Registry
    if registry and type(registry.GetLiveZombie) == "function"
        and recipientID
    then
        local ok, body = pcall(registry.GetLiveZombie, recipientID)
        if ok then origin = body end
    end
    origin = origin or spec.context and spec.context.player
        or getSpecificPlayer and getSpecificPlayer(0) or nil
    return {
        npcID = spec.npcID,
        targetID = spec.npcID,
        actor = actorID and { id = actorID } or nil,
        recipient = recipientID and { id = recipientID } or nil,
        dialogueID = session and session.conversationID,
        conversationID = session and session.conversationID,
        -- A nearby turn is fanned out as one request per NPC.  Keep the
        -- transport scope single so a companion command is not expanded a
        -- second time by the group command resolver.
        requestID = view and view.semanticRequestID or result.sequence,
        scope = "single",
        groupID = group and group.id,
        groupTurnID = group and group.activeTurn
            and group.activeTurn.id or nil,
        groupScope = group and "nearby" or "single",
        rawText = value,
        normalizedText = result.ir and result.ir.normalizedText,
        confidence = result.ir and result.ir.confidence,
        provenance = result.ir and result.ir.provenance,
        conversationToken = lifecycle and lifecycle.token or nil,
        worldOrigin = origin,
        selectionOrigin = selectionOrigin,
    }
end

Internal.Audit = audit
Internal.ActionContext = actionContext

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

local function copyActionWithTarget(actionIntent, target)
    local output = {}
    for key, value in pairs(actionIntent or {}) do output[key] = value end
    output.target = target
    return output
end

local function attachWorldTargetHint(actionIntent, context)
    if actionIntent and actionIntent.target
        and actionIntent.target.kind == "camp_site"
    then
        return actionIntent
    end
    if type(WorldTargetHints) ~= "table"
        or type(WorldTargetHints.Resolve) ~= "function"
        or not targetNeedsHint(actionIntent and actionIntent.target)
    then
        return actionIntent
    end

    local target = actionIntent.target
    local hint, reason = WorldTargetHints.Resolve(target, context)
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

local function attachCampSiteHint(actionIntent, context)
    local target = actionIntent and actionIntent.target
    local x = target and number(target.x or target.targetX)
    local y = target and number(target.y or target.targetY)
    if not actionIntent or actionIntent.action ~= "CAMP"
        or type(target) ~= "table"
        or target.kind ~= "camp_site"
        or x ~= nil or y ~= nil
        or target.siteID ~= nil or target.campfireID ~= nil
        or type(CampSiteHints) ~= "table"
        or type(CampSiteHints.Resolve) ~= "function"
    then
        return actionIntent
    end

    local hint, reason = CampSiteHints.Resolve(target, context)
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
        return actionIntent
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
    return copyActionWithTarget(actionIntent, targetCopy)
end

function Internal.DispatchInventoryQuery(view, result, value)
    local decision = result and result.decision or {}
    if type(decision.inventoryQuery) ~= "table"
        or type(InventoryQueryAdapter) ~= "table"
        or type(InventoryQueryAdapter.Dispatch) ~= "function"
    then
        return nil
    end
    local context = actionContext(view, result, value)
    local session = view and view.session
    session.semanticInventoryQueries = session.semanticInventoryQueries or {}
    local requestID = context.requestID
    session.semanticInventoryQueries[tostring(requestID)] = {
        rawText = value,
        query = decision.inventoryQuery,
        at = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0,
    }
    local dispatched = InventoryQueryAdapter.Dispatch(
        decision.inventoryQuery, context)
    dispatched = type(dispatched) == "table" and dispatched or {
        status = "rejected", accepted = false,
    }
    dispatched.requestID = dispatched.request
        and dispatched.request.requestID or requestID
    dispatched.query = decision.inventoryQuery
    audit("semantic.inventory.dispatch", {
        npcID = context.npcID,
        conversationID = context.conversationID,
        requestID = dispatched.requestID,
        status = dispatched.status,
        accepted = dispatched.accepted == true,
        pending = dispatched.pending == true,
        reason = dispatched.reason,
        query = decision.inventoryQuery,
    }, { requestID = dispatched.requestID })
    if dispatched.result and dispatched.result.status
        and dispatched.result.status ~= "pending"
        and Input.ReceiveInventoryQueryResult
    then
        Input.ReceiveInventoryQueryResult(dispatched.result)
    end
    return dispatched
end

function Internal.DispatchAction(view, result, value)
    local decision = result and result.decision or {}
    if decision.giftOffer then
        if type(Internal.DispatchGiftOffer) == "function" then
            return Internal.DispatchGiftOffer(view, result, value)
        end
        return {
            status = "gift_dispatch_unavailable",
            accepted = false,
            reason = "gift_dispatch_unavailable",
        }
    end
    if decision.inventoryQuery then
        return Internal.DispatchInventoryQuery(view, result, value)
    end
    if not decision.actionIntent then return nil end
    local context = actionContext(view, result, value)
    local actionIntent = attachCampSiteHint(
        decision.actionIntent, context)
    actionIntent = attachWorldTargetHint(actionIntent, context)
    local commandResult = CommandAdapter.Dispatch(
        actionIntent, context)
    if commandResult.status ~= "unmapped" then
        audit("semantic.command.dispatch", {
            npcID = context.npcID,
            conversationID = context.conversationID,
            requestID = context.requestID,
            action = actionIntent.action,
            status = commandResult.status,
            accepted = commandResult.accepted == true,
            reason = commandResult.reason,
        }, { requestID = context.requestID })
        return commandResult
    end
    local session = view and view.session
    local provisionalID = context.requestID
    if session and provisionalID then
        session.semanticTaskRequests = session.semanticTaskRequests or {}
        -- Register before transport so a same-tick server response cannot
        -- race the request into the inactive-result cache.
        session.semanticTaskRequests[tostring(provisionalID)] = {
            action = actionIntent.action,
            rawText = value,
        }
    end
    local taskResult = TaskAdapter.Dispatch(actionIntent, context)
    local status = tostring(taskResult and taskResult.status or "")
    local request = taskResult and taskResult.request or nil
    local requestID = request and request.requestID or context.requestID
    audit("semantic.task.dispatch", {
        npcID = context.npcID,
        conversationID = context.conversationID,
        requestID = requestID,
        action = actionIntent.action,
        status = status,
        accepted = taskResult and taskResult.accepted == true,
        reason = taskResult and taskResult.reason,
        planID = taskResult and taskResult.planID,
    }, { requestID = requestID })
    if session and requestID and status ~= "unmapped"
        and status ~= "skipped"
    then
        session.semanticTaskRequests = session.semanticTaskRequests or {}
        if provisionalID and tostring(provisionalID) ~= tostring(requestID) then
            session.semanticTaskRequests[tostring(provisionalID)] = nil
        end
        session.semanticTaskRequests[tostring(requestID)] = {
            action = actionIntent.action,
            rawText = value,
            request = request,
            siteLabel = taskResult and taskResult.details
                and taskResult.details.siteLabel,
            siteScope = taskResult and taskResult.details
                and taskResult.details.siteScope,
            siteID = taskResult and taskResult.details
                and taskResult.details.siteID,
        }
    elseif session and provisionalID then
        session.semanticTaskRequests[tostring(provisionalID)] = nil
    end
    if taskResult and taskResult.accepted ~= true
        and Input.ReceiveSemanticTaskResult
    then
        Input.ReceiveSemanticTaskResult({
            requestID = requestID,
            npcID = context.npcID,
            action = actionIntent.action,
            accepted = false,
            status = status ~= "" and status or "failed",
            reason = taskResult.reason,
            admissionReason = taskResult.details
                and taskResult.details.reason,
            admissionPlanState = taskResult.details
                and taskResult.details.planState,
            admissionStepState = taskResult.details
                and taskResult.details.stepState,
            admissionActive = taskResult.details
                and taskResult.details.active,
            admissionPlanID = taskResult.details
                and taskResult.details.planID,
            admissionCleanupReason = taskResult.details
                and taskResult.details.cleanupReason,
        })
    end
    return taskResult
end

return Input
