-- Client presentation diary for player/NPC conversation exchanges.
-- Authoritative relationship deltas are copied from server results; this is
-- only a bounded UI journal and never a second relationship store.

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local Diary = PNC.Conversation.Diary or {}
PNC.Conversation.Diary = Diary
Diary.MAX_ENTRIES = 80

local function state()
    PNC.Network = PNC.Network or {}
    PNC.Network.ClientState = PNC.Network.ClientState or {}
    return PNC.Network.ClientState
end

local function copy(value)
    if type(value) ~= "table" then return value end
    local output = {}
    for key, child in pairs(value) do output[key] = copy(child) end
    return output
end

function Diary.Append(npcID, entry)
    npcID = tostring(npcID or "")
    if npcID == "" or type(entry) ~= "table" then return false end
    local clientState = state()
    clientState.conversationDiary = clientState.conversationDiary or {}
    clientState.conversationDiary[npcID] =
        clientState.conversationDiary[npcID] or {}
    local entries = clientState.conversationDiary[npcID]
    local record = copy(entry)
    record.npcID = npcID
    record.at = record.at or (PNC.Core and PNC.Core.Now
        and PNC.Core.Now() or 0)
    entries[#entries + 1] = record
    while #entries > Diary.MAX_ENTRIES do table.remove(entries, 1) end
    clientState.conversationDiaryRevision =
        (tonumber(clientState.conversationDiaryRevision) or 0) + 1
    return true
end

function Diary.Get(npcID)
    local clientState = state()
    local entries = clientState.conversationDiary
        and clientState.conversationDiary[tostring(npcID or "")] or nil
    return entries or {}
end

function Diary.Clear(npcID)
    local clientState = state()
    if npcID == nil then
        clientState.conversationDiary = {}
    else
        clientState.conversationDiary[tostring(npcID)] = nil
    end
    clientState.conversationDiaryRevision =
        (tonumber(clientState.conversationDiaryRevision) or 0) + 1
    return true
end

return Diary
