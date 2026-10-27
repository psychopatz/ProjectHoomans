-- Client-side delivery and presentation lifecycle provider.

PNC = PNC or {}
PNC.SemanticSpeechPresentation = PNC.SemanticSpeechPresentation or {}
PNC.SemanticSpeechPresentationInternal =
    PNC.SemanticSpeechPresentationInternal or {}

local Presentation = PNC.SemanticSpeechPresentation
local H = PNC.SemanticSpeechPresentationInternal
local Client = PsychopatzCore.SocialFlavorClient
local EventBus = PsychopatzCore.Events
local Diary = PNC.Conversation.Diary
local OWNER_TOKEN = Presentation
local log = H.Log
local InteractionPresentationRegistry = require
    "PNC/Conversation/PNC_SemanticInteractionPresentationRegistry"

local function onDelivered(payload)
    if type(payload) ~= "table" then return end
    local item = payload.item or {}
    local message = payload.message
    local source = item.source or {}
    local context = type(item.context) == "table" and item.context or {}
    local npcID = tostring(item.speakerID or "")
    local interaction = item.interaction or source.interaction
    if not interaction then
        interaction = InteractionPresentationRegistry.Take(item.eventID)
    else
        InteractionPresentationRegistry.Take(item.eventID)
    end
    if type(interaction) == "table" then
        local conversation = PsychopatzCore and PsychopatzCore.Conversation
        local view = conversation and conversation.instance or nil
        if view and view.session and view.spec
            and tostring(view.spec.npcID or "") == npcID
        then
            -- Keep provenance available to the next semantic input while
            -- leaving the visible history and durable state presentation-only.
            view.lastNPCSemanticInteraction = interaction
            view.session.semanticNPCProvenance = interaction
        end
    end
    -- Interaction speech has its own exchange/diary owner.  The ambient
    -- listener must not reinterpret player lines or command replies as new
    -- proximity commentary when they share Core's arbitration queue.
    if item.speakerKind == "player"
        or source.kind == "emote_interaction"
        or source.deliveryOwner == "player_emote"
    then
        return
    end
    if npcID == "" or type(message) ~= "table" then return end
    Diary.Append(npcID, {
        kind = source.eventType == "corpse_reaction"
            and "npc_corpse_reaction" or "social_flavor",
        source = "social_flavor",
        eventType = context.eventType or source.eventType or item.family,
        eventID = item.eventID,
        npcSpeechID = item.realizationID or item.flavorID,
        npcText = payload.text or message.text,
        npcType = context.socialRole or context.npcType,
        relationshipState = context.relationshipState,
        relationshipTier = context.relationshipTier,
        memoryID = context.memoryID,
        memoryType = context.memoryType,
        interactionType = context.interactionType,
        corpseNPCID = context.corpseNPCID,
        corpseName = context.corpseName,
        factionName = context.factionName,
        relationshipKind = context.relationshipKind,
        priority = item.priority,
        mergedCount = item.mergedCount,
        llm = payload.llm == true,
    })
    log("delivered", "event=" .. tostring(item.eventID or "")
        .. " npc=" .. npcID .. " llm=" .. tostring(payload.llm == true)
        .. " text=" .. string.gsub(tostring(payload.text or message.text or ""),
            "[\r\n]+", " "))
    if message.presentationState
        and message.presentationState.conversationUI == true
    then
        local conversation = PsychopatzCore and PsychopatzCore.Conversation
        local view = conversation and conversation.instance or nil
        if view and view.spec
            and tostring(view.spec.npcID or "") == npcID
            and view.historyPart and view.historyPart.addMessage
        then
            view.historyPart:addMessage(message)
        end
    end
end

function Presentation.SetDebug(enabled)
    return Client.SetDebug(enabled)
end

if PNC.PBrainZ
    and PNC.PBrainZ.SubmitAmbientFlavor
then
    Client.SetLLMProvider(
        function(item, complete)
            return PNC.PBrainZ.SubmitAmbientFlavor(item, complete)
        end,
        function(eventID)
            if PNC.PBrainZ.CancelAmbientFlavor then
                return PNC.PBrainZ.CancelAmbientFlavor(eventID)
            end
            return false
        end
    )
end
EventBus.clearOwner(OWNER_TOKEN)
EventBus.subscribe(Client.EVENT_DELIVERED, onDelivered, OWNER_TOKEN)


return Presentation
