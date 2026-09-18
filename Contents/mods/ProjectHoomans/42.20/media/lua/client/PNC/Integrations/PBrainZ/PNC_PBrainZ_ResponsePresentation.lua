-- Live conversation and detached nameplate message presentation.
PNC = PNC or {}
PNC.PBrainZ = PNC.PBrainZ or {}
PNC.PBrainZ.Internal = PNC.PBrainZ.Internal or {}

local Integration = PNC.PBrainZ
local Internal = Integration.Internal
local RequestFlow = Internal.RequestFlow
local Presentation = Internal.ResponsePresentation or {}
Internal.ResponsePresentation = Presentation

local Message = PsychopatzCore.Conversation.Message
local Speech = PNC.NameplateSpeech

function Presentation.CompleteText(view, response, source)
    local session = view and view.session
    if not session then return false end
    session.queue = {}
    session.llmPending = nil
    session.busy = true
    source = source or {}
    source.messageID = source.messageID
        or (source.requestID and "llm-response:" .. tostring(source.requestID))
    session:queueMessage("npc", { fallback = response }, {
        source = source,
        messageID = source.messageID,
        portraitAnimation = source.portraitAnimation,
    })
    RequestFlow.Finish()
    return true
end

function Presentation.PublishDetached(pending, response, source)
    local view = pending and pending.view
    local session = view and view.session
    local packet = pending and pending.packet or {}
    local context = packet.conversation_context or {}
    if not view then return nil end
    if session then
        session.queue = {}
        session.llmPending = nil
        session.busy = false
        session.pendingNext = nil
        session.pendingClose = nil
        session.pendingCloseReason = nil
        if session.historyPart then
            session.historyPart:setTyping(nil)
        end
    elseif view.historyPart then
        view.historyPart:setTyping(nil)
    end
    if Speech and Speech.ClearPending then
        Speech.ClearPending(pending.npcID, pending.requestID)
    end
    source = source or {}
    source.messageID = source.messageID
        or (source.requestID and "llm-response:" .. tostring(source.requestID))
    local payload = { fallback = response }
    local message = Message.New({
        messageID = source.messageID,
        saveUUID = context.world_uuid or Message.GetSaveID(),
        conversationID = context.conversation_id
            or context.session_id
            or "llm:" .. tostring(pending.requestID),
        sequence = 0,
        speaker = "npc",
        speakerID = pending.npcID,
        speakerName = context.npc_name,
        speakerKind = "npc",
        playerUUID = context.player_uuid,
        npcUUID = context.npc_uuid or pending.npcID,
        namespace = session and session.namespace or "default",
        payload = payload,
        text = response,
        gameDay = Message.GetGameDay(),
        worldAgeHours = Message.GetWorldAgeHours(),
        participants = context.participants,
        source = source,
        presentationState = {
            conversationUI = false,
            nameplate = true,
            speech = context.audio_presentation,
        },
    })
    local History = PsychopatzCore.Conversation.History
        or require "PsychopatzCore/UI/Conversation/PsychopatzConversationHistory"
    if History and History.Append then
        History.Append(
            session and session.namespace or "default",
            pending.npcID,
            "npc",
            payload,
            session and session.characterUUID or context.player_uuid,
            message
        )
    end
    Message.Publish(message)
    if session and view.historyPart and view.historyPart.addMessage then
        view.historyPart:addMessage(message)
    end
    return message
end

return Presentation
