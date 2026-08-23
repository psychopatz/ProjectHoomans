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

Internal.PlayerKey = playerKey
Internal.SendToPlayer = sendToPlayer
Internal.SendToInterestedNPC = sendToInterestedNPC

