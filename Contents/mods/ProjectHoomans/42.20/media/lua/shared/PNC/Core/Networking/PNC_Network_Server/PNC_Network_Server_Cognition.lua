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
    local cognition = PNC and PNC.Semantics
        and PNC.Semantics.CognitionProjection or nil
    local memoryGossip = type(projection) == "table"
        and projection._memoryGossip or nil
    if type(projection) == "table" then
        projection._memoryGossip = nil
    end
    if type(projection) == "table" and cognition
        and type(cognition.Compact) == "function"
    then
        projection = cognition.Compact(projection, npcID)
    end
    local payload = {
        projection = projection,
        reason = reason,
        requestID = requestID,
        npcID = npcID,
        serverTime = Core.Now(),
    }
    if type(memoryGossip) == "table"
        and type(memoryGossip.codes) == "table"
    then
        payload.g = memoryGossip.codes
        payload.gs = memoryGossip.subject
    end
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
