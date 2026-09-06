-- Keep PNC live bodies compatible with vanilla IsoPlayer threat evaluation.
--
-- PNC actors intentionally remain IsoZombie instances for animation and
-- replication. IsoPlayer.updateLOS() therefore needs a synchronous exclusion
-- around an exact native pass. The flag must never survive into the normal
-- IsoZombie update, because the live-body safety path treats it as native NPC
-- state and may otherwise remove the actor.

PNC = PNC or {}
PNC.HumanNPCThreatSafeguards = PNC.HumanNPCThreatSafeguards or {}

local Safeguards = PNC.HumanNPCThreatSafeguards
local Core = PNC.Core

Safeguards.PlayerState = Safeguards.PlayerState or {}
Safeguards.KnownBodies = Safeguards.KnownBodies
    or setmetatable({}, { __mode = "k" })
Safeguards.LeasedBodies = Safeguards.LeasedBodies
    or setmetatable({}, { __mode = "k" })

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

local function playerKey(player)
    if player and player.getPlayerNum then
        return tostring(player:getPlayerNum())
    end
    return tostring(player)
end

local function isAlive(body)
    return body and (not body.isDead or not body:isDead())
        and (not body.isAlive or body:isAlive())
end

local function isZombie(body)
    if not body then return false end
    if instanceof then
        return instanceof(body, "IsoZombie")
    end
    return body.isZombie and body:isZombie() == true or false
end

local function isManagedBody(body)
    if not body or not isZombie(body) then return false end
    return Core and Core.IsManagedNPCBody
        and Core.IsManagedNPCBody(body) == true or false
end

local function isNearPlayer(player, body)
    local px = tonumber(player and player.getX and player:getX())
    local py = tonumber(player and player.getY and player:getY())
    local pz = tonumber(player and player.getZ and player:getZ())
    local bx = tonumber(body and body.getX and body:getX())
    local by = tonumber(body and body.getY and body:getY())
    local bz = tonumber(body and body.getZ and body:getZ())
    local dx
    local dy
    if not px or not py or not pz or not bx or not by or not bz then
        return false
    end
    if math.abs(bz - pz) >= 1 then return false end
    dx = bx - px
    dy = by - py
    return (dx * dx) + (dy * dy) < 64
end

local function addBody(player, bodies, seen, body)
    if not body or seen[body] or not isAlive(body)
        or not isManagedBody(body)
        or not body.setReanimatedForGrappleOnly
        or not isNearPlayer(player, body)
    then
        return false
    end
    seen[body] = true
    bodies[#bodies + 1] = body
    return true
end

local function collectBodies(player)
    local bodies = {}
    local seen = {}
    local cell = player and player.getCell and player:getCell() or nil
    local zombies = cell and cell.getZombieList and cell:getZombieList() or nil
    local spotted = player and player.getSpottedList and player:getSpottedList() or nil
    local lastSpotted = player and player.getLastSpotted and player:getLastSpotted() or nil
    local sync = PNC.ClientPresenceSync
    local body
    local id
    local i

    for i = 0, listSize(zombies) - 1 do
        addBody(player, bodies, seen, listGet(zombies, i))
    end
    for i = 0, listSize(spotted) - 1 do
        addBody(player, bodies, seen, listGet(spotted, i))
    end
    for i = 0, listSize(lastSpotted) - 1 do
        addBody(player, bodies, seen, listGet(lastSpotted, i))
    end
    for id, body in pairs(sync and sync.BodyByID or {}) do
        addBody(player, bodies, seen, body)
    end
    for body, _ in pairs(Safeguards.KnownBodies) do
        addBody(player, bodies, seen, body)
    end
    return bodies
end

local function readPanic(player)
    local stats = player and player.getStats and player:getStats() or nil
    if not stats or not stats.get or not CharacterStat
        or not CharacterStat.PANIC
    then
        return nil
    end
    return tonumber(stats:get(CharacterStat.PANIC))
end

local function writePanic(player, value)
    local stats = player and player.getStats and player:getStats() or nil
    if not stats or not stats.set or value == nil or not CharacterStat
        or not CharacterStat.PANIC
    then
        return false
    end
    stats:set(CharacterStat.PANIC, value)
    if player.getMoodles then
        local moodles = player:getMoodles()
        if moodles and moodles.Update then moodles:Update() end
    end
    return true
end

local function hasThreatCounters(player)
    local stats = player and player.getStats and player:getStats() or nil
    return stats and (
        (stats.getNumVisibleZombies and stats:getNumVisibleZombies() > 0)
        or (stats.getNumChasingZombies and stats:getNumChasingZombies() > 0)
        or (stats.getNumVeryCloseZombies and stats:getNumVeryCloseZombies() > 0)
    ) or false
end

local function hasRealZombieVisible(player)
    local spotted = player and player.getSpottedList and player:getSpottedList() or nil
    local body
    local i
    for i = 0, listSize(spotted) - 1 do
        body = listGet(spotted, i)
        if isAlive(body) and isZombie(body) and not isManagedBody(body) then
            return true
        end
    end
    return false
end

local function seedManagedBodies(player, bodies)
    local lastSpotted = player and player.getLastSpotted
        and player:getLastSpotted() or nil
    local entry
    local i
    for i = 1, #(bodies or {}) do
        entry = bodies[i]
        if entry and isNearPlayer(player, entry.body) then
            listAdd(lastSpotted, entry.body)
        end
    end
end

local function restoreLease(state)
    local body
    local entry
    local leaseCount
    local i
    for i = 1, #(state and state.bodies or {}) do
        entry = state.bodies[i]
        body = entry.body
        if body then
            leaseCount = (Safeguards.LeasedBodies[body] or 1) - 1
            if leaseCount > 0 then
                Safeguards.LeasedBodies[body] = leaseCount
            else
                Safeguards.LeasedBodies[body] = nil
                -- Also clear a flag left by a prior hot reload of the old
                -- cross-tick implementation. Managed bodies must never leave
                -- this native state set between LOS passes.
                if body.setReanimatedForGrappleOnly then
                    pcall(body.setReanimatedForGrappleOnly, body, false)
                end
            end
        end
    end
end

local function updateSafePanic(player, state, realVisible)
    local panic = readPanic(player)
    local safePanic = state.safePanic
    if panic == nil then return end
    if not realVisible then
        if safePanic == nil then
            safePanic = state.panicBefore or panic
            state.safePanic = safePanic
        end
        if state.hadManagedThreat and panic > safePanic then
            writePanic(player, safePanic)
            panic = safePanic
        end
        if not state.hadManagedThreat then
            state.safePanic = panic
        end
    end
    state.lastPanic = panic
end

local function finishLease(player, state)
    local refreshed
    local realVisible
    if not state or not state.pending then return false end
    refreshed, realVisible = Safeguards.RefreshVanillaThreatCounters(player)
    if refreshed then
        state.hadManagedThreat = true
        state.lastRealVisible = realVisible
        updateSafePanic(player, state, realVisible)
    end
    state.pending = false
    state.hadManagedThreat = false
    return refreshed
end

function Safeguards.CapturePanicBaseline(player, overwrite)
    local key = playerKey(player)
    local state = Safeguards.PlayerState[key] or {}
    local panic = readPanic(player)
    if panic == nil then return end
    if overwrite or state.safePanic == nil then
        state.safePanic = panic
    end
    state.lastPanic = panic
    Safeguards.PlayerState[key] = state
end

function Safeguards.RegisterHumanBody(body)
    if not body then return false end
    Safeguards.KnownBodies[body] = true
    return true
end

function Safeguards.IsBodyLeased(body)
    return body and (Safeguards.LeasedBodies[body] or 0) > 0 or false
end

function Safeguards.BeginPlayerUpdate(player)
    local key = playerKey(player)
    local state = Safeguards.PlayerState[key] or {}
    if not player then return false end
    -- OnPlayerUpdate is raised immediately before the engine's own LOS pass.
    -- Only remember the frame here; holding the native grapple-only flag until
    -- OnTick changes the live NPC's normal IsoZombie update and can kill it.
    state.pending = true
    state.panicBefore = readPanic(player)
    if state.safePanic == nil then state.safePanic = state.panicBefore end
    Safeguards.PlayerState[key] = state
    return true
end

function Safeguards.FinishPlayerUpdate(player)
    local key = playerKey(player)
    local state = Safeguards.PlayerState[key]
    local refreshed = finishLease(player, state)
    Safeguards.PlayerState[key] = state or {}
    return refreshed
end

function Safeguards.RefreshVanillaThreatCounters(player)
    local key = playerKey(player)
    local state = Safeguards.PlayerState[key] or {}
    local bodies
    local entries = {}
    local body
    local previous
    local refreshed = false
    local realVisible
    local i
    if not player or not player.updateLOS then return false end
    bodies = collectBodies(player)
    if #bodies == 0 then
        return false
    end
    for i = 1, #bodies do
        body = bodies[i]
        previous = body.isReanimatedForGrappleOnly
            and body:isReanimatedForGrappleOnly() or false
        entries[i] = { body = body, previous = previous }
        Safeguards.LeasedBodies[body] =
            (Safeguards.LeasedBodies[body] or 0) + 1
        if not previous then body:setReanimatedForGrappleOnly(true) end
    end
    local ok = pcall(player.updateLOS, player)
    refreshed = ok == true
    realVisible = hasRealZombieVisible(player)
    seedManagedBodies(player, entries)
    restoreLease({ bodies = entries })
    state.lastRealVisible = realVisible
    state.pending = false
    Safeguards.PlayerState[key] = state
    return refreshed, realVisible
end

local function forEachPlayer(callback)
    if Core and Core.ForEachPlayer then
        Core.ForEachPlayer(callback)
        return
    end
    if getNumActivePlayers and getSpecificPlayer then
        local count = getNumActivePlayers()
        local i
        for i = 0, math.max(0, count - 1) do
            local player = getSpecificPlayer(i)
            if player then callback(player) end
        end
    end
end

function Safeguards.OnPlayerUpdate(player)
    Safeguards.BeginPlayerUpdate(player)
end

function Safeguards.OnTick()
    forEachPlayer(function(player)
        local key = playerKey(player)
        local state = Safeguards.PlayerState[key] or {}
        local bodies
        local stats
        if state.pending then
            Safeguards.FinishPlayerUpdate(player)
        else
            -- This is a recovery path for runtimes that do not emit
            -- OnPlayerUpdate on the authority. It also repairs counters left
            -- behind by a hot reload without touching ordinary zombies.
            bodies = collectBodies(player)
            stats = player.getStats and player:getStats() or nil
            if #bodies > 0 and hasThreatCounters(player) then
                Safeguards.RefreshVanillaThreatCounters(player)
            elseif stats then
                updateSafePanic(player, state, hasRealZombieVisible(player))
            end
            Safeguards.PlayerState[key] = state
        end
    end)
end

function Safeguards.OnResetLua()
    local body
    for body, _ in pairs(Safeguards.LeasedBodies) do
        if body and body.setReanimatedForGrappleOnly then
            pcall(body.setReanimatedForGrappleOnly, body, false)
        end
    end
    Safeguards.PlayerState = {}
    Safeguards.KnownBodies = setmetatable({}, { __mode = "k" })
    Safeguards.LeasedBodies = setmetatable({}, { __mode = "k" })
end

if Events and Events.OnPlayerUpdate then
    Events.OnPlayerUpdate.Add(Safeguards.OnPlayerUpdate)
end
if Events and Events.OnTick then
    Events.OnTick.Add(Safeguards.OnTick)
end
if Events and Events.OnResetLua then
    Events.OnResetLua.Add(Safeguards.OnResetLua)
end

return Safeguards
