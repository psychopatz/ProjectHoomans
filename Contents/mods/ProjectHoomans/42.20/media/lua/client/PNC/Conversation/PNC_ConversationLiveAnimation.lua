-- Bridges freshly delivered NPC conversation messages to the authoritative
-- live presentation-animation path. Portrait rendering remains independent;
-- this listener only consumes the existing transient animation identifier.

require "PsychopatzCore/Conversation/PsychopatzConversationMessage"
require "PsychopatzCore/Events/PC_EventBus"

PNC = PNC or {}
PNC.ConversationLiveAnimation = PNC.ConversationLiveAnimation or {}

local Bridge = PNC.ConversationLiveAnimation
local Presentation = PNC.PresentationAnimations
local Message = PsychopatzCore.Conversation.Message
local EventBus = PsychopatzCore.Events
local Const = PNC.Const
local Core = PNC.Core
local Registry = PNC.Registry
local OWNER_TOKEN = Bridge

Bridge.Internal = Bridge.Internal or {}
Bridge.Internal.Seen = Bridge.Internal.Seen or {}

local function currentConversationToken(npcID)
    local conversation = PsychopatzCore
        and PsychopatzCore.Conversation or nil
    local view = conversation and conversation.instance or nil
    local context = view and view.spec and view.spec.context or nil
    local state = context and context.conversationLifecycleState or nil
    if not view or tostring(view.spec.npcID or "") ~= tostring(npcID or "") then
        return nil
    end
    return state and state.token or nil
end

local function messageConversationToken(message)
    local source = message and message.source or nil
    local token = type(source) == "table"
        and (source.conversationToken or source.conversation_token)
        or nil
    if token == nil or tostring(token) == "" then return nil end
    return tostring(token)
end

local function liveBody(npcID)
    local snapshot
    local body
    if Registry and Registry.GetLiveZombie then
        body = Registry.GetLiveZombie(npcID)
        if body then return body end
    end
    snapshot = PNC.Network and PNC.Network.ClientState
        and PNC.Network.ClientState.snapshots
        and PNC.Network.ClientState.snapshots[tostring(npcID)] or nil
    if PNC.ClientPresenceSync
        and PNC.ClientPresenceSync.ResolveBodyForNPC
    then
        return PNC.ClientPresenceSync.ResolveBodyForNPC(npcID, snapshot)
    end
    return nil
end

local function eventIDFor(message)
    local value = message.messageID
    if value == nil or tostring(value) == "" then
        value = tostring(message.conversationID or "")
            .. ":" .. tostring(message.sequence or 0)
    end
    return tostring(value or "")
end

local function markClientEvent(eventID)
    local seen = Bridge.Internal.Seen
    local count = 0
    local oldest
    local oldestAt
    if eventID == "" then return true end
    if seen[eventID] ~= nil then return false end
    seen[eventID] = Core and Core.Now and Core.Now() or 0
    for key, at in pairs(seen) do
        count = count + 1
        if oldestAt == nil or (tonumber(at) or 0) < oldestAt then
            oldest = key
            oldestAt = tonumber(at) or 0
        end
    end
    if count > 64 and oldest then seen[oldest] = nil end
    return true
end

function Bridge.HandleMessage(message)
    local presentationState
    local animationID
    local npcID
    local eventID
    local definition
    local record
    local body
    local started
    local reason
    local token
    if type(message) ~= "table" then return false, "message_missing" end
    if tostring(message.speakerKind or message.speaker or "") ~= "npc" then
        return false, "not_npc_message"
    end
    presentationState = type(message.presentationState) == "table"
        and message.presentationState or {}
    animationID = message.liveAnimation
        or message.portraitAnimation
        or presentationState.liveAnimation
        or presentationState.portraitAnimation
    definition = Presentation and Presentation.Get
        and Presentation.Get(animationID) or nil
    if not definition then return false, "animation_not_registered" end
    npcID = tostring(message.npcUUID or message.speakerID or "")
    if npcID == "" then return false, "npc_id_missing" end
    token = messageConversationToken(message)
        or currentConversationToken(npcID)
    eventID = eventIDFor(message)
    if not markClientEvent(eventID) then return false, "duplicate_event" end
    if Core and Core.IsClientOnly and Core.IsClientOnly() then
        if not sendClientCommand then return false, "network_unavailable" end
        sendClientCommand(
            Const.MODULE,
            Const.CMD_NPC_PRESENTATION_ANIMATION,
            {
                id = npcID,
                animationID = definition.id,
                eventID = eventID,
                token = token,
            }
        )
        return true, "network_queued"
    end
    record = Registry and Registry.Get and Registry.Get(npcID) or nil
    body = liveBody(npcID)
    started, reason = Presentation.Request(
        record,
        body,
        definition.id,
        {
            eventID = eventID,
            reason = "conversation_delivery",
        }
    )
    return started == true, reason
end

if EventBus and Message and Message.EVENT_TYPE and EventBus.subscribe then
    EventBus.clearOwner(OWNER_TOKEN)
    EventBus.subscribe(
        Message.EVENT_TYPE,
        Bridge.HandleMessage,
        OWNER_TOKEN
    )
end

return Bridge
