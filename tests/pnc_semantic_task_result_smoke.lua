local T = require "tests/support/test"
T.addPackagePaths()

PsychopatzCore = { Conversation = {} }
PNC = { Semantics = {} }
T.load(
    "ProjectHoomans",
    "client",
    "PNC/Semantics/PNC_SemanticDialogueInput_Presentation.lua"
)
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

session.semanticTaskRequests["task:camp"] = {
    action = "CAMP",
    request = {
        target = {
            kind = "camp_site",
            clientHint = {
                label = "client guessed room",
                scope = "room",
            },
        },
    },
}
local campAdmitted = Input.ReceiveSemanticTaskResult({
    requestID = "task:camp",
    npcID = "npc:alice",
    action = "CAMP",
    accepted = true,
    status = "accepted",
    siteLabel = "living room",
    siteScope = "room",
})
T.equal(campAdmitted, true, "camp admission is accepted")
T.equal(session.semanticTaskRequests["task:camp"].siteLabel,
    "living room", "authoritative camp label overrides the client hint")

local campCompleted = Input.ReceiveSemanticTaskResult({
    requestID = "task:camp",
    npcID = "npc:alice",
    action = "CAMP",
    accepted = true,
    status = "completed",
})
T.equal(campCompleted, true, "completed camp reaches the conversation queue")
T.equal(queued[2].payload.fallback,
    "We're set up in the living room.",
    "completed camp response names the selected room")

local immediateCamp = Input.Internal.QueueDeterministicResponse(
    view,
    "let's camp here",
    {
        ir = {},
        decision = {
            branch = "CAMP_REQUESTED",
            action = "CAMP",
            actionIntent = { action = "CAMP" },
            response = {
                templateID = "semantic.camp.requested",
                fallback = "I'll find us a safe place to camp.",
            },
        },
    },
    {
        accepted = true,
        status = "accepted",
        action = "CAMP",
        request = {
            target = {
                kind = "camp_site",
                clientHint = {
                    label = "campfire",
                    scope = "campfire",
                },
            },
        },
    }
)
T.equal(immediateCamp, true,
    "camp admission acknowledgement is queued")
T.equal(queued[3].payload.fallback,
    "I'll set up camp by the campfire.",
    "immediate camp acknowledgement names the observed campfire")

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
T.equal(queued[4].payload.fallback, "I don't have that.",
    "item failure has a semantic response")
T.equal(queued[4].metadata.source.reason, "item_not_found",
    "internal failure reason remains available in metadata")
T.equal(queued[4].metadata.source.admissionReason, "blocked",
    "admission diagnostics remain available in metadata")

local taskResponses = Input.Internal.TaskResponses
T.equal(taskResponses.ForResult({ status = "completed" }, nil, "FETCH"),
    "Here you go.", "completed fetch has an item handoff response")
T.equal(taskResponses.ForResult({
    status = "blocked",
    reason = "item_not_found",
}, nil, "FETCH"), "I don't have that.",
    "missing fetch item has a useful response")
T.equal(taskResponses.ForResult({
    status = "rejected",
    reason = "fetch_source_unsupported",
}, nil, "FETCH"),
    "I can only fetch something I'm already carrying.",
    "unsupported fetch source is explained")
T.equal(taskResponses.ForResult({
    status = "rejected",
    reason = "fetch_destination_unsupported",
}, nil, "FETCH"),
    "I can bring that to you, but not to someone else right now.",
    "unsupported fetch destination is explained")

local function campFailureResponse(requestID, reason)
    session.semanticTaskRequests[requestID] = { action = "CAMP" }
    local received = Input.ReceiveSemanticTaskResult({
        requestID = requestID,
        npcID = "npc:alice",
        action = "CAMP",
        accepted = false,
        status = "blocked",
        reason = reason,
    })
    T.equal(received, true, "camp failure reaches the conversation queue")
    return queued[#queued].payload.fallback
end

T.equal(campFailureResponse("task:camp-no-site", "camp_no_visible_site"),
    "I don't see a safe place to camp nearby.",
    "missing visible camp sites retain their response")
T.equal(campFailureResponse("task:camp-room", "room_not_found"),
    "I can't find a safe room like that nearby.",
    "missing requested rooms retain their response")
T.equal(campFailureResponse("task:campfire", "campfire_not_found"),
    "There isn't a usable campfire nearby.",
    "missing campfires retain their response")

local groupQueued = {}
local groupSession = {
    queueMessage = function(self, speaker, payload, metadata)
        groupQueued[#groupQueued + 1] = {
            speaker = speaker,
            payload = payload,
            metadata = metadata,
        }
    end,
}
view.groupConversation = {
    id = "group:1",
    participantIDs = { "npc:alice", "npc:bob" },
    activeTurn = { id = "turn:2" },
    PrimarySession = function() return groupSession end,
    SpeakerFor = function(_, memberView)
        T.equal(memberView, view, "group presentation uses the matching view")
        return "npc:bob", "Bob"
    end,
}
session.semanticTaskRequests["task:group"] = { action = "WAIT_AT" }
local groupResult = Input.ReceiveSemanticTaskResult({
    requestID = "task:group",
    npcID = "npc:alice",
    action = "WAIT_AT",
    accepted = true,
    status = "completed",
})
T.equal(groupResult, true, "group task result is presented")
T.equal(#queued, 7, "group result uses the primary session")
T.equal(groupQueued[1].speaker, "npc", "group result keeps its speaker role")
T.equal(groupQueued[1].metadata.speakerID, "npc:bob",
    "group result uses the selected speaker identity")
T.equal(groupQueued[1].metadata.speakerName, "Bob",
    "group result uses the selected speaker name")
T.equal(groupQueued[1].metadata.participants[2], "npc:bob",
    "group result retains its participant list")
T.equal(groupQueued[1].metadata.source.groupID, "group:1",
    "group result records its group")
T.equal(groupQueued[1].metadata.source.groupTurnID, "turn:2",
    "group result records its active turn")

T.finish("pnc_semantic_task_result_smoke")
