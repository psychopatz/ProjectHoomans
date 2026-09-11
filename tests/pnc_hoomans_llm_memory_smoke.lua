local T = require "tests/support/test"
T.addPackagePaths()

PsychopatzCore = { Conversation = {} }
PNC = {
    Network = {
        ClientState = {
            playerContext = { characterUUID = "player-one" },
        },
    },
}
local modData = {}
getTimeInMillis = function() return 1000 end
getCurrentSaveName = function()
    return "/home/player/Zomboid/Saves/Apocalypse/Save One"
end
getWorld = function()
    return {
        getGameMode = function() return "Apocalypse" end,
        getWorld = function() return "Muldraugh, KY" end,
    }
end
getGameTime = function()
    return {
        getWorldAgeHours = function() return 73.5 end,
        getYear = function() return 1993 end,
        getMonth = function() return 6 end,
        getDay = function() return 3 end,
        getHour = function() return 9 end,
        getMinutes = function() return 30 end,
    }
end
getSpecificPlayer = function()
    return {
        getFullName = function() return "Alex Survivor" end,
    }
end
ModData = {
    getOrCreate = function(key)
        modData[key] = modData[key] or {}
        return modData[key]
    end,
}

T.load("PsychopatzCore", "common",
    "PsychopatzCore/Conversation/PsychopatzConversationMessage.lua")
T.load("ProjectHoomans", "client",
    "PNC/Integrations/PNC_HoomansLLMMemory.lua")

local Memory = PNC.HoomansLLM.Memory
local ok, state = Memory.EnqueueFirstMeeting("npc-one", "Harley", "request-one")
T.truthy(ok, "first meeting queues")
T.equal(state, "queued", "first meeting queue state")
local duplicate, duplicateState = Memory.EnqueueFirstMeeting(
    "npc-one", "Harley", "request-retry"
)
T.truthy(duplicate, "duplicate first meeting is accepted")
T.equal(duplicateState, "duplicate", "duplicate first meeting state")

local queued = Memory.EnqueueSnapshotPrimitives({
    {
        primitive_type = "pre_outbreak_relationship",
        player_uuid = "player-one",
        npc_uuid = "npc-two",
        npc_name = "Morgan",
        relationship_kind = "friend",
        variant_key = "friend-01",
        event_time = { kind = "pre_outbreak" },
        source = "lifelong_relationship",
        authoritative = true,
    },
})
T.equal(queued, 1, "server relationship primitive queues")

local batch = Memory.Poll()
T.equal(#batch.memory_primitives, 2, "primitive batch is bounded and populated")
T.equal(batch.memory_primitives[1].event_time.game_day, 3,
    "first meeting uses in-world game day")
T.equal(batch.memory_primitives[1].event_time.month, 7,
    "calendar month is normalized to one-based")
T.equal(batch.memory_primitives[1].event_time.day, 4,
    "calendar day is normalized to one-based")
T.equal(batch.memory_primitives[2].event_time.kind, "pre_outbreak",
    "relationship uses pre-outbreak event time")

local sync = T.load("ProjectHoomans", "client",
    "PNC/Integrations/PNC_ConversationMemorySync.lua")
local syncBatch = sync.Poll()
T.equal(#syncBatch.memory_primitives, 2,
    "conversation sync exposes primitive outbox")
T.equal(syncBatch.memory_context.world_mode, "singleplayer",
    "conversation sync exposes active world mode")
T.equal(syncBatch.memory_context.event_time.label,
    "July 4, 1993 (Day 3, 09:30)",
    "conversation sync exposes parseable calendar label")

local eventIDs = {
    batch.memory_primitives[1].event_id,
    batch.memory_primitives[2].event_id,
}
local ack = sync.Ack({ event_ids = eventIDs })
T.equal(ack.primitivesAcknowledged, 2, "primitive IDs are acknowledged")
T.equal(Memory.Poll().pendingCount, 0, "ack clears durable primitive outbox")

local handlers = {}
PNC.Client = {
    Internal = {
        RegisterServerCommand = function(command, handler)
            handlers[command] = handler
        end,
    },
}
PNC.Const = {
    CMD_KNOWLEDGE_DEBUG = "KnowledgeDebug",
    CMD_KNOWLEDGE_DISCLOSURE = "KnowledgeDisclosure",
    CMD_NPC_KNOWLEDGE = "NPCKnowledge",
    CMD_NPC_PRESENTATION = "NPCPresentation",
    CMD_PLAYER_BOOTSTRAP = "PlayerBootstrap",
}
PNC.Core = {}
PNC.Conversation = {}
T.load("ProjectHoomans", "client",
    "PNC/Networking/ClientCommandRouter/PNC_ClientCommandRouter_Knowledge.lua")
handlers[PNC.Const.CMD_KNOWLEDGE_DISCLOSURE]({
    success = true,
    topicID = "identity_name",
    npcID = "npc-three",
    presentation = { displayName = "Jordan" },
    requestID = "request-three",
})
local disclosureBatch = Memory.Poll()
T.equal(#disclosureBatch.memory_primitives, 1,
    "successful name disclosure records first meeting")
T.equal(disclosureBatch.memory_primitives[1].npc_name, "Jordan",
    "first meeting keeps the NPC display name")

T.finish("pnc_hoomans_llm_memory_smoke")
