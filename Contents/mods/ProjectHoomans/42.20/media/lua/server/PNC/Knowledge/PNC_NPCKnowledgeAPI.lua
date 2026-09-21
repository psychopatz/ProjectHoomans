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

local function authorizeDisclosure(player, npcID, options)
    local context, reason = contextFor(player, "knowledge_disclosure")
    local record = recordFor(npcID)
    local origin = tostring(options.origin or "conversation")
    local topicID = tostring(options.topicID or "")
    local verifiedIdentityClaim = options.verifiedIdentityClaim == true
    if not context then return nil, nil, reason end
    if not record then return nil, nil, "npc_not_found" end
    if not API.ORIGINS[origin] then return nil, nil, "invalid_knowledge_origin" end

    -- Identity is disclosed during conversation only after the server has
    -- compared the player's claim with their authoritative character record.
    -- HandleDisclosure forwards a whitelist of request fields, so a client
    -- cannot supply verifiedIdentityClaim through the network route.
    if topicID == "identity_name" and origin ~= "debug"
        and (origin ~= "semantic_identity_claim"
            or verifiedIdentityClaim ~= true)
    then
        return nil, nil, "identity_claim_required"
    end
    if origin == "semantic_identity_claim"
        and (topicID ~= "identity_name" or verifiedIdentityClaim ~= true)
    then
        return nil, nil, "identity_claim_required"
    end

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

local function safePreferenceItemType(value)
    local itemType = safeID(value)
    if not itemType or #itemType > 160
        or not string.match(itemType, "^[A-Za-z0-9_.:%-]+$")
    then
        return nil
    end
    return itemType
end

local function preferenceDisposition(value)
    local disposition = tostring(value or "")
    if disposition == "favorite" or disposition == "liked"
        or disposition == "like"
    then
        return "like"
    end
    if disposition == "disliked" or disposition == "hated"
        or disposition == "dislike"
    then
        return "dislike"
    end
    if disposition == "neutral" then return "neutral" end
    return nil
end

local function evaluateGiftPreference(record, itemType)
    local gifts = PNC.Gifts
    if not gifts or type(gifts.IsValidItemType) ~= "function"
        or gifts.IsValidItemType(itemType) ~= true
    then
        return nil, "invalid_gift_item_type"
    end
    local foundation = gifts.Foundation
    local runtime = foundation and foundation.RuntimeEvaluator or nil
    if not runtime or type(runtime.Evaluate) ~= "function" then
        return nil, "gift_foundation_unavailable"
    end
    local evaluation, reason = runtime.Evaluate(record, { itemType })
    if type(evaluation) ~= "table" then
        return nil, reason or "gift_preference_unavailable"
    end
    local row = evaluation.breakdown and evaluation.breakdown[1] or nil
    local disposition = row and preferenceDisposition(row.disposition) or nil
    if not disposition then return nil, "gift_preference_unavailable" end
    return disposition
end

local function preferenceResult(context, npcID, itemType)
    if not context or not itemType
        or not Knowledge.GetGiftPreference
    then
        return nil
    end
    local fact = Knowledge.GetGiftPreference(
        context.characterUUID, npcID, itemType
    )
    if not fact then return nil end
    return {
        itemType = itemType,
        disposition = fact.disposition,
    }
end

local function discloseGiftPreference(
    player, context, record, npcID, options, lease
)
    local itemType = safePreferenceItemType(options.preferenceItemType)
    if not itemType then return nil, "preference_item_required" end
    -- Item preference questions use the same face-to-face disclosure gate as
    -- asking an NPC's name; authorizeDisclosure has already validated the
    -- active conversation lease.
    if type(Knowledge.CanDisclose) ~= "function" then
        return nil, "knowledge_gate_unavailable"
    end
    local allowed, gateReason = Knowledge.CanDisclose(
        context.characterUUID, npcID, "identity.name"
    )
    if allowed ~= true then return nil, gateReason or "not_disclosable" end
    if type(Knowledge.RecordGiftPreferences) ~= "function"
        or type(Knowledge.GetGiftPreference) ~= "function"
    then
        return nil, "gift_preference_knowledge_unavailable"
    end
    local existing = Knowledge.GetGiftPreference(
        context.characterUUID, npcID, itemType
    )
    local disposition = existing and existing.disposition or nil
    local changed = false
    local reason
    if not disposition then
        disposition, reason = evaluateGiftPreference(record, itemType)
        if not disposition then return nil, reason end
        changed, reason = Knowledge.RecordGiftPreferences(
            context.characterUUID,
            npcID,
            { [itemType] = disposition },
            "direct_disclosure",
            options.requestID or ("preference:" .. itemType),
            options.worldAgeHours
        )
        if reason then return nil, reason end
    end
    local committed = true
    if changed then
        committed, reason = commit(
            player,
            options.requestID or ("preference:" .. itemType)
        )
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
        topicID = "gift_preferences",
        revealed = changed and { "gift.preference:" .. itemType } or {},
        failures = {},
        snapshot = snapshot,
        characterUUID = context.characterUUID,
        bindingRevision = context.bindingRevision,
        lease = lease and { token = lease.token } or nil,
        giftPreference = {
            itemType = itemType,
            disposition = disposition,
        },
    }
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
    local giftPreference = topicID == "gift_preferences"
        and preferenceResult(
            context, npcID,
            safePreferenceItemType(options.preferenceItemType)
        ) or nil
    return {
        accepted = true, committed = true, requestID = options.requestID,
        npcID = npcID, topicID = topicID, revealed = {}, failures = {},
        snapshot = snapshot, characterUUID = context.characterUUID,
        bindingRevision = context.bindingRevision,
        lease = lease and { token = lease.token } or nil,
        giftPreference = giftPreference,
    }
end

function API.RecordGiftPreferencesForPlayer(
    player, npcID, preferences, sourceEventID
)
    npcID = safeID(npcID)
    if not npcID then return nil, "invalid_npc_id" end
    local context, reason = contextFor(player, "gift_preference_reaction")
    if not context then return nil, reason end
    if not recordFor(npcID) then return nil, "npc_not_found" end
    if type(Knowledge.RecordGiftPreferences) ~= "function" then
        return nil, "gift_preference_knowledge_unavailable"
    end
    local changed
    changed, reason = Knowledge.RecordGiftPreferences(
        context.characterUUID,
        npcID,
        preferences,
        "gift_reaction",
        sourceEventID
    )
    if reason then return nil, reason end
    local committed = true
    if changed then
        committed, reason = commit(
            player, "gift_reaction:" .. tostring(sourceEventID or npcID)
        )
    end
    local snapshot
    local snapshotReason
    snapshot, snapshotReason = API.GetForPlayer(player, npcID)
    if not snapshot then return nil, snapshotReason end
    local result = {
        snapshot = snapshot,
        changed = changed == true,
        committed = committed == true,
    }
    if committed ~= true then return result, reason end
    return result
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
    if topicID == "gift_preferences" then
        return discloseGiftPreference(
            player, context, record, npcID, options, lease
        )
    end
    -- Semantic origins preserve caller provenance above. They still enter
    -- the knowledge service through direct_disclosure so its disclosure
    -- eligibility checks remain active.
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
