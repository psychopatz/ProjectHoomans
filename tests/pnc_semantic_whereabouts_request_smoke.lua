local T = require "tests/support/test"
T.addPackagePaths({
    { "ProjectHoomans", "client" },
})

local clientState = {
    pendingSemanticCognition = {},
    semanticCognitionDialogueRequests = {},
}
PNC = {
    Network = { ClientState = clientState },
    Client = {},
}

PNC.Client.RequestSemanticCognition = function(npcID, options)
    clientState.pendingSemanticCognition[npcID] = {
        requestID = "fact:1",
        subject = options.subject,
        targetID = options.targetID,
    }
    return true, "queued", "fact:1"
end

local Requests = T.load(
    "ProjectHoomans", "client",
    "PNC/Semantics/PNC_SemanticDialogueInput_Requests.lua"
)
local session = {
    conversationID = "conversation:whereabouts",
}
local view = {
    spec = {
        npcID = "npc-speaker",
        context = {
            conversationLifecycleState = { token = "lease:whereabouts" },
        },
    },
    session = session,
}

local accepted, reason, requestID, waiting = Requests.RequestCognitionForIR(
    view,
    {
        intent = "QUESTION",
        subject = "COMMUNITY_ROLE_WHEREABOUTS",
        target = {
            kind = "community_role",
            id = "trader",
            role = "trader",
            unresolved = false,
        },
        extensions = {
            facts = {
                COMMUNITY_ROLE_WHEREABOUTS = { status = "known" },
            },
        },
    }
)
T.equal(accepted, true,
    "live whereabouts facts refresh even when a prior fact is known")
T.equal(reason, "queued", "live fact request keeps the transport reason")
T.equal(requestID, "fact:1", "live fact request preserves correlation")
T.equal(waiting, true, "live fact request enters the deferred dialogue lane")
T.equal(session.semanticFactRequestID, "fact:1",
    "live fact request binds the dialogue session")
T.equal(
    clientState.semanticCognitionDialogueRequests["fact:1"].kind,
    "fact",
    "live fact request is typed separately from gossip")

T.finish("pnc_semantic_whereabouts_request_smoke")
