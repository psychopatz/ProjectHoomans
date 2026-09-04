local Network = PNC.Network
local Internal = Network.Internal
local Core = PNC.Core
local Const = PNC.Const

function Network.SendDebugRoster(targetPlayer, diagnostics, authorized, audit)
    local payload = {
        authorized = authorized == true,
        diagnostics = diagnostics or {},
        audit = audit or {},
        serverTime = Core.Now(),
    }
    if isServer and isServer() and targetPlayer then
        sendServerCommand(targetPlayer, Const.MODULE, Const.CMD_DEBUG_ROSTER, payload)
    elseif not isServer or not isServer() then
        triggerEvent("OnServerCommand", Const.MODULE, Const.CMD_DEBUG_ROSTER, payload)
    end
end

function Network.SendRelationshipDebug(
    targetPlayer,
    snapshot,
    authorized,
    reason
)
    local payload = {
        authorized = authorized == true,
        snapshot = authorized == true and snapshot or nil,
        reason = reason,
        serverTime = Core.Now(),
    }
    if isServer and isServer() and targetPlayer then
        sendServerCommand(
            targetPlayer,
            Const.MODULE,
            Const.CMD_RELATIONSHIP_DEBUG,
            payload
        )
    elseif not isServer or not isServer() then
        triggerEvent(
            "OnServerCommand",
            Const.MODULE,
            Const.CMD_RELATIONSHIP_DEBUG,
            payload
        )
    end
end

-- Relationship presentation has one transport contract for every
-- authoritative social source.  Emotes, LLM reactions, gifts, and social
-- events may still send their own result payloads for dialogue/diary data,
-- but the relationship panel always consumes this message shape.
function Network.SendConversationRelationship(
    targetPlayer,
    summary,
    reason,
    relationshipContext
)
    relationshipContext = type(relationshipContext) == "table"
        and relationshipContext or {}
    local payload = {
        summary = summary,
        reason = reason,
        source = relationshipContext.source,
        eventID = relationshipContext.eventID,
        -- This is only a compact client-presentation hint.  Relationship
        -- values remain authoritative on the server; the Core client owns
        -- wording, cooldowns, queue arbitration, and optional LLM handling.
        ambientFlavor = relationshipContext.ambientFlavor,
        relationshipDelta = relationshipContext.relationshipDelta
            or relationshipContext.delta,
        relationshipBefore = relationshipContext.relationshipBefore
            or relationshipContext.before,
        relationshipAfter = relationshipContext.relationshipAfter
            or relationshipContext.after
            or summary,
        revision = relationshipContext.revision
            or summary and summary.revision or nil,
        serverTime = Core.Now(),
    }
    if relationshipContext.npcID ~= nil then
        payload.npcID = tostring(relationshipContext.npcID)
    elseif type(summary) == "table" and summary.npcID ~= nil then
        payload.npcID = tostring(summary.npcID)
    end
    if isServer and isServer() and targetPlayer then
        sendServerCommand(
            targetPlayer,
            Const.MODULE,
            Const.CMD_CONVERSATION_RELATIONSHIP,
            payload
        )
        return true
    elseif not isServer or not isServer() then
        triggerEvent(
            "OnServerCommand",
            Const.MODULE,
            Const.CMD_CONVERSATION_RELATIONSHIP,
            payload
        )
        return true
    end
    return false
end

function Network.SendNPCKnowledge(targetPlayer, snapshot, reason)
    local payload = { snapshot = snapshot, reason = reason, serverTime = Core.Now() }
    if isServer and isServer() and targetPlayer then
        sendServerCommand(targetPlayer, Const.MODULE, Const.CMD_NPC_KNOWLEDGE, payload)
    elseif not isServer or not isServer() then
        triggerEvent("OnServerCommand", Const.MODULE, Const.CMD_NPC_KNOWLEDGE, payload)
    end
end

function Internal.SendIdentityPayload(targetPlayer, command, payload)
    payload = payload or {}
    payload.serverTime = Core.Now()
    if isServer and isServer() and targetPlayer then
        sendServerCommand(targetPlayer, Const.MODULE, command, payload)
    elseif not isServer or not isServer() then
        triggerEvent("OnServerCommand", Const.MODULE, command, payload)
    end
end

function Network.SendPlayerBootstrap(targetPlayer, payload)
    Internal.SendIdentityPayload(targetPlayer, Const.CMD_PLAYER_BOOTSTRAP, payload)
end

function Network.SendNPCPresentation(targetPlayer, payload)
    Internal.SendIdentityPayload(targetPlayer, Const.CMD_NPC_PRESENTATION, payload)
end

function Network.SendKnowledgeDisclosure(targetPlayer, payload)
    Internal.SendIdentityPayload(targetPlayer, Const.CMD_KNOWLEDGE_DISCLOSURE, payload)
end

function Network.SendKnowledgeDebug(targetPlayer, snapshot, authorized, reason)
    local payload = { authorized = authorized == true, snapshot = authorized == true and snapshot or nil, reason = reason, serverTime = Core.Now() }
    if isServer and isServer() and targetPlayer then
        sendServerCommand(targetPlayer, Const.MODULE, Const.CMD_KNOWLEDGE_DEBUG, payload)
    elseif not isServer or not isServer() then
        triggerEvent("OnServerCommand", Const.MODULE, Const.CMD_KNOWLEDGE_DEBUG, payload)
    end
end

function Network.SendFactionDebug(
    targetPlayer,
    snapshot,
    authorized,
    reason
)
    local payload = {
        authorized = authorized == true,
        snapshot = authorized == true and snapshot or nil,
        reason = reason,
        serverTime = Core.Now(),
    }
    if isServer and isServer() and targetPlayer then
        sendServerCommand(
            targetPlayer,
            Const.MODULE,
            Const.CMD_FACTION_DEBUG,
            payload
        )
    elseif not isServer or not isServer() then
        triggerEvent(
            "OnServerCommand",
            Const.MODULE,
            Const.CMD_FACTION_DEBUG,
            payload
        )
    end
end

function Network.SendFactionMembers(
    targetPlayer,
    snapshot,
    reason
)
    local payload = {
        snapshot = snapshot,
        reason = reason,
        serverTime = Core.Now(),
    }
    if isServer and isServer() and targetPlayer then
        sendServerCommand(
            targetPlayer,
            Const.MODULE,
            Const.CMD_FACTION_MEMBERS,
            payload
        )
    elseif not isServer or not isServer() then
        triggerEvent(
            "OnServerCommand",
            Const.MODULE,
            Const.CMD_FACTION_MEMBERS,
            payload
        )
    end
end

function Network.SendCommunityDebug(
    targetPlayer,
    snapshot,
    authorized,
    reason
)
    local payload = {
        authorized = authorized == true,
        snapshot = authorized == true and snapshot or nil,
        reason = reason,
        serverTime = Core.Now(),
    }
    if isServer and isServer() and targetPlayer then
        sendServerCommand(
            targetPlayer,
            Const.MODULE,
            Const.CMD_COMMUNITY_DEBUG,
            payload
        )
    elseif not isServer or not isServer() then
        triggerEvent(
            "OnServerCommand",
            Const.MODULE,
            Const.CMD_COMMUNITY_DEBUG,
            payload
        )
    end
end

function Network.SendNeedsDebug(targetPlayer, snapshot, authorized, reason)
    local payload = { authorized = authorized == true, snapshot = authorized == true and snapshot or nil,
        reason = reason, serverTime = Core.Now() }
    if isServer and isServer() and targetPlayer then
        sendServerCommand(targetPlayer, Const.MODULE, Const.CMD_NEEDS_DEBUG, payload)
    elseif not isServer or not isServer() then
        triggerEvent("OnServerCommand", Const.MODULE, Const.CMD_NEEDS_DEBUG, payload)
    end
end

function Network.SendDirectorDebug(targetPlayer, snapshot, authorized, reason)
    local payload = { authorized = authorized == true,
        snapshot = authorized == true and snapshot or nil,
        reason = reason, serverTime = Core.Now() }
    if isServer and isServer() and targetPlayer then
        sendServerCommand(targetPlayer, Const.MODULE,
            Const.CMD_DIRECTOR_DEBUG, payload)
    elseif not isServer or not isServer() then
        triggerEvent("OnServerCommand", Const.MODULE,
            Const.CMD_DIRECTOR_DEBUG, payload)
    end
end

function Network.SendWorldEffectDebug(targetPlayer, snapshot, authorized, reason)
    local payload = { authorized = authorized == true,
        snapshot = authorized == true and snapshot or nil,
        reason = reason, serverTime = Core.Now() }
    if isServer and isServer() and targetPlayer then
        sendServerCommand(targetPlayer, Const.MODULE,
            Const.CMD_WORLD_EFFECT_DEBUG, payload)
    elseif not isServer or not isServer() then
        triggerEvent("OnServerCommand", Const.MODULE,
            Const.CMD_WORLD_EFFECT_DEBUG, payload)
    end
end
