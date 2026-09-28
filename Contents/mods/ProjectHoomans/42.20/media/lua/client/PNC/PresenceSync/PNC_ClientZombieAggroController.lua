-- Client-side zombie safety and MP directive application.
-- Standalone singleplayer target selection is owned by ZombieAggro.Pump; this
-- handler remains installed there for managed-shell safety only. Managed NPCs
-- are IsoZombie shells, so neither lane installs one as a native combat target.

PNC = PNC or {}
PNC.ClientPresenceSync = PNC.ClientPresenceSync or {}
PNC.ClientPresenceSync.Internal =
    PNC.ClientPresenceSync.Internal or {}

local Sync = PNC.ClientPresenceSync
local Internal = Sync.Internal
local Core = PNC.Core
local Const = PNC.Const or {}
local ClientState = PNC.Network and PNC.Network.ClientState or nil
local TargetIndex = require
    "PNC/PresenceSync/PNC_ClientZombieAggroController_TargetIndex"
local Effects = require
    "PNC/PresenceSync/PNC_ClientZombieAggroController_BodyEffects"

local function isForeignOwnedBody(body)
    local ownership = PNC.Compatibility
        and PNC.Compatibility.ActorOwnership or nil
    return ownership
        and ownership.IsForeignOwned
        and ownership.IsForeignOwned(body) == true
        or false
end

local AGGRO_RADIUS = tonumber(Const.ZOMBIE_AGGRO_RADIUS) or 12
local AGGRO_TIER_MS = math.max(
    10,
    tonumber(Const.CLIENT_ZOMBIE_AGGRO_TIER_MS) or 50
)
local AGGRO_TIER_COUNT = math.max(
    1,
    math.floor(tonumber(Const.CLIENT_ZOMBIE_AGGRO_TIER_COUNT) or 4)
)
local CONTROLLER_BY_ZOMBIE =
    setmetatable({}, { __mode = "k" })
local NEXT_UPDATE_TIER = 0
-- TurnAlerted is still a vanilla engine transition. PNC no longer produces,
-- suppresses, or resets it, but the client aggro lane must not claim a zombie
-- while that engine-owned transition is active.
local ACTION_OWNED_ELSEWHERE = {
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

local function isMultiplayerMode()
    return (isServer and isServer() == true)
        or (isClient and isClient() == true)
end

local function isStandaloneSingleplayer()
    -- Standalone singleplayer still runs the authoritative server scheduler
    -- in PNC_Server_SubsystemPumps. Keep this event hook passive after the
    -- managed-shell safety guard so it cannot run a second target-selection
    -- and pathing lane for the same zombie.
    return not isMultiplayerMode()
end

local function isLivePlayer(player)
    return player
        and instanceof
        and instanceof(player, "IsoPlayer")
        and not (player.isDead and player:isDead())
end

local function findNearestPlayer(zombie)
    local bestPlayer
    local bestDistanceSq = math.huge
    local seenPlayers = {}
    local currentTarget = zombie.getTarget
        and zombie:getTarget() or nil
    local zombieZ = zombie:getZ()
    local zombieX = zombie:getX()
    local zombieY = zombie:getY()

    local function consider(player)
        local dx
        local dy
        local distanceSq
        if not isLivePlayer(player) or seenPlayers[player]
            or math.abs(player:getZ() - zombieZ) >= 1
        then
            return
        end
        seenPlayers[player] = true
        dx = player:getX() - zombieX
        dy = player:getY() - zombieY
        distanceSq = (dx * dx) + (dy * dy)
        if distanceSq < bestDistanceSq then
            bestPlayer = player
            bestDistanceSq = distanceSq
        end
    end

    -- Preserve the engine's current player target as a candidate even when
    -- it is outside the local player list. This prevents an NPC inside the
    -- search radius from displacing a farther player unless it is actually
    -- the nearer target.
    consider(currentTarget)

    if getOnlinePlayers then
        local players = getOnlinePlayers()
        local i
        if players and players.size then
            for i = 0, players:size() - 1 do
                consider(players:get(i))
            end
        end
    end
    if getNumActivePlayers and getSpecificPlayer then
        local i
        for i = 0, getNumActivePlayers() - 1 do
            consider(getSpecificPlayer(i))
        end
    end
    return bestPlayer, bestDistanceSq
end

local function findNearestTarget(zombie, now)
    local npcBody
    local npcDistanceSq
    local player
    local playerDistanceSq
    local aggroInternal
    local leasedRecord
    local leasedBody
    local leasedDistanceSq
    local preferNPC
    aggroInternal = PNC.ZombieAggro and PNC.ZombieAggro.Internal
    if aggroInternal and aggroInternal.getForcedNPCBodyTarget then
        leasedRecord, leasedBody = aggroInternal.getForcedNPCBodyTarget(
            zombie,
            now
        )
        if leasedRecord and leasedBody then
            local stealth = PNC.Stealth
            local suppressed = stealth
                and stealth.ShouldSuppressZombieAggro
                and stealth.ShouldSuppressZombieAggro(leasedRecord)
            if not suppressed then
                player, playerDistanceSq = findNearestPlayer(zombie)
                leasedDistanceSq = Core.DistanceSq(
                    zombie:getX(),
                    zombie:getY(),
                    leasedBody:getX(),
                    leasedBody:getY()
                )
                if not (player and aggroInternal.isPlayerImmediateThreatToNPC
                    and aggroInternal.isPlayerImmediateThreatToNPC(
                        leasedDistanceSq,
                        playerDistanceSq
                    )
                ) then
                    return leasedBody, leasedDistanceSq, true
                end
                if aggroInternal.clearZombieTarget then
                    aggroInternal.clearZombieTarget(zombie)
                end
            end
        end
    end
    npcBody, npcDistanceSq = TargetIndex.FindNearestBody(zombie, now)
    player, playerDistanceSq = findNearestPlayer(zombie)
    if aggroInternal and aggroInternal.shouldPreferNPCOverPlayer then
        preferNPC = aggroInternal.shouldPreferNPCOverPlayer(
            npcDistanceSq,
            playerDistanceSq
        )
    else
        preferNPC = npcBody ~= nil
    end
    if npcBody and preferNPC then
        if aggroInternal and aggroInternal.forceAggro then
            aggroInternal.forceAggro(zombie, npcBody)
        end
        return npcBody, npcDistanceSq, true
    end
    return player, playerDistanceSq, false
end

local function getPursuitDirective(zombie)
    local onlineID
    local directives
    if not ClientState or not zombie or not zombie.getOnlineID then
        return nil
    end
    onlineID = tonumber(zombie:getOnlineID())
    if onlineID == nil or onlineID < 0 then
        return nil
    end
    directives = ClientState.zombiePursuitDirectives
    return directives
        and directives[tostring(math.floor(onlineID))]
        or nil
end

local function logPursuitDiagnostic(zombie, npcId, state, detail, now)
    local aggro = PNC.ZombieAggro
    if aggro and aggro.LogPursuitDiagnostic then
        aggro.LogPursuitDiagnostic(
            zombie, npcId, "client_control", state, detail, now
        )
    end
end

local function ensureControllerEntry(zombie)
    local entry = CONTROLLER_BY_ZOMBIE[zombie]
    if not entry then
        entry = {
            updateTier = NEXT_UPDATE_TIER,
        }
        NEXT_UPDATE_TIER =
            (NEXT_UPDATE_TIER + 1) % AGGRO_TIER_COUNT
        CONTROLLER_BY_ZOMBIE[zombie] = entry
    end
    return entry
end

local function isScheduledAggroTier(zombie, now)
    local entry = ensureControllerEntry(zombie)
    local currentTier = math.floor(now / AGGRO_TIER_MS)
        % AGGRO_TIER_COUNT
    return entry.updateTier == currentTier
end

local function isLocalZombieUpdate(zombie)
    -- Build 42 raises OnZombieUpdate for the local simulation lane. Keep this
    -- guard for the short remote-shell update window without touching the
    -- non-exposed server-side UdpConnection owner object.
    return not zombie.isRemoteZombie or zombie:isRemoteZombie() ~= true
end

function Internal.ResetClientZombieAggro()
    CONTROLLER_BY_ZOMBIE = setmetatable({}, { __mode = "k" })
    NEXT_UPDATE_TIER = 0
    TargetIndex.Reset()
end

function Internal.UpdateClientZombieAggro(zombie, now)
    local actionState
    local body
    local distanceSq
    local target
    local targetIsNPC
    local npcId
    local entry
    local directive
    local hasActiveDirective
    local directiveApplied
    now = tonumber(now) or (Core and Core.Now and Core.Now() or 0)
    if not zombie or (zombie.isDead and zombie:isDead()) then
        return false
    end
    entry = ensureControllerEntry(zombie)
    if entry.handlerSeen ~= true then
        entry.handlerSeen = true
        logPursuitDiagnostic(
            zombie,
            nil,
            "handler_enter",
            "isClient=" .. tostring(isClient and isClient() == true)
                .. " isServer=" .. tostring(isServer and isServer() == true)
                .. " remote=" .. tostring(
                    zombie.isRemoteZombie
                        and zombie:isRemoteZombie() == true or false
                ),
            now
        )
    end
    directive = isClient and isClient() == true
        and getPursuitDirective(zombie) or nil
    hasActiveDirective = directive
        and directive.active == true
        and (tonumber(directive.expiresAt) or 0) > now
        or false
    if not isLocalZombieUpdate(zombie) then
        if hasActiveDirective then
            logPursuitDiagnostic(
                zombie, directive.npcId, "not_local_simulation",
                "revision=" .. tostring(directive.revision)
                    .. " expiresAt=" .. tostring(directive.expiresAt), now
            )
        end
        return false
    end
    -- Bandits owns its own client-side zombie mind. Do not clear targets,
    -- hands, teeth, or lunge variables before its update lane runs.
    if isForeignOwnedBody(zombie) then
        if hasActiveDirective then
            logPursuitDiagnostic(
                zombie, directive.npcId, "foreign_owned_skip",
                "revision=" .. tostring(directive.revision), now
            )
        end
        return false
    end
    if Effects.EnforceManagedSafetyGuard(zombie) then return false end
    if isStandaloneSingleplayer()
        and PNC.ZombieAggro
        and type(PNC.ZombieAggro.Pump) == "function"
    then
        logPursuitDiagnostic(
            zombie,
            nil,
            "sp_authority_lane",
            "client_fallback_skipped",
            now
        )
        return false
    end
    if PNC.ZombieAggro
        and PNC.ZombieAggro.Internal
        and PNC.ZombieAggro.Internal.ShouldYieldToPursuitOwner
        and PNC.ZombieAggro.Internal.ShouldYieldToPursuitOwner(
            zombie,
            "ProjectHoomans",
            now
        )
    then
        local lease = PNC.ZombieAggro.Internal.GetPursuitLease
            and PNC.ZombieAggro.Internal.GetPursuitLease(zombie, now)
            or nil
        logPursuitDiagnostic(
            zombie,
            nil,
            "foreign_pursuit_owner",
            "owner=" .. tostring(lease and lease.owner or "unknown"),
            now
        )
        return false
    end
    -- The server owns MP target selection. Only the local client applies its
    -- short-lived coordinate directive to the locally simulated zombie.
    if isMultiplayerMode() and not (isClient and isClient() == true) then
        if hasActiveDirective then
            logPursuitDiagnostic(
                zombie, directive.npcId, "mp_not_client_skip",
                "revision=" .. tostring(directive.revision), now
            )
        end
        return false
    end
    actionState = zombie.getActionStateName
        and string.lower(tostring(
            zombie:getActionStateName() or ""
        ))
        or ""
    if ACTION_OWNED_ELSEWHERE[actionState] == true
        or (zombie.isProne and zombie:isProne())
    then
        if hasActiveDirective then
            logPursuitDiagnostic(
                zombie, directive.npcId, "action_state_skip",
                "action=" .. actionState
                    .. " prone=" .. tostring(
                        zombie.isProne and zombie:isProne() or false
                    )
                    .. " revision=" .. tostring(directive.revision), now
            )
        end
        return false
    end
    -- A live server directive is already an authoritative work item. Do not
    -- defer it behind the round-robin scan: OnZombieUpdate cadence can be
    -- slower than the directive TTL, which otherwise makes every directive
    -- expire while the client reports update_tier_skip. Keep tiering for
    -- idle scans and for releasing a directive that is no longer active.
    if not hasActiveDirective
        and entry.directiveActive ~= true
        and not isScheduledAggroTier(zombie, now)
    then
        return false
    end

    if isClient and isClient() == true then
        directive = directive or getPursuitDirective(zombie)
        if directive
            and directive.active == true
            and (tonumber(directive.expiresAt) or 0) > now
        then
            directiveApplied = Effects.ApplyCoordinateDirective(
                zombie,
                directive.x,
                directive.y,
                directive.z,
                now,
                directive.npcId,
                directive.approach,
                directive.owner,
                directive.provider,
                directive.expiresAt,
                directive.priority,
                directive.reason
            )
        end
        if directiveApplied then
            entry.directiveActive = true
            logPursuitDiagnostic(
                zombie, directive.npcId, "mp_directive_applied",
                "revision=" .. tostring(directive.revision)
                    .. " expiresIn=" .. tostring(
                        (tonumber(directive.expiresAt) or 0) - now
                    )
                    .. " targetX=" .. tostring(directive.x)
                    .. " targetY=" .. tostring(directive.y)
                    .. " targetZ=" .. tostring(directive.z)
                    .. " approach=" .. tostring(directive.approach == true),
                now
            )
            return true
        end
        if entry.directiveActive then
            logPursuitDiagnostic(
                zombie,
                directive and directive.npcId or nil,
                directive and directive.active == true
                    and "mp_directive_expired" or "mp_directive_cleared",
                "revision=" .. tostring(directive and directive.revision)
                    .. " expiresAt="
                    .. tostring(directive and directive.expiresAt)
                    .. " now=" .. tostring(now),
                now
            )
            Effects.ReleaseCoordinateDirective(zombie)
            entry.directiveActive = false
        elseif directive and directive.active == true then
            logPursuitDiagnostic(
                zombie, directive.npcId, "mp_directive_not_applied",
                "revision=" .. tostring(directive.revision)
                    .. " expiresAt=" .. tostring(directive.expiresAt)
                    .. " now=" .. tostring(now), now
            )
        end
        return false
    end

    logPursuitDiagnostic(
        zombie,
        nil,
        "sp_target_scan",
        "bodyIndex=" .. tostring(Sync.BodyByID ~= nil)
            .. " snapshots=" .. tostring(ClientState and ClientState.snapshots ~= nil),
        now
    )
    target, distanceSq, targetIsNPC = findNearestTarget(zombie, now)
    if not target then
        logPursuitDiagnostic(
            zombie,
            nil,
            "sp_no_target",
            "distanceSq=" .. tostring(distanceSq),
            now
        )
        Effects.ReleaseManagedTarget(zombie)
        return false
    end
    if not targetIsNPC then
        Effects.ApplyPlayerTarget(zombie, target)
        return false
    end
    body = target
    if not body
    then
        Effects.ReleaseManagedTarget(zombie)
        return false
    end
    npcId = body.getModData and body:getModData()
        and body:getModData().PNC_UUID or nil
    logPursuitDiagnostic(
        zombie, npcId, "sp_npc_selected",
        "distanceSq=" .. tostring(distanceSq)
            .. " npcX=" .. tostring(body:getX())
            .. " npcY=" .. tostring(body:getY())
            .. " action=" .. actionState,
        now
    )
    Effects.ApplySingleplayerAggro(
        zombie,
        body,
        distanceSq,
        now,
        npcId
    )
    return true
end

function Internal.OnClientZombieAggroUpdate(zombie)
    Internal.UpdateClientZombieAggro(
        zombie,
        Core and Core.Now and Core.Now() or 0
    )
end

-- This file is client-side, but also runs in standalone singleplayer where
-- isClient() is false. Register in both modes: SP keeps only the safety guard,
-- while an MP client applies the server's short-lived coordinate directive.
if Events and Events.OnZombieUpdate then
    if Sync.ClientZombieAggroUpdateHandler then
        Events.OnZombieUpdate.Remove(
            Sync.ClientZombieAggroUpdateHandler
        )
    end
    Sync.ClientZombieAggroUpdateHandler =
        Internal.OnClientZombieAggroUpdate
    Events.OnZombieUpdate.Add(
        Sync.ClientZombieAggroUpdateHandler
    )
end

return Internal
