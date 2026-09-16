local T = require "tests/support/test"
T.addPackagePaths()

PsychopatzCore = {
    RuntimeRole = {
        AllowsServerCode = function() return true end,
    },
}
PNC = {
    Core = { IsAuthority = function() return true end },
    Semantics = {},
}

local Service = T.load(
    "ProjectHoomans",
    "server",
    "PNC/Semantics/PNC_SemanticTaskRequestService.lua"
)

local handled
local registered, definition = Service.RegisterHandler("FETCH", {
    Validate = function(request, context)
        return request.object and request.object.category == "WATER"
            and context.npcID == "npc:alice", "unsupported_fetch"
    end,
    Submit = function(request, context)
        handled = { request = request, context = context }
        return true, "queued", { durable = false }
    end,
})
T.equal(registered, true, "domain handler registration succeeds")
T.equal(definition.action, "FETCH", "handler action is normalized")

local accepted = Service.Submit({
    kind = "semantic_task_request",
    schemaVersion = 1,
    requestID = "dialogue:1",
    intent = "REQUEST",
    speechAct = "REQUEST",
    action = "fetch",
    object = { category = "WATER" },
    rawText = "Bring me water",
    normalizedText = "bring me water",
    confidence = 0.94,
}, { npcID = "npc:alice" })
T.equal(accepted.status, "accepted", "server routes a valid task request")
T.equal(accepted.reason, "queued", "domain result is preserved")
T.equal(handled.request.action, "FETCH", "server normalizes action identity")
T.equal(handled.context.npcID, "npc:alice",
    "server keeps domain context separate from the contract")

local missing = Service.Submit({
    kind = "semantic_task_request",
    schemaVersion = 1,
    intent = "REQUEST",
    action = "HELP",
    rawText = "Help Sarah",
    normalizedText = "help sarah",
    confidence = 0.90,
}, { npcID = "npc:alice" })
T.equal(missing.status, "unhandled",
    "unsupported task actions do not enter Tasking")
T.equal(missing.reason, "no_task_handler",
    "missing downstream ownership is explicit")
T.falsy(missing.executed, "router never claims to execute gameplay")

Service.UnregisterHandler("FETCH")
local noHandler = Service.Submit({
    kind = "semantic_task_request",
    schemaVersion = 1,
    intent = "REQUEST",
    action = "FETCH",
    rawText = "Bring me water",
    normalizedText = "bring me water",
    confidence = 0.94,
})
T.equal(noHandler.status, "unhandled",
    "removing a handler fails closed")

T.finish("pnc_semantic_task_service_smoke")
