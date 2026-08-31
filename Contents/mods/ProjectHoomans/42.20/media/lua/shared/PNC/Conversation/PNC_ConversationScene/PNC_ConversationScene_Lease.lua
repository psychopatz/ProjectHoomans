local Scene = PNC.ConversationScene
local Internal = Scene.Internal

local function log(event, details)
    if print then
        print("[PNC][LLM] " .. tostring(event) .. " "
            .. tostring(details or ""))
    end
end

local function sceneOptions(options)
    options = type(options) == "table" and options or {}
    return options, math.max(
        2,
        math.min(12, tonumber(options.maximumDistance)
            or Scene.START_DISTANCE)
    ), math.max(
        2,
        math.min(20, tonumber(options.dangerRadius)
            or Scene.DANGER_RADIUS)
    )
end

local function playerOwnsLease(player, lease)
    if not player or not lease then return false end
    if lease.playerOnlineID ~= nil and player.getOnlineID
        and tostring(lease.playerOnlineID) == tostring(player:getOnlineID())
    then
        return true
    end
    return lease.playerUsername ~= nil and player.getUsername
        and tostring(lease.playerUsername) == tostring(player:getUsername())
end

local function hostileParleyRequested(record, options)
    return options.allowHostileParley == true
        and tostring(record.tacticalClass or "") == "hostile"
        and type(record.hostility) == "table"
        and record.hostility.attackPlayers == true
end

local function renewLease(record, token, currentTime)
    local current = record.runtime.conversationLease
    if not current
        or tostring(current.token or "") ~= token
        or not record.runtime.animationScene
        or record.runtime.animationScene.id ~= Scene.ID
    then
        return nil
    end
    current.expiresAt = currentTime + Scene.LEASE_MS
    if current.hostileParley == true
        and record.runtime.conversationParley
        and tostring(record.runtime.conversationParley.token or "")
            == token
    then
        record.runtime.conversationParley.untilAt = current.expiresAt
    end
    return current
end

local function ownedByAnotherPlayer(current, player, currentTime)
    if not current or not current.expiresAt
        or currentTime >= current.expiresAt
    then
        return false
    end
    return tostring(current.playerUsername or "") ~= tostring(
        player and player.getUsername and player:getUsername() or ""
    )
end

local function requestScene(record, zombie, currentTime)
    return PNC.AnimationScenes.Request(record, zombie, Scene.ID, {
        reason = "conversation",
        repeatMode = "loop",
        now = currentTime,
    })
end

local function createLease(
    record, player, token, currentTime,
    maximumDistance, dangerRadius, hostileParley
)
    return {
        token = token,
        playerOnlineID = player and player.getOnlineID
            and player:getOnlineID() or nil,
        playerUsername = player and player.getUsername
            and player:getUsername() or nil,
        startedAt = currentTime,
        expiresAt = currentTime + Scene.LEASE_MS,
        previousJob = record.activeJob,
        previousBehavior = record.activeBehavior,
        maximumDistance = maximumDistance,
        dangerRadius = dangerRadius,
        hostileParley = hostileParley,
    }
end

local function establishParley(
    record, zombie, player, token, currentTime
)
    local key = Internal.PlayerKey(player, "conversation_parley")
    if not key then
        PNC.AnimationScenes.Stop(
            record,
            zombie,
            "conversation_identity_unavailable"
        )
        return false
    end
    record.runtime.conversationParley = {
        token = token,
        playerKey = key,
        untilAt = currentTime + Scene.LEASE_MS,
    }
    Internal.ApplyParley(record, zombie, "conversation_parley_started")
    return true
end

function Scene.Begin(record, zombie, player, token, options)
    local maximumDistance
    local dangerRadius
    local hostileParley
    local registered
    local reason
    local currentTime
    local current
    local renewed
    local started
    local lease
    local pending
    options, maximumDistance, dangerRadius = sceneOptions(options)
    if not record or record.alive == false
        or not Internal.IsAlive(zombie)
    then
        return false, "npc_unavailable"
    end
    if Internal.DistanceSq(player, zombie)
        > maximumDistance * maximumDistance
    then
        return false, "distance"
    end
    hostileParley = hostileParleyRequested(record, options)
    if Scene.HasThreat(
        record,
        zombie,
        player,
        dangerRadius,
        { ignoreTalkingNPC = hostileParley }
    ) then
        return false, "danger"
    end
    registered, reason = Scene.EnsureRegistered()
    if not registered then return false, reason end
    record.runtime = record.runtime or {}
    currentTime = Internal.Now()
    token = tostring(token or "")
    renewed = renewLease(record, token, currentTime)
    if renewed then return true, renewed end
    pending = record.runtime.llmRequestLease
    if pending then
        if currentTime >= (tonumber(pending.expiresAt) or 0) then
            Scene.ClearLLMRequest(record, "request_timeout")
            pending = nil
        elseif not playerOwnsLease(player, pending) then
            return false, "already_talking"
        else
            return false, "llm_request_pending"
        end
    end
    current = record.runtime.conversationLease
    if ownedByAnotherPlayer(current, player, currentTime) then
        return false, "already_talking"
    end
    started, reason = requestScene(record, zombie, currentTime)
    if not started then return false, reason end
    lease = createLease(
        record,
        player,
        token,
        currentTime,
        maximumDistance,
        dangerRadius,
        hostileParley
    )
    if hostileParley
        and not establishParley(
            record, zombie, player, token, currentTime
        )
    then
        return false, "player_identity_unavailable"
    end
    record.runtime.conversationLease = lease
    record.nextThinkAt = currentTime
    return true, lease
end

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
    if Internal.DistanceSq(player, zombie)
        > (tonumber(lease.maximumDistance) or Scene.START_DISTANCE)
            ^ 2
    then
        return false, "distance"
    end
    if Scene.HasThreat(
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
    if Internal.DistanceSq(player, zombie)
        > (tonumber(pending.maximumDistance) or Scene.START_DISTANCE)
            ^ 2
    then
        return false, "distance"
    end
    if Scene.HasThreat(
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

function Scene.End(record, zombie, token, reason, options)
    local runtime = record and record.runtime or nil
    local lease = runtime and runtime.conversationLease or nil
    local parley
    local requestID = type(options) == "table"
        and tostring(options.llmRequestID or "") or ""
    if not lease then return false end
    if token ~= nil and tostring(token) ~= ""
        and tostring(lease.token or "") ~= tostring(token)
    then
        return false
    end
    if requestID ~= "" then
        local reserved, reserveReason = Scene.ReserveLLMRequest(
            record,
            zombie,
            type(options) == "table" and options.player or nil,
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
    local maximumDistance
    currentTime = tonumber(currentTime) or Internal.Now()
    if pending then
        player = resolveLeasePlayer(pending)
        maximumDistance = tonumber(pending.maximumDistance)
            or Scene.START_DISTANCE
        if currentTime >= (tonumber(pending.expiresAt) or 0) then
            Scene.ClearLLMRequest(record, "request_timeout")
        elseif not player or not Internal.IsAlive(zombie)
            or Internal.DistanceSq(player, zombie)
                > maximumDistance * maximumDistance
            or Scene.HasThreat(
                record,
                zombie,
                player,
                tonumber(pending.dangerRadius) or Scene.DANGER_RADIUS,
                { ignoreTalkingNPC = pending.hostileParley == true }
            )
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
    maximumDistance = tonumber(lease.maximumDistance)
        or Scene.START_DISTANCE
    if not player or Internal.DistanceSq(player, zombie)
        > maximumDistance * maximumDistance
    then
        return Scene.End(
            record, zombie, lease.token, "conversation_distance"
        )
    end
    if Scene.HasThreat(
        record,
        zombie,
        player,
        tonumber(lease.dangerRadius) or Scene.DANGER_RADIUS,
        { ignoreTalkingNPC = lease.hostileParley == true }
    ) then
        return Scene.End(
            record, zombie, lease.token, "conversation_danger"
        )
    end
    return false
end
