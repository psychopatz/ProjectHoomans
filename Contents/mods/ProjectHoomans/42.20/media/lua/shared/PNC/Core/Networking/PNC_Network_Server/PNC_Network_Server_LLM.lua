-- Compact, request-scoped results for Project Hoomans LLM gameplay tools.

local Network = PNC.Network
local Core = PNC.Core
local Const = PNC.Const

function Network.SendLLMSocialReactionResult(targetPlayer, result)
    local payload = type(result) == "table" and result or {}
    payload.serverTime = Core.Now()
    if isServer and isServer() and targetPlayer then
        sendServerCommand(
            targetPlayer,
            Const.MODULE,
            Const.CMD_LLM_SOCIAL_REACTION_RESULT,
            payload
        )
    elseif not isServer or not isServer() then
        triggerEvent(
            "OnServerCommand",
            Const.MODULE,
            Const.CMD_LLM_SOCIAL_REACTION_RESULT,
            payload
        )
    end
    return true
end

return Network
