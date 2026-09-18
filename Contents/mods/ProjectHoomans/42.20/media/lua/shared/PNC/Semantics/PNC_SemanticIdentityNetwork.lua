-- Transport adapter for semantic identity validation results.
PNC = PNC or {}
PNC.Network = PNC.Network or {}
PNC.Const = PNC.Const or {}

local Network = PNC.Network
local Identity = PNC.Semantics and PNC.Semantics.IdentityExchange

function Network.SendSemanticIdentityResult(targetPlayer, payload)
    payload = type(payload) == "table" and payload or {}
    payload.serverTime = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
    local command = PNC.Const.CMD_SEMANTIC_IDENTITY_RESULT
    if isServer and isServer() and targetPlayer then
        sendServerCommand(targetPlayer, PNC.Const.MODULE, command, payload)
        return true
    end
    if not isServer or not isServer() then
        triggerEvent("OnServerCommand", PNC.Const.MODULE, command, payload)
        return true
    end
    return false
end

return Identity or Network
