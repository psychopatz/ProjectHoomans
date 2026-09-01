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
    llm_tool = true,
    debug = true,
}

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

local function authorizeDisclosure(player, npcID, options)
    local context, reason = contextFor(player, "knowledge_disclosure")
    local record = recordFor(npcID)
    local origin = tostring(options.origin or "conversation")
    if not context then return nil, nil, reason end
    if not record then return nil, nil, "npc_not_found" end
    if not API.ORIGINS[origin] then return nil, nil, "invalid_knowledge_origin" end

    if origin == "debug" then
        local router = PNC.ServerCommandRouter
        if not router or not router.CanUseDebug
            or router.CanUseDebug(player) ~= true
        then return nil, nil, "not_authorized" end
        return context, record
    end

    local token = safeID(options.conversationToken or options.token)
    if not token then return nil, nil, "conversation_token_required" end
    local valid, leaseReason, lease = validateConversation(
        player, record, token
    )
    if not valid then return nil, nil, leaseReason or "invalid_lease" end
    return context, record, nil, lease
end

local function commit(player, requestID)
    if not PNC.PersistenceCoordinator
        or not PNC.PersistenceCoordinator.Commit
    then return false, "persistence_unavailable" end
    return PNC.PersistenceCoordinator.Commit(
        "knowledge_disclosure:" .. tostring(requestID or "retry")
    )
end

-- A failed disk commit leaves the in-memory evidence intentionally pending.
-- Retrying the same request commits that evidence without asking the provider
-- to create a duplicate fact.
function API.CommitPendingForPlayer(player, options)
    options = type(options) == "table" and options or {}
    local npcID = safeID(options.npcID)
    local topicID = safeID(options.topicID)
    if not npcID or not topicID then return nil, "invalid_disclosure_request" end
    local context, _, reason, lease = authorizeDisclosure(
        player, npcID, options
    )
    if not context then return nil, reason end
    local committed
    committed, reason = commit(player, options.requestID)
    if committed ~= true then return nil, reason or "knowledge_save_failed" end
    local snapshot
    snapshot, reason = API.GetForPlayer(player, npcID)
    if not snapshot then return nil, reason end
    return {
        accepted = true, committed = true, requestID = options.requestID,
        npcID = npcID, topicID = topicID, revealed = {}, failures = {},
        snapshot = snapshot, characterUUID = context.characterUUID,
        bindingRevision = context.bindingRevision,
        lease = lease and { token = lease.token } or nil,
    }
end

-- Mutating disclosure is one small contract for native UI and LLM tools.
-- The request is authorized before any descriptor/provider is evaluated.
function API.DiscloseForPlayer(player, options)
    options = type(options) == "table" and options or {}
    local npcID = safeID(options.npcID)
    local topicID = safeID(options.topicID)
    if not npcID or not topicID then return nil, "invalid_disclosure_request" end

    local context, record, reason, lease = authorizeDisclosure(
        player, npcID, options
    )
    if not context then return nil, reason end
    local sourceType = options.origin == "debug" and "debug"
        or "direct_disclosure"
    local disclosure
    disclosure, reason = Knowledge.DiscoverTopicForPlayer(
        player, npcID, topicID, options.worldAgeHours, sourceType, true
    )
    if not disclosure then return nil, reason end

    local committed = true
    if #(disclosure.revealed or {}) > 0 then
        committed, reason = commit(player, options.requestID or topicID)
        if committed ~= true then
            return nil, reason or "knowledge_save_failed"
        end
    end
    local snapshot
    snapshot, reason = API.GetForPlayer(player, npcID)
    if not snapshot then return nil, reason end
    return {
        accepted = true,
        committed = committed,
        requestID = options.requestID,
        npcID = npcID,
        topicID = topicID,
        revealed = disclosure.revealed or {},
        failures = disclosure.failures or {},
        snapshot = snapshot,
        characterUUID = context.characterUUID,
        bindingRevision = context.bindingRevision,
        lease = lease and { token = lease.token } or nil,
    }
end

return API
