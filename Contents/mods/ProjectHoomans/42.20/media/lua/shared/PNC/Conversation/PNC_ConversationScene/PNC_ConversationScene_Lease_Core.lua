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

local function isAbstractRecord(record)
    return type(record) == "table"
        and (record.abstractOnly == true
            or record.runtimeView == true
                and tostring(record.presenceState or "") == "abstract")
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

local function hasActiveDirectedWork(record)
    local rt = type(record) == "table" and record.runtime or nil
    if type(rt) == "table" and type(rt.behaviorScript) == "table"
        and rt.behaviorScript.active == true
    then
        return true
    end
    local plans = PNC.Semantics and PNC.Semantics.ActionPlanService or nil
    if plans and type(plans.Get) == "function" and record and record.id ~= nil then
        local plan = plans.Get(record.id)
        if type(plan) == "table" then
            local st = string.upper(tostring(plan.state or ""))
            if st == "PENDING" or st == "ACTIVE" or st == "RUNNING" then
                return true
            end
        end
    end
    return false
end

-- Smart, non-invasive conversation hold release: stops the blocking
-- `social.conversation` animation scene so the NPC can immediately carry out
-- a player order/script while keeping the chat lease alive for follow-ups.
function Scene.YieldForOrder(record, zombie, reason)
    if type(record) ~= "table" then return false end
    local rt = record.runtime
    if type(rt) ~= "table" then return false end
    local activeScene = rt.animationScene
    if type(activeScene) == "table" and tostring(activeScene.id or "") == Scene.ID then
        local scenes = PNC.AnimationScenes
        if scenes and type(scenes.Stop) == "function" then
            scenes.Stop(record, zombie, tostring(reason or "order_dispatched"))
        else
            rt.animationScene = nil
        end
        return true
    end
    return false
end

local function renewLease(record, token, currentTime)
    local current = record.runtime.conversationLease
    if not current
        or tostring(current.token or "") ~= token
    then
        return nil
    end
    if not isAbstractRecord(record)
        and not hasActiveDirectedWork(record)
        and (not record.runtime.animationScene
            or record.runtime.animationScene.id ~= Scene.ID)
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
    if isAbstractRecord(record) then
        return true, "abstract_no_body_scene"
    end
    if hasActiveDirectedWork(record) then
        Scene.YieldForOrder(record, zombie, "directed_work_active")
        return true, "directed_work_non_blocking"
    end
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
Internal.IsAbstractRecord = isAbstractRecord
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
