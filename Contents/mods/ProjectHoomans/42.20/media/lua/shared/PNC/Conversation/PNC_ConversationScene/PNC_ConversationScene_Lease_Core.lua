-- Conversation lease shared context and ownership helpers.

PNC = PNC or {}
PNC.ConversationScene = PNC.ConversationScene or {}
PNC.ConversationScene.Internal = PNC.ConversationScene.Internal or {}

local Scene = PNC.ConversationScene
local Internal = Scene.Internal
local Const = PNC.Const or {}

local ACTIVE_JOURNEY_STATES = {
    planned = true,
    en_route = true,
    waiting = true,
    paused = true,
}

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

local function isTravelJourney(record)
    local order = record and record.orderSpec or nil
    local journey = record and record.travel or nil
    local state = journey and tostring(journey.state or "") or ""
    return tostring(order and order.kind or "")
            == tostring(Const.ORDER_TRAVEL or "travel")
        and ACTIVE_JOURNEY_STATES[state] == true
end

local function isTravelConversation(record, lease)
    return (lease and lease.travelHold == true)
        or isTravelJourney(record)
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
    maximumDistance, dangerRadius, guardThreats, hostileParley, travelHold
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
        guardThreats = guardThreats,
        hostileParley = hostileParley,
        travelHold = travelHold == true,
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


Internal.LeaseLog = log
Internal.SceneOptions = sceneOptions
Internal.IsTravelJourney = isTravelJourney
Internal.IsTravelConversation = isTravelConversation
Internal.PlayerOwnsLease = playerOwnsLease
Internal.HostileParleyRequested = hostileParleyRequested
Internal.RenewLease = renewLease
Internal.OwnedByAnotherPlayer = ownedByAnotherPlayer
Internal.RequestScene = requestScene
Internal.CreateLease = createLease
Internal.EstablishParley = establishParley

return Scene
