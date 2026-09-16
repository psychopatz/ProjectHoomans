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

local giveSubmitted
PNC.Client = {
    RequestSemanticTask = function(request, context)
        giveSubmitted = { request = request, context = context }
        return true, "sent"
    end,
}
local giveAccepted = Adapter.Dispatch({
    intent = "REQUEST",
    speechAct = "REQUEST",
    action = "GIVE",
    object = { text = "apple", unresolved = true, quantity = "SOME" },
    confidence = 0.89,
}, {
    requestID = "dialogue:give:1",
    npcID = "npc:alice",
    conversationToken = "lease:1",
    rawText = "Can you give me an apple?",
})
T.equal(giveAccepted.status, "accepted",
    "give item uses the shared task transport")
T.equal(giveSubmitted.request.action, "GIVE",
    "give item preserves its semantic action")
T.equal(giveSubmitted.request.object.text, "apple",
    "give item preserves unresolved MarketSense text")
T.equal(giveSubmitted.context.conversationToken, "lease:1",
    "give item carries the conversation authority token")

local campSubmitted
PNC.Client.RequestSemanticTask = function(request, context)
    campSubmitted = { request = request, context = context }
    return true, "sent"
end
local campAccepted = Adapter.Dispatch({
    intent = "REQUEST",
    speechAct = "REQUEST",
    action = "CAMP",
    target = { kind = "camp_site", scope = "room",
        roomType = "BEDROOM", roomQuery = "bedroom" },
    confidence = 0.95,
}, {
    requestID = "dialogue:camp:1",
    npcID = "npc:alice",
    conversationToken = "lease:1",
    rawText = "Let's camp in the bedroom",
})
T.equal(campAccepted.status, "accepted",
    "camp uses the shared semantic task transport")
T.equal(campSubmitted.request.action, "CAMP",
    "camp preserves its semantic action")
T.equal(campSubmitted.request.target.scope, "room",
    "camp preserves the room-scoped target")

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
