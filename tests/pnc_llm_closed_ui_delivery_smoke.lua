local T = require "tests/support/test"
T.addPackagePaths()

local layout = {
    defaults = {},
    GetNormalized = function() return {} end,
}
package.preload["PsychopatzCore/UI/Conversation/PsychopatzConversationLayout"] =
    function() return layout end
local traceEvents = {}
PsychopatzCore = {
    DebugTrace = {
        IsEnabled = function() return true end,
        Record = function(event) traceEvents[#traceEvents + 1] = event end,
    },
    Conversation = {
        Layout = layout,
        History = {
            Append = function() end,
        },
        Text = {
            Resolve = function(value)
                return type(value) == "table" and value.fallback or tostring(value or "")
            end,
        },
    },
    BridgeBootstrap = {
        IsEnabled = function() return true end,
    },
}
PNC = {
    Network = { ClientState = { playerContext = { characterUUID = "player-one" } } },
    Client = {
        ExecuteLLMSocialReaction = function()
            return true, "accepted"
        end,
    },
}
getCurrentSaveName = function() return "Save One" end
getTimeInMillis = function() return 1000 end
getGameTime = function()
    return { getWorldAgeHours = function() return 49 end }
end

T.load("ProjectHoomans", "client", "PNC/Integrations/PNC_HoomansLLM.lua")

local Message = PsychopatzCore.Conversation.Message
local Sync = PNC.ConversationMemorySync
local Speech = PNC.NameplateSpeech
local view = {
    spec = {
        npcID = "npc-one",
        characterUUID = "player-one",
        context = { npcName = "Harley", playerName = "Alex" },
    },
    session = {
        namespace = "Test",
        characterUUID = "player-one",
        currentNode = { choices = {} },
        append = function(self)
            local message = Message.New({
                messageID = "conversation-one:1",
                saveUUID = Message.GetSaveID(),
                conversationID = "conversation-one",
                sequence = 1,
                playerUUID = self.characterUUID,
                npcUUID = "npc-one",
                speakerID = "player-one",
                speakerKind = "player",
                text = "Hello",
            })
            Message.Publish(message)
            return message
        end,
    },
    historyPart = {
        messages = {},
        setTyping = function() end,
    },
}
function view:isConversationInteractive() return true end
PsychopatzCore.Conversation.instance = view

local Integration = PNC.HoomansLLM
local submitted = Integration.Submit(view, "Hello")
T.truthy(submitted, "LLM request submitted")
local packet = Integration.Poll()
T.equal(packet.status, "pending", "LLM request polled")
T.truthy(traceEvents[1] and traceEvents[1].event == "llm.request_queued",
    "queued request was not published to the core trace")
T.truthy(traceEvents[2] and traceEvents[2].event == "llm.request_polled",
    "polled request was not published to the core trace")

-- The player closed the conversation before the provider returned.
PsychopatzCore.Conversation.instance = nil
local pendingRecord = Speech.Get("npc-one")
T.truthy(pendingRecord and pendingRecord.pending,
    "closed UI does not expose pending nameplate state")
T.equal(Speech.GetDisplayText(pendingRecord), ".",
    "pending nameplate does not use the shared typing frame")
view.session = nil
local delivered = Integration.Deliver({
    request_id = packet.request_id,
    response_text = "A long reply that remains available above the NPC.",
})
T.truthy(delivered.accepted, "closed UI still accepts provider response")
T.equal(delivered.presentation, "nameplate", "closed UI selects nameplate presentation")
local record = Speech.Get("npc-one")
T.truthy(record, "detached response reaches nameplate")
T.equal(record.message.text, "A long reply that remains available above the NPC.",
    "nameplate keeps canonical response text")
T.truthy(traceEvents[3] and traceEvents[3].event == "llm.response_detached",
    "detached response was not published to the core trace")
local batch = Sync.Poll()
T.equal(batch.pendingCount, 2, "player and detached NPC messages are queued")
T.equal(batch.messages[2].messageID, "llm-response:" .. packet.request_id,
    "detached response keeps provider correlation ID")

-- The compact overlay uses a Core headless host but remains on the same
-- submission, polling, persistence, and detached-delivery pipeline.
local headlessView = {
    headless = true,
    hoomansLLM = true,
    spec = {
        npcID = "npc-two",
        characterUUID = "player-one",
        context = { npcName = "Harley", playerName = "Alex" },
    },
    session = {
        namespace = "Test",
        characterUUID = "player-one",
        conversationID = "conversation-two",
        currentNode = { choices = {} },
        append = function(self)
            local message = Message.New({
                messageID = "conversation-two:1",
                saveUUID = Message.GetSaveID(),
                conversationID = self.conversationID,
                sequence = 1,
                playerUUID = self.characterUUID,
                npcUUID = "npc-two",
                speakerID = "player-one",
                speakerKind = "player",
                text = "Hello from the overlay",
            })
            Message.Publish(message)
            return message
        end,
    },
    historyPart = {
        messages = {},
        setTyping = function(self, speaker) self.typingSpeaker = speaker end,
    },
}
function headlessView:isConversationInteractive()
    return self.session.busy ~= true
end

local inlineSubmitted = Integration.Submit(headlessView, "Hello from the overlay")
T.truthy(inlineSubmitted, "headless overlay request was rejected")
local inlinePending = Speech.Get("npc-two")
T.truthy(inlinePending and inlinePending.pending,
    "headless request did not expose pending nameplate state")
local inlinePacket = Integration.Poll()
local inlineDelivered = Integration.Deliver({
    request_id = inlinePacket.request_id,
    semantic_tool_calls = {
        {
            id = "reaction-1",
            name = "social_react",
            arguments = { kind = "praise", intensity = "normal" },
        },
    },
})
T.equal(inlineDelivered.presentation, "nameplate",
    "headless response did not detach to the nameplate")
T.truthy(headlessView.session.llmSemanticResults
    and headlessView.session.llmSemanticResults[1]
    and headlessView.session.llmSemanticResults[1].accepted == true,
    "headless response did not execute the shared semantic tool pipeline")
T.equal(Speech.Get("npc-two").message.text,
    "I will take care of that.",
    "headless tool acknowledgement was not published to the nameplate")

T.finish("pnc_llm_closed_ui_delivery_smoke")
