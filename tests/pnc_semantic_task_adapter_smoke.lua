local T = require "tests/support/test"
T.addPackagePaths()

PNC = { Semantics = {} }
local Adapter = T.load(
    "ProjectHoomans",
    "client",
    "PNC/Semantics/PNC_SemanticTaskAdapter.lua"
)

local submitted
Adapter.RegisterAction("FETCH", {
    CanSubmit = function(request)
        return request.object and request.object.category == "WATER"
    end,
    Dispatch = function(request, context)
        submitted = { request = request, context = context }
        return true, "sent"
    end,
})

local accepted = Adapter.Dispatch({
    intent = "REQUEST",
    speechAct = "REQUEST",
    action = "FETCH",
    object = { category = "WATER", quantity = "SOME" },
    confidence = 0.94,
}, {
    requestID = "dialogue:1",
    npcID = "npc:alice",
    actor = { id = "player:one" },
    recipient = { id = "npc:alice" },
    rawText = "Bring me water",
})
T.equal(accepted.status, "accepted", "registered task handler is dispatched")
T.equal(accepted.reason, "sent", "transport result is preserved")
T.equal(submitted.request.action, "FETCH", "adapter builds the task contract")
T.equal(submitted.request.object.category, "WATER",
    "adapter preserves compositional object data")
T.equal(submitted.context.npcID, "npc:alice",
    "adapter passes conversation context to transport")
T.equal(submitted.request.actor.id, "player:one",
    "task contract preserves the conversation actor")
T.equal(submitted.request.recipient.id, "npc:alice",
    "task contract preserves the addressed recipient")

local negated = Adapter.Dispatch({
    action = "FETCH",
    modifiers = { negated = true },
}, { rawText = "Don't fetch that" })
T.equal(negated.status, "skipped", "negated task actions never dispatch")
T.equal(submitted.request.action, "FETCH",
    "negation does not replace a prior submitted request")

local unmapped = Adapter.Dispatch({ action = "BUILD" }, {})
T.equal(unmapped.status, "unmapped", "unknown task actions fail closed")
T.equal(unmapped.reason, "unmapped_action",
    "unknown task reason is diagnosable")

T.finish("pnc_semantic_task_adapter_smoke")
