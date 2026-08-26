local Scene = PNC.ConversationScene
local Internal = Scene.Internal

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

function Scene.End(record, zombie, token, reason)
    local runtime = record and record.runtime or nil
    local lease = runtime and runtime.conversationLease or nil
    local parley
    if not lease then return false end
    if token ~= nil and tostring(token) ~= ""
        and tostring(lease.token or "") ~= tostring(token)
    then
        return false
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
    local lease = record and record.runtime
        and record.runtime.conversationLease or nil
    local player
    local maximumDistance
    if not lease then return false end
    currentTime = tonumber(currentTime) or Internal.Now()
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
