if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.API = PNC.API or {}
PNC.NPCKnowledgeAPI = PNC.NPCKnowledgeAPI or {}
PNC.API.Knowledge = PNC.NPCKnowledgeAPI

local API = PNC.NPCKnowledgeAPI
local Internal = API.Internal or {}
API.Internal = Internal
local Knowledge = PNC.NPCKnowledge
local safeID = Internal.SafeID
local contextFor = Internal.ContextFor
local recordFor = Internal.RecordFor
local commit = Internal.Commit
local authorizeDisclosure = Internal.AuthorizeDisclosure
local discloseGiftPreference = Internal.DiscloseGiftPreference

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

-- A related-NPC disclosure is still authored by an active conversation, but
-- the NPC speaking is not the NPC whose identity becomes known. This narrow
-- public seam keeps lease validation, persistence, and the player snapshot in
-- the Hoomans knowledge boundary instead of making integrations mutate the
-- lower-level knowledge service directly.
function API.DiscloseRelatedForPlayer(
    player, sourceNPCID, targetNPCID, options
)
    options = type(options) == "table" and options or {}
    sourceNPCID = safeID(sourceNPCID)
    targetNPCID = safeID(targetNPCID)
    local topicID = safeID(options.topicID)
    local origin = tostring(options.origin or "conversation")
    local token = safeID(options.conversationToken or options.token)
    local conversationRequestID = safeID(
        options.conversationRequestID or options.requestID,
        160
    )
    local requiredChoiceID = safeID(options.requiredChoiceID, 96)
    local context
    local reason
    local sourceRecord
    local targetRecord
    local authority
    local validate
    local valid
    local lease
    local disclosure
    local committed = true
    local snapshot
    if not sourceNPCID or not targetNPCID or not topicID then
        return nil, "invalid_related_disclosure_request"
    end
    if sourceNPCID == targetNPCID then
        return nil, "related_disclosure_target_required"
    end
    if topicID ~= "identity_name" then
        return nil, "related_identity_topic_required"
    end
    if origin ~= "conversation" and origin ~= "semantic_dialogue" then
        return nil, "invalid_related_knowledge_origin"
    end
    if not token then return nil, "conversation_token_required" end
    if origin == "conversation" and not conversationRequestID then
        return nil, "conversation_request_required"
    end
    context, reason = contextFor(player, "related_knowledge_disclosure")
    sourceRecord = recordFor(sourceNPCID)
    targetRecord = recordFor(targetNPCID)
    if not context then return nil, reason end
    if not sourceRecord then return nil, "source_npc_not_found" end
    if not targetRecord then return nil, "target_npc_not_found" end
    authority = PNC.Conversation and PNC.Conversation.Authority or nil
    validate = authority and authority.ValidateLease
    if type(validate) ~= "function" then
        local internal = authority and authority.Internal or nil
        validate = internal and internal.ValidateLease
    end
    if type(validate) ~= "function" then
        return nil, "conversation_authority_unavailable"
    end
    valid, reason, lease = validate(player, sourceRecord, token)
    if valid ~= true then return nil, reason or "invalid_lease" end
    if origin == "conversation" then
        local processed = lease and lease.processedConversationRequests or nil
        local outcome = processed and processed[conversationRequestID] or nil
        if not outcome or outcome.success ~= true then
            return nil, "conversation_outcome_required"
        end
        if requiredChoiceID
            and tostring(outcome.choiceID or "") ~= requiredChoiceID
        then
            return nil, "conversation_choice_mismatch"
        end
    end
    disclosure, reason = Knowledge.DiscoverTopicForPlayer(
        player,
        targetNPCID,
        topicID,
        options.worldAgeHours,
        "conversation_referral",
        true
    )
    if not disclosure then return nil, reason end
    if #(disclosure.revealed or {}) > 0 then
        committed, reason = commit(
            player,
            options.requestID or ("related:" .. targetNPCID)
        )
        if committed ~= true then
            return nil, reason or "knowledge_save_failed"
        end
    end
    snapshot, reason = API.GetForPlayer(player, targetNPCID)
    if not snapshot then return nil, reason end
    return {
        accepted = true,
        committed = committed == true,
        requestID = options.requestID,
        sourceNPCID = sourceNPCID,
        npcID = targetNPCID,
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
