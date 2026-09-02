require "PsychopatzCore/Conversation/PsychopatzConversationMessage"
require "PsychopatzCore/Events/PC_EventBus"
require "PsychopatzCore/UI/Conversation/PsychopatzConversationTyping"
require "PsychopatzCore/Text/PsychopatzMarkdown"

PNC = PNC or {}
PNC.NameplateSpeech = PNC.NameplateSpeech or {}

local Speech = PNC.NameplateSpeech
local Message = PsychopatzCore.Conversation.Message
local Events = PsychopatzCore.Events
local Typing = PsychopatzCore.Conversation.Typing
local Markdown = PsychopatzCore.Markdown

Speech.MAX_PREVIEW_LENGTH = 180
Speech.MIN_DURATION_MS = 4500
Speech.MAX_DURATION_MS = 12000

local OWNER_TOKEN = Speech
local records = Speech.records or {}
Speech.records = records
local observedDay = Speech.observedDay

local function now()
    return getTimeInMillis and tonumber(getTimeInMillis()) or 0
end

local function compactText(value)
    value = tostring(value or "")
    value = string.gsub(value, "[\r\n]+", " ")
    value = string.gsub(value, "%s+", " ")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    return value
end

local function preview(value)
    value = compactText(value)
    if #value <= Speech.MAX_PREVIEW_LENGTH then return value end
    return string.sub(value, 1, Speech.MAX_PREVIEW_LENGTH - 1) .. "…"
end

local function durationFor(value)
    local duration = 2200 + (#compactText(value) * 28)
    return math.max(
        Speech.MIN_DURATION_MS,
        math.min(Speech.MAX_DURATION_MS, duration)
    )
end

local function activeConversationOwns(message)
    local conversation = PsychopatzCore and PsychopatzCore.Conversation
    local view = conversation and conversation.instance or nil
    local session = view and view.session or nil
    return session and tostring(session.conversationID or "")
        == tostring(message and message.conversationID or "")
end

local function activeConversationOwnsSpeaker(message)
    local conversation = PsychopatzCore and PsychopatzCore.Conversation
    local view = conversation and conversation.instance or nil
    local npcID = view and view.spec and view.spec.npcID or nil
    return view and tostring(npcID or "")
        == tostring(message and message.speakerID or "")
end

local function clearExpiredDay()
    local day = Message.GetGameDay()
    if observedDay == nil then
        observedDay = day
        Speech.observedDay = day
        return
    end
    if observedDay == day then return end
    observedDay = day
    Speech.observedDay = day
    for npcID, _ in pairs(records) do records[npcID] = nil end
end

local function onMessage(message)
    if type(message) ~= "table"
        or tostring(message.speakerKind or message.speaker or "") ~= "npc"
    then
        return
    end
    local npcID = tostring(message.speakerID or "")
    local text = compactText(message.text)
    if npcID == "" or text == "" then return end
    local presentation = message.presentationState
    if type(presentation) == "table" and presentation.nameplate == false
        and activeConversationOwnsSpeaker(message)
    then
        return
    end
    clearExpiredDay()
    records[npcID] = {
        message = message,
        text = preview(text),
        expiresAt = now() + durationFor(text),
    }
end

function Speech.Get(npcID)
    clearExpiredDay()
    npcID = tostring(npcID or "")
    local record = records[npcID]
    if not record then return nil end
    if not record.pending
        and now() >= (tonumber(record.expiresAt) or 0)
    then
        records[npcID] = nil
        return nil
    end
    if activeConversationOwns(record.message)
        or activeConversationOwnsSpeaker(record.message)
    then
        return nil
    end
    return record
end

function Speech.GetDisplayText(record)
    if record and record.pending then return Typing.GetText() end
    if not record then return "" end
    if record.displayText == nil then
        local source = record.message and record.message.text or record.text
        record.displayText = preview(Markdown.ToSingleLine(source))
    end
    return record.displayText or ""
end

function Speech.SetPending(npcID, requestID, conversationID)
    npcID = tostring(npcID or "")
    if npcID == "" then return false end
    records[npcID] = {
        pending = true,
        requestID = tostring(requestID or ""),
        message = {
            conversationID = conversationID,
            speakerID = npcID,
            speakerKind = "npc",
        },
        text = "",
        startedAt = now(),
    }
    return true
end

function Speech.ClearPending(npcID, requestID)
    npcID = tostring(npcID or "")
    local record = records[npcID]
    if not record or record.pending ~= true then return false end
    if requestID ~= nil
        and tostring(record.requestID or "") ~= tostring(requestID)
    then
        return false
    end
    records[npcID] = nil
    return true
end

function Speech.Clear(npcID)
    if npcID == nil then
        for id, _ in pairs(records) do records[id] = nil end
        return true
    end
    npcID = tostring(npcID)
    records[npcID] = nil
    return true
end

Events.clearOwner(OWNER_TOKEN)
Events.subscribe(Message.EVENT_TYPE, onMessage, OWNER_TOKEN)

return Speech
