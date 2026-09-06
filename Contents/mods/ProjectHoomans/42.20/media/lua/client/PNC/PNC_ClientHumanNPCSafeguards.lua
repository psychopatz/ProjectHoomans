-- Client-side companion to the shared human-NPC threat lease.
--
-- The shared module owns the LOS exclusion because the server must protect its
-- authoritative panic/counter path too. This client module owns only the
-- single-player fast-forward restoration and keeps the public compatibility
-- API used by the presentation and sleep patches.

require "PNC/Core/Perception/PNC_HumanNPCThreatSafeguards"

PNC = PNC or {}
PNC.ClientHumanNPCSafeguards = PNC.ClientHumanNPCSafeguards or {}

local Safeguards = PNC.ClientHumanNPCSafeguards
local Threat = PNC.HumanNPCThreatSafeguards

Safeguards.PlayerState = Safeguards.PlayerState or {}
Safeguards.DebugLogByPlayer = Safeguards.DebugLogByPlayer or {}

local function playerKey(player)
    if player and player.getPlayerNum then
        return tostring(player:getPlayerNum())
    end
    return tostring(player)
end

local function getSpeedControls()
    return UIManager and UIManager.getSpeedControls
        and UIManager.getSpeedControls() or nil
end

local function getCurrentSpeed(controls)
    controls = controls or getSpeedControls()
    if controls and controls.getCurrentGameSpeed then
        return tonumber(controls:getCurrentGameSpeed())
    end
    return nil
end

local function applyFastForwardSpeed(controls, speed)
    local buttonNames = {
        [2] = "Fast Forward x 1",
        [3] = "Fast Forward x 2",
        [4] = "Wait",
    }
    local buttonName = buttonNames[tonumber(speed)]
    if not controls or not controls.ButtonClicked or not buttonName then
        return false
    end
    -- This invokes the public Java method normally. Never assign or wrap it:
    -- Kahlua cannot replace methods owned by zombie.ui.SpeedControls.
    controls:ButtonClicked(buttonName)
    return true
end

local function playerInterruptsFastForward(player)
    return (player.isJustMoved and player:isJustMoved())
        or (player.isPlayerMoving and player:isPlayerMoving())
        or (player.isAiming and player:isAiming())
        or (player.isAttacking and player:isAttacking())
        or (player.isOnFire and player:isOnFire())
        or (player.isDead and player:isDead())
end

local function hasThreatCounters(stats)
    return stats and (
        (stats.getNumVisibleZombies and stats:getNumVisibleZombies() > 0)
        or (stats.getNumChasingZombies and stats:getNumChasingZombies() > 0)
        or (stats.getNumVeryCloseZombies and stats:getNumVeryCloseZombies() > 0)
    ) or false
end

local function logDebugThrottled(player, key, message)
    local id
    local now
    local previous
    local core = PNC.Core
    if not (PNC.Runtime and PNC.Runtime.debugEnabled)
        or not core or not core.Log
    then
        return
    end
    id = playerKey(player)
    now = core.Now and core.Now() or 0
    previous = Safeguards.DebugLogByPlayer[id]
    if previous and previous.key == key
        and (now - (tonumber(previous.at) or 0)) < 5000
    then
        return
    end
    Safeguards.DebugLogByPlayer[id] = { key = key, at = now }
    core.Log("DEBUG", "human_safeguard player=" .. id .. " " .. message)
end

function Safeguards.RefreshVanillaThreatCounters(player)
    return Threat and Threat.RefreshVanillaThreatCounters
        and Threat.RefreshVanillaThreatCounters(player) or false
end

function Safeguards.RegisterHumanBody(body)
    return Threat and Threat.RegisterHumanBody
        and Threat.RegisterHumanBody(body) or false
end

function Safeguards.OnPlayerUpdate(player)
    local state
    local currentSpeed
    if not player then return end

    -- The shared handler is registered from the shared composition root. Keep
    -- this direct call for reloads and focused harnesses; BeginPlayerUpdate is
    -- idempotent for the current player-update frame.
    if Threat and Threat.BeginPlayerUpdate then
        Threat.BeginPlayerUpdate(player)
    end

    state = Safeguards.PlayerState[playerKey(player)] or {}
    if not (isClient and isClient()) then
        currentSpeed = getCurrentSpeed()
        if currentSpeed and currentSpeed > 1 then
            state.fastForwardSpeed = currentSpeed
            state.awaitingLOS = true
        elseif currentSpeed == 1 then
            -- Normal speed at this pre-LOS point is an explicit vanilla/user
            -- interruption, not a nearby-zombie reset that has yet to run.
            state.fastForwardSpeed = nil
            state.awaitingLOS = false
        end
    end
    Safeguards.PlayerState[playerKey(player)] = state
end

function Safeguards.OnTick()
    local controls
    local currentSpeed
    local count
    local restoreSpeed
    local blocked = false
    local i
    local player
    local stats
    local state
    local rawThreat

    -- The shared handler is registered first in normal game load order. This
    -- direct call makes the client wrapper safe when reloaded independently.
    if Threat and Threat.OnTick then Threat.OnTick() end

    controls = getSpeedControls()
    currentSpeed = getCurrentSpeed(controls)
    if currentSpeed == nil then return end
    count = getNumActivePlayers and getNumActivePlayers() or 1
    for i = 0, math.max(0, count - 1) do
        player = getSpecificPlayer and getSpecificPlayer(i) or nil
        state = player and Safeguards.PlayerState[playerKey(player)] or nil
        if state and state.awaitingLOS == true then
            state.awaitingLOS = false
            if currentSpeed == 1 and state.fastForwardSpeed
                and state.fastForwardSpeed > 1
            then
                stats = player.getStats and player:getStats() or nil
                rawThreat = hasThreatCounters(stats)
                if playerInterruptsFastForward(player) or rawThreat then
                    state.fastForwardSpeed = nil
                    blocked = true
                else
                    restoreSpeed = math.max(
                        tonumber(restoreSpeed) or 1,
                        tonumber(state.fastForwardSpeed) or 1
                    )
                    logDebugThrottled(player, "fast_forward_restore",
                        "event=fast_forward_restore speed="
                        .. tostring(state.fastForwardSpeed)
                        .. " rawThreat=" .. tostring(rawThreat))
                end
            end
            Safeguards.PlayerState[playerKey(player)] = state
        end
    end
    if not blocked and restoreSpeed and currentSpeed == 1 then
        applyFastForwardSpeed(controls, restoreSpeed)
    end
end

function Safeguards.OnCreatePlayer(playerIndex, player)
    player = player or (getSpecificPlayer and getSpecificPlayer(playerIndex) or nil)
    if Threat and Threat.CapturePanicBaseline then
        Threat.CapturePanicBaseline(player, true)
    end
end

function Safeguards.OnResetLua()
    Safeguards.PlayerState = {}
    Safeguards.DebugLogByPlayer = {}
    if Threat and Threat.OnResetLua then Threat.OnResetLua() end
end

if Events and Events.OnPlayerUpdate then
    Events.OnPlayerUpdate.Add(Safeguards.OnPlayerUpdate)
end
if Events and Events.OnTick then
    Events.OnTick.Add(Safeguards.OnTick)
end
if Events and Events.OnCreatePlayer then
    Events.OnCreatePlayer.Add(Safeguards.OnCreatePlayer)
end
if Events and Events.OnResetLua then
    Events.OnResetLua.Add(Safeguards.OnResetLua)
end

return Safeguards
