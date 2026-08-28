-- Durable, bounded handoff of canonical conversation messages to pbrainz.
--
-- This is an outbox, not a transcript database. Messages remain here only
-- until pbrainz acknowledges their canonical message IDs. Retrying a poll is
-- safe because the receiver enforces the same IDs at its SQLite boundary.
require "PsychopatzCore/Conversation/PsychopatzConversationMessage"
require "PsychopatzCore/Events/PC_EventBus"

PNC = PNC or {}
PNC.HoomansLLM = PNC.HoomansLLM or {}
PNC.ConversationMemorySync = PNC.ConversationMemorySync or {}

local Sync = PNC.ConversationMemorySync
local Message = PsychopatzCore.Conversation.Message
local Events = PsychopatzCore.Events

Sync.VERSION = 1
Sync.STORAGE_KEY = "PNC_ConversationMemorySync"
Sync.MAX_PENDING = 256
Sync.MAX_BATCH = 4
Sync.MAX_CONTENT_LENGTH = 12000

local OWNER_TOKEN = Sync
local memoryRoot = Sync.memoryRoot or {}
Sync.memoryRoot = memoryRoot

local function storage()
    local root
    if ModData and ModData.getOrCreate then
        root = ModData.getOrCreate(Sync.STORAGE_KEY)
    else
        root = memoryRoot
    end
    root.version = Sync.VERSION
    root.records = root.records or {}
    root.index = root.index or {}
    -- Rebuild the index once for data written by an older outbox shape.
    if root.indexReady ~= true then
        root.index = {}
        for _, record in ipairs(root.records) do
            if record and record.messageID then
                root.index[tostring(record.messageID)] = true
            end
        end
        root.indexReady = true
    end
    return root
end

local function compactSource(source)
    local output = {}
    if type(source) ~= "table" then return output end
    local keys = {
        "kind", "channel", "requestID", "sessionID", "utteranceID",
    }
    for _, key in ipairs(keys) do
        if source[key] ~= nil then output[key] = tostring(source[key]) end
    end
    return output
end

local function compactParticipants(participants)
    local output = {}
    if type(participants) ~= "table" then return output end
    for index = 1, math.min(#participants, 16) do
        local participant = participants[index]
        if type(participant) == "table" then
            output[#output + 1] = {
                id = participant.id or participant.speakerID,
                name = participant.name or participant.speakerName,
                kind = participant.kind or participant.speakerKind,
            }
        end
    end
    return output
end

local function wireMessage(message)
    local text = tostring(message.text or "")
    if #text > Sync.MAX_CONTENT_LENGTH then
        text = string.sub(text, 1, Sync.MAX_CONTENT_LENGTH)
    end
    return {
        version = Sync.VERSION,
        messageID = tostring(message.messageID or ""),
        saveUUID = tostring(message.saveUUID or Message.GetSaveID()),
        conversationID = tostring(message.conversationID or ""),
        namespace = tostring(message.namespace or ""),
        sequence = tonumber(message.sequence) or 0,
        playerUUID = tostring(message.playerUUID or ""),
        npcUUID = tostring(message.npcUUID or ""),
        speakerID = tostring(message.speakerID or ""),
        speakerName = message.speakerName,
        speakerKind = tostring(message.speakerKind or message.speaker or "npc"),
        role = message.speakerKind == "player" and "user" or "assistant",
        text = text,
        gameDay = tonumber(message.gameDay) or 0,
        worldAgeHours = tonumber(message.worldAgeHours) or 0,
        participants = compactParticipants(message.participants),
        visibility = tostring(message.visibility or "PUBLIC"),
        provenance = compactSource(message.provenance),
        source = compactSource(message.source),
    }
end

function Sync.Enqueue(message)
    if type(message) ~= "table" then return false, "invalid_message" end
    local messageID = tostring(message.messageID or "")
    if messageID == "" then return false, "missing_message_id" end
    local saveUUID = tostring(message.saveUUID or "")
    if saveUUID == "" or saveUUID == "ephemeral"
        or tostring(message.playerUUID or "") == ""
        or tostring(message.npcUUID or "") == ""
    then
        return false, "not_persistent"
    end
    local text = tostring(message.text or "")
    if text == "" then return false, "empty_message" end
    local root = storage()
    if root.index[messageID] then return true, "duplicate" end
    if #root.records >= Sync.MAX_PENDING then
        root.overflow = (tonumber(root.overflow) or 0) + 1
        if print then
            print("[PNC][LLM] conversation_sync_outbox_full pending="
                .. tostring(#root.records))
        end
        return false, "outbox_full"
    end
    root.records[#root.records + 1] = wireMessage(message)
    root.index[messageID] = true
    return true, "queued"
end

function Sync.Poll()
    local root = storage()
    local records = {}
    for index = 1, math.min(#root.records, Sync.MAX_BATCH) do
        records[#records + 1] = root.records[index]
    end
    return {
        status = #records > 0 and "pending" or "idle",
        version = Sync.VERSION,
        messages = records,
        pendingCount = #root.records,
        overflow = tonumber(root.overflow) or 0,
    }
end

function Sync.Ack(arguments)
    arguments = type(arguments) == "table" and arguments or {}
    local messageIDs = arguments.message_ids or arguments.messageIDs or {}
    if type(messageIDs) ~= "table" then return nil, "INVALID_ARGUMENTS", "message_ids must be a list." end
    local acknowledged = {}
    for index = 1, math.min(#messageIDs, Sync.MAX_BATCH * 8) do
        local messageID = tostring(messageIDs[index] or "")
        if messageID ~= "" then acknowledged[messageID] = true end
    end
    local root = storage()
    local kept = {}
    local removed = 0
    for _, record in ipairs(root.records) do
        if record and acknowledged[tostring(record.messageID or "")] then
            root.index[tostring(record.messageID)] = nil
            removed = removed + 1
        elseif record then
            kept[#kept + 1] = record
        end
    end
    root.records = kept
    return {
        acknowledged = removed,
        pendingCount = #root.records,
    }
end

function Sync.GetPendingCount()
    return #(storage().records or {})
end

Events.clearOwner(OWNER_TOKEN)
Events.subscribe(Message.EVENT_TYPE, function(message)
    Sync.Enqueue(message)
end, OWNER_TOKEN)

return Sync
