-- Shared contracts for the client request spokes.
--
-- This module intentionally owns only cross-spoke transport helpers. Domain
-- request methods remain in their respective request modules.
PNC = PNC or {}
PNC.Client = PNC.Client or {}
PNC.Client.Internal = PNC.Client.Internal or {}

local Client = PNC.Client
local Internal = Client.Internal
local Const = PNC.Const
local Core = PNC.Core
local ClientState = PNC.Network.ClientState

ClientState.identityRequestSerial = ClientState.identityRequestSerial or 0

function Internal.GetPlayer()
    return getSpecificPlayer and getSpecificPlayer(0) or nil
end

function Internal.RequestID(prefix)
    ClientState.identityRequestSerial =
        (tonumber(ClientState.identityRequestSerial) or 0) + 1
    return tostring(prefix) .. ":" .. tostring(Core.Now()) .. ":"
        .. tostring(ClientState.identityRequestSerial)
end

function Internal.DispatchIdentity(player, command, args, localHandler)
    if Core.IsClientOnly and Core.IsClientOnly() then
        if not player or not sendClientCommand then
            return false, "player_unavailable", args.requestId
        end
        sendClientCommand(player, Const.MODULE, command, args)
        return true, "sent"
    end
    if not PNC.PlayerKnowledgeCommands
        or not PNC.PlayerKnowledgeCommands[localHandler]
    then
        return false, "identity_command_handler_unavailable"
    end
    local result = PNC.PlayerKnowledgeCommands[localHandler](player, args)
    if type(result) == "table"
        and (result.success == false or result.state == "error")
    then
        return false, result.reason or "identity_request_failed", result
    end
    return true, "dispatched", result
end

return Client
