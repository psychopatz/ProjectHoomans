-- Conversation lease begin provider.

PNC = PNC or {}
PNC.ConversationScene = PNC.ConversationScene or {}
PNC.ConversationScene.Internal = PNC.ConversationScene.Internal or {}

local Scene = PNC.ConversationScene
local Internal = Scene.Internal
local Const = PNC.Const or {}
local sceneOptions = Internal.SceneOptions
local isTravelJourney = Internal.IsTravelJourney
local playerOwnsLease = Internal.PlayerOwnsLease
local hostileParleyRequested = Internal.HostileParleyRequested
local renewLease = Internal.RenewLease
local ownedByAnotherPlayer = Internal.OwnedByAnotherPlayer
local requestScene = Internal.RequestScene
local createLease = Internal.CreateLease
local establishParley = Internal.EstablishParley

function Scene.Begin(record, zombie, player, token, options)
    local maximumDistance
    local dangerRadius
    local guardThreats
    local hostileParley
    local enforceDistance
    local registered
    local reason
    local currentTime
    local current
    local renewed
    local started
    local lease
    local pending
    local previousState
    local previousProcessedRequests
    local activeTravelHeartbeat
    options, maximumDistance, dangerRadius = sceneOptions(options)
    guardThreats = options.guardThreats ~= false
    enforceDistance = options.enforceDistance ~= false
    if not record or record.alive == false
        or not Internal.IsAlive(zombie)
    then
        return false, "npc_unavailable"
    end
    record.runtime = record.runtime or {}
    currentTime = Internal.Now()
    token = tostring(token or "")
    current = record.runtime.conversationLease
    activeTravelHeartbeat = current
        and tostring(current.token or "") == token
        and playerOwnsLease(player, current)
        and (tonumber(current.expiresAt) or 0) > currentTime
        and current.travelHold == true
    if enforceDistance
        and Internal.DistanceSq(player, zombie)
            > maximumDistance * maximumDistance
    then
        return false, "distance"
    end
    hostileParley = hostileParleyRequested(record, options)
    if guardThreats and not activeTravelHeartbeat and Scene.HasThreat(
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
    if current and (tonumber(current.expiresAt) or 0) > currentTime
        and tostring(current.token or "") == token
        and playerOwnsLease(player, current)
    then
        previousState = current.conversationState
        previousProcessedRequests = current.processedConversationRequests
    end
    lease = createLease(
        record,
        player,
        token,
        currentTime,
        maximumDistance,
        dangerRadius,
        guardThreats,
        hostileParley,
        isTravelJourney(record)
    )
    if hostileParley
        and not establishParley(
            record, zombie, player, token, currentTime
        )
    then
        return false, "player_identity_unavailable"
    end
    if type(previousState) == "table" then
        lease.conversationState = previousState
    end
    if type(previousProcessedRequests) == "table" then
        lease.processedConversationRequests = previousProcessedRequests
    end
    record.runtime.conversationLease = lease
    record.nextThinkAt = currentTime
    return true, lease
end


return Scene
