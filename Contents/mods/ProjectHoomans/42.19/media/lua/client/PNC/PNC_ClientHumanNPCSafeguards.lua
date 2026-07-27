--[[
    Client-only correction for vanilla IsoPlayer.updateLOS().

    PNC live bodies must remain IsoZombie objects for animation and replication,
    but updateLOS counts every visible IsoZombie toward panic, music threat,
    and the close-zombie jump scare. The engine does not consult isUseless()
    for those counters. This module preserves ordinary zombie behavior while
    removing the false contribution when the visible "zombies" are only PNC
    human NPC bodies.
]]

PNC = PNC or {}
PNC.ClientHumanNPCSafeguards = PNC.ClientHumanNPCSafeguards or {}

local Safeguards = PNC.ClientHumanNPCSafeguards
local Core = PNC.Core

Safeguards.PlayerState = Safeguards.PlayerState or {}
Safeguards.DebugLogByPlayer = Safeguards.DebugLogByPlayer or {}

local function listSize(list)
    if not list then return 0 end
    if list.size then
        return tonumber(list:size()) or 0
    end
    return type(list) == "table" and #list or 0
end

local function listGet(list, index)
    if not list then return nil end
    if list.get then
        return list:get(index)
    end
    return type(list) == "table" and list[index + 1] or nil
end

local function listContains(list, value)
    if list and list.contains then
        return list:contains(value)
    end
    local i
    for i = 0, listSize(list) - 1 do
        if listGet(list, i) == value then return true end
    end
    return false
end

local function listAdd(list, value)
    if not list or not value or listContains(list, value) then return false end
    if list.add then
        list:add(value)
        return true
    end
    if type(list) == "table" then
        list[#list + 1] = value
        return true
    end
    return false
end

local function isManagedBody(body)
    local sync
    local id
    local knownBody
    local modData
    if Core and Core.IsManagedNPCBody and Core.IsManagedNPCBody(body) then
        return true
    end
    modData = body and body.getModData and body:getModData() or nil
    if modData and (modData.PNC_NPC == true
        or (modData.PNC_UUID ~= nil and modData.PNC_BodyKind == "live"))
    then
        return true
    end
    -- A newly replicated body can enter updateLOS one frame before its modData
    -- identity copy finishes. The authoritative client binding is sufficient
    -- proof during that narrow race.
    sync = PNC.ClientPresenceSync
    for id, knownBody in pairs(sync and sync.BodyByID or {}) do
        if knownBody == body then return true end
    end
    return false
end

local function isZombie(body)
    if not body then return false end
    if instanceof then
        return instanceof(body, "IsoZombie")
    end
    return body.isZombie and body:isZombie() == true or false
end

local function isAlive(body)
    return body and (not body.isDead or not body:isDead())
        and (not body.isAlive or body:isAlive())
end

local function playerKey(player)
    if player and player.getPlayerNum then
        return tostring(player:getPlayerNum())
    end
    return tostring(player)
end

local function seedBodyForPlayer(player, lastSpotted, body)
    local px = tonumber(player and player.getX and player:getX()) or 0
    local py = tonumber(player and player.getY and player:getY()) or 0
    local pz = tonumber(player and player.getZ and player:getZ()) or 0
    local dx
    local dy
    if not isAlive(body) or not isManagedBody(body) then return false end
    dx = (tonumber(body.getX and body:getX()) or px) - px
    dy = (tonumber(body.getY and body:getY()) or py) - py
    if math.abs((tonumber(body.getZ and body:getZ()) or pz) - pz) >= 1
        or ((dx * dx) + (dy * dy)) >= 64
    then
        return false
    end
    return listAdd(lastSpotted, body)
end

local function seedKnownHumanBodies(player, lastSpotted)
    local sync = PNC.ClientPresenceSync
    local id
    local body
    local found = false
    for id, body in pairs(sync and sync.BodyByID or {}) do
        found = seedBodyForPlayer(player, lastSpotted, body) or found
    end
    return found
end

local function addManagedBody(bodies, seen, body)
    if not isAlive(body) or not isManagedBody(body)
        or not body.setReanimatedForGrappleOnly
    then
        return false
    end
    if seen[body] then return false end
    seen[body] = true
    bodies[#bodies + 1] = body
    return true
end

local function collectManagedBodies(player)
    local bodies = {}
    local seen = {}
    local spotted = player and player.getSpottedList and player:getSpottedList() or nil
    local sync = PNC.ClientPresenceSync
    local id
    local body
    local i
    for id, body in pairs(sync and sync.BodyByID or {}) do
        addManagedBody(bodies, seen, body)
    end
    for i = 0, listSize(spotted) - 1 do
        addManagedBody(bodies, seen, listGet(spotted, i))
    end
    return bodies
end

-- Build 42 exposes no setter for Stats.lastVeryCloseZombies. Re-running the
-- vanilla LOS pass while managed human bodies carry its built-in grapple-only
-- exclusion is the only supported way to obtain exact counters. The flag is
-- restored synchronously so it cannot leak into NPC posture or reanimation.
function Safeguards.RefreshVanillaThreatCounters(player)
    local bodies
    local previous = {}
    local lastSpotted
    local body
    local i
    if not player or not player.updateLOS then return false end
    bodies = collectManagedBodies(player)
    if #bodies == 0 then return false end
    lastSpotted = player.getLastSpotted and player:getLastSpotted() or nil
    for i = 1, #bodies do
        body = bodies[i]
        previous[i] = body.isReanimatedForGrappleOnly
            and body:isReanimatedForGrappleOnly() or false
        seedBodyForPlayer(player, lastSpotted, body)
        if not previous[i] then body:setReanimatedForGrappleOnly(true) end
    end
    player:updateLOS()
    for i = 1, #bodies do
        body = bodies[i]
        if not previous[i] then body:setReanimatedForGrappleOnly(false) end
        seedBodyForPlayer(player, lastSpotted, body)
    end
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
    if not (PNC.Runtime and PNC.Runtime.debugEnabled)
        or not Core or not Core.Log
    then
        return
    end
    id = playerKey(player)
    now = Core.Now and Core.Now() or 0
    previous = Safeguards.DebugLogByPlayer[id]
    if previous and previous.key == key
        and (now - (tonumber(previous.at) or 0)) < 5000
    then
        return
    end
    Safeguards.DebugLogByPlayer[id] = { key = key, at = now }
    Core.Log("DEBUG", "human_safeguard player=" .. id .. " " .. message)
end

local function capturePanicBaseline(player, overwrite)
    local stats = player and player.getStats and player:getStats() or nil
    local panic = CharacterStat and CharacterStat.PANIC and stats and stats.get
        and stats:get(CharacterStat.PANIC) or nil
    local state
    if panic == nil then return end
    state = Safeguards.PlayerState[playerKey(player)] or {}
    if overwrite or state.safePanic == nil then
        state.safePanic = panic
    end
    if state.lastPanic == nil then state.lastPanic = panic end
    Safeguards.PlayerState[playerKey(player)] = state
end

function Safeguards.OnPlayerUpdate(player)
    local stats = player and player.getStats and player:getStats() or nil
    local spotted = player and player.getSpottedList and player:getSpottedList() or nil
    local lastSpotted = player and player.getLastSpotted and player:getLastSpotted() or nil
    local state = Safeguards.PlayerState[playerKey(player)] or {}
    local managedVisible = false
    local realZombieVisible = false
    local body
    local i
    local panic
    local rawVisible
    local rawChasing
    local rawVeryClose
    local rawThreatCounters
    local currentSpeed
    local refreshed = false
    local panicCorrected = false
    if not player or not stats then return end

    if not (isClient and isClient()) then
        currentSpeed = getCurrentSpeed()
        if currentSpeed and currentSpeed > 1 then
            -- OnPlayerUpdate is raised immediately before IsoPlayer.updateLOS.
            -- Arm one post-world-update check without intercepting UI input.
            state.fastForwardSpeed = currentSpeed
            state.awaitingLOS = true
        elseif currentSpeed == 1 then
            -- Normal speed at this pre-LOS point is an explicit vanilla/user
            -- interruption, not the nearby-zombie reset that has yet to run.
            state.fastForwardSpeed = nil
            state.awaitingLOS = false
        end
    end

    managedVisible = seedKnownHumanBodies(player, lastSpotted)
    for i = 0, listSize(spotted) - 1 do
        body = listGet(spotted, i)
        if isAlive(body) and isZombie(body) then
            if isManagedBody(body) then
                managedVisible = true
                -- Keep the body in lastSpotted so vanilla does not repeatedly
                -- classify the same nearby human as a newly discovered zombie.
                listAdd(lastSpotted, body)
            else
                realZombieVisible = true
            end
        end
    end

    panic = CharacterStat and CharacterStat.PANIC and stats.get
        and stats:get(CharacterStat.PANIC) or nil
    rawVisible = stats.getNumVisibleZombies and stats:getNumVisibleZombies() or nil
    rawChasing = stats.getNumChasingZombies and stats:getNumChasingZombies() or nil
    rawVeryClose = stats.getNumVeryCloseZombies and stats:getNumVeryCloseZombies() or nil
    rawThreatCounters = (rawVisible and rawVisible > 0)
        or (rawChasing and rawChasing > 0)
        or (rawVeryClose and rawVeryClose > 0)
    if managedVisible and rawThreatCounters then
        refreshed = Safeguards.RefreshVanillaThreatCounters(player)
    end
    if managedVisible and not realZombieVisible then
        if stats.setNumVisibleZombies then stats:setNumVisibleZombies(0) end
        if stats.setLastNumberChasingZombies then
            stats:setLastNumberChasingZombies(0)
        end
        if panic ~= nil and state.safePanic ~= nil and panic > state.safePanic
            and rawThreatCounters
            and stats.set and CharacterStat and CharacterStat.PANIC
        then
            stats:set(CharacterStat.PANIC, state.safePanic)
            panic = state.safePanic
            panicCorrected = true
        end
    elseif panic ~= nil then
        state.safePanic = panic
    end
    if rawThreatCounters then
        logDebugThrottled(player,
            "counter_scan:" .. tostring(managedVisible)
                .. ":" .. tostring(realZombieVisible),
            "event=counter_scan managed=" .. tostring(managedVisible)
                .. " realZombie=" .. tostring(realZombieVisible)
                .. " refreshed=" .. tostring(refreshed)
                .. " counters=" .. tostring(rawVisible)
                .. "/" .. tostring(rawChasing)
                .. "/" .. tostring(rawVeryClose)
                .. " panic=" .. tostring(panic))
    end
    if panicCorrected and player.getMoodles then
        local moodles = player:getMoodles()
        if moodles and moodles.Update then moodles:Update() end
    end
    if panic ~= nil then state.lastPanic = panic end
    Safeguards.PlayerState[playerKey(player)] = state
end

-- IngameState raises OnTick after IsoWorld.update(), so vanilla updateLOS has
-- finished and any close-zombie speed reset is now observable. Recount with
-- only managed bodies temporarily excluded, then restore the captured speed
-- only when no ordinary zombie or player interruption remains.
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
    local refreshed
    if isClient and isClient() then return end
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
                refreshed = rawThreat
                    and Safeguards.RefreshVanillaThreatCounters(player) or false
                if playerInterruptsFastForward(player)
                    or not refreshed
                    or hasThreatCounters(stats)
                then
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

function Safeguards.RegisterHumanBody(body)
    local count = getNumActivePlayers and getNumActivePlayers() or 1
    local i
    local player
    local lastSpotted
    for i = 0, math.max(0, count - 1) do
        player = getSpecificPlayer and getSpecificPlayer(i) or nil
        lastSpotted = player and player.getLastSpotted and player:getLastSpotted() or nil
        capturePanicBaseline(player, false)
        seedBodyForPlayer(player, lastSpotted, body)
    end
end

function Safeguards.OnResetLua()
    Safeguards.PlayerState = {}
    Safeguards.DebugLogByPlayer = {}
end

function Safeguards.OnCreatePlayer(playerIndex, player)
    player = player or (getSpecificPlayer and getSpecificPlayer(playerIndex) or nil)
    capturePanicBaseline(player, true)
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
