PNC = PNC or {}
PNC.ConversationScene = PNC.ConversationScene or {}

local Scene = PNC.ConversationScene

Scene.ID = "social.conversation"
Scene.CMD_BEGIN = "conversationBegin"
Scene.CMD_END = "conversationEnd"
Scene.LEASE_MS = 3500
Scene.START_DISTANCE = 6.0
Scene.DANGER_RADIUS = 8.0

local function now()
    return PNC.Core and PNC.Core.Now and PNC.Core.Now()
        or getTimeInMillis and getTimeInMillis()
        or 0
end

local function distanceSq(first, second)
    if not first or not second
        or not first.getX or not second.getX
    then
        return math.huge
    end
    if first.getZ and second.getZ
        and math.abs(first:getZ() - second:getZ()) >= 1
    then
        return math.huge
    end
    local dx = first:getX() - second:getX()
    local dy = first:getY() - second:getY()
    return dx * dx + dy * dy
end

local function isAlive(value)
    return value ~= nil
        and (not value.isDead or value:isDead() ~= true)
end

local function sameTarget(target, player, zombie, record)
    if not target then return false end
    if target == player or target == zombie then return true end
    if type(target) ~= "table" then return false end
    return tostring(target.id or "") == tostring(record and record.id or "")
        or target.worldObject == player
        or target.worldObject == zombie
end

function Scene.EnsureRegistered()
    local scenes = PNC.AnimationScenes
    if not scenes or not scenes.Register then
        return false, "animation_scenes_unavailable"
    end
    if scenes.Get and scenes.Get(Scene.ID) then return true end
    return scenes.Register(Scene.ID, {
        label = "Conversation Idle",
        description = "A subtle, blocking idle used while an NPC is talking.",
        category = "social",
        priority = 45,
        blocking = true,
        repeatMode = "loop",
        stepGapMs = 180,
        stepGapJitterMs = 220,
        steps = {
            {
                id = "shift_weight",
                bump = "ShiftWeight",
                durationMs = 2600,
            },
        },
        interrupts = {
            movement = false,
            combat = true,
            externalBump = true,
            abstract = true,
        },
    })
end

function Scene.HasThreat(record, zombie, player, radius)
    local runtime = record and record.runtime or {}
    local health = record and record.health or {}
    local current = now()
    if runtime.target ~= nil
        or runtime.attackAction ~= nil
        or current < (tonumber(runtime.inCombatUntil) or 0)
        or current < (tonumber(health.recentDamageUntil) or 0)
    then
        return true
    end
    radius = tonumber(radius) or Scene.DANGER_RADIUS
    local spatial = PNC.SpatialIndex
    local relationships = PNC.Relationships
    if spatial and spatial.QueryZombies and player then
        local candidates = spatial.QueryZombies(
            player:getX(),
            player:getY(),
            radius
        )
        for index = 1, #candidates do
            local candidate = candidates[index]
            if candidate ~= zombie
                and isAlive(candidate)
                and (
                    distanceSq(candidate, player) <= radius * radius
                    or distanceSq(candidate, zombie) <= radius * radius
                )
            then
                return true
            end
        end
    end
    if spatial and spatial.QueryNPCs and record then
        local candidates = spatial.QueryNPCs(
            tonumber(record.x) or zombie and zombie:getX() or 0,
            tonumber(record.y) or zombie and zombie:getY() or 0,
            radius
        )
        for index = 1, #candidates do
            local candidate = candidates[index]
            if candidate ~= record
                and candidate.alive ~= false
                and (
                    relationships
                    and relationships.AreNPCsEnemies
                    and relationships.AreNPCsEnemies(record, candidate)
                    or sameTarget(
                        candidate.runtime and candidate.runtime.target,
                        player,
                        zombie,
                        record
                    )
                )
            then
                return true
            end
        end
    end
    return false
end

function Scene.Begin(record, zombie, player, token, options)
    options = type(options) == "table" and options or {}
    if not record or record.alive == false or not isAlive(zombie) then
        return false, "npc_unavailable"
    end
    local maximumDistance = math.max(
        2,
        math.min(
            12,
            tonumber(options.maximumDistance)
                or Scene.START_DISTANCE
        )
    )
    local dangerRadius = math.max(
        2,
        math.min(
            20,
            tonumber(options.dangerRadius)
                or Scene.DANGER_RADIUS
        )
    )
    if distanceSq(player, zombie) > maximumDistance * maximumDistance then
        return false, "distance"
    end
    if Scene.HasThreat(
        record,
        zombie,
        player,
        dangerRadius
    ) then
        return false, "danger"
    end
    local registered, registrationReason = Scene.EnsureRegistered()
    if not registered then return false, registrationReason end

    record.runtime = record.runtime or {}
    local current = record.runtime.conversationLease
    local currentTime = now()
    token = tostring(token or "")
    if current
        and tostring(current.token or "") == token
        and record.runtime.animationScene
        and record.runtime.animationScene.id == Scene.ID
    then
        current.expiresAt = currentTime + Scene.LEASE_MS
        return true, current
    end
    if current
        and current.expiresAt
        and currentTime < current.expiresAt
        and tostring(current.playerUsername or "")
            ~= tostring(
                player and player.getUsername
                    and player:getUsername() or ""
            )
    then
        return false, "already_talking"
    end

    local started, scene = PNC.AnimationScenes.Request(
        record,
        zombie,
        Scene.ID,
        {
            reason = "conversation",
            repeatMode = "loop",
            now = currentTime,
        }
    )
    if not started then return false, scene end
    local lease = {
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
    }
    record.runtime.conversationLease = lease
    record.nextThinkAt = currentTime
    return true, lease
end

function Scene.End(record, zombie, token, reason)
    local runtime = record and record.runtime or nil
    local lease = runtime and runtime.conversationLease or nil
    if not lease then return false end
    if token ~= nil and tostring(token) ~= ""
        and tostring(lease.token or "") ~= tostring(token)
    then
        return false
    end
    runtime.conversationLease = nil
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
    record.nextThinkAt = now()
    return true
end

local function resolveLeasePlayer(lease)
    local core = PNC.Core
    if core and core.ResolvePlayerByOnlineID
        and lease.playerOnlineID ~= nil
    then
        local player = core.ResolvePlayerByOnlineID(lease.playerOnlineID)
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
    if not lease then return false end
    currentTime = tonumber(currentTime) or now()
    local player = resolveLeasePlayer(lease)
    if currentTime >= (tonumber(lease.expiresAt) or 0) then
        return Scene.End(record, zombie, lease.token, "conversation_timeout")
    end
    if not player
        or distanceSq(player, zombie)
            > (tonumber(lease.maximumDistance) or Scene.START_DISTANCE)
                * (tonumber(lease.maximumDistance) or Scene.START_DISTANCE)
    then
        return Scene.End(record, zombie, lease.token, "conversation_distance")
    end
    if Scene.HasThreat(
        record,
        zombie,
        player,
        tonumber(lease.dangerRadius) or Scene.DANGER_RADIUS
    ) then
        return Scene.End(record, zombie, lease.token, "conversation_danger")
    end
    return false
end

function Scene.HandleClientCommand(player, command, args)
    args = type(args) == "table" and args or {}
    local registry = PNC.Registry
    local record = registry and registry.Get and registry.Get(args.id) or nil
    local zombie = record and registry.GetLiveZombie(record.id) or nil
    if command == Scene.CMD_BEGIN then
        return Scene.Begin(record, zombie, player, args.token, {
            maximumDistance = args.maximumDistance,
            dangerRadius = args.dangerRadius,
        })
    end
    if command == Scene.CMD_END then
        return Scene.End(
            record,
            zombie,
            args.token,
            args.reason or "conversation_client_close"
        )
    end
    return false, "unknown_command"
end

return Scene
