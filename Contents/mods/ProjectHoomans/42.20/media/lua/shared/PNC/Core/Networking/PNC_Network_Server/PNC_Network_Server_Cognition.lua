-- Transport adapter for the conversation-scoped NPC-cognition projection.
local Network = PNC.Network
local Core = PNC.Core
local Const = PNC.Const

function Network.SendSemanticCognition(
    targetPlayer,
    projection,
    reason,
    requestID,
    npcID
)
    local payload = {
        projection = projection,
        reason = reason,
        requestID = requestID,
        npcID = npcID,
        serverTime = Core.Now(),
    }
    if isServer and isServer() and targetPlayer and sendServerCommand then
        sendServerCommand(
            targetPlayer,
            Const.MODULE,
            Const.CMD_SEMANTIC_COGNITION,
            payload
        )
        return true
    elseif (not isServer or not isServer())
        and type(triggerEvent) == "function"
    then
        triggerEvent(
            "OnServerCommand",
            Const.MODULE,
            Const.CMD_SEMANTIC_COGNITION,
            payload
        )
        return true
    end
    return false
end

return Network
