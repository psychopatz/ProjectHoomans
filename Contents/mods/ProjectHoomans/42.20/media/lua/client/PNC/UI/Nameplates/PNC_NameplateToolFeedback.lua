-- Client-only feedback for authoritative LLM companion commands.
--
-- This is intentionally separate from NameplateSpeech and relationship
-- feedback.  It is a short-lived visual status record, not dialogue and not
-- gameplay state.
PNC = PNC or {}
PNC.NameplateToolFeedback = PNC.NameplateToolFeedback or {}

require "PNC/UI/Nameplates/PNC_NameplateToolFeedbackCatalog"

local Feedback = PNC.NameplateToolFeedback

Feedback.VERSION = 1
Feedback.DURATION_MS = 3600
Feedback.MAX_TRACKED = 128

local records = Feedback.records or {}
local seenResults = Feedback.seenResults or {}
Feedback.records = records
Feedback.seenResults = seenResults

local COMMAND_LABELS = PNC.NameplateToolFeedbackCatalog

local function now(at)
    if at ~= nil then return tonumber(at) or 0 end
    if getTimeInMillis then return tonumber(getTimeInMillis()) or 0 end
    if PNC.Core and PNC.Core.Now then
        return tonumber(PNC.Core.Now()) or 0
    end
    return 0
end

local function translated(key, fallback)
    local value = getText and getText(key) or nil
    if value and value ~= "" and value ~= key then return value end
    return fallback
end

local function normalize(value)
    value = string.lower(tostring(value or ""))
    return string.gsub(value, "[%s%-]", "_")
end

local function resultKey(result, npcID, at)
    local requestID = tostring(result and (result.requestID
        or result.request_id) or "")
    local callID = tostring(result and (result.callID
        or result.call_id) or "")
    local eventID = tostring(result and (result.eventID
        or result.eventId) or "")
    if requestID ~= "" and callID ~= "" then
        return requestID .. ":" .. callID
    end
    if eventID ~= "" then return eventID end
    return tostring(result and result.commandID or "order")
        .. ":" .. tostring(npcID) .. ":" .. tostring(at)
end

local function statusOf(result)
    local status = normalize(result and result.status)
    if status == "queued" or status == "submitted"
        or tostring(result and result.reason or "") == "network_queued"
    then
        return "queued"
    end
    if result and result.accepted == true then return "accepted" end
    return "rejected"
end

local function labelFor(commandID)
    local normalized = normalize(commandID)
    return COMMAND_LABELS[normalized] or {
        key = "UI_PNC_ToolFeedback_GenericOrder",
        fallback = "Order",
    }
end

local function targetIDs(result)
    local ids = {}
    local seen = {}
    local targets = result and result.targets
    local function add(value)
        local id
        if type(value) == "table" then
            id = value.id or value.npcID or value.npcId
        else
            id = value
        end
        id = tostring(id or "")
        if id ~= "" and not seen[id] then
            seen[id] = true
            ids[#ids + 1] = id
        end
    end
    if type(targets) == "table" then
        for index = 1, #targets do add(targets[index]) end
    end
    if #ids == 0 then
        add(result and (result.npcID or result.npcId
            or result.dialogueID or result.id))
    end
    return ids
end

local function prune(currentTime)
    local count = 0
    local oldestID
    local oldestAt
    local key
    local record
    for key, seenAt in pairs(seenResults) do
        if currentTime - (tonumber(seenAt.at) or 0)
            > Feedback.DURATION_MS * 2
        then
            seenResults[key] = nil
        end
    end
    for key, record in pairs(records) do
        if currentTime >= (tonumber(record.expiresAt) or 0) then
            records[key] = nil
        else
            count = count + 1
            if oldestAt == nil
                or (tonumber(record.startedAt) or currentTime) < oldestAt
            then
                oldestID = key
                oldestAt = tonumber(record.startedAt) or currentTime
            end
        end
    end
    while count > Feedback.MAX_TRACKED and oldestID do
        records[oldestID] = nil
        count = count - 1
        oldestID = nil
        oldestAt = nil
        for key, record in pairs(records) do
            if oldestAt == nil
                or (tonumber(record.startedAt) or currentTime) < oldestAt
            then
                oldestID = key
                oldestAt = tonumber(record.startedAt) or currentTime
            end
        end
    end
end

function Feedback.GetCommandLabel(commandID)
    return labelFor(commandID)
end

function Feedback.GetDisplayText(record)
    local label = record and record.label or labelFor(nil)
    local labelText = translated(label.key, label.fallback)
    local key
    local fallback
    if not record then return "" end
    if record.status == "queued" then
        key = "UI_PNC_ToolFeedback_Sending"
        fallback = "Sending %s order"
    elseif record.status == "accepted" then
        key = "UI_PNC_ToolFeedback_Switching"
        fallback = "Switching to %s"
    else
        key = "UI_PNC_ToolFeedback_Unavailable"
        fallback = "%s unavailable"
    end
    return string.format(translated(key, fallback), labelText)
end

function Feedback.Push(result, at)
    local currentTime = now(at)
    local ids = targetIDs(result)
    local commandID = normalize(result and (result.commandID
        or result.command_id))
    local status = statusOf(result)
    local label = labelFor(commandID)
    local inserted = false
    if commandID == "" or #ids == 0 then return false end
    prune(currentTime)
    for index = 1, #ids do
        local npcID = ids[index]
        local key = resultKey(result, npcID, currentTime)
        local prior = seenResults[key]
        if not prior or prior.status ~= status then
            seenResults[key] = { at = currentTime, status = status }
            records[npcID] = {
                npcID = npcID,
                commandID = commandID,
                label = label,
                status = status,
                reason = result.reason,
                requestID = result.requestID or result.request_id,
                callID = result.callID or result.call_id,
                resultKey = key,
                startedAt = currentTime,
                expiresAt = currentTime + Feedback.DURATION_MS,
            }
            inserted = true
        end
    end
    prune(currentTime)
    return inserted
end

Feedback.PushResult = Feedback.Push

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
    if progress < 0.14 then
        alpha = progress / 0.14
    elseif progress > 0.76 then
        alpha = (1 - progress) / 0.24
    end
    record.progress = progress
    record.alpha = math.max(0, math.min(1, alpha))
    return record
end

function Feedback.IsActive(npcID, at)
    return Feedback.Get(npcID, at) ~= nil
end

function Feedback.Reset(npcID)
    if npcID == nil then
        for id, _ in pairs(records) do records[id] = nil end
        for key, _ in pairs(seenResults) do seenResults[key] = nil end
        return true
    end
    npcID = tostring(npcID)
    records[npcID] = nil
    return true
end

return Feedback
