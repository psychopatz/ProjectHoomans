local T = require "tests/support/test"
T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "client" },
    { "ProjectHoomans", "common_lua" },
})
getModFileReader = function(modID, path)
    if modID ~= "ProjectHoomans" then return nil end
    local handle = io.open(
        T.path("ProjectHoomans", "common_mod", path),
        "r"
    )
    if not handle then return nil end
    return {
        readLine = function() return handle:read("*l") end,
        close = function() return handle:close() end,
    }
end

PNC = {
    Core = { Now = function() return 100 end },
    Network = { ClientState = {} },
}

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticCognitionProjection.lua"
)
local Cognition = T.load(
    "ProjectHoomans",
    "client",
    "PNC/Semantics/PNC_SemanticCognitionClient.lua"
)

Cognition.Reset()
local memory = PNC.Conversation.Memory
T.load(
    "ProjectHoomans",
    "common_lua",
    "PNC/Conversation/Definitions/Memory/EventTypes/00_PNC_ConversationMemoryEventTypes.lua"
)
T.load(
    "ProjectHoomans",
    "common_lua",
    "PNC/Conversation/Definitions/Memory/GossipTemplates/00_PNC_ConversationGossipTemplates.lua"
)
local accepted
local reason
accepted, reason = Cognition.ApplyPayload({
    requestID = "request:1",
    projection = {
        npcID = "observer",
        revision = 2,
        facts = {
            {
                subject = "SEEN",
                targetID = "sarah",
                targetName = "Sarah",
                status = "known",
                value = true,
                source = "witnessed",
                observedAt = 10,
            },
        },
    },
})
T.equal(accepted, true, "client accepts a valid cognition projection")
T.equal(reason, "updated", "client reports a fresh projection")
T.equal(
    Cognition.GetFact("observer", "SEEN", "sarah").value,
    true,
    "client cache exposes the received fact"
)

accepted, reason = Cognition.ApplyPayload({
    projection = {
        npcID = "observer",
        revision = 1,
        facts = {
            {
                subject = "SEEN",
                targetID = "sarah",
                status = "known",
                value = false,
                observedAt = 1,
            },
        },
    },
})
T.equal(accepted, true, "stale packets are harmlessly acknowledged")
T.equal(reason, "stale_projection", "client identifies stale packets")
T.equal(
    Cognition.GetFact("observer", "SEEN", "sarah").value,
    true,
    "stale packets cannot overwrite the current fact"
)

accepted, reason = Cognition.ApplyPayload({
    projection = {
        npcID = "observer",
        revision = 3,
        replace = true,
        scope = { subject = "SEEN", targetID = "sarah" },
        facts = {},
    },
})
T.equal(accepted, true, "client accepts an empty scoped replacement")
T.equal(reason, "updated", "client reports the cache removal")
T.falsy(Cognition.GetFact("observer", "SEEN", "sarah"),
    "client removes facts absent from an authoritative replacement")

accepted, reason = Cognition.ApplyPayload({
    projection = {
        npcID = "other_observer",
        revision = 1,
        facts = {},
    },
})
T.equal(accepted, true, "a distinct NPC receives an isolated cache entry")
T.falsy(Cognition.GetFact("other_observer", "SEEN", "sarah"),
    "NPC cognition caches remain isolated by observer")

accepted, reason = Cognition.ApplyPayload({
    npcID = "observer",
    reason = "invalid_lease",
    requestID = "request:2",
})
T.equal(accepted, false, "failed server projection does not create facts")
T.equal(reason, "invalid_lease", "client preserves server rejection reason")

local completedRequest
local completedPayload
local gossipRequest = { requestID = "gossip:1" }
local clientState = PNC.Network.ClientState
PNC.Semantics.DialogueInput = {
    CompleteGossipRequest = function(request, payload)
        completedRequest = request
        completedPayload = payload
        return true
    end,
}
clientState.pendingSemanticCognition.observer = {
    requestID = "gossip:1",
    targetID = "self",
    subject = "GOSSIP",
}
clientState.semanticCognitionDialogueRequests["gossip:1"] = gossipRequest
accepted = Cognition.ApplyPayload({
    requestID = "gossip:1",
    projection = {
        npcID = "observer",
        revision = 4,
        facts = {},
    },
    g = { 4002 },
    gs = "Mara",
})
T.equal(accepted, true,
    "client accepts server-projected shareable gossip")
T.equal(completedRequest, gossipRequest,
    "server gossip response completes its matching dialogue request")
T.equal(completedPayload.requestID, "gossip:1",
    "gossip callback preserves response correlation")
local gossipContext = Cognition.GetGossipContext("observer", "self")
T.equal(gossipContext.statements[1],
    "I got away when a whole horde came after me.",
    "client renders the horde gossip template from the server payload")
T.falsy(clientState.pendingSemanticCognition.observer,
    "completed gossip request leaves no stale cognition request")

local failedGossipRequest = { requestID = "gossip:2" }
clientState.pendingSemanticCognition.observer = {
    requestID = "gossip:2",
    targetID = "self",
    subject = "GOSSIP",
}
clientState.semanticCognitionDialogueRequests["gossip:2"] =
    failedGossipRequest
accepted, reason = Cognition.ApplyPayload({
    npcID = "observer",
    requestID = "gossip:2",
    reason = "invalid_lease",
})
T.equal(accepted, false,
    "server rejection does not create a cognition projection")
T.equal(reason, "invalid_lease",
    "client preserves a gossip request rejection")
T.equal(completedRequest, failedGossipRequest,
    "rejected gossip request still completes its pending dialogue turn")
T.equal(completedPayload.reason, "invalid_lease",
    "rejected gossip completion keeps the server reason")
T.falsy(Cognition.GetGossipContext("observer", "self"),
    "rejected gossip does not leave stale memory statements")

T.finish("pnc_semantic_cognition_client_smoke")
