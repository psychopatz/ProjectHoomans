--[[
    PNC Player Reaction
    Owns the short-lived player-side presentation of NPC counter reactions.

    NPCs use the native bump/stagger lifecycle. Players use the native player
    hit-reaction lifecycle instead; mixing those two protocols leaves the
    player's blockMovement latch owned by BumpedState.
]]

PNC = PNC or {}
PNC.PlayerReaction = PNC.PlayerReaction or {}

local Reaction = PNC.PlayerReaction
local Core = PNC.Core or {}

Reaction.LocalActive = Reaction.LocalActive or {}
Reaction.ServerActive = Reaction.ServerActive or {}
Reaction.Sequence = tonumber(Reaction.Sequence) or 0

local function nowMillis(fallback)
    if fallback ~= nil then
        return tonumber(fallback) or 0
    end
    if Core.Now then
        return tonumber(Core.Now()) or 0
    end
    return 0
end

local function isServerProcess()
    return isServer and isServer() == true
end

local function isClientOnly()
    return Core.IsClientOnly and Core.IsClientOnly() == true
end

local function isPlayer(player)
    return player
        and player.getObjectName
        and tostring(player:getObjectName() or "") == "Player"
end

local function playerKey(player)
    local onlineID
    if player and player.getOnlineID then
        onlineID = tonumber(player:getOnlineID())
        if onlineID and onlineID >= 0 then
            return tostring(onlineID)
        end
    end
    if player and player.getUsername then
        return tostring(player:getUsername() or "")
    end
    return tostring(player)
end

local function objectKey(object)
    local modData
    local onlineID
    if object and object.getModData then
        modData = object:getModData()
        if modData and modData.PNC_UUID ~= nil then
            return tostring(modData.PNC_UUID)
        end
    end
    if object and object.getOnlineID then
        onlineID = tonumber(object:getOnlineID())
        if onlineID and onlineID >= 0 then
            return tostring(onlineID)
        end
    end
    return nil
end

local function actionStateName(player)
    local value
    if player and player.getActionStateName then
        value = player:getActionStateName()
        if value ~= nil then return tostring(value) end
    end
    if player and player.getCurrentActionContextStateName then
        value = player:getCurrentActionContextStateName()
        if value ~= nil then return tostring(value) end
    end
    return ""
end

local function isHitReactionState(name)
    return string.find(string.lower(tostring(name or "")), "hitreaction", 1, true) ~= nil
end

local function hitReactionValue(player)
    if player and player.getHitReaction then
        return tostring(player:getHitReaction() or "")
    end
    return nil
end

local function nextToken(key, now)
    Reaction.Sequence = Reaction.Sequence + 1
    return "counter-stagger:" .. tostring(key) .. ":"
        .. tostring(now) .. ":" .. tostring(Reaction.Sequence)
end

local function durationValues(options)
    local constants = PNC.Const or {}
    local duration = tonumber(options.durationMs)
        or tonumber(constants.NPC_GROUNDED_COUNTER_STAGGER_DURATION_MS)
        or 650
    local timeout = tonumber(options.timeoutMs)
        or tonumber(constants.NPC_GROUNDED_COUNTER_STAGGER_TIMEOUT_MS)
        or 1400
    duration = math.max(100, math.min(duration, 2000))
    timeout = math.max(duration, math.min(timeout, 3000))
    return duration, timeout
end

local function canStart(active, key, now)
    local state = active[key]
    if not state then return true end
    if now >= (tonumber(state.expiresAt) or 0) then
        active[key] = nil
        return true
    end
    return false
end

local function buildPayload(player, sourceNPC, options, now)
    local duration, timeout = durationValues(options)
    local key = playerKey(player)
    return {
        kind = "counter_stagger",
        reaction = "HitReaction",
        event = "washit",
        durationMs = duration,
        timeoutMs = timeout,
        token = tostring(options.token or nextToken(key, now)),
        targetOnlineID = player.getOnlineID and tonumber(player:getOnlineID()) or nil,
        sourceOnlineID = sourceNPC and sourceNPC.getOnlineID
            and tonumber(sourceNPC:getOnlineID()) or nil,
        sourceNpcId = objectKey(sourceNPC),
    }
end

local function releaseLocal(player, state)
    local currentReaction = hitReactionValue(player)
    local currentState = actionStateName(player)
    if player and player.setHitReaction
        and (currentReaction == nil or currentReaction == "HitReaction")
    then
        player:setHitReaction("")
    end
    -- Only release the movement flag when the native action context still
    -- identifies this reaction. Never clear movement ownership from another
    -- action, vehicle state, or UI action.
    if player and player.setIgnoreMovement and isHitReactionState(currentState) then
        player:setIgnoreMovement(false)
    end
    return true
end

function Reaction.ReleaseLocal(player, token)
    local key = playerKey(player)
    local state = Reaction.LocalActive[key]
    if not state then return false end
    if token ~= nil and tostring(state.token) ~= tostring(token) then
        return false
    end
    releaseLocal(player, state)
    Reaction.LocalActive[key] = nil
    return true
end

function Reaction.ApplyLocalCounterStagger(player, payload)
    local key
    local now
    local duration
    local timeout
    local currentReaction
    local state
    if not isPlayer(player) or type(payload) ~= "table"
        or tostring(payload.kind or "") ~= "counter_stagger"
    then
        return false
    end
    if not player.setHitReaction or not player.reportEvent then
        return false
    end
    key = playerKey(player)
    now = nowMillis()
    if not canStart(Reaction.LocalActive, key, now) then
        state = Reaction.LocalActive[key]
        if state and tostring(state.token) == tostring(payload.token) then
            return true
        end
        return false
    end
    currentReaction = hitReactionValue(player)
    if currentReaction ~= nil and currentReaction ~= "" then
        return false
    end
    duration, timeout = durationValues(payload)
    state = {
        player = player,
        token = tostring(payload.token or nextToken(key, now)),
        startedAt = now,
        releaseAt = now + duration,
        expiresAt = now + timeout,
        sourceNpcId = payload.sourceNpcId,
    }
    Reaction.LocalActive[key] = state
    player:setHitReaction(tostring(payload.reaction or "HitReaction"))
    player:reportEvent(tostring(payload.event or "washit"))
    return true
end

function Reaction.Pump(now)
    now = nowMillis(now)
    local key
    local state
    local player
    local currentReaction
    local currentState
    for key, state in pairs(Reaction.LocalActive) do
        player = state.player
        currentReaction = hitReactionValue(player)
        currentState = actionStateName(player)
        if now - (tonumber(state.startedAt) or now) >= 50
            and currentReaction == ""
        then
            releaseLocal(player, state)
            Reaction.LocalActive[key] = nil
        elseif now >= (tonumber(state.expiresAt) or now)
        then
            -- The normal action graph should clear HitReaction. This guarded
            -- fallback prevents a broken animation transition from leaving
            -- the player movement-locked forever.
            if currentReaction == "HitReaction"
                and isHitReactionState(currentState)
            then
                releaseLocal(player, state)
            end
            Reaction.LocalActive[key] = nil
        end
    end
    return true
end

function Reaction.Reset()
    local key
    local state
    for key, state in pairs(Reaction.LocalActive) do
        releaseLocal(state.player, state)
        Reaction.LocalActive[key] = nil
    end
    Reaction.ServerActive = {}
    return true
end

function Reaction.StartCounterStagger(player, sourceNPC, options)
    local now
    local key
    local duration
    local timeout
    local payload
    local network
    local internal
    if not isPlayer(player) or isClientOnly() then
        return false
    end
    if Core.IsAuthority and Core.IsAuthority() ~= true then
        return false
    end
    options = type(options) == "table" and options or {}
    now = nowMillis()
    key = playerKey(player)
    if not canStart(Reaction.ServerActive, key, now) then
        return false
    end
    payload = buildPayload(player, sourceNPC, options, now)
    duration, timeout = durationValues(payload)
    if isServerProcess() then
        network = PNC.Network
        internal = network and network.Internal or nil
        if not internal or not internal.SendToPlayer
            or not PNC.Const or not PNC.Const.CMD_PLAYER_REACTION
        then
            return false
        end
        if internal.SendToPlayer(
            player,
            PNC.Const.CMD_PLAYER_REACTION,
            payload
        ) ~= true then
            return false
        end
        Reaction.ServerActive[key] = {
            token = payload.token,
            startedAt = now,
            expiresAt = now + timeout,
        }
        return true
    end
    return Reaction.ApplyLocalCounterStagger(player, payload)
end

return Reaction
