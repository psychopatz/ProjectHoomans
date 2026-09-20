-- Side-effect boundary for semantic dialogue actions.
-- Known movement actions use the existing authoritative command transport;
-- task actions use only explicitly registered domain transports.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

require "PNC/Semantics/PNC_SemanticDiagnostics"
require "PNC/Semantics/PNC_SemanticWorldTargetHints"
require "PNC/Semantics/PNC_SemanticCampSiteHints"
require "PNC/Semantics/PNC_SemanticCampSite"
require "PNC/Semantics/PNC_SemanticDialogueInput_ActionContext"
require "PNC/Semantics/PNC_SemanticDialogueInput_ActionTargetHints"
require "PNC/Semantics/PNC_SemanticDialogueInput_TaskDispatch"

local Input = PNC.Semantics.DialogueInput or {}
PNC.Semantics.DialogueInput = Input

local Internal = Input.Internal or {}
Input.Internal = Internal

local EXECUTABLE_ACTION_BRANCHES = {
    COMMAND_ACCEPTED = true,
    REQUEST_ACKNOWLEDGED = true,
    CAMP_REQUESTED = true,
}
local GIFT_DISPATCH_BRANCHES = {
    GIFT_OFFER_DISPATCHED = true,
    GIFT_SELECTION_REQUIRED = true,
    GIFT_CONSENT_GRANTED = true,
}
local INVENTORY_DISPATCH_BRANCHES = {
    INVENTORY_QUERY_RECEIVED = true,
}

local function dispatchBranchEligibility(decision, executableBranches)
    if decision.route == "llm_fallback" then
        return false, "llm_fallback_pending"
    end
    if executableBranches[decision.branch] == true then
        return true
    end
    if decision.branch == "ASK_CLARIFICATION"
        or decision.branch == "AMBIGUOUS_INPUT"
    then
        return false, "clarification_required"
    end
    return false, "dispatch_branch_not_approved"
end

local function blockedDispatch(reason)
    return {
        status = "semantic_dispatch_blocked",
        accepted = false,
        reason = reason,
    }
end

local InventoryPending = require
    "PNC/Semantics/PNC_SemanticDialogueInput_InventoryPending"
local CommandAdapter = PNC.Semantics.CommandAdapter
local InventoryQueryAdapter = PNC.Semantics.InventoryQueryAdapter
local Diagnostics = PNC.Semantics.SemanticDiagnostics
local WorldTargetHints = PNC.Semantics.ClientWorldTargetHints
local CampSiteHints = PNC.Semantics.ClientCampSiteHints
local CampSite = PNC.Semantics.CampSite
local ActionContext = PNC.Semantics.DialogueInputActionContext
local ActionTargetHints = PNC.Semantics.DialogueInputActionTargetHints

local function audit(eventName, data, options)
    if not Diagnostics
        or type(Diagnostics.IsEnabled) ~= "function"
        or Diagnostics.IsEnabled() ~= true
    then
        return false
    end
    return Diagnostics.Record(eventName, data, options)
end

local actionContext = ActionContext.Build
Internal.Audit = audit
Internal.ActionContext = actionContext

function Internal.DispatchInventoryQuery(view, result, value)
    local decision = result and result.decision or {}
    if type(decision.inventoryQuery) ~= "table"
        or type(InventoryQueryAdapter) ~= "table"
        or type(InventoryQueryAdapter.Dispatch) ~= "function"
    then
        return nil
    end
    local context = actionContext(view, result, value)
    local requestID = context.requestID
    local registered, registrationReason = InventoryPending.Register(
        view, requestID, {
            rawText = value,
            query = decision.inventoryQuery,
            at = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0,
        })
    local dispatched
    if registered then
        -- Register before transport because local-server responses can arrive
        -- synchronously from inside Dispatch.
        dispatched = InventoryQueryAdapter.Dispatch(
            decision.inventoryQuery, context)
    else
        dispatched = {
            status = "rejected",
            accepted = false,
            reason = registrationReason,
        }
    end
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
    local resultStatus = type(dispatched.result) == "table"
        and dispatched.result.status or nil
    if dispatched.result and dispatched.result.status
        and dispatched.result.status ~= "pending"
        and Input.ReceiveInventoryQueryResult
    then
        Input.ReceiveInventoryQueryResult(dispatched.result)
    end
    if registered and dispatched.pending ~= true
        and resultStatus ~= "pending"
    then
        InventoryPending.Remove(view, requestID)
    end
    return dispatched
end

function Internal.DispatchAction(view, result, value)
    local decision = result and result.decision or {}
    if decision.giftConsent then
        if decision.giftConsent.status ~= "granted" then return nil end
        local allowed, blockReason = dispatchBranchEligibility(
            decision, GIFT_DISPATCH_BRANCHES)
        if not allowed then return blockedDispatch(blockReason) end
        if type(Internal.DispatchGiftConsent) == "function" then
            return Internal.DispatchGiftConsent(view, result, value)
        end
        return {
            status = "gift_dispatch_unavailable",
            accepted = false,
            reason = "gift_dispatch_unavailable",
        }
    end
    if decision.giftOffer then
        local allowed, blockReason = dispatchBranchEligibility(
            decision, GIFT_DISPATCH_BRANCHES)
        if not allowed then return blockedDispatch(blockReason) end
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
        local allowed, blockReason = dispatchBranchEligibility(
            decision, INVENTORY_DISPATCH_BRANCHES)
        if not allowed then return blockedDispatch(blockReason) end
        return Internal.DispatchInventoryQuery(view, result, value)
    end
    if not decision.actionIntent then return nil end
    local actionAllowed, actionBlockReason = dispatchBranchEligibility(
        decision, EXECUTABLE_ACTION_BRANCHES)
    if not actionAllowed then
        return blockedDispatch(actionBlockReason)
    end
    local context = actionContext(view, result, value)
    local actionIntent = ActionTargetHints.AttachCampSiteHint(
        decision.actionIntent, context, CampSite, CampSiteHints, audit)
    if actionIntent and actionIntent.action == "CAMP"
        and actionIntent.target
        and type(actionIntent.target.clientHint) == "table"
    then
        -- Reuse the already-bounded observation for the command adapter. This
        -- avoids a second client scan in the same dialogue dispatch tick.
        context.campSiteHint = actionIntent.target.clientHint
    end
    actionIntent = ActionTargetHints.AttachWorldTargetHint(
        actionIntent, context, WorldTargetHints, audit)
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
    local taskDispatch = Internal.DispatchTaskAction
    if type(taskDispatch) ~= "function" then
        return {
            status = "task_dispatch_unavailable",
            accepted = false,
            reason = "task_dispatch_unavailable",
        }
    end
    return taskDispatch(view, actionIntent, context, value)
end

return Input
