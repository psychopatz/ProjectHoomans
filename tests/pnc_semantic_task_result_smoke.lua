local T = require "tests/support/test"
T.addPackagePaths()

PsychopatzCore = { Conversation = {} }
PNC = { Semantics = {} }
local Input = T.load(
    "ProjectHoomans",
    "client",
    "PNC/Semantics/PNC_SemanticDialogueInput_Tasks.lua"
)

local queued = {}
local session = {
    semanticTaskRequests = {},
    queueMessage = function(self, speaker, payload, metadata)
        queued[#queued + 1] = {
            speaker = speaker,
            payload = payload,
            metadata = metadata,
        }
    end,
}
local view = {
    spec = { npcID = "npc:alice" },
    session = session,
}
Input.ActiveView = view

session.semanticTaskRequests["task:wait"] = {
    action = "WAIT_AT",
}
local admitted, admittedReason = Input.ReceiveSemanticTaskResult({
    requestID = "task:wait",
    npcID = "npc:alice",
    action = "WAIT_AT",
    accepted = true,
    status = "accepted",
})
T.equal(admitted, true, "task admission is accepted")
T.equal(admittedReason, "task_admitted", "admission reason is stable")
T.truthy(session.semanticTaskRequests["task:wait"],
    "admission keeps the request pending for execution")
T.equal(#queued, 0, "admission does not duplicate the acknowledgement")

local completed = Input.ReceiveSemanticTaskResult({
    requestID = "task:wait",
    npcID = "npc:alice",
    action = "WAIT_AT",
    accepted = true,
    status = "completed",
})
T.equal(completed, true, "completed task reaches the conversation queue")
T.falsy(session.semanticTaskRequests["task:wait"],
    "completed task is removed from the pending map")
T.equal(queued[1].payload.fallback, "I'm here.",
    "completed wait task has a human-readable response")

session.semanticTaskRequests["task:give"] = { action = "GIVE" }
local failed = Input.ReceiveSemanticTaskResult({
    requestID = "task:give",
    npcID = "npc:alice",
    action = "GIVE",
    accepted = false,
    status = "blocked",
    reason = "item_not_found",
    admissionReason = "blocked",
    admissionPlanState = "RUNNING",
    admissionStepState = "BLOCKED",
})
T.equal(failed, true, "failed task reaches the conversation queue")
T.equal(queued[2].payload.fallback, "I don't have that.",
    "item failure has a semantic response")
T.equal(queued[2].metadata.source.reason, "item_not_found",
    "internal failure reason remains available in metadata")
T.equal(queued[2].metadata.source.admissionReason, "blocked",
    "admission diagnostics remain available in metadata")

T.finish("pnc_semantic_task_result_smoke")
