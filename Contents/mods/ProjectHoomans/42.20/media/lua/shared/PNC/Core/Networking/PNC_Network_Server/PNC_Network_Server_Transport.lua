--[[
    PNC Networking - Server Replication
    Owns transport fan-out, interest sets, roster deltas, and detail payloads.
]]

PNC = PNC or {}
PNC.Network = PNC.Network or {}
PNC.Network.Internal = PNC.Network.Internal or {}

local Network = PNC.Network
local Internal = Network.Internal
local Core = PNC.Core
local Const = PNC.Const
local Inventory = PNC.Inventory
local MotionHints = PNC.MotionHints
local ServerState = Network.ServerState

local function playerKey(player)
    if player and player.getUsername then
        return tostring(player:getUsername())
    end
    if player and player.getOnlineID then
        return tostring(player:getOnlineID())
    end
    return tostring(player)
end

local function sendToPlayer(player, command, payload)
    if isServer and isServer() and player and sendServerCommand then
        sendServerCommand(player, Const.MODULE, command, payload)
        return true
    end
    if not isServer or not isServer() then
        triggerEvent("OnServerCommand", Const.MODULE, command, payload)
        return true
    end
    return false
end

local function sendToInterestedNPC(npcId, command, payload)
    local state
    local count = 0
    npcId = npcId and tostring(npcId) or nil
    if not npcId then
        return 0
    end
    for _, state in pairs(ServerState.interests) do
        if state.player and state.ids and state.ids[npcId] then
            sendToPlayer(state.player, command, payload)
            count = count + 1
        end
    end
    return count
end

-- Movement ownership follows the client that currently simulates a zombie,
-- not the NPC's interest set. Broadcast only to players near either endpoint
-- so the owner can receive the directive without making every aggro update a
-- server-wide packet.
local function sendToNearbyPlayers(primary, secondary, command, payload)
    local radius = tonumber(Const.ZOMBIE_NPC_DIRECTIVE_RADIUS) or 72
    local radiusSq = radius * radius
    local primaryX = primary and primary.getX and primary:getX() or nil
    local primaryY = primary and primary.getY and primary:getY() or nil
    local primaryZ = primary and primary.getZ and primary:getZ() or nil
    local secondaryX = secondary and secondary.getX and secondary:getX() or nil
    local secondaryY = secondary and secondary.getY and secondary:getY() or nil
    local secondaryZ = secondary and secondary.getZ and secondary:getZ() or nil
    local payloadX = payload and tonumber(payload.x) or nil
    local payloadY = payload and tonumber(payload.y) or nil
    local payloadZ = payload and tonumber(payload.z) or nil
    local count = 0
    if not (isServer and isServer() == true)
        or not Core
        or not Core.ForEachPlayer
    then
        return 0
    end
    Core.ForEachPlayer(function(player)
        local px
        local py
        local pz
        local dx
        local dy
        local nearPrimary
        local nearSecondary
        if not player then return end
        px = tonumber(player:getX()) or 0
        py = tonumber(player:getY()) or 0
        pz = tonumber(player:getZ()) or 0
        nearPrimary = false
        nearSecondary = false
        if primaryX and primaryY and primaryZ
            and math.abs(pz - primaryZ) <= 2
        then
            dx = px - primaryX
            dy = py - primaryY
            nearPrimary = (dx * dx) + (dy * dy) <= radiusSq
        end
        if secondaryX and secondaryY and secondaryZ
            and math.abs(pz - secondaryZ) <= 2
        then
            dx = px - secondaryX
            dy = py - secondaryY
            nearSecondary = (dx * dx) + (dy * dy) <= radiusSq
        end
        if not nearPrimary and not nearSecondary
            and payloadX and payloadY and payloadZ
            and math.abs(pz - payloadZ) <= 2
        then
            dx = px - payloadX
            dy = py - payloadY
            nearSecondary = (dx * dx) + (dy * dy) <= radiusSq
        end
        if nearPrimary or nearSecondary then
            if sendToPlayer(player, command, payload) then
                count = count + 1
            end
        end
    end)
    return count
end

Internal.PlayerKey = playerKey
Internal.SendToPlayer = sendToPlayer
Internal.SendToInterestedNPC = sendToInterestedNPC
Internal.SendToNearbyPlayers = sendToNearbyPlayers
