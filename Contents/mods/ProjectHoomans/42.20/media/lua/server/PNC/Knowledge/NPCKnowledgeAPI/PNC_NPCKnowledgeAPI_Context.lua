-- Server-authoritative knowledge boundary used by UI, conversation, and LLM
-- adapters. Callers provide intent and a conversation token; they never
-- provide player identity or NPC truth.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.API = PNC.API or {}
PNC.NPCKnowledgeAPI = PNC.NPCKnowledgeAPI or {}
PNC.API.Knowledge = PNC.NPCKnowledgeAPI

local API = PNC.NPCKnowledgeAPI
local Knowledge = PNC.NPCKnowledge
local Registry = PNC.Registry

API.VERSION = 1
API.ORIGINS = API.ORIGINS or {
    conversation = true,
    semantic_dialogue = true,
    semantic_identity_claim = true,
    llm_tool = true,
    debug = true,
}
-- Preserve semantic provenance while routing these requests through the same
-- conversation-lease validation used by native conversation disclosures.
API.ORIGINS.semantic_dialogue = API.ORIGINS.semantic_dialogue ~= false
API.ORIGINS.semantic_identity_claim =
    API.ORIGINS.semantic_identity_claim ~= false

local function safeID(value)
    value = tostring(value or "")
    if value == "" or #value > 128 or string.find(value, "%c") then
        return nil
    end
    return value
end

local function contextFor(player, reason)
    if not PNC.PlayerContext or not PNC.PlayerContext.Resolve then
        return nil, "player_context_unavailable"
    end
    return PNC.PlayerContext.Resolve(player, reason)
end

local function recordFor(npcID)
    return Registry and Registry.Get and Registry.Get(npcID) or nil
end

local function validateConversation(player, record, token)
    local authority = PNC.Conversation and PNC.Conversation.Authority
    local internal = authority and authority.Internal or nil
    local validate = internal and internal.ValidateLease
    if type(validate) ~= "function" then
        return false, "conversation_authority_unavailable"
    end
    local okay, reason, lease = validate(player, record, token)
    return okay == true, reason, lease
end

-- Read access is player-scoped and safe for both singleplayer and multiplayer.
-- It intentionally returns the sparse snapshot built by NPCKnowledgeService.
function API.GetForPlayer(player, npcID)
    npcID = safeID(npcID)
    if not npcID then return nil, "invalid_npc_id" end
    local context, reason = contextFor(player, "knowledge_snapshot")
    if not context then return nil, reason end
    if not recordFor(npcID) then return nil, "npc_not_found" end
    local snapshot
    snapshot, reason = Knowledge.BuildPlayerSnapshotForPlayer(player, npcID)
    if not snapshot then return nil, reason end
    return snapshot, nil, context
end

function API.ListTopics()
    local topics = {}
    local descriptors = PNC.KnowledgeDescriptors
        and PNC.KnowledgeDescriptors.List and PNC.KnowledgeDescriptors.List()
        or {}
    for _, descriptor in ipairs(descriptors) do
        local topicID = descriptor.presentation
            and tostring(descriptor.presentation.topicID or "") or ""
        if topicID ~= "" then
            local topic = topics[topicID] or {
                topicID = topicID, descriptorIDs = {}, disclosable = false,
            }
            topic.descriptorIDs[#topic.descriptorIDs + 1] = descriptor.id
            topic.disclosable = topic.disclosable
                or descriptor.discovery.allowDisclosure == true
            topics[topicID] = topic
        end
    end
    topics.gift_preferences = topics.gift_preferences or {
        topicID = "gift_preferences",
        descriptorIDs = {},
        disclosable = true,
    }
    local output = {}
    for _, topic in pairs(topics) do
        table.sort(topic.descriptorIDs)
        output[#output + 1] = topic
    end
    table.sort(output, function(left, right)
        return left.topicID < right.topicID
    end)
    return output
end

local Internal = API.Internal or {}
API.Internal = Internal
Internal.SafeID = safeID
Internal.ContextFor = contextFor
Internal.RecordFor = recordFor
Internal.ValidateConversation = validateConversation

return API
