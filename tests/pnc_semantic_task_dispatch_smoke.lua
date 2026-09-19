local T = require "tests/support/test"
T.addPackagePaths()

local observedProvisionalRequest
local dispatchedAction
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

T.finish("pnc_semantic_task_dispatch_smoke")
