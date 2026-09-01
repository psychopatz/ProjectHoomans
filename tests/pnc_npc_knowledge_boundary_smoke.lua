local T = require "tests/support/test"

local SHARED = T.path("ProjectHoomans", "shared", "PNC/Core/")
local SERVER = T.path("ProjectHoomans", "server", "PNC/")

PNC = { Core = {
    DeepCopy = function(value)
        if type(value) ~= "table" then return value end
        local output = {}
        for key, item in pairs(value) do output[key] = PNC.Core.DeepCopy(item) end
        return output
    end,
} }

T.load(SHARED .. "Needs/PNC_ConditionStats.lua")
T.load(SHARED .. "Needs/PNC_PlayerNeedsModel.lua")
T.load(SHARED .. "Knowledge/PNC_KnowledgeRegistry.lua")
T.load(SHARED .. "Knowledge/PNC_KnowledgeBuiltins.lua")

local highThirst = PNC.KnowledgeDescriptors.Get("trait.highthirst")
local traitProvider = PNC.KnowledgeProviders.GetTruth(
    { vanillaTraits = { highthirst = true } }, highThirst
)
T.truthy(highThirst, "vanilla traits are independently registered as knowledge")
T.equal(traitProvider, true, "trait provider returns the authoritative boolean")
T.equal(PNC.KnowledgeProviders.GetTruth({ vanillaTraits = {} }, highThirst),
    false, "trait provider preserves a known negative")
T.equal(PNC.KnowledgeDescriptors.Get("faction.identity").presentation.topicID,
    "faction", "faction disclosure is not coupled to name disclosure")

local disclosureCalls = 0
local commitCalls = 0
local leaseToken = "lease:good"
PNC.Registry = {
    Get = function(id)
        return id == "npc_one" and { id = id } or nil
    end,
}
PNC.PlayerContext = {
    Resolve = function(_, reason)
        return {
            characterUUID = "character_one", bindingRevision = 2,
        }, reason
    end,
}
PNC.Conversation = { Authority = { Internal = {
    ValidateLease = function(_, _, token)
        return token == leaseToken, token == leaseToken and "validated" or "invalid_lease", {
            token = token,
        }
    end,
} } }
PNC.PersistenceCoordinator = {
    Commit = function() commitCalls = commitCalls + 1; return true, "committed" end,
}
PNC.NPCKnowledge = {
    BuildPlayerSnapshotForPlayer = function(_, npcID)
        return { npcID = npcID, categories = {}, revision = 1 }
    end,
    DiscoverTopicForPlayer = function(_, npcID, topicID)
        disclosureCalls = disclosureCalls + 1
        return { npcID = npcID, topicID = topicID,
            revealed = { "trait.highthirst" }, failures = {} }
    end,
}

T.load(SERVER .. "Knowledge/PNC_NPCKnowledgeAPI.lua")
local API = PNC.NPCKnowledgeAPI
T.truthy(API and PNC.API.Knowledge == API, "knowledge API is reusable and namespaced")

local denied, deniedReason = API.DiscloseForPlayer({}, {
    npcID = "npc_one", topicID = "traits", requestID = "request:missing",
})
T.equal(denied, nil, "disclosure without a conversation token is rejected")
T.equal(deniedReason, "conversation_token_required",
    "missing token has an explicit authorization reason")
T.equal(disclosureCalls, 0, "unauthorized disclosure never evaluates NPC truth")

local invalid, invalidReason = API.DiscloseForPlayer({}, {
    npcID = "npc_one", topicID = "traits", requestID = "request:bad",
    conversationToken = "lease:bad", origin = "conversation",
})
T.equal(invalid, nil, "invalid lease is rejected")
T.equal(invalidReason, "invalid_lease", "invalid lease is diagnosable")
T.equal(disclosureCalls, 0, "invalid lease never evaluates NPC truth")

local accepted, acceptedReason = API.DiscloseForPlayer({}, {
    npcID = "npc_one", topicID = "traits", requestID = "request:good",
    conversationToken = leaseToken, origin = "llm_tool",
})
T.truthy(accepted and accepted.accepted == true,
    "authorized SP/MP-compatible disclosure is accepted")
T.equal(acceptedReason, nil, "successful disclosure has no error reason")
T.equal(disclosureCalls, 1, "authorized disclosure reaches the knowledge service")
T.equal(commitCalls, 1, "authorized disclosure commits once")
T.equal(accepted.snapshot.npcID, "npc_one", "disclosure returns a player snapshot")

local topics = API.ListTopics()
local foundTraits = false
for _, topic in ipairs(topics) do
    if topic.topicID == "traits" then foundTraits = topic.disclosable end
end
T.truthy(foundTraits, "registered trait topic is exposed to adapters")
T.finish("pnc_npc_knowledge_boundary_smoke")
