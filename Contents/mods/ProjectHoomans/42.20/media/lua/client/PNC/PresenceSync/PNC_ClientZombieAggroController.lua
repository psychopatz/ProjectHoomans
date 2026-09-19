-- Singleplayer zombie pursuit fallback.
--
-- The multiplayer lane now uses the vanilla WorldSoundManager/RespondToSound
-- path so the engine owns client-side movement. Managed NPCs are IsoZombie
-- shells, so singleplayer pursuit uses coordinates and never installs one as
-- a native combat target.

PNC = PNC or {}
PNC.ClientPresenceSync = PNC.ClientPresenceSync or {}
PNC.ClientPresenceSync.Internal =
    PNC.ClientPresenceSync.Internal or {}

local Sync = PNC.ClientPresenceSync
local Internal = Sync.Internal
local Core = PNC.Core
local Const = PNC.Const or {}
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
    onground = true,
    staggerback = true,
    turnalerted = true,
}

local function isMultiplayerMode()
    return (isServer and isServer() == true)
        or (isClient and isClient() == true)
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
    npcBody, npcDistanceSq = TargetIndex.FindNearestBody(zombie, now)
    player, playerDistanceSq = findNearestPlayer(zombie)
    if npcBody and npcDistanceSq < playerDistanceSq then
        return npcBody, npcDistanceSq, true
    end
    return player, playerDistanceSq, false
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
    now = tonumber(now) or (Core and Core.Now and Core.Now() or 0)
    if not zombie
        or (zombie.isDead and zombie:isDead())
        or not isLocalZombieUpdate(zombie)
    then
        return false
    end
    -- Bandits owns its own client-side zombie mind. Do not clear targets,
    -- hands, teeth, or lunge variables before its update lane runs.
    if isForeignOwnedBody(zombie) then
        return false
    end
    if Effects.EnforceManagedSafetyGuard(zombie) then return false end
    -- Multiplayer movement is owned by the vanilla
    -- WorldSoundManager/RespondToSound path. Server directives must not
    -- compete with that simulation lane.
    if isMultiplayerMode() then
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
        return false
    end
    if not isScheduledAggroTier(zombie, now) then
        return false
    end

    target, distanceSq, targetIsNPC = findNearestTarget(zombie, now)
    if not target then
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
    Effects.ApplySingleplayerAggro(
        zombie,
        body,
        distanceSq,
        now
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
-- isClient() is false. Register in both local runtime modes; the update guard
-- above keeps multiplayer movement under vanilla/server ownership.
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
