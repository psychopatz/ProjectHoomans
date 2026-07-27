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
    if Core and Core.IsManagedNPCBody then
        return Core.IsManagedNPCBody(body)
    end
    local modData = body and body.getModData and body:getModData() or nil
    return modData and modData.PNC_NPC == true or false
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
    if not player or not stats then return end

    seedKnownHumanBodies(player, lastSpotted)
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
    if managedVisible and not realZombieVisible then
        if stats.setNumVisibleZombies then stats:setNumVisibleZombies(0) end
        if panic ~= nil and state.lastPanic ~= nil and panic > state.lastPanic
            and (rawVisible == nil or rawVisible > 0)
            and stats.set and CharacterStat and CharacterStat.PANIC
        then
            stats:set(CharacterStat.PANIC, state.lastPanic)
            panic = state.lastPanic
        end
        local emitter = player.getEmitter and player:getEmitter() or nil
        if emitter and emitter.stopSoundByName then
            emitter:stopSoundByName("ZombieSurprisedPlayer")
        end
    end
    if panic ~= nil then state.lastPanic = panic end
    Safeguards.PlayerState[playerKey(player)] = state
end

function Safeguards.RegisterHumanBody(body)
    local count = getNumActivePlayers and getNumActivePlayers() or 1
    local i
    local player
    local lastSpotted
    for i = 0, math.max(0, count - 1) do
        player = getSpecificPlayer and getSpecificPlayer(i) or nil
        lastSpotted = player and player.getLastSpotted and player:getLastSpotted() or nil
        seedBodyForPlayer(player, lastSpotted, body)
    end
end

function Safeguards.OnResetLua()
    Safeguards.PlayerState = {}
end

if Events and Events.OnPlayerUpdate then
    Events.OnPlayerUpdate.Add(Safeguards.OnPlayerUpdate)
end
if Events and Events.OnResetLua then
    Events.OnResetLua.Add(Safeguards.OnResetLua)
end

return Safeguards
