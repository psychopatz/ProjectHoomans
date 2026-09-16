local T = require "tests/support/test"
T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "server" },
})

local dirtyDomain
local sent

PNC = {
    Core = {
        Now = function() return 48 end,
        IsAuthority = function() return true end,
    },
    Semantics = {},
    Registry = { Data = {} },
    Network = {},
    ConversationScene = {},
}

function PNC.Registry.Get(id)
    return PNC.Registry.Data[tostring(id)]
end

function PNC.Registry.MarkDirty(_, domain)
    dirtyDomain = domain
    return true
end

function PNC.ConversationScene.ValidateConversationLease(
    record, _, token
)
    if record.runtime and record.runtime.conversationLease
        and tostring(record.runtime.conversationLease.token)
            == tostring(token or "")
    then
        return true, record.runtime.conversationLease
    end
    return false, "invalid_conversation"
end

function PNC.Network.SendSemanticCognition(
    player, projection, reason, requestID, npcID
)
    sent = {
        player = player,
        projection = projection,
        reason = reason,
        requestID = requestID,
        npcID = npcID,
    }
    return true
end

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticCognitionProjection.lua"
)
local Service = T.load(
    "ProjectHoomans",
    "server",
    "PNC/Semantics/PNC_SemanticCognitionService.lua"
)

local record = {
    id = "observer",
    alive = true,
    runtime = {
        conversationLease = { token = "lease:1" },
    },
}
PNC.Registry.Data.observer = record

local accepted, fact, projection = Service.Remember("observer", {
    subject = "SEEN",
    targetID = "sarah",
    targetName = "Sarah",
    known = true,
    value = true,
    source = "witnessed",
    evidence = { method = "line_of_sight" },
    observedAt = 40,
    recordedAt = 40,
})
T.equal(accepted, true, "authority accepts evidenced cognition")
T.equal(fact.status, "known", "known compatibility flag normalizes safely")
T.equal(record.semanticCognition.revision, 1,
    "remembering cognition increments the projection revision")
T.equal(dirtyDomain, "semantic_cognition",
    "cognition writes use the existing persistence dirty boundary")

accepted = Service.Remember("observer", {
    subject = "SECRET",
    targetID = "sarah",
    status = "known",
    value = "private",
    clientVisible = false,
    observedAt = 41,
})
T.equal(accepted, true, "private cognition can be stored authoritatively")

local filtered = Service.BuildProjection("observer", {
    subject = "SEEN",
    targetID = "sarah",
})
T.truthy(filtered.facts["SEEN|sarah"],
    "projection includes only the requested public fact")
T.falsy(filtered.facts["SECRET|sarah"],
    "projection never exposes private cognition")

local player = { username = "Alex" }
local conversationProjection, reason = Service.BuildForConversation(
    player,
    "observer",
    {
        subject = "SEEN",
        targetID = "sarah",
        conversationToken = "lease:1",
    }
)
T.truthy(conversationProjection, "valid conversation lease permits projection")
T.equal(reason, nil, "valid cognition projection has no failure reason")

accepted, reason = Service.HandleRequest(player, {
    npcID = "observer",
    subject = "SEEN",
    targetID = "sarah",
    conversationToken = "lease:1",
    requestID = "request:1",
})
T.equal(accepted, true, "request handler accepts a valid scoped request")
T.equal(sent.requestID, "request:1", "response preserves request correlation")
T.truthy(sent.projection.facts["SEEN|sarah"],
    "response sends the scoped cognition projection")

accepted, reason = Service.HandleRequest(player, {
    npcID = "observer",
    subject = "SEEN",
    targetID = "sarah",
    conversationToken = "wrong-lease",
    requestID = "request:2",
})
T.equal(accepted, false, "invalid lease cannot read private cognition")
T.equal(reason, "invalid_conversation",
    "invalid lease reason is returned to the client")
T.equal(sent.requestID, "request:2",
    "rejection still correlates to the requesting turn")
T.equal(sent.npcID, "observer",
    "rejection preserves the observer identity for the client cache")
T.equal(sent.projection, nil, "rejection does not send a fact projection")

accepted = Service.Forget("observer", "SEEN", "sarah")
T.equal(accepted, true, "authority can forget a cognition fact")
T.falsy(record.semanticCognition.facts["SEEN|sarah"],
    "forgotten cognition is removed from the authority store")

PNC.Core.IsAuthority = function() return false end
accepted, reason = Service.Remember("observer", {
    subject = "SEEN",
    targetID = "sarah",
    status = "known",
    observedAt = 50,
})
T.equal(accepted, false, "non-authority cannot mutate cognition")
T.equal(reason, "not_authority", "non-authority mutation is rejected")

T.finish("pnc_semantic_cognition_service_smoke")
