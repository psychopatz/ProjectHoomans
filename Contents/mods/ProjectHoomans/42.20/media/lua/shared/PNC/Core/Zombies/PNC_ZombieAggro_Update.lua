PNC = PNC or {}
PNC.ZombieAggro = PNC.ZombieAggro or {}

local ZombieAggro = PNC.ZombieAggro
local Core = PNC.Core
local Const = PNC.Const
local Registry = PNC.Registry
local Stealth = PNC.Stealth
local ZombieReaction = PNC.CombatZombieReaction
local Settings = PNC.Sandbox
local Diagnostics = PNC.PerformanceScalingDiagnostics

local Internal = ZombieAggro.Internal
local pursuitLogThrottle = {}
local pursuitLogCalls = 0

local function isForeignOwnedBody(body)
    local ownership = PNC.Compatibility
        and PNC.Compatibility.ActorOwnership or nil
    return ownership
        and ownership.IsForeignOwned
        and ownership.IsForeignOwned(body) == true
        or false
end

local function isMultiplayerServer()
    return isServer and isServer() == true or false
end

function ZombieAggro.ClearForNPCBody(npcBody)
    local target
    local forcedRecord
    local forcedBody
    if not npcBody or not getCell then
        return
    end
    ZombieAggro.ClearBiteEntriesForNPCBody(npcBody)
    if ZombieAggro.ForEachActive then
        ZombieAggro.ForEachActive(function(zombie)
        if zombie and (not zombie:isDead())
            and (not Internal.isManagedNPCBody(zombie))
            and not isForeignOwnedBody(zombie)
        then
            target = zombie.getTarget and zombie:getTarget() or nil
            forcedRecord, forcedBody = Internal.getForcedNPCBodyTarget(zombie)
            if target == npcBody or forcedBody == npcBody then
                Internal.clearZombieTarget(zombie)
                ZombieAggro.ClearBiteEntryForZombie(zombie)
            end
        end
        end)
    end
end

function ZombieAggro.OnZombieProvoked(zombie, npcBody)
    if not zombie or not npcBody or zombie:isDead()
        or Internal.isManagedNPCBody(zombie)
        or isForeignOwnedBody(zombie)
    then
        return
    end
    if ZombieAggro.Activate then
        ZombieAggro.Activate(zombie, Core.Now(), "provoked")
    end
    Internal.forceAggro(zombie, npcBody)
end

local function setNoLungeAttack(zombie, disabled)
    if zombie and zombie.setVariable then
        zombie:setVariable("NoLungeAttack", disabled == true)
    end
end

local function incrementDiagnostic(name, amount)
    if Diagnostics and Diagnostics.Increment then
        Diagnostics.Increment(name, amount)
    end
end

local function logPursuitDiagnostic(
    zombie, npcId, channel, state, detail, now
)
    local perZombie
    local previous
    local zombieId
    local throttleKey
    local lastAt
    local fields
    local auditEnabled
    auditEnabled = not Diagnostics
        or type(Diagnostics.IsZombieAggroAuditEnabled) ~= "function"
        or Diagnostics.IsZombieAggroAuditEnabled() == true
    if not auditEnabled then
        return false
    end
    if not zombie or not Core or not Core.LogInfo then
        return false
    end
    now = tonumber(now) or Core.Now()
    channel = tostring(channel or "pursuit")
    state = tostring(state or "unknown")
    zombieId = zombie.getOnlineID and zombie:getOnlineID() or nil
    if (tonumber(zombieId) or -1) < 0
        and Internal.ensureZombieID
    then
        zombieId = Internal.ensureZombieID(zombie)
    end
    throttleKey = tostring(zombieId or zombie)
    perZombie = pursuitLogThrottle[throttleKey]
    if not perZombie then
        perZombie = {}
        pursuitLogThrottle[throttleKey] = perZombie
    end
    previous = perZombie[channel]
    if previous
        and previous.state == state
        and now - (tonumber(previous.at) or 0) < 2500
    then
        return false
    end
    if previous
        and previous.state ~= state
        and now - (tonumber(previous.at) or 0) < 500
    then
        return false
    end
    perZombie[channel] = { state = state, at = now }
    pursuitLogCalls = pursuitLogCalls + 1
    if pursuitLogCalls % 128 == 0 then
        for cachedZombie, channels in pairs(pursuitLogThrottle) do
            lastAt = 0
            for _, entry in pairs(channels) do
                if (tonumber(entry.at) or 0) > lastAt then
                    lastAt = tonumber(entry.at) or 0
                end
            end
            if now - lastAt > 30000 then
                pursuitLogThrottle[cachedZombie] = nil
            end
        end
    end
    fields = {
        "zombie=" .. tostring(zombieId or ("local@" .. throttleKey)),
        "npc=" .. tostring(npcId or "unknown"),
        "state=" .. state,
        tostring(detail or ""),
    }
    if Diagnostics and type(Diagnostics.LogZombieAggroAudit) == "function" then
        return Diagnostics.LogZombieAggroAudit(channel, fields)
    end
    Core.LogInfo(
        "ZombieAggro." .. channel .. " " .. table.concat(fields, " ")
    )
    return true
end

-- Shared and client-side controllers use the same bounded logger so a single
-- console capture can show target selection, movement, and MP handoff.
ZombieAggro.LogPursuitDiagnostic = logPursuitDiagnostic

local function actionStateName(zombie)
    return zombie
        and zombie.getActionStateName
        and string.lower(tostring(zombie:getActionStateName() or ""))
        or ""
end

local PURSUIT_ACTION_LOCKS = {
    ["attack"] = true,
    ["attack-network"] = true,
    bumped = true,
    climbfence = true,
    climbwindow = true,
    getup = true,
    lunge = true,
    onground = true,
    staggerback = true,
    turnalerted = true,
}

local function isPursuitActionLocked(zombie)
    return PURSUIT_ACTION_LOCKS[actionStateName(zombie)] == true
end

-- Use the vanilla coordinate-goal API without ever creating an NPC character
-- goal. When a zombie is already in PathFindState, calling the character
-- wrapper can be ignored by IsoZombie's allowRepathDelay guard. PathFindState
-- already owns Behavior2:update(), so update its location goal directly in
-- that state. In all other states the public wrapper remains responsible for
-- entering the normal pathfind/movement animation contract.
function ZombieAggro.RequestCoordinatePath(zombie, targetX, targetY, targetZ)
    local behavior
    local state
    local pathState
    local currentState
    if not zombie then
        return false, "missing_zombie"
    end
    behavior = zombie.getPathFindBehavior2
        and zombie:getPathFindBehavior2() or nil
    state = actionStateName(zombie)
    if isPursuitActionLocked(zombie) then
        incrementDiagnostic("ZombieAggro.PathRequestsDeferred")
        return false, "action_state_locked:" .. state
    end
    if not behavior or not behavior.pathToLocationF then
        return false, "behavior2_unavailable"
    end

    pathState = PathFindState and PathFindState.instance
        and PathFindState.instance() or nil
    currentState = zombie.getCurrentState and zombie:getCurrentState() or nil
    -- IsoZombie:pathToLocationF() is guarded by allowRepathDelay while it is
    -- in PathFind/WalkToward states. Use the same direct Behavior2 + state
    -- transition sequence that Project A-Life uses for its owned shells in
    -- every state, so the goal update cannot be silently discarded.
    if pathState and currentState ~= pathState then
        if behavior.cancel then behavior:cancel() end
        if behavior.reset then behavior:reset() end
        if zombie.setPath2 then zombie:setPath2(nil) end
    end
    behavior:pathToLocationF(targetX, targetY, targetZ)
    if zombie.setVariable then
        zombie:setVariable("bPathfind", true)
        zombie:setVariable("bMoving", false)
    end
    if pathState and currentState ~= pathState and zombie.changeState then
        zombie:changeState(pathState)
    end
    incrementDiagnostic("ZombieAggro.Behavior2PathRequests")
    return true, "behavior2_pathfind_state"
end

local function suppressForStealth(zombie, record)
    Internal.clearZombieTarget(zombie)
    ZombieAggro.ClearBiteEntryForZombie(zombie)
    -- clearZombieTarget intentionally restores the ordinary zombie default.
    -- Stealth suppression must override that default on the same frame or a
    -- stale native target can still lunge before the next aggro tick.
    setNoLungeAttack(zombie, true)
    record.runtime = record.runtime or {}
    record.runtime.combatBlockReason = Stealth
        and Stealth.IsTravelStealthActive
        and Stealth.IsTravelStealthActive(record)
        and "travel_stealth_hidden"
        or "follow_stealth_hidden"
end

local function refreshPursuitPath(zombie, npcBody, now, npcId)
    local modData = Internal.getZombieModData(zombie)
    local targetX = npcBody:getX()
    local targetY = npcBody:getY()
    local dx = targetX - zombie:getX()
    local dy = targetY - zombie:getY()
    local distanceSq = (dx * dx) + (dy * dy)
    local lastX = modData and tonumber(modData.PNC_AggroPathX) or nil
    local lastY = modData and tonumber(modData.PNC_AggroPathY) or nil
    local movedSq = lastX and lastY and Core.DistanceSq(lastX, lastY, targetX, targetY) or math.huge
    local refreshDistance = tonumber(Const.ZOMBIE_NPC_PATH_REFRESH_DISTANCE) or 0.6
    local lastAt = modData
        and tonumber(modData.PNC_AggroPathAt) or nil
    local elapsed
    local refreshMs = tonumber(Const.ZOMBIE_NPC_PATH_REFRESH_MS) or 350
    local stableRetryMs = tonumber(
        Const.ZOMBIE_NPC_PATH_STABLE_RETRY_MS
    ) or 1500
    now = tonumber(now) or Core.Now()
    if isPursuitActionLocked(zombie) then
        logPursuitDiagnostic(
            zombie,
            npcId,
            "server_path",
            "action_state_locked",
            "action=" .. actionStateName(zombie),
            now
        )
        return false
    end
    elapsed = lastAt and (now - lastAt) or math.huge
    if modData and lastAt and (
        elapsed < refreshMs
        or (movedSq < (refreshDistance * refreshDistance)
            and elapsed < stableRetryMs)
    ) then
        logPursuitDiagnostic(
            zombie,
            npcId,
            "server_path",
            elapsed < refreshMs and "request_cooldown"
                or "stable_goal_kept",
            "targetMovedSq=" .. tostring(movedSq)
                .. " elapsedMs=" .. tostring(elapsed)
                .. " minIntervalMs=" .. tostring(refreshMs)
                .. " stableRetryMs=" .. tostring(stableRetryMs),
            now
        )
        return false
    end
    if ZombieAggro.ConsumePathRequestBudget
        and not ZombieAggro.ConsumePathRequestBudget()
    then
        if Diagnostics then
            Diagnostics.Increment(
                "ZombieAggro.PathRequestsDeferred"
            )
        end
        logPursuitDiagnostic(
            zombie,
            npcId,
            "server_path",
            "budget_deferred",
            "targetX=" .. tostring(targetX)
                .. " targetY=" .. tostring(targetY),
            now
        )
        return false
    end
    if modData then
        modData.PNC_AggroPathAt = now
        modData.PNC_AggroPathX = targetX
        modData.PNC_AggroPathY = targetY
    end
    -- PNC bodies are IsoZombie shells, not IsoPlayer targets. A native
    -- character goal can enter Build 42's lunge/fence attack path, whose
    -- animation event dereferences player-only state such as Moodles and
    -- BodyDamage. Keep SP pursuit coordinate-only; the abstract bite lane
    -- owns NPC damage separately.
    local requested
    local requestReason
    if ZombieAggro.RequestCoordinatePath then
        requested, requestReason = ZombieAggro.RequestCoordinatePath(
            zombie,
            targetX,
            targetY,
            npcBody:getZ()
        )
    elseif zombie.pathToLocationF then
        zombie:pathToLocationF(targetX, targetY, npcBody:getZ())
        requested = true
    end
    if requested then
        if Diagnostics then
            Diagnostics.Increment("ZombieAggro.PathRequests")
        end
    end
    logPursuitDiagnostic(
        zombie,
        npcId,
        "server_path",
        requested and "path_requested" or "path_request_failed",
        "api=" .. tostring(requestReason or "pathToLocationF")
            .. " action=" .. actionStateName(zombie)
            .. " distance=" .. tostring(math.sqrt(distanceSq))
            .. " targetX=" .. tostring(targetX)
            .. " targetY=" .. tostring(targetY),
        now
    )
    return true
end

-- The shared composition loads the zombie subsystem before PNC_Network. Keep
-- this lookup lazy so a fresh dedicated-server load sees the transport after
-- the networking facade has finished registering its functions.
local function getMPNetwork()
    local network = PNC.Network
    if not network
        or not network.GetZombieOnlineID
        or not network.Internal
        or not network.Internal.SendToNearbyPlayers
    then
        return nil
    end
    return network
end

local function isMPDirectiveServer()
    return isMultiplayerServer()
        and getMPNetwork() ~= nil
end

local function clearMPTargetDirective(zombie, now)
    local modData
    local zombieOnlineID
    local revision
    local payload
    local sent
    local network
    if not isMPDirectiveServer() or not zombie then
        return 0
    end
    network = getMPNetwork()
    modData = Internal.getZombieModData(zombie)
    if not modData or modData.PNC_MPAggroDirectiveNPCId == nil then
        return 0
    end
    zombieOnlineID = network.GetZombieOnlineID(zombie)
    revision = (tonumber(modData.PNC_MPAggroDirectiveRevision) or 0) + 1
    payload = {
        active = false,
        owner = "ProjectHoomans",
        provider = "Hoomans",
        priority = 100,
        reason = "hoomans_npc",
        zombieOnlineID = zombieOnlineID,
        npcId = modData.PNC_MPAggroDirectiveNPCId,
        x = tonumber(modData.PNC_MPAggroDirectiveX),
        y = tonumber(modData.PNC_MPAggroDirectiveY),
        z = tonumber(modData.PNC_MPAggroDirectiveZ),
        expiresAt = tonumber(now) or Core.Now(),
        revision = revision,
    }
    sent = 0
    if zombieOnlineID ~= nil then
        sent = network.Internal.SendToNearbyPlayers(
            zombie,
            nil,
            Const.CMD_ZOMBIE_PURSUIT,
            payload
        )
    end
    modData.PNC_MPAggroDirectiveRevision = revision
    modData.PNC_MPAggroDirectiveNPCId = nil
    modData.PNC_MPAggroDirectiveLastSentAt = nil
    modData.PNC_MPAggroDirectiveX = nil
    modData.PNC_MPAggroDirectiveY = nil
    modData.PNC_MPAggroDirectiveZ = nil
    modData.PNC_MPAggroDirectiveApproach = nil
    if sent > 0 then
        incrementDiagnostic("ZombieAggro.MPDirectiveCleared", sent)
    end
    return sent
end

local function publishMPTargetDirective(
    zombie, record, npcBody, now, approach
)
    local modData
    local zombieOnlineID
    local npcId
    local targetX
    local targetY
    local targetZ
    local previousId
    local previousX
    local previousY
    local previousApproach
    local targetChanged
    local approachChanged
    local movedSq
    local sendAt
    local sent
    local payload
    local network
    network = getMPNetwork()
    if isMultiplayerServer() and not network then
        logPursuitDiagnostic(
            zombie,
            record and record.id or nil,
            "server_mp",
            "network_unavailable",
            "networkFacade=" .. tostring(PNC.Network ~= nil),
            now
        )
        return 0
    end
    if not isMultiplayerServer()
        or not network
        or not zombie
        or not record
        or not npcBody
    then
        return 0
    end
    modData = Internal.getZombieModData(zombie)
    zombieOnlineID = network.GetZombieOnlineID(zombie)
    npcId = record.id ~= nil and tostring(record.id) or nil
    targetX = tonumber(npcBody:getX())
    targetY = tonumber(npcBody:getY())
    targetZ = tonumber(npcBody:getZ())
    if not modData or zombieOnlineID == nil or not npcId
        or targetX == nil or targetY == nil or targetZ == nil
    then
        return 0
    end
    previousId = modData.PNC_MPAggroDirectiveNPCId
    previousX = tonumber(modData.PNC_MPAggroDirectiveX)
    previousY = tonumber(modData.PNC_MPAggroDirectiveY)
    previousApproach = modData.PNC_MPAggroDirectiveApproach == true
    targetChanged = tostring(previousId or "") ~= npcId
    approachChanged = previousApproach ~= (approach == true)
    movedSq = previousX and previousY
        and Core.DistanceSq(previousX, previousY, targetX, targetY)
        or math.huge
    now = tonumber(now) or Core.Now()
    sendAt = tonumber(modData.PNC_MPAggroDirectiveLastSentAt) or 0
    if not targetChanged and not approachChanged
        and now - sendAt < (tonumber(Const.ZOMBIE_NPC_DIRECTIVE_SEND_MS) or 400)
        and movedSq < ((tonumber(Const.ZOMBIE_NPC_PATH_REFRESH_DISTANCE) or 0.6) ^ 2)
    then
        return 0
    end
    if targetChanged or approachChanged then
        modData.PNC_MPAggroDirectiveRevision =
            (tonumber(modData.PNC_MPAggroDirectiveRevision) or 0) + 1
    end
    payload = {
        active = true,
        owner = "ProjectHoomans",
        provider = "Hoomans",
        priority = 100,
        reason = "hoomans_npc",
        zombieOnlineID = zombieOnlineID,
        npcId = npcId,
        x = targetX,
        y = targetY,
        z = targetZ,
        approach = approach == true,
        expiresAt = now + (tonumber(Const.ZOMBIE_NPC_DIRECTIVE_TTL_MS) or 1100),
        revision = tonumber(modData.PNC_MPAggroDirectiveRevision) or 1,
    }
    sent = network.Internal.SendToNearbyPlayers(
        zombie,
        npcBody,
        Const.CMD_ZOMBIE_PURSUIT,
        payload
    )
    logPursuitDiagnostic(
        zombie,
        npcId,
        "server_mp",
        sent > 0 and "directive_sent" or "directive_no_recipients",
        "recipients=" .. tostring(sent)
            .. " revision=" .. tostring(payload.revision)
            .. " x=" .. tostring(targetX)
            .. " y=" .. tostring(targetY)
            .. " z=" .. tostring(targetZ)
            .. " approach=" .. tostring(approach == true),
        now
    )
    modData.PNC_MPAggroDirectiveNPCId = npcId
    modData.PNC_MPAggroDirectiveX = targetX
    modData.PNC_MPAggroDirectiveY = targetY
    modData.PNC_MPAggroDirectiveZ = targetZ
    modData.PNC_MPAggroDirectiveApproach = approach == true
    if sent > 0 then
        modData.PNC_MPAggroDirectiveLastSentAt = now
        incrementDiagnostic("ZombieAggro.MPDirectiveSent", sent)
    end
    return sent
end

local function pursueForcedTarget(zombie, npcBody, record, now, hitSettling)
    local distSq
    local dist
    local zDistance
    local zombieSquare
    local npcSquare
    local blocked
    local approach = true
    local repathClose = false
    local biteStarted
    if not Internal.AcquirePursuitLease(
        zombie,
        "ProjectHoomans",
        "Hoomans",
        record and record.id or nil,
        now,
        Const.ZOMBIE_NPC_AGGRO_LEASE_MS,
        100,
        "hoomans_npc"
    ) then
        logPursuitDiagnostic(
            zombie,
            record and record.id or nil,
            "server_target",
            "pursuit_lease_denied",
            "owner=" .. tostring(
                Internal.GetPursuitLease
                    and Internal.GetPursuitLease(zombie, now)
                    and Internal.GetPursuitLease(zombie, now).owner
                    or "unknown"
            ),
            now
        )
        return
    end
    if npcBody.setZombiesDontAttack then
        -- This flag protects the IsoZombie shell from vanilla zombie attack
        -- acquisition. PNC's abstract bite lane does not use the native
        -- target slot, so it remains independently targetable by PNC.
        npcBody:setZombiesDontAttack(true)
    end
    distSq = Core.DistanceSq(zombie:getX(), zombie:getY(), npcBody:getX(), npcBody:getY())
    dist = math.sqrt(distSq)
    zDistance = math.abs(zombie:getZ() - npcBody:getZ())
    if Internal.rememberZombieAttacker then
        Internal.rememberZombieAttacker(
            record,
            zombie,
            dist < Const.ZOMBIE_BITE_DISTANCE
                and "bite_range" or "pursuit",
            now,
            distSq
        )
    end
    if isMultiplayerServer() or not (isClient and isClient() == true) then
        -- The server selects the target in MP. The owning client follows this
        -- bounded coordinate directive; a location-only WorldSound can send
        -- the same zombie down a conflicting path and carries no NPC identity.
        setNoLungeAttack(zombie, true)
    else
        -- The client-side SP controller owns the abstract NPC damage gate.
        -- Keep native lunge disabled because the shell is not an IsoPlayer.
        setNoLungeAttack(zombie, true)
    end
    if (isMultiplayerServer() or not (isClient and isClient() == true))
        and not hitSettling
    then
        if zombie.setTarget then zombie:setTarget(nil) end
        if zombie.setAttackedBy then zombie:setAttackedBy(nil) end
        if zombie.setTargetSeenTime then zombie:setTargetSeenTime(0) end
        if zombie.clearAggroList then zombie:clearAggroList() end
    end
    if dist < Const.ZOMBIE_BITE_DISTANCE and zDistance < 0.3 then
        zombieSquare = zombie.getSquare and zombie:getSquare() or nil
        npcSquare = npcBody.getSquare and npcBody:getSquare() or nil
        if not zombieSquare or not npcSquare then
            repathClose = true
            logPursuitDiagnostic(
                zombie, record.id, "server_combat", "close_square_missing",
                "distance=" .. tostring(dist)
                    .. " zombieSquare=" .. tostring(zombieSquare ~= nil)
                    .. " npcSquare=" .. tostring(npcSquare ~= nil), now
            )
        else
            blocked = zombieSquare:isSomethingTo(npcSquare)
        end
        if zombieSquare and npcSquare and not blocked then
            if zombie.isFacingObject and zombie:isFacingObject(npcBody, 0.3) then
                if not hitSettling then
                    biteStarted = ZombieAggro.TryStartBite(
                        zombie, npcBody, record
                    )
                    approach = biteStarted ~= true
                    repathClose = approach
                    logPursuitDiagnostic(
                        zombie, record.id, "server_combat",
                        biteStarted and "bite_started_or_active"
                            or "bite_start_rejected",
                        "distance=" .. tostring(dist)
                            .. " action=" .. actionStateName(zombie), now
                    )
                else
                    approach = true
                    repathClose = true
                    logPursuitDiagnostic(
                        zombie, record.id, "server_combat", "hit_settling",
                        "distance=" .. tostring(dist)
                            .. " action=" .. actionStateName(zombie), now
                    )
                end
            elseif zombie.faceThisObject then
                approach = hitSettling == true
                repathClose = approach
                zombie:faceThisObject(npcBody)
                logPursuitDiagnostic(
                    zombie, record.id, "server_combat", "turning_to_npc",
                    "distance=" .. tostring(dist)
                        .. " action=" .. actionStateName(zombie), now
                )
            else
                approach = true
                repathClose = true
                logPursuitDiagnostic(
                    zombie, record.id, "server_combat", "cannot_face_npc",
                    "distance=" .. tostring(dist)
                        .. " hasFacingApi="
                        .. tostring(zombie.isFacingObject ~= nil), now
                )
            end
        elseif zombieSquare and npcSquare and blocked then
            approach = true
            repathClose = true
            logPursuitDiagnostic(
                zombie, record.id, "server_combat", "close_path_blocked",
                "distance=" .. tostring(dist)
                    .. " action=" .. actionStateName(zombie), now
            )
        end
        if repathClose and not isMultiplayerServer() then
            refreshPursuitPath(zombie, npcBody, now, record.id)
        end
    elseif not isMultiplayerServer() then
        -- SP/local authority owns the native zombie path. In MP the owning
        -- client performs native pursuit while this server code owns only the
        -- forced-target lease, coordinate directive, bite validation, and
        -- damage.
        if zombie.isUseless and zombie.setUseless
            and zombie:isUseless()
        then
            -- Match Bandits for the active ordinary-zombie lane. Do this only
            -- while a pursuit is active; distant zombies retain engine tiering.
            zombie:setUseless(false)
        end
        refreshPursuitPath(zombie, npcBody, now, record.id)
    end
    if isMultiplayerServer() then
        publishMPTargetDirective(
            zombie, record, npcBody, now, approach
        )
    end
    -- The pursuit lane already has the authoritative zombie/NPC pair. Publish
    -- the group stimulus here once per zombie cadence so NPC behavior ticks do
    -- not repeat the fan-out work. The helper remains authority-gated for
    -- singleplayer and multiplayer safety.
    if PNC.Perception and PNC.Perception.PublishZombieGroupAlert then
        PNC.Perception.PublishZombieGroupAlert(record, zombie, now)
    end
end

local function acquireNearestTarget(zombie)
    local nearestRecord
    local nearestBody
    local nearestDistSq
    local nearestPlayer
    local nearestPlayerDistSq
    nearestRecord, nearestBody, nearestDistSq = Internal.findNearestLiveNPC(zombie, Const.ZOMBIE_AGGRO_RADIUS)
    nearestPlayer, nearestPlayerDistSq = Internal.findNearestLivePlayer(
        zombie,
        Const.ZOMBIE_AGGRO_RADIUS
    )
    if nearestPlayer
        and not Internal.shouldPreferNPCOverPlayer(
            nearestDistSq,
            nearestPlayerDistSq
        )
    then
        logPursuitDiagnostic(
            zombie, nil, "server_target", "player_preferred",
            "npcDistanceSq=" .. tostring(nearestDistSq)
                .. " playerDistanceSq=" .. tostring(nearestPlayerDistSq),
            Core.Now()
        )
        setNoLungeAttack(zombie, false)
        return nil, nil
    end
    if nearestRecord and nearestBody then
        logPursuitDiagnostic(
            zombie, nearestRecord.id, "server_target", "npc_selected",
            "npcDistanceSq=" .. tostring(nearestDistSq)
                .. " playerDistanceSq=" .. tostring(nearestPlayerDistSq),
            Core.Now()
        )
        incrementDiagnostic("ZombieAggro.NPCTargetSelected")
        Internal.forceAggro(zombie, nearestBody)
        if isMultiplayerServer() then
            setNoLungeAttack(zombie, true)
        else
            setNoLungeAttack(
                zombie,
                math.sqrt(nearestDistSq) <= Const.ZOMBIE_AGGRO_KEEP_RADIUS
            )
        end
        return nearestRecord, nearestBody
    end
    logPursuitDiagnostic(
        zombie, nil, "server_target", "no_npc_selected",
        "npcDistanceSq=" .. tostring(nearestDistSq)
            .. " playerDistanceSq=" .. tostring(nearestPlayerDistSq),
        Core.Now()
    )
    setNoLungeAttack(zombie, false)
    return nil, nil
end

local function pursueNPCRecord(zombie, record, npcBody, now, hitSettling)
    local lease
    if not record or not npcBody then
        clearMPTargetDirective(zombie, now)
        return false
    end
    lease = Internal.GetPursuitLease
        and Internal.GetPursuitLease(zombie, now)
        or nil
    if lease
        and Internal.ShouldYieldToPursuitOwner
        and Internal.ShouldYieldToPursuitOwner(
            zombie, "ProjectHoomans", now, 100
        )
    then
        logPursuitDiagnostic(
            zombie,
            record.id,
            "server_target",
            "foreign_pursuit_owner",
            "owner=" .. tostring(lease.owner)
                .. " provider=" .. tostring(lease.provider),
            now
        )
        return false
    end
    if not Settings.CanZombieTargetRecord(record) then
        Internal.clearZombieTarget(zombie)
        clearMPTargetDirective(zombie, now)
        ZombieAggro.ClearBiteEntryForZombie(zombie, "target_protected")
        return false
    end
    if Stealth and Stealth.ShouldSuppressZombieAggro and Stealth.ShouldSuppressZombieAggro(record) then
        suppressForStealth(zombie, record)
        clearMPTargetDirective(zombie, now)
    else
        pursueForcedTarget(zombie, npcBody, record, now, hitSettling)
    end
    return true
end

local function processZombie(zombie, now)
    local target
    local record
    local npcBody
    local hitSettling
    local zombieId
    local biteEntry
    if isForeignOwnedBody(zombie) then
        return
    end
    if Internal.ShouldYieldToPursuitOwner
        and Internal.ShouldYieldToPursuitOwner(zombie, "ProjectHoomans", now)
    then
        return
    end
    if ZombieReaction and ZombieReaction.Pump then
        ZombieReaction.Pump(zombie, now)
    end
    hitSettling = ZombieReaction
        and ZombieReaction.IsEngineHitSettling
        and ZombieReaction.IsEngineHitSettling(zombie, now)
        or false
    -- Keep target selection and path goals current during the brief hit
    -- animation. The animation may pause locomotion; it must not drop aggro.
    if ZombieAggro.UpdateBiteState(zombie, now) then
        -- Bite flow owns the zombie while the bite is active.
        zombieId = Internal.ensureZombieID(zombie)
        biteEntry = ZombieAggro.BiteInternal
            and ZombieAggro.BiteInternal.GetBiteEntry
            and ZombieAggro.BiteInternal.GetBiteEntry(zombieId)
        logPursuitDiagnostic(
            zombie,
            biteEntry and biteEntry.npcId or nil,
            "server_combat",
            "bite_state_owns_zombie",
            "action=" .. actionStateName(zombie)
                .. " phase=" .. tostring(biteEntry and biteEntry.phase)
                .. " damageApplied="
                .. tostring(biteEntry and biteEntry.appliedDamage == true),
            now
        )
        return
    end

    -- Keep a valid NPC lease through player proximity. Reacquisition below
    -- falls back to players only after this NPC target is no longer eligible.
    record, npcBody = Internal.getForcedNPCBodyTarget(zombie, now)
    if pursueNPCRecord(zombie, record, npcBody, now, hitSettling) then
        return
    end

    target = zombie.getTarget and zombie:getTarget() or nil
    if Core.IsManagedNPCBody(target) then
        Internal.forceAggro(zombie, target)
        record, npcBody = Internal.getForcedNPCBodyTarget(zombie, now)
        pursueNPCRecord(zombie, record, npcBody, now, hitSettling)
        return
    end
    if Internal.isCloseLivePlayerTarget(zombie, target) then
        record, npcBody = acquireNearestTarget(zombie)
        if not pursueNPCRecord(zombie, record, npcBody, now, hitSettling) then
            setNoLungeAttack(zombie, false)
            clearMPTargetDirective(zombie, now)
        end
        return
    end
    record, npcBody = acquireNearestTarget(zombie)
    if isMultiplayerServer() then
        -- Clear a stale directive when this zombie no longer has an eligible
        -- NPC target; active directives are refreshed by pursueForcedTarget.
        if not record or not npcBody then
            clearMPTargetDirective(zombie, now)
        end
    end
end

function ZombieAggro.Pump(now)
    if not Core.IsAuthority() then
        return
    end

    if ZombieAggro.PumpBiteRecovery then
        ZombieAggro.PumpBiteRecovery(now)
    end

    if ZombieAggro.RefreshActiveSet then
        ZombieAggro.RefreshActiveSet(now, false)
    end
    if ZombieAggro.PumpActiveSet then
        return ZombieAggro.PumpActiveSet(now, processZombie)
    end
    return 0
end
