-- Conversation LLM request lease and authority validation provider.

PNC = PNC or {}
PNC.ConversationScene = PNC.ConversationScene or {}
PNC.ConversationScene.Internal = PNC.ConversationScene.Internal or {}

local Scene = PNC.ConversationScene
local Internal = Scene.Internal
local playerOwnsLease = Internal.PlayerOwnsLease
local log = Internal.LeaseLog

function Scene.ReserveLLMRequest(record, zombie, player, token, requestID)
    local runtime = record and record.runtime or nil
    local lease = runtime and runtime.conversationLease or nil
    local pending
    local currentTime
    requestID = tostring(requestID or "")
    if requestID == "" then return false, "llm_request_id_required" end
    if not lease or tostring(lease.token or "") ~= tostring(token or "") then
        return false, "invalid_lease"
    end
    if not playerOwnsLease(player, lease) then
        return false, "conversation_player_mismatch"
    end
    currentTime = Internal.Now()
    if currentTime >= (tonumber(lease.expiresAt) or 0) then
        return false, "invalid_lease"
    end
    pending = runtime.llmRequestLease
    if pending then
        if tostring(pending.requestID or "") == requestID
            and tostring(pending.token or "") == tostring(token or "")
            and playerOwnsLease(player, pending)
        then
            return true, pending
        end
        if currentTime < (tonumber(pending.expiresAt) or 0) then
            return false, "llm_request_pending"
        end
        Scene.ClearLLMRequest(record, "request_timeout")
    end
    if not Internal.IsAlive(zombie) then
        return false, "npc_unavailable"
    end
    if lease.guardThreats ~= false and Scene.HasThreat(
        record,
        zombie,
        player,
        tonumber(lease.dangerRadius) or Scene.DANGER_RADIUS,
        { ignoreTalkingNPC = lease.hostileParley == true }
    ) then
        return false, "danger"
    end
    pending = {
        requestID = requestID,
        token = lease.token,
        playerOnlineID = lease.playerOnlineID,
        playerUsername = lease.playerUsername,
        createdAt = currentTime,
        expiresAt = currentTime + Scene.LLM_REQUEST_LEASE_MS,
        maximumDistance = lease.maximumDistance,
        dangerRadius = lease.dangerRadius,
        guardThreats = lease.guardThreats ~= false,
        hostileParley = lease.hostileParley,
        llmToolCalls = {},
        consumed = false,
    }
    runtime.llmRequestLease = pending
    log(
        "llm_request_lease_reserved",
        "npc=" .. tostring(record.id)
            .. " request=" .. requestID
            .. " expiresAt=" .. tostring(pending.expiresAt)
    )
    return true, pending
end

-- Shared authority check for read-only conversation projections.  Keeping the
-- lease ownership rule here prevents semantic cognition requests from
-- reimplementing player/token validation in a second subsystem.
function Scene.ValidateConversationLease(record, player, token)
    local runtime = record and record.runtime or nil
    local lease = runtime and runtime.conversationLease or nil
    local currentTime
    token = tostring(token or "")
    if token == "" or not lease then
        return false, "invalid_lease"
    end
    if tostring(lease.token or "") ~= token then
        return false, "invalid_lease"
    end
    if not playerOwnsLease(player, lease) then
        return false, "conversation_player_mismatch"
    end
    currentTime = Internal.Now()
    if currentTime >= (tonumber(lease.expiresAt) or 0) then
        return false, "conversation_expired"
    end
    return true, lease
end

function Scene.ClearLLMRequest(record, reason)
    local runtime = record and record.runtime or nil
    local pending = runtime and runtime.llmRequestLease or nil
    if not pending then return false end
    runtime.llmRequestLease = nil
    log(
        "llm_request_lease_cleared",
        "npc=" .. tostring(record and record.id or "")
            .. " request=" .. tostring(pending.requestID or "")
            .. " reason=" .. tostring(reason or "cleared")
    )
    return true
end

function Scene.ReleaseLLMRequest(record, player, token, requestID, reason)
    local runtime = record and record.runtime or nil
    local pending = runtime and runtime.llmRequestLease or nil
    requestID = tostring(requestID or "")
    if requestID == "" then return false, "llm_request_id_required" end
    if not pending then return true, "already_released" end
    if tostring(pending.requestID or "") ~= requestID
        or tostring(pending.token or "") ~= tostring(token or "")
    then
        return false, "invalid_lease"
    end
    if not playerOwnsLease(player, pending) then
        return false, "conversation_player_mismatch"
    end
    Scene.ClearLLMRequest(record, reason or "request_completed")
    return true, "released"
end

function Scene.ValidateLLMRequest(record, zombie, player, token, requestID)
    local runtime = record and record.runtime or nil
    local pending = runtime and runtime.llmRequestLease or nil
    local currentTime = Internal.Now()
    if not pending
        or tostring(pending.token or "") ~= tostring(token or "")
        or tostring(pending.requestID or "") ~= tostring(requestID or "")
    then
        return false, "invalid_lease"
    end
    if currentTime >= (tonumber(pending.expiresAt) or 0) then
        Scene.ClearLLMRequest(record, "request_timeout")
        return false, "llm_request_expired"
    end
    if not playerOwnsLease(player, pending) then
        return false, "conversation_player_mismatch"
    end
    if not Internal.IsAlive(zombie) then
        return false, "npc_unavailable"
    end
    if pending.guardThreats ~= false and Scene.HasThreat(
        record,
        zombie,
        player,
        tonumber(pending.dangerRadius) or Scene.DANGER_RADIUS,
        { ignoreTalkingNPC = pending.hostileParley == true }
    ) then
        return false, "danger"
    end
    return true, nil, pending
end

local function recordConversationTopics(record, player, topicMask)
    local playerCharacters = PNC and PNC.PlayerCharacters or nil
    local uuid
    local memory
    local events
    local ok
    if not player or not playerCharacters
        or type(playerCharacters.GetCharacterUUID) ~= "function"
    then
        return false, "player_identity_unavailable"
    end
    ok, uuid = pcall(playerCharacters.GetCharacterUUID, player)
    if not ok or not uuid then return false, "player_identity_unavailable" end
    pcall(require, "PNC/Conversation/Memory/PNC_ConversationMemory")
    pcall(require,
        "PNC/Conversation/Definitions/Memory/ConversationTopics/00_PNC_ConversationMemoryTopics")
    memory = PNC.Conversation and PNC.Conversation.Memory or nil
    events = memory and memory.Events or nil
    if not events or type(events.RecordConversationTopics) ~= "function" then
        return false, "conversation_memory_unavailable"
    end
    return events.RecordConversationTopics(record, topicMask, uuid)
end


Internal.RecordConversationTopics = recordConversationTopics

return Scene
