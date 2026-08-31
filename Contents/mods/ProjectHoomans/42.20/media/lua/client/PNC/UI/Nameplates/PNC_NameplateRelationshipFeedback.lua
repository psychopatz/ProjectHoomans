-- Client-only relationship change pipe for world nameplates.  Relationship
-- services publish signed deltas here; the renderer consumes short-lived
-- presentation records without owning or mutating relationship state.
require "PNC/UI/Nameplates/PNC_NameplateRelationshipFeedbackMath"

PNC = PNC or {}
PNC.NameplateRelationshipFeedback = PNC.NameplateRelationshipFeedback or {}

local Feedback = PNC.NameplateRelationshipFeedback
local Math = PNC.NameplateRelationshipFeedbackMath

Feedback.VERSION = 1
Feedback.DURATION_MS = 2200
Feedback.MERGE_WINDOW_MS = 450
Feedback.MAX_VISIBLE_MS = 3600
Feedback.MAX_TRACKED = 128

local records = Feedback.records or {}
local lastRevisionByNPC = Feedback.lastRevisionByNPC or {}
local seenEventKeys = Feedback.seenEventKeys or {}
Feedback.records = records
Feedback.lastRevisionByNPC = lastRevisionByNPC
Feedback.seenEventKeys = seenEventKeys

local function now(at)
    if at ~= nil then return tonumber(at) or 0 end
    if getTimeInMillis then return tonumber(getTimeInMillis()) or 0 end
    if PNC.Core and PNC.Core.Now then return tonumber(PNC.Core.Now()) or 0 end
    return 0
end

local function revision(metadata, after)
    metadata = type(metadata) == "table" and metadata or {}
    return Math.Number(metadata.revision or metadata.relationshipRevision
        or after and after.revision)
end

local function eventKey(metadata)
    metadata = type(metadata) == "table" and metadata or {}
    local value = metadata.eventID or metadata.eventId or metadata.eventKey
    value = tostring(value or "")
    return value ~= "" and value or nil
end

local function prune(currentTime)
    local count = 0
    local oldestID
    local oldestAt
    for key, seenAt in pairs(seenEventKeys) do
        if currentTime - (tonumber(seenAt) or 0)
            > Feedback.MAX_VISIBLE_MS
        then
            seenEventKeys[key] = nil
        end
    end
    for npcID, record in pairs(records) do
        if currentTime >= (tonumber(record.expiresAt) or 0) then
            records[npcID] = nil
        else
            count = count + 1
            local startedAt = tonumber(record.startedAt) or currentTime
            if oldestAt == nil or startedAt < oldestAt then
                oldestID = npcID
                oldestAt = startedAt
            end
        end
    end
    while count > Feedback.MAX_TRACKED and oldestID do
        records[oldestID] = nil
        count = count - 1
        oldestID = nil
        oldestAt = nil
        for npcID, record in pairs(records) do
            local startedAt = tonumber(record.startedAt) or currentTime
            if oldestAt == nil or startedAt < oldestAt then
                oldestID = npcID
                oldestAt = startedAt
            end
        end
    end
end

function Feedback.Score(delta, before, after)
    return Math.Score(delta, before, after)
end

function Feedback.Push(npcID, delta, metadata, at)
    npcID = tostring(npcID or "")
    if npcID == "" then return false end
    metadata = type(metadata) == "table" and metadata or {}
    local currentTime = now(at)
    local value = Math.Score(delta, metadata.before, metadata.after)
    if value == 0 then return false end

    local relationshipRevision = revision(metadata, metadata.after)
    if relationshipRevision > 0 then
        if lastRevisionByNPC[npcID] == relationshipRevision then
            return false
        end
        lastRevisionByNPC[npcID] = relationshipRevision
    end
    local key = eventKey(metadata)
    if key then
        local seenAt = seenEventKeys[npcID .. ":" .. key]
        if seenAt and currentTime - seenAt <= Feedback.MAX_VISIBLE_MS then
            return false
        end
        seenEventKeys[npcID .. ":" .. key] = currentTime
    end

    local direction = value > 0 and "up" or "down"
    local existing = records[npcID]
    if existing
        and existing.direction == direction
        and currentTime - (tonumber(existing.lastAt) or 0)
            <= Feedback.MERGE_WINDOW_MS
    then
        existing.score = Math.Number(existing.score) + value
        existing.magnitude = math.abs(existing.score)
        existing.delta.approval = existing.delta.approval
            + Math.Axis(delta, "approval")
        existing.delta.respect = existing.delta.respect
            + Math.Axis(delta, "respect")
        existing.delta.familiarity = existing.delta.familiarity
            + Math.Axis(delta, "familiarity")
        existing.lastAt = currentTime
        existing.expiresAt = math.min(
            (tonumber(existing.startedAt) or currentTime)
                + Feedback.MAX_VISIBLE_MS,
            currentTime + Feedback.DURATION_MS
        )
        existing.source = metadata.source or existing.source
        existing.eventID = key or existing.eventID
        existing.revision = relationshipRevision > 0
            and relationshipRevision or existing.revision
        prune(currentTime)
        return true
    end

    records[npcID] = {
        npcID = npcID,
        direction = direction,
        score = value,
        magnitude = math.abs(value),
        delta = Math.CopyDelta(delta),
        source = metadata.source,
        eventID = key,
        revision = relationshipRevision > 0 and relationshipRevision or nil,
        startedAt = currentTime,
        lastAt = currentTime,
        expiresAt = currentTime + Feedback.DURATION_MS,
    }
    prune(currentTime)
    return true
end

function Feedback.Observe(npcID, before, after, delta, metadata, at)
    metadata = type(metadata) == "table" and metadata or {}
    metadata.before = before
    metadata.after = after
    if before == nil and type(delta) ~= "table" then
        return false
    end
    local value = Math.Score(delta, before, after)
    if value == 0 and before ~= nil then
        local derived = Math.Delta(before, after)
        if Math.Score(derived, before, after) ~= 0 then
            delta = derived
        end
    end
    return Feedback.Push(npcID, delta, metadata, at)
end

function Feedback.Get(npcID, at)
    npcID = tostring(npcID or "")
    if npcID == "" then return nil end
    local currentTime = now(at)
    prune(currentTime)
    local record = records[npcID]
    if not record then return nil end
    local duration = math.max(1,
        (tonumber(record.expiresAt) or currentTime)
            - (tonumber(record.startedAt) or currentTime))
    local progress = math.max(0, math.min(1,
        (currentTime - (tonumber(record.startedAt) or currentTime))
            / duration))
    local alpha = 1
    if progress < 0.15 then
        alpha = progress / 0.15
    elseif progress > 0.72 then
        alpha = (1 - progress) / 0.28
    end
    record.alpha = math.max(0, math.min(1, alpha))
    record.progress = progress
    return record
end

function Feedback.IsActive(npcID, at)
    return Feedback.Get(npcID, at) ~= nil
end

function Feedback.Reset(npcID)
    if npcID == nil then
        for id, _ in pairs(records) do records[id] = nil end
        for id, _ in pairs(lastRevisionByNPC) do lastRevisionByNPC[id] = nil end
        for id, _ in pairs(seenEventKeys) do seenEventKeys[id] = nil end
        return true
    end
    npcID = tostring(npcID)
    records[npcID] = nil
    lastRevisionByNPC[npcID] = nil
    local prefix = npcID .. ":"
    for key, _ in pairs(seenEventKeys) do
        if string.sub(key, 1, #prefix) == prefix then
            seenEventKeys[key] = nil
        end
    end
    return true
end

return Feedback
