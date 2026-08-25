if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}

local Feed = PNC.ColonyJournalFeed or {}
PNC.ColonyJournalFeed = Feed

local RingBuffer = require "PsychopatzCore/Collections/PC_RingBuffer"
local CoreJournals = require "PsychopatzCore/Journal/PC_JournalService"
local Protocol = PNC.ColonyJournalProtocol
    or require "PNC/Core/Networking/PNC_ColonyJournalProtocol"

Feed.MAX_ENTRIES = Protocol.MAX_SERVER_ENTRIES
Feed._ring = Feed._ring or RingBuffer.new(Feed.MAX_ENTRIES)
Feed._sequence = tonumber(Feed._sequence) or 0
Feed._seeded = Feed._seeded or {}
Feed._scopeCache = Feed._scopeCache or {}

local function worldMinute()
    local gameTime = getGameTime and getGameTime() or nil
    local hours = gameTime and gameTime.getWorldAgeHours
        and tonumber(gameTime:getWorldAgeHours()) or 0
    return math.max(0, math.floor(hours * 60 + 0.5))
end

local function text(value, maxLength)
    return string.sub(tostring(value or ""), 1, maxLength or 96)
end

local function playerIdentity(player)
    local onlineID = player and player.getOnlineID
        and tostring(player:getOnlineID() or "") or ""
    local username = player and player.getUsername
        and tostring(player:getUsername() or "") or ""
    return onlineID, username
end

local function playerFaction(player)
    if PNC.Factions and PNC.Factions.GetPlayerFaction then
        return PNC.Factions.GetPlayerFaction(player)
    end
    return nil
end

local function playerScope(player)
    local onlineID, username = playerIdentity(player)
    local key = onlineID .. "\31" .. username
    local at = getTimestampMs and tonumber(getTimestampMs()) or 0
    local cached = Feed._scopeCache[key]
    if cached and at > 0 and at - cached.checkedAt < 5000 then
        return cached.faction, onlineID, username
    end
    local faction = playerFaction(player)
    Feed._scopeCache[key] = { faction = faction, checkedAt = at }
    return faction, onlineID, username
end

local function recordFactionID(record)
    local affiliation = record and record.affiliation
    return affiliation and tostring(affiliation.factionID or "") or ""
end

local function eventKey(entry)
    local args = entry.args or {}
    return table.concat({
        tostring(entry.source or ""), tostring(entry.subjectID or ""),
        tostring(entry.eventType or ""), tostring(entry.at or 0),
        tostring(args[1] or ""), tostring(args[2] or ""),
        tostring(args[3] or ""), tostring(args[4] or ""),
    }, "\31")
end

local function inCurrentRing(key)
    for entry in Feed._ring:oldestToNewest() do
        if entry and eventKey(entry) == key then return true end
    end
    return false
end

local function appendEntry(spec, historical)
    local eventType = text(spec.eventType, 96)
    local eventCode = Protocol.EventCode(eventType)
    if eventType == "" or not spec.subjectID then return false end

    local args = {}
    for index = 1, 4 do
        local value = spec.args and spec.args[index]
        if type(value) == "string" then
            args[index] = text(value)
        elseif type(value) == "number" then
            args[index] = tonumber(value) or 0
        elseif type(value) == "boolean" then
            args[index] = value
        elseif value ~= nil then
            args[index] = ""
        end
    end

    local entry = {
        source = math.floor(tonumber(spec.source) or 0),
        eventType = eventType,
        eventCode = eventCode,
        at = math.max(0, math.floor(tonumber(spec.at) or worldMinute())),
        subjectID = text(spec.subjectID, 96),
        label = text(spec.label, 64),
        ownerFactionID = text(spec.ownerFactionID, 96),
        ownerOnlineID = text(spec.ownerOnlineID, 64),
        ownerUsername = text(spec.ownerUsername, 64),
        args = args,
    }

    if historical and inCurrentRing(eventKey(entry)) then return false end
    Feed._sequence = Feed._sequence + 1
    entry.sequence = Feed._sequence
    Feed._ring:append(entry)
    return true
end

function Feed.AppendNPC(eventType, record, at, ...)
    if type(record) ~= "table" or not record.id then return false end
    return appendEntry({
        source = Protocol.SOURCE_NPC,
        eventType = eventType,
        at = at,
        subjectID = record.id,
        label = record.name or record.id,
        ownerFactionID = recordFactionID(record),
        ownerOnlineID = record.ownerOnlineID,
        ownerUsername = record.ownerUsername,
        args = { ... },
    }, false)
end

function Feed.AppendStorage(eventType, storageID, actor, typeID, quantity,
        reason, at)
    local storage = PNC.ColonyStorageRepository
        and PNC.ColonyStorageRepository.Get
        and PNC.ColonyStorageRepository.Get(storageID) or nil
    return appendEntry({
        source = Protocol.SOURCE_STORAGE,
        eventType = eventType,
        at = at,
        subjectID = storageID,
        label = storage and storage.storageType or storageID,
        ownerFactionID = storage and storage.ownerFactionId or "",
        args = { actor, typeID, quantity, reason },
    }, false)
end

local function ownedByPlayer(entry, faction, onlineID, username)
    if faction and tostring(entry.ownerFactionID or "") ~= ""
        and tostring(entry.ownerFactionID) == tostring(faction.id)
    then return true end
    if onlineID ~= "" and onlineID == tostring(entry.ownerOnlineID or "")
    then return true end
    return username ~= "" and username == tostring(entry.ownerUsername or "")
end

local function queueHistorical(pending, source, subjectID, label,
        ownerFactionID, ownerOnlineID, ownerUsername, raw)
    if type(raw) ~= "table" or type(raw[1]) ~= "string" then return end
    pending[#pending + 1] = {
        source = source, eventType = raw[1], at = raw[2], subjectID = subjectID,
        label = label, ownerFactionID = ownerFactionID,
        ownerOnlineID = ownerOnlineID, ownerUsername = ownerUsername,
        args = { raw[3], raw[4], raw[5], raw[6] },
    }
end

local function seedForPlayer(player)
    local faction, onlineID, username = playerScope(player)
    local scope = table.concat({ tostring(faction and faction.id or ""), onlineID,
        username }, "\31")
    if Feed._seeded[scope] then
        return faction, onlineID, username
    end

    local pending = {}
    local journals = PNC.Journals
    local records = PNC.Registry and PNC.Registry.Data or {}
    for _, record in pairs(records) do
        local recordFaction = recordFactionID(record)
        local owned = (faction and recordFaction == tostring(faction.id))
            or (onlineID ~= "" and tostring(record.ownerOnlineID or "") == onlineID)
            or (username ~= "" and tostring(record.ownerUsername or "") == username)
        if owned and record.id and journals and journals.GetNPC then
            for _, raw in ipairs(journals.GetNPC(record.id,
                journals.NPC_CAPACITY or 32, false) or {}) do
                queueHistorical(pending, Protocol.SOURCE_NPC, record.id,
                    record.name or record.id, recordFaction, record.ownerOnlineID,
                    record.ownerUsername, raw)
            end
        end
    end

    local repository = PNC.ColonyStorageRepository
    if repository and repository.EnsureLoaded then repository.EnsureLoaded() end
    for _, storage in pairs(repository and repository.ByID or {}) do
        if faction and tostring(storage.ownerFactionId or "") == tostring(faction.id)
            and journals
        then
            local history = CoreJournals.getRecent(
                journals.TYPE.COLONY_ACTIVITY, storage.id,
                journals.STORAGE_CAPACITY or 10, false)
            for _, raw in ipairs(history or {}) do
                queueHistorical(pending, Protocol.SOURCE_STORAGE, storage.id,
                    storage.storageType or storage.id, storage.ownerFactionId,
                    nil, nil, raw)
            end
        end
    end

    table.sort(pending, function(left, right)
        return (tonumber(left.at) or 0) < (tonumber(right.at) or 0)
    end)
    for _, spec in ipairs(pending) do appendEntry(spec, true) end
    Feed._seeded[scope] = true
    return faction, onlineID, username
end

function Feed.GetDelta(player, args)
    args = type(args) == "table" and args or {}
    if not player then
        return { v = Protocol.VERSION, error = "player_unavailable" }
    end

    local faction, onlineID, username = seedForPlayer(player)
    local after = math.max(0, math.floor(tonumber(args.after) or 0))
    local limit = math.min(Protocol.MAX_BATCH,
        math.max(1, math.floor(tonumber(args.limit) or Protocol.MAX_BATCH)))
    local oldest = Feed._ring:getOldest(1)
    local latest = Feed._sequence
    local reset = oldest and after > 0 and after < oldest.sequence - 1 or false
    local rows = {}
    local lastSequence = after
    local more = false

    for entry in Feed._ring:oldestToNewest() do
        if entry and entry.sequence > after
            and ownedByPlayer(entry, faction, onlineID, username)
        then
            if #rows < limit then
                rows[#rows + 1] = Protocol.ToWire(entry)
                lastSequence = entry.sequence
            else
                more = true
                break
            end
        end
    end

    if not more then lastSequence = latest end
    return {
        v = Protocol.VERSION,
        rows = rows,
        reset = reset,
        latestSequence = latest,
        nextCursor = lastSequence,
        more = more,
    }
end

return Feed
