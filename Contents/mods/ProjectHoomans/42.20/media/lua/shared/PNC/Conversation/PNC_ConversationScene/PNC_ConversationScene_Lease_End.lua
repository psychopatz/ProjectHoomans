-- Conversation lease end and heartbeat provider.

PNC = PNC or {}
PNC.ConversationScene = PNC.ConversationScene or {}
PNC.ConversationScene.Internal = PNC.ConversationScene.Internal or {}

local Scene = PNC.ConversationScene
local Internal = Scene.Internal
local isTravelConversation = Internal.IsTravelConversation
local playerOwnsLease = Internal.PlayerOwnsLease
local log = Internal.LeaseLog
local recordConversationTopics = Internal.RecordConversationTopics

function Scene.End(record, zombie, token, reason, options)
    local runtime = record and record.runtime or nil
    local lease = runtime and runtime.conversationLease or nil
    local parley
    local player = type(options) == "table" and options.player or nil
    local requestID = type(options) == "table"
        and tostring(options.llmRequestID or "") or ""
    if not lease then return false end
    if token ~= nil and tostring(token) ~= ""
        and tostring(lease.token or "") ~= tostring(token)
    then
        return false
    end
    if player and (tostring(token or "") == ""
        or not playerOwnsLease(player, lease))
    then
        return false, "conversation_player_mismatch"
    end
    if player and type(options) == "table"
        and options.memoryTopicMask ~= nil
    then
        recordConversationTopics(record, player, options.memoryTopicMask)
    end
    if requestID ~= "" then
        local reserved, reserveReason = Scene.ReserveLLMRequest(
            record,
            zombie,
            player,
            token,
            requestID
        )
        if not reserved then
            log(
                "llm_request_lease_failed",
                "npc=" .. tostring(record.id)
                    .. " request=" .. requestID
                    .. " reason=" .. tostring(reserveReason or "rejected")
            )
        end
    end
    runtime.conversationLease = nil
    parley = runtime.conversationParley
    if parley and (
        token == nil or tostring(token) == ""
        or tostring(parley.token or "") == tostring(token)
    ) then
        runtime.conversationParley = nil
    end
    if runtime.animationScene
        and runtime.animationScene.id == Scene.ID
        and PNC.AnimationScenes
        and PNC.AnimationScenes.Stop
    then
        PNC.AnimationScenes.Stop(
            record,
            zombie,
            reason or "conversation_ended"
        )
    end
    record.nextThinkAt = Internal.Now()
    return true
end

local function resolveLeasePlayer(lease)
    local core = PNC.Core
    local player
    if core and core.ResolvePlayerByOnlineID
        and lease.playerOnlineID ~= nil
    then
        player = core.ResolvePlayerByOnlineID(lease.playerOnlineID)
        if player then return player end
    end
    if PNC.SpatialIndex and PNC.SpatialIndex.FindPlayerByUsername
        and lease.playerUsername
    then
        return PNC.SpatialIndex.FindPlayerByUsername(lease.playerUsername)
    end
    return nil
end

function Scene.Pump(record, zombie, currentTime)
    local runtime = record and record.runtime or nil
    local lease = runtime and runtime.conversationLease or nil
    local pending = runtime and runtime.llmRequestLease or nil
    local player
    currentTime = tonumber(currentTime) or Internal.Now()
    if pending then
        player = resolveLeasePlayer(pending)
        if currentTime >= (tonumber(pending.expiresAt) or 0) then
            Scene.ClearLLMRequest(record, "request_timeout")
        elseif not player or not Internal.IsAlive(zombie)
            or (pending.guardThreats ~= false and Scene.HasThreat(
                record,
                zombie,
                player,
                tonumber(pending.dangerRadius) or Scene.DANGER_RADIUS,
                { ignoreTalkingNPC = pending.hostileParley == true }
            ))
        then
            Scene.ClearLLMRequest(record, "request_safety_failed")
        end
    end
    if not lease then return false end
    player = resolveLeasePlayer(lease)
    if currentTime >= (tonumber(lease.expiresAt) or 0) then
        return Scene.End(
            record, zombie, lease.token, "conversation_timeout"
        )
    end
    if not player or not Internal.IsAlive(zombie) then
        return Scene.End(
            record, zombie, lease.token, "conversation_unavailable"
        )
    end
    if lease.guardThreats ~= false and Scene.HasThreat(
        record,
        zombie,
        player,
        tonumber(lease.dangerRadius) or Scene.DANGER_RADIUS,
        { ignoreTalkingNPC = lease.hostileParley == true }
    ) then
        if isTravelConversation(record, lease) then
            -- ThreatGuard owns the temporary combat overlay. Keep the
            -- conversation lease alive so the NPC returns to its stationary
            -- conversation hold after the danger clears.
            return false
        end
        return Scene.End(
            record, zombie, lease.token, "conversation_danger"
        )
    end
    return false
end

return Scene
