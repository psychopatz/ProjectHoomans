local T = require "tests/support/test"
T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "common_lua" },
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
    Identity = {
        HashText = function(value, seed)
            local hash = tonumber(seed) or 5381
            local index
            for index = 1, #tostring(value or "") do
                hash = (hash * 33 + string.byte(value, index)) % 2147483646
            end
            return math.max(1, hash)
        end,
        MixSeed = function(seed) return tonumber(seed) end,
    },
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
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Relationships/PNC_EntityRef.lua"
)
local Service = T.load(
    "ProjectHoomans",
    "server",
    "PNC/Semantics/PNC_SemanticCognitionService.lua"
)

local record = {
    id = "observer",
    name = "Mara",
    identitySeed = 17,
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

local player = {
    getUsername = function() return "Alex" end,
}
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
local playerKey = "player:Alex:char_gossip"
PNC.PlayerCharacters = {
    GetEntityKey = function() return playerKey end,
}
local playerTarget = memory.Events.ResolveTarget(playerKey)
record.memory = {
    v = memory.Events.VERSION,
    d = 1,
    l = {
        1102,
        playerTarget.seed,
        1,
        memory.Events.FLAG_SHAREABLE + memory.Events.FLAG_DURABLE,
    },
}
local gossipProjection = Service.BuildForConversation(
    player,
    "observer",
    {
        subject = "GOSSIP",
        targetID = "self",
        conversationToken = "lease:1",
    }
)
T.equal(gossipProjection._memoryGossip.codes[1], 2003,
    "targetless gossip resolves the authenticated player's shareable memory")
T.equal(gossipProjection._memoryGossip.subject, "Alex",
    "targetless gossip uses the authenticated player's display identity")

local npcTarget = memory.Events.ResolveTarget("npc:observer")
record.memory = {
    v = memory.Events.VERSION,
    d = 1,
    l = {
        1104,
        npcTarget.seed,
        1,
        memory.Events.FLAG_SHAREABLE + memory.Events.FLAG_DURABLE,
    },
}
local selfGossipProjection = Service.BuildForConversation(
    player,
    "observer",
    {
        subject = "GOSSIP",
        targetID = "self",
        conversationToken = "lease:1",
    }
)
T.equal(selfGossipProjection._memoryGossip.codes[1], 4002,
    "targetless gossip falls back to the NPC's shareable horde memory")
T.equal(selfGossipProjection._memoryGossip.subject, "Mara",
    "horde survival story keeps the speaking NPC as its subject")

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
