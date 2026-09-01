-- Compact results for authority-owned vanilla emote interactions.

local Network = PNC.Network
local Core = PNC.Core
local Const = PNC.Const
local Presentation = PNC.RelationshipPresentation

function Network.SendPlayerEmoteInteractionResult(targetPlayer, result)
    local payload = type(result) == "table" and result or {}
    payload.serverTime = Core.Now()
    if isServer and isServer() and targetPlayer and sendServerCommand then
        sendServerCommand(
            targetPlayer,
            Const.MODULE,
            Const.CMD_PLAYER_EMOTE_INTERACTION_RESULT,
            payload
        )
        return true
    end
    return false
end

-- Ambient NPC speech is addressed only to the player who entered the social
-- radius.  The relationship summary itself still travels through the shared
-- ConversationRelationship transport below.
function Network.SendSocialGreeting(targetPlayer, greeting)
    local payload = type(greeting) == "table" and greeting or {}
    payload.serverTime = Core.Now()
    if isServer and isServer() and targetPlayer and sendServerCommand then
        sendServerCommand(
            targetPlayer,
            Const.MODULE,
            Const.CMD_SOCIAL_GREETING,
            payload
        )
        return true
    elseif not isServer or not isServer() then
        triggerEvent(
            "OnServerCommand",
            Const.MODULE,
            Const.CMD_SOCIAL_GREETING,
            payload
        )
        return true
    end
    return false
end

-- Builds the same player-facing relationship summary used by the conversation
-- request and sends it through Network.SendConversationRelationship.  Callers
-- should use this after an authoritative mutation when they have an NPC id but
-- do not want to recreate presentation formatting locally.
function Network.SendConversationRelationshipForNPC(
    targetPlayer,
    npcID,
    reason,
    relationshipContext
)
    local summary
    local buildReason
    local context = type(relationshipContext) == "table"
        and relationshipContext or {}
    if Presentation and Presentation.BuildForConversation then
        summary, buildReason = Presentation.BuildForConversation(
            targetPlayer,
            npcID
        )
    end
    if not summary then
        return false, buildReason or "relationship_presentation_unavailable"
    end
    context.npcID = tostring(npcID or summary.npcID or "")
    context.relationshipAfter = summary
    local sent = Network.SendConversationRelationship(
        targetPlayer,
        summary,
        reason or "relationship_changed",
        context
    )
    return sent == true, sent and nil or "relationship_transport_unavailable",
        summary
end

return Network
