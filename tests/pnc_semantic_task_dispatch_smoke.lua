local T = require "tests/support/test"
T.addPackagePaths()

local observedProvisionalRequest
local dispatchedAction
local taskDispatchCalls = 0
local session = { semanticTaskRequests = {} }
local view = {
    spec = { npcID = "npc:alice" },
    session = session,
}

PNC = {
    Core = { Now = function() return 100 end },
    Semantics = {
        DialogueInput = { Internal = {} },
        CommandAdapter = {
            Dispatch = function()
                return { status = "unmapped", accepted = false }
            end,
        },
        TaskAdapter = {},
    },
}

local Input = T.load(
    "ProjectHoomans",
    "client",
    "PNC/Semantics/PNC_SemanticDialogueInput_Actions.lua"
)
Input.ActiveView = view
PNC.Semantics.TaskAdapter.Dispatch = function(actionIntent, context)
    taskDispatchCalls = taskDispatchCalls + 1
    dispatchedAction = actionIntent.action
    observedProvisionalRequest = session.semanticTaskRequests[
        tostring(context.requestID)
    ]
    local accepted, reason = Input.ReceiveSemanticTaskResult({
        requestID = context.requestID,
        npcID = context.npcID,
        action = actionIntent.action,
        accepted = true,
        status = "accepted",
    })
    T.equal(accepted, true,
        "same-tick admission finds its provisional task request")
    T.equal(reason, "task_admitted", "same-tick admission is retained")
    return {
        status = "accepted",
        accepted = true,
        request = { requestID = "task:17" },
        planID = "plan:wait",
    }
end

local viewResult = Input.Internal.DispatchAction(view, {
    sequence = "dialogue:17",
    ir = { normalizedText = "wait here", confidence = 0.95 },
    decision = {
        action = "WAIT_AT",
        branch = "COMMAND_ACCEPTED",
        route = "deterministic",
        actionIntent = { action = "WAIT_AT" },
    },
}, "wait here")

T.equal(dispatchedAction, "WAIT_AT",
    "unmapped commands continue through task dispatch")
T.equal(observedProvisionalRequest.action, "WAIT_AT",
    "task lifecycle registers the pending action before transport")
T.equal(viewResult.status, "accepted", "accepted task result is preserved")
T.equal(session.semanticTaskRequests["dialogue:17"], nil,
    "provisional request state is removed after transport assigns an ID")
T.equal(session.semanticTaskRequests["task:17"].request.requestID,
    "task:17", "task lifecycle stores the canonical transport request")
T.equal(session.semanticTaskRequests["task:17"].rawText, "wait here",
    "pending task state retains the original utterance")

local clarification = Input.Internal.DispatchAction(view, {
    sequence = "dialogue:18",
    decision = {
        branch = "ASK_CLARIFICATION",
        route = "deterministic",
        actionIntent = { action = "WAIT_AT" },
    },
}, "maybe wait here")
T.equal(clarification.reason, "clarification_required",
    "a clarification candidate never reaches gameplay dispatch")
T.equal(taskDispatchCalls, 1,
    "clarification leaves the task adapter untouched")

local missingBranch = Input.Internal.DispatchAction(view, {
    sequence = "dialogue:19",
    decision = {
        route = "deterministic",
        actionIntent = { action = "WAIT_AT" },
    },
}, "wait here")
T.equal(missingBranch.reason, "dispatch_branch_not_approved",
    "an action without an approved policy branch fails closed")
T.equal(taskDispatchCalls, 1,
    "a missing branch does not reach the task adapter")

local pendingLLM = Input.Internal.DispatchAction(view, {
    sequence = "dialogue:20",
    decision = {
        branch = "COMMAND_ACCEPTED",
        route = "llm_fallback",
        actionIntent = { action = "WAIT_AT" },
    },
}, "wait here")
T.equal(pendingLLM.reason, "llm_fallback_pending",
    "an unresolved LLM route cannot dispatch a candidate action")
T.equal(taskDispatchCalls, 1,
    "a pending LLM route does not reach the task adapter")

local giftDispatchCalls = 0
Input.Internal.DispatchGiftOffer = function()
    giftDispatchCalls = giftDispatchCalls + 1
    return { status = "accepted", accepted = true }
end
local blockedGift = Input.Internal.DispatchAction(view, {
    sequence = "dialogue:21",
    decision = {
        branch = "ASK_CLARIFICATION",
        route = "deterministic",
        giftOffer = { mode = "explicit", query = "water" },
    },
}, "maybe this is a gift")
T.equal(blockedGift.reason, "clarification_required",
    "a clarification candidate never reaches gift dispatch")
T.equal(giftDispatchCalls, 0,
    "clarification leaves the gift handler untouched")
local approvedGift = Input.Internal.DispatchAction(view, {
    sequence = "dialogue:22",
    decision = {
        branch = "GIFT_OFFER_DISPATCHED",
        route = "deterministic",
        giftOffer = { mode = "explicit", query = "water" },
    },
}, "I have water for you")
T.equal(approvedGift.accepted, true,
    "an approved gift branch keeps the existing gift dispatch path")
T.equal(giftDispatchCalls, 1,
    "an approved gift branch reaches the gift handler")

local inventoryDispatchCalls = 0
Input.Internal.DispatchInventoryQuery = function()
    inventoryDispatchCalls = inventoryDispatchCalls + 1
    return { status = "accepted", accepted = true }
end
local blockedInventory = Input.Internal.DispatchAction(view, {
    sequence = "dialogue:23",
    decision = {
        branch = "ASK_CLARIFICATION",
        route = "deterministic",
        inventoryQuery = { concept = "FOOD", mode = "LIST" },
    },
}, "do you have food?")
T.equal(blockedInventory.reason, "clarification_required",
    "a clarification candidate never reaches inventory dispatch")
T.equal(inventoryDispatchCalls, 0,
    "clarification leaves the inventory query handler untouched")
local approvedInventory = Input.Internal.DispatchAction(view, {
    sequence = "dialogue:24",
    decision = {
        branch = "INVENTORY_QUERY_RECEIVED",
        route = "deterministic",
        inventoryQuery = { concept = "FOOD", mode = "LIST" },
    },
}, "do you have food?")
T.equal(approvedInventory.accepted, true,
    "an approved inventory branch keeps the existing query path")
T.equal(inventoryDispatchCalls, 1,
    "an approved inventory branch reaches the query handler")

T.finish("pnc_semantic_task_dispatch_smoke")
