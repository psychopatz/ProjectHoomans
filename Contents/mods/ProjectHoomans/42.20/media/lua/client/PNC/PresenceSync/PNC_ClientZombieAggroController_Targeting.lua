local Sync = PNC.ClientPresenceSync
local Internal = Sync.Internal
local Core = PNC.Core
local Const = PNC.Const or {}
local ClientState = PNC.Network and PNC.Network.ClientState or nil
local TargetIndex = Internal.TargetIndex
local AGGRO_RADIUS = Internal.AggroRadius

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


Internal.IsForeignOwnedBody = isForeignOwnedBody
Internal.IsMultiplayerMode = isMultiplayerMode
Internal.IsStandaloneSingleplayer = isStandaloneSingleplayer
Internal.FindNearestTarget = findNearestTarget
Internal.GetPursuitDirective = getPursuitDirective
Internal.LogPursuitDiagnostic = logPursuitDiagnostic
