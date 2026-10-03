-- Client-side delivery and presentation lifecycle provider.

PNC = PNC or {}
PNC.SocialFlavorPresentation = PNC.SocialFlavorPresentation or {}
PNC.SocialFlavorPresentationInternal =
    PNC.SocialFlavorPresentationInternal or {}

local Presentation = PNC.SocialFlavorPresentation
local H = PNC.SocialFlavorPresentationInternal
local Client = PsychopatzCore.SocialFlavorClient
local EventBus = PsychopatzCore.Events
local Diary = PNC.Conversation.Diary
local OWNER_TOKEN = Presentation
local log = H.Log

local function onDelivered(payload)
    if type(payload) ~= "table" then return end
    local item = payload.item or {}
    local message = payload.message
    local source = item.source or {}
    local context = type(item.context) == "table" and item.context or {}
    local npcID = tostring(item.speakerID or "")
    -- Interaction speech has its own exchange/diary owner.  The ambient
    -- listener must not reinterpret player lines or command replies as new
    -- proximity commentary when they share Core's arbitration queue.
    if item.speakerKind == "player"
        or source.kind == "emote_interaction"
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
        npcFlavorID = item.flavorID,
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
