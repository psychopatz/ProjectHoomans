-- Interactive request session preparation.
PNC = PNC or {}
PNC.PBrainZ = PNC.PBrainZ or {}
PNC.PBrainZ.Internal = PNC.PBrainZ.Internal or {}

local Integration = PNC.PBrainZ
local Internal = Integration.Internal
local RequestMemory = Internal.RequestMemory
local Speech = PNC.NameplateSpeech
local Session = Internal.RequestSession or {}
Internal.RequestSession = Session

function Session.Prepare(item, value)
    local view = item.view
    local session = view.session
    local pendingChoices = session.currentNode
        and session.currentNode.choices or {}
    local inputMessage = session:append("player", value, {
        source = {
            kind = "llm",
            channel = "input",
            requestID = item.requestID,
            sessionID = item.packet.session_id,
        },
    })
    if inputMessage then item.packet.message_id = inputMessage.messageID end
    RequestMemory.QueueNameQuestion(item, value, inputMessage)
    session.pendingChoices = pendingChoices
    session.pendingNext = nil
    session.pendingClose = nil
    session.pendingCloseReason = nil
    session.llmPending = true
    -- A never-ready queue item keeps the core session interactive lock held
    -- while the external provider is working. It is removed on delivery.
    session.queue = {
        {
            speaker = "npc",
            payload = { fallback = "", delayMs = math.huge },
            readyAt = math.huge,
        },
    }
    session.busy = true
    view.historyPart:setTyping("npc")
    if Speech and Speech.SetPending then
        Speech.SetPending(
            item.npcID,
            item.requestID,
            session.conversationID
        )
    end
end

return Session
