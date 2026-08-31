local T = require "tests/support/test"
T.addPackagePaths()

PsychopatzCore = { Conversation = {} }
PNC = {}
local now = 1000
local worldHours = 49
local modData = {}
getTimeInMillis = function() return now end
getCurrentSaveName = function() return "Save One" end
getGameTime = function()
    return {
        getWorldAgeHours = function() return worldHours end,
    }
end
ModData = {
    getOrCreate = function(key)
        modData[key] = modData[key] or {}
        return modData[key]
    end,
}

T.load("PsychopatzCore", "common", "PsychopatzCore/Events/PC_EventBus.lua")
T.load("PsychopatzCore", "common",
    "PsychopatzCore/Conversation/PsychopatzConversationMessage.lua")
T.load("ProjectHoomans", "client",
    "PNC/Integrations/PNC_ConversationMemorySync.lua")

local Message = PsychopatzCore.Conversation.Message
local Sync = PNC.ConversationMemorySync

local message = Message.New({
    saveUUID = Message.GetSaveID(),
    messageID = "conversation-one:1",
    conversationID = "conversation-one",
    sequence = 1,
    playerUUID = "player-one",
    npcUUID = "npc-one",
    speakerID = "player-one",
    speakerName = "Alex",
    speakerKind = "player",
    text = "I brought you medicine.",
    gameDay = 2,
    worldAgeHours = worldHours,
    participants = {
        { id = "player-one", kind = "player" },
        { id = "npc-one", kind = "npc" },
        { id = "npc-two", kind = "npc" },
    },
    source = { kind = "conversation", channel = "choice" },
})

Message.Publish(message)
Message.Publish(message)
local batch = Sync.Poll()
T.equal(batch.status, "pending", "sync outbox has a message")
T.equal(batch.pendingCount, 1, "duplicate publication is collapsed")
T.equal(#batch.messages, 1, "sync batch is bounded")
T.equal(batch.messages[1].messageID, message.messageID, "canonical ID crosses bridge")
T.equal(batch.messages[1].role, "user", "player message role")
T.equal(batch.messages[1].playerUUID, "player-one", "player scope crosses bridge")
T.equal(batch.messages[1].npcUUID, "npc-one", "NPC scope crosses bridge")
T.equal(batch.messages[1].gameDay, 2, "game day crosses bridge")
T.equal(#batch.messages[1].participants, 3, "multi-NPC participants cross bridge")

worldHours = 73
T.equal(Sync.Poll().pendingCount, 1,
    "unacknowledged outbox survives a new game day")

local ack = Sync.Ack({ message_ids = { message.messageID } })
T.equal(ack.acknowledged, 1, "sync acknowledges canonical ID")
T.equal(Sync.Poll().status, "idle", "acknowledged message leaves outbox")

local providerFailure = Message.New({
    saveUUID = Message.GetSaveID(),
    messageID = "conversation-one:provider-failure",
    conversationID = "conversation-one",
    sequence = 2,
    playerUUID = "player-one",
    npcUUID = "npc-one",
    speakerID = "npc-one",
    speakerName = "Harley",
    speakerKind = "npc",
    text = "I cannot answer right now. (OpenAI-compatible provider request failed.)",
    source = {
        kind = "llm",
        channel = "response",
        providerFailure = true,
        contextEligible = false,
    },
})
Message.Publish(providerFailure)
T.equal(Sync.Poll().pendingCount, 0,
    "provider failures are excluded from LLM memory ingestion")

local toolAck = Message.New({
    saveUUID = Message.GetSaveID(),
    messageID = "conversation-one:tool-ack",
    conversationID = "conversation-one",
    sequence = 3,
    playerUUID = "player-one",
    npcUUID = "npc-one",
    speakerID = "npc-one",
    speakerName = "Harley",
    speakerKind = "npc",
    text = "I will check that now.",
    source = {
        kind = "llm",
        channel = "response",
        providerFailure = false,
        contextEligible = true,
    },
})
Message.Publish(toolAck)
local toolBatch = Sync.Poll()
T.equal(toolBatch.pendingCount, 1,
    "tool acknowledgement remains eligible for LLM memory ingestion")
T.equal(toolBatch.messages[1].source.contextEligible, true,
    "tool acknowledgement eligibility crosses the bridge")
T.equal(toolBatch.messages[1].source.providerFailure, false,
    "tool acknowledgement is not marked as a provider failure")

T.finish("pnc_conversation_memory_sync_smoke")
