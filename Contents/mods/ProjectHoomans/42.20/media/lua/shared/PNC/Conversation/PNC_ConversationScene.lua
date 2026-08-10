-- Build 42.20 shared conversation authority and lease implementation.
PNC = PNC or {}
PNC.ConversationScene = PNC.ConversationScene or {}

local Scene = PNC.ConversationScene

Scene.ID = "social.conversation"
Scene.CMD_BEGIN = "conversationBegin"
Scene.CMD_END = "conversationEnd"
Scene.CMD_CEASEFIRE = "conversationCeasefire"
Scene.LEASE_MS = 3500
Scene.START_DISTANCE = 6.0
Scene.DANGER_RADIUS = 8.0
Scene.CEASEFIRE_HOURS = 1

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

local function targetsPlayer(target, player)
    if not target or not player then return false end
    if target == player then return true end
    return type(target) == "table"
        and (target.player == player or target.worldObject == player)
end

-- Proximity is not danger by itself. A nearby body becomes a conversation
-- threat only when it is actively targeting the player or the NPC currently
-- being spoken to. This avoids collapsing dialogue because an idle zombie or
-- unrelated hostile happens to be inside the configured radius.
local function engineTargetsConversation(candidate, player, zombie)
    if not candidate or not candidate.getTarget then return false end
    local target = candidate:getTarget()
    return target == player or target == zombie
end

local function recordTargetsConversation(
    candidate,
    record,
    player,
    zombie
)
    local runtime = candidate and candidate.runtime or {}
    if sameTarget(runtime.target, player, zombie, record) then
        return true
    end
    local live = candidate and PNC.Registry
        and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(candidate.id) or nil
    return engineTargetsConversation(live, player, zombie)
end

local function zombieIsConversationEnemy(candidate, record, relationships)
    local candidateRecord = PNC.Registry
        and PNC.Registry.FindRecordByZombie
        and PNC.Registry.FindRecordByZombie(candidate) or nil
    if not candidateRecord then return true end -- vanilla zombie
    return candidateRecord ~= record
        and relationships
        and relationships.AreNPCsEnemies
        and relationships.AreNPCsEnemies(record, candidateRecord)
        or false
end

local function worldAgeHours()
    local gameTime = getGameTime and getGameTime() or nil
    return gameTime and gameTime.getWorldAgeHours
        and math.max(0, tonumber(gameTime:getWorldAgeHours()) or 0)
        or 0
end

local function playerKey(player, callback)
    if not player or not PNC.PlayerCharacters
        or not PNC.PlayerCharacters.GetEntityKey
    then
        return nil
    end
    return PNC.PlayerCharacters.GetEntityKey(player, {
        callback = callback or "conversation",
        worldAgeHours = worldAgeHours(),
    })
end

local function applyParley(record, zombie, reason)
    -- Do not derive a globally neutral legacy faction here: a parley is
    -- scoped to one NPC/player pair, not a ceasefire for every player. The
    -- target filter in FactionBehavior.ResolveIntent handles re-acquisition
    -- for this stable player key while this clears the existing attack.
    if PNC.BehaviorCommon
        and PNC.BehaviorCommon.ClearCombatTarget
    then
        PNC.BehaviorCommon.ClearCombatTarget(record, reason, zombie)
    else
        record.runtime = record.runtime or {}
        record.runtime.target = nil
    end
    record.runtime = record.runtime or {}
    record.runtime.attackAction = nil
    record.runtime.inCombatUntil = 0
    record.nextThinkAt = now()
end

local function sendCeasefireResult(player, ok, reason, value)
    local network = PNC.Network
    local command = PNC.Const
        and PNC.Const.CMD_CONVERSATION_CEASEFIRE_RESULT or nil
    if not command or not network or not network.Internal
        or not network.Internal.SendToPlayer
    then
        return false
    end
    return network.Internal.SendToPlayer(player, command, {
        ok = ok == true,
        reason = tostring(reason or "unknown"),
        factionID = value and value.factionID or nil,
        untilWorldAgeHours = value
            and value.untilWorldAgeHours or nil,
    })
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

function Scene.HasThreat(record, zombie, player, radius, options)
    options = type(options) == "table" and options or {}
    local runtime = record and record.runtime or {}
    local health = record and record.health or {}
    local current = now()
    local hostileTalkingTarget = options.ignoreTalkingNPC == true
        and targetsPlayer(runtime.target, player)
    if (runtime.target ~= nil and not hostileTalkingTarget)
        or (runtime.attackAction ~= nil and not hostileTalkingTarget)
        or (current < (tonumber(runtime.inCombatUntil) or 0)
            and not hostileTalkingTarget)
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
                and zombieIsConversationEnemy(
                    candidate,
                    record,
                    relationships
                )
                and engineTargetsConversation(candidate, player, zombie)
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
                and relationships
                and relationships.AreNPCsEnemies
                and relationships.AreNPCsEnemies(record, candidate)
                and recordTargetsConversation(
                    candidate,
                    record,
                    player,
                    zombie
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
    -- The client may request a parley, but only the authoritative hostile
    -- compatibility state may grant one. It is useful even before the NPC
    -- has acquired the player as a direct runtime target.
    local hostileParley = options.allowHostileParley == true
        and tostring(record.faction or "") == "hostile"
        and type(record.hostility) == "table"
        and record.hostility.attackPlayers == true
    if Scene.HasThreat(
        record,
        zombie,
        player,
        dangerRadius,
        { ignoreTalkingNPC = hostileParley }
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
        if current.hostileParley == true
            and record.runtime.conversationParley
            and tostring(
                record.runtime.conversationParley.token or ""
            ) == token
        then
            record.runtime.conversationParley.untilAt =
                current.expiresAt
        end
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
        hostileParley = hostileParley,
    }
    if hostileParley then
        local key = playerKey(player, "conversation_parley")
        if not key then
            PNC.AnimationScenes.Stop(
                record,
                zombie,
                "conversation_identity_unavailable"
            )
            return false, "player_identity_unavailable"
        end
        record.runtime.conversationParley = {
            token = token,
            playerKey = key,
            untilAt = currentTime + Scene.LEASE_MS,
        }
        applyParley(record, zombie, "conversation_parley_started")
    end
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
    local parley = runtime.conversationParley
    if parley and (token == nil or tostring(token) == ""
        or tostring(parley.token or "") == tostring(token))
    then
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
        tonumber(lease.dangerRadius) or Scene.DANGER_RADIUS,
        { ignoreTalkingNPC = lease.hostileParley == true }
    ) then
        return Scene.End(record, zombie, lease.token, "conversation_danger")
    end
    return false
end

local function handleCeasefire(player, record, zombie, token)
    local runtime = record and record.runtime or nil
    local lease = runtime and runtime.conversationLease or nil
    local parley = runtime and runtime.conversationParley or nil
    if not lease or not parley
        or tostring(lease.token or "") ~= tostring(token or "")
        or tostring(parley.token or "") ~= tostring(token or "")
    then
        sendCeasefireResult(player, false, "no_active_parley")
        return false, "no_active_parley"
    end
    if tostring(lease.playerUsername or "") ~= tostring(
        player and player.getUsername and player:getUsername() or ""
    ) then
        sendCeasefireResult(player, false, "lease_owner_mismatch")
        return false, "lease_owner_mismatch"
    end
    if lease.playerOnlineID ~= nil
        and tostring(lease.playerOnlineID) ~= tostring(
            player and player.getOnlineID and player:getOnlineID()
                or ""
        )
    then
        sendCeasefireResult(player, false, "lease_owner_mismatch")
        return false, "lease_owner_mismatch"
    end
    local factionID = PNC.Factions
        and PNC.Factions.GetOrganizationalFactionID
        and PNC.Factions.GetOrganizationalFactionID(record) or nil
    if not factionID or not PNC.Factions.PacifyForPlayer then
        sendCeasefireResult(player, false, "faction_unavailable")
        return false, "faction_unavailable"
    end
    local key = playerKey(player, "conversation_ceasefire")
    if not key or key ~= parley.playerKey then
        sendCeasefireResult(player, false, "player_identity_unavailable")
        return false, "player_identity_unavailable"
    end
    local ok, reason, entry = PNC.Factions.PacifyForPlayer(
        factionID,
        key,
        {
            worldAgeHours = worldAgeHours(),
            durationHours = Scene.CEASEFIRE_HOURS,
            reason = "conversation_ceasefire",
            sourceNPCID = record.id,
        }
    )
    if ok then
        entry = entry or {}
        entry.factionID = factionID
        applyParley(record, zombie, "conversation_ceasefire")
    end
    sendCeasefireResult(player, ok, reason, entry)
    return ok, reason, entry
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
            allowHostileParley = args.allowHostileParley == true,
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
    if command == Scene.CMD_CEASEFIRE then
        return handleCeasefire(player, record, zombie, args.token)
    end
    return false, "unknown_command"
end

return Scene
