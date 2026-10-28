-- Server-authoritative write path for compact relationship event references.
PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local Memory = PNC.Conversation.Memory
local Events = Memory.Events
local Internal = Events.Internal
local positiveInteger = Internal.PositiveInteger
local currentWorldDay = Internal.CurrentWorldDay
local resolveEventType = Internal.ResolveEventType
local resolveTarget = Internal.ResolveEntityReference
local upsertShort = Internal.UpsertShort
local upsertLong = Internal.UpsertLong

local function hasAuthority()
    local Core = PNC and PNC.Core
    if Core and type(Core.IsAuthority) == "function" then
        local ok, result = pcall(Core.IsAuthority)
        return ok and result == true
    end
    return type(isServer) == "function" and isServer() == true
end

-- Compact read projection, independent of relationship-memory survival.
function Events.QuerySemanticEvidence(record, targetKey, actorID, query)
    local Evidence = require "PNC/Semantics/PNC_SemanticInteractionEvidence"
    local target = Events.ResolveTarget(targetKey)
    if not target or not target.seed or type(record) ~= "table" then return {} end
    local normalized = Events.Normalize(record.memory) or {}
    local values, rows = normalized.s or {}, {}
    for offset = #values - 2, 1, -3 do
        local entry = Events.GetType(values[offset])
        local metadata = entry and entry.semantic
        if values[offset + 1] == target.seed and metadata and Evidence.MatchesMeaning(metadata, query) then
            rows[#rows + 1] = {
                sourceRef = "today:" .. tostring(normalized.d) .. ":"
                    .. tostring(values[offset]) .. ":" .. tostring(target.seed),
                eventType = entry.id,
                actorID = metadata.actorRole == "observer" and record.id or actorID,
                targetID = metadata.actorRole == "observer" and actorID or record.id,
                classes = metadata.classes, relations = metadata.relations,
                retentionSalience = metadata.retentionSalience,
                sequence = (offset + 2) / 3, ageHours = 24,
                provenance = "record.memory.s", visibility = "direct",
            }
        end
    end
    return rows
end

function Events.RecordRelationshipMemory(record, relationshipMemory, targetKey)
    local sourceType
    local day
    local target
    local eventType
    local durable
    local shareable
    local flags
    local normalized
    local short
    local long
    local changed
    if not hasAuthority() then return false, "not_authority" end
    if type(record) ~= "table" or type(relationshipMemory) ~= "table" then
        return false, "invalid_memory"
    end
    sourceType = Internal.NormalizeEventID(relationshipMemory.type)
    if not sourceType then return false, "invalid_event_source" end
    day = currentWorldDay()
    if not day then return false, "world_date_unavailable" end
    target = resolveTarget(targetKey or relationshipMemory.aboutKey)
    if not target or not target.seed then
        return false, "invalid_memory_target"
    end
    eventType = resolveEventType(sourceType)
    if not eventType then return false, "event_type_unavailable" end
    durable = eventType.longTerm == true
        or relationshipMemory.permanent == true
    shareable = relationshipMemory.shareable == true
    flags = (shareable and Events.FLAG_SHAREABLE or 0)
        + (durable and Events.FLAG_DURABLE or 0)
    normalized = Events.Normalize(record.memory) or { v = Events.VERSION }
    short = {}
    if positiveInteger(normalized.d, 2147483646) == day then
        short = normalized.s or {}
    end
    changed = upsertShort(short, eventType.code, target.seed, flags)
    normalized.v = Events.VERSION
    normalized.d = day
    normalized.s = short
    if durable then
        long = normalized.l or {}
        if upsertLong(long, eventType.code, target.seed, day, flags) then
            changed = true
        end
        normalized.l = long
    end
    if type(normalized.l) ~= "table" or #normalized.l == 0 then
        normalized.l = nil
    end
    record.memory = normalized
    if changed and PNC.Registry
        and type(PNC.Registry.MarkDirty) == "function"
    then
        PNC.Registry.MarkDirty(record, "conversation_memory")
    end
    return true, changed and "recorded" or "unchanged", eventType.code
end

function Events.RecordConversationTopics(record, topicMask, playerUUID)
    local day
    local seed
    local mask
    local normalized
    local topicPlayers
    local changed
    if not hasAuthority() then return false, "not_authority" end
    if type(record) ~= "table" then return false, "invalid_memory" end
    day = currentWorldDay()
    if not day then return false, "world_date_unavailable" end
    seed = Events.ConversationPlayerSeed(record, playerUUID)
    if not seed then return false, "invalid_memory_target" end
    mask = Events.FilterConversationTopicMask(topicMask)
    if mask <= 0 then return false, "invalid_topic_mask" end

    normalized = Events.Normalize(record.memory) or { v = Events.VERSION }
    topicPlayers = positiveInteger(normalized.d, Events.MAX_DAY) == day
        and normalized.t or {}
    changed = Internal.UpsertConversationTopicPlayer(
        topicPlayers,
        seed,
        mask
    )
    if not changed then return true, "unchanged" end

    normalized.v = Events.VERSION
    normalized.d = day
    normalized.t = topicPlayers
    if type(normalized.s) ~= "table" or #normalized.s == 0 then
        normalized.s = nil
    end
    if type(normalized.l) ~= "table" or #normalized.l == 0 then
        normalized.l = nil
    end
    record.memory = normalized
    if PNC.Registry and type(PNC.Registry.MarkDirty) == "function" then
        PNC.Registry.MarkDirty(record, "conversation_memory")
    end
    return true, "recorded", mask
end

return true
