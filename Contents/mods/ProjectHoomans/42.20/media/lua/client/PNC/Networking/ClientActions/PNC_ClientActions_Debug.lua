-- Debug action transport for the client action façade.
--
-- The façade owns authorization and transport. Action-specific local
-- behavior lives in focused handler modules so new debug hooks do not grow
-- this networking entry point into another dispatcher monolith.
PNC = PNC or {}
PNC.Client = PNC.Client or {}

local Client = PNC.Client
local Const = PNC.Const
local Core = PNC.Core

local CONTINUE = "__pnc_debug_dispatch_continue"
local handlers = {}
local handlerModules = {
    require "PNC/Networking/ClientActions/PNC_ClientActions_Debug_Companion",
    require "PNC/Networking/ClientActions/PNC_ClientActions_Debug_Relationship",
    require "PNC/Networking/ClientActions/PNC_ClientActions_Debug_State",
    require "PNC/Networking/ClientActions/PNC_ClientActions_Debug_Spawn",
}

for index = 1, #handlerModules do
    local module = handlerModules[index]
    for action, handler in pairs(module) do
        handlers[action] = handler
    end
end

local function dispatchLocal(action, player, args)
    local handler = handlers[action]
    if handler then
        local result, reason, details = handler(player, args)
        if reason ~= CONTINUE then
            return result, reason, details
        end
    end
    if PNC.API and args.id then
        return PNC.API.DebugCommand(args.id, action, args)
    end
    return false
end

function Client.SendDebug(action, payload)
    local player = getSpecificPlayer(0)
    local args = payload or {}
    args.action = action
    if action == "set_map_known" and player then
        args.playerKey = player.getUsername and player:getUsername()
            or player.getOnlineID and tostring(player:getOnlineID())
            or nil
    end
    if not Client.CanUseDebug() then
        return false
    end
    if Core.IsClientOnly and Core.IsClientOnly() and player then
        sendClientCommand(player, Const.MODULE, Const.CMD_DEBUG, args)
        return true
    end
    return dispatchLocal(action, player, args)
end

return Client
