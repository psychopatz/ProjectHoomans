-- Typed client-side memory primitives for the local PBrainZ bridge.
--
-- Gameplay systems provide an event type and authoritative identifiers. This
-- module owns the bounded durable outbox, calendar snapshot, and retry-safe
-- event IDs. It deliberately does not accept free-form LLM memory text.

require "PsychopatzCore/Conversation/PsychopatzConversationMessage"
require "PNC/Core/Identity/PNC_FlavorAddress"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_Runtime"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_Identity"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_Outbox"

PNC = PNC or {}
PNC.PBrainZ = PNC.PBrainZ or {}
PNC.PBrainZ.Memory = PNC.PBrainZ.Memory or {}

local Memory = PNC.PBrainZ.Memory
local Message = PsychopatzCore.Conversation.Message
local FlavorAddress = PNC.FlavorAddress
local Identity = PNC.PBrainZ.Identity
local Runtime = PNC.PBrainZ.Internal.Runtime
local Outbox = PNC.PBrainZ.Internal.Outbox

Memory.VERSION = 1
Memory.STORAGE_KEY = "PNC_PBrainZMemory"
Memory.MAX_PENDING = 256
Memory.MAX_BATCH = 8
Memory.MAX_EVENT_ID = 256

local outbox = Outbox.New({
    owner = Memory,
    storageKey = Memory.STORAGE_KEY,
    -- One-time save compatibility boundary. Normal runtime reads and writes
    -- use only PNC_PBrainZMemory after this migration succeeds.
    legacyStorageKeys = { "PNC_HoomansLLMMemory" },
    version = Memory.VERSION,
    idField = "event_id",
    resetOwner = "llm_memory",
})
local monthNames = {
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December",
}

local function text(value, limit)
    return Runtime.Trim(value, limit)
end

local function call(object, method, fallback)
    if not object or type(object[method]) ~= "function" then
        return fallback
    end
    local ok, value = pcall(object[method], object)
    return ok and value ~= nil and value or fallback
end

local function player()
    return getSpecificPlayer and getSpecificPlayer(0) or nil
end

local function clientState()
    return PNC.Network and PNC.Network.ClientState or {}
end

local function playerUUID(explicit)
    local context = clientState().playerContext or {}
    return text(explicit or context.characterUUID, 256)
end

local function logPrimitive(primitiveType, npcID, result, reason, pending)
    if not print then return end
    print("[PNC][LLM] memory_primitive_"
        .. (result == true and "queued" or "rejected")
        .. " type=" .. text(primitiveType, 64)
        .. " npc=" .. text(npcID, 128)
        .. " result=" .. tostring(reason or "unknown")
        .. " pending=" .. tostring(pending or 0))
end

local function playerAddressName(npcID)
    if not npcID or text(npcID, 256) == "" then
        return "the player"
    end
    local state = clientState()
    local context = state.playerContext or {}
    local address = FlavorAddress.ResolveForNPC({
        npcID = npcID,
        player = player(),
        playerContext = context,
        playerUUID = context.characterUUID or context.playerUUID,
        state = state,
    })
    return address.addressName
end

local function calendarSnapshot(worldAgeHours)
    local gameTime = getGameTime and getGameTime() or nil
    local year = tonumber(call(gameTime, "getYear", 0)) or 0
    local rawMonth = tonumber(call(gameTime, "getMonth", -1))
    local rawDay = tonumber(call(gameTime, "getDay", -1))
    local hour = tonumber(call(gameTime, "getHour", nil))
    local minutes = tonumber(call(gameTime, "getMinutes", 0)) or 0
    if not hour then
        hour = math.floor(tonumber(call(gameTime, "getTimeOfDay", 0)) or 0)
    end
    local month = rawMonth and rawMonth + 1 or nil
    local day = rawDay and rawDay + 1 or nil
    local age = tonumber(worldAgeHours)
    if not age and gameTime then
        age = tonumber(call(gameTime, "getWorldAgeHours", 0)) or 0
    end
    age = age or 0
    local gameDay = Message.GetGameDay and Message.GetGameDay(age)
        or math.floor(age / 24)
    if year <= 0 or not month or month < 1 or month > 12
        or not day or day < 1 or day > 31
    then
        return {
            kind = "in_world_calendar",
            game_day = gameDay,
            world_age_hours = age,
            year = nil, month = nil, day = nil,
            hour = math.max(0, math.min(23, math.floor(hour or 0))),
            minute = math.max(0, math.min(59, math.floor(minutes))),
            iso = nil,
            label = "In-world day " .. tostring(gameDay),
        }
    end
    hour = math.max(0, math.min(23, math.floor(hour or 0)))
    minutes = math.max(0, math.min(59, math.floor(minutes)))
    local iso = string.format(
        "%04d-%02d-%02dT%02d:%02d:00",
        year, month, day, hour, minutes
    )
    local monthName = monthNames[month] or string.format("Month %02d", month)
    return {
        kind = "in_world_calendar",
        game_day = gameDay,
        world_age_hours = age,
        year = year, month = month, day = day,
        hour = hour, minute = minutes,
        iso = iso,
        label = string.format(
            "%s %d, %d (Day %d, %02d:%02d)",
            monthName, day, year, gameDay, hour, minutes
        ),
    }
end

local function preOutbreakTime()
    return {
        kind = "pre_outbreak",
        phase = "before_outbreak",
        game_day = nil,
        world_age_hours = nil,
        calendar_date = nil,
        label = "Before the outbreak",
    }
end

function Memory.CurrentContext(worldAgeHours, npcID)
    local identity = Identity.Current()
    local currentAge = tonumber(worldAgeHours)
    if not currentAge then
        local gameTime = getGameTime and getGameTime() or nil
        currentAge = tonumber(call(gameTime, "getWorldAgeHours", 0)) or 0
    end
    return {
        version = Memory.VERSION,
        status = "active",
        world_uuid = Message.GetSaveID and Message.GetSaveID() or nil,
        world_mode = identity.world_mode,
        save_relative_path = identity.save_relative_path,
        server_instance_id = identity.server_instance_id,
        server_world_generation = identity.server_world_generation,
        player_uuid = playerUUID(),
        player_name = playerAddressName(npcID),
        event_time = calendarSnapshot(currentAge),
    }
end

local function storage()
    return outbox.Storage()
end

local function stableEventID(primitiveType, playerID, npcID, relationshipKind)
    local eventID = "pnc:memory:v1:" .. text(primitiveType, 64)
        .. ":" .. text(playerID, 128) .. ":" .. text(npcID, 128)
    if relationshipKind and text(relationshipKind, 64) ~= "" then
        eventID = eventID .. ":" .. text(relationshipKind, 64)
    end
    return text(eventID, Memory.MAX_EVENT_ID)
end

local function currentFields(event, context)
    local fields = {
        "world_uuid", "world_mode", "save_relative_path",
        "server_instance_id", "server_world_generation",
    }
    for _, key in ipairs(fields) do
        if event[key] == nil then event[key] = context[key] end
    end
    if event.player_uuid == nil or text(event.player_uuid) == "" then
        event.player_uuid = context.player_uuid
    end
    if event.player_name == nil then event.player_name = context.player_name end
    return event
end

function Memory.Enqueue(event)
    if type(event) ~= "table" then return false, "invalid_memory_event" end
    local primitiveType = text(event.primitive_type or event.primitiveType, 64)
    local playerID = text(event.player_uuid or event.playerUUID, 256)
    local npcID = text(event.npc_uuid or event.npcUUID, 256)
    if primitiveType == "" or playerID == "" or npcID == "" then
        return false, "memory_event_identity_required"
    end
    local context = Memory.CurrentContext(event.world_age_hours)
    currentFields(event, context)
    event.primitive_type = primitiveType
    event.player_uuid = playerID
    event.npc_uuid = npcID
    event.event_id = text(
        event.event_id or event.eventID
            or stableEventID(
                primitiveType,
                playerID,
                npcID,
                event.relationship_kind or event.relationshipKind
            ),
        Memory.MAX_EVENT_ID
    )
    if event.event_time == nil then event.event_time = context.event_time end
    if not event.event_time then return false, "memory_event_time_required" end
    local root = storage()
    if root.index[event.event_id] then
        if primitiveType == "first_meeting" then
            logPrimitive(primitiveType, npcID, true, "duplicate", #root.records)
        end
        return true, "duplicate"
    end
    local queued, reason = outbox.Append(
        event, event.event_id, Memory.MAX_PENDING
    )
    if not queued then
        if primitiveType == "first_meeting" then
            logPrimitive(primitiveType, npcID, false,
                "memory_outbox_full", #root.records)
        end
        return false, "memory_outbox_full"
    end
    if primitiveType == "first_meeting" then
        logPrimitive(primitiveType, npcID, true, reason, #root.records)
    end
    return true, "queued"
end

function Memory.IsNameQuestion(value)
    local normalized = string.lower(text(value, 512))
    normalized = string.gsub(normalized, "['’]", "")
    normalized = string.gsub(normalized, "[^%w%s]", " ")
    normalized = string.gsub(normalized, "%s+", " ")
    normalized = text(normalized, 512)
    return string.find(normalized, "what is your name", 1, true) ~= nil
        or string.find(normalized, "whats your name", 1, true) ~= nil
        or string.find(normalized, "what s your name", 1, true) ~= nil
end

function Memory.EnqueueFirstMeeting(npcID, npcName, sourceEventID, explicitPlayerID)
    local context = Memory.CurrentContext(nil, npcID)
    local playerID = playerUUID(explicitPlayerID)
    local targetID = text(npcID, 256)
    if playerID == "" or targetID == "" then
        logPrimitive("first_meeting", targetID, false,
            "memory_event_identity_required", 0)
        return false, "memory_event_identity_required"
    end
    return Memory.Enqueue({
        primitive_type = "first_meeting",
        memory_type = "PERSONAL_EVENT",
        event_id = stableEventID("first_meeting", playerID, targetID),
        world_uuid = context.world_uuid,
        world_mode = context.world_mode,
        save_relative_path = context.save_relative_path,
        server_instance_id = context.server_instance_id,
        server_world_generation = context.server_world_generation,
        player_uuid = playerID,
        player_name = context.player_name,
        npc_uuid = targetID,
        npc_name = text(npcName, 256),
        event_time = context.event_time,
        source = "identity_disclosure",
        authoritative = true,
        source_event_id = text(sourceEventID, 256),
    })
end

function Memory.EnqueueSnapshotPrimitives(primitives)
    if type(primitives) ~= "table" then return 0 end
    local queued = 0
    for _, event in ipairs(primitives) do
        local ok = Memory.Enqueue(event)
        if ok then queued = queued + 1 end
    end
    return queued
end

function Memory.Poll()
    local events, pendingCount = outbox.Peek(Memory.MAX_BATCH)
    return {
        status = #events > 0 and "pending" or "idle",
        version = Memory.VERSION,
        memory_primitives = events,
        pendingCount = pendingCount,
    }
end

function Memory.Ack(arguments)
    arguments = type(arguments) == "table" and arguments or {}
    local eventIDs = arguments.event_ids or arguments.eventIDs or {}
    if type(eventIDs) ~= "table" then return 0 end
    local removed = outbox.Acknowledge(
        eventIDs,
        Memory.MAX_BATCH * 8,
        function(value) return text(value, Memory.MAX_EVENT_ID) end
    )
    if removed > 0 and print then
        print("[PNC][LLM] memory_primitive_acknowledged count="
            .. tostring(removed)
            .. " pending=" .. tostring(outbox.PendingCount()))
    end
    return removed
end

return Memory
