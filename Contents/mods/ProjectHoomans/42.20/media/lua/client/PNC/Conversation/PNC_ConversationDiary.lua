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

local function npcName(npcID, entry)
    local stateValue = state()
    local snapshot = stateValue.snapshots
        and stateValue.snapshots[tostring(npcID or "")] or nil
    local identity = PNC.NPCIdentityPresentation
    if identity and identity.GetName then
        return identity.GetName(snapshot or { id = npcID })
    end
    return tostring(entry and entry.npcName
        or snapshot and (snapshot.name or snapshot.displayName)
        or "Companion")
end

local function flavorContext(npcID, entry)
    local name = npcName(npcID, entry)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    return {
        name = name,
        names = name,
        count = 1,
        player = tostring(player and player.getUsername
            and player:getUsername() or "Survivor"),
    }
end

local function resolveFlavor(npcID, entry, flavorID, speaker)
    local flavor = PNC.CompanionCommandFlavor
    if not flavor or not flavor.Resolve or not flavorID then return nil end
    return flavor.Resolve(
        flavorID,
        speaker,
        entry.eventID,
        flavorContext(npcID, entry)
    )
end

local function resolveConversationText(entry, key)
    local conversation = PNC.Conversation
    local registry = conversation and conversation.Registry
    local loader = conversation and conversation.TextLoader
    local text = PsychopatzCore and PsychopatzCore.Conversation
        and PsychopatzCore.Conversation.Text or nil
    local block = registry and registry.GetBlock
        and registry.GetBlock(entry.blockID) or nil
    local source = block and block.textSource or nil
    local payload
    if not key or not source or not loader or not loader.Payload
        or not text or not text.Resolve
    then
        return nil
    end
    if loader.EnsureSource then loader.EnsureSource(source, { key }) end
    payload = loader.Payload(source, key, {})
    return text.Resolve(payload)
end

local function enrich(npcID, value)
    local entry = copy(value)
    if not entry.playerText then
        entry.playerText = resolveFlavor(
            npcID, entry, entry.playerFlavorID, "player"
        ) or resolveConversationText(entry, entry.playerTextKey)
    end
    if not entry.npcText then
        entry.npcText = resolveFlavor(
            npcID, entry, entry.npcFlavorID, "npc"
        ) or resolveConversationText(entry, entry.npcTextKey
            or entry.responseKey)
    end
    entry.npcID = tostring(npcID or entry.npcID or "")
    return entry
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
    clientState.conversationDiaryRevisions =
        clientState.conversationDiaryRevisions or {}
    clientState.conversationDiaryRevisions[npcID] = math.max(
        tonumber(clientState.conversationDiaryRevisions[npcID]) or 0,
        tonumber(record.sequence) or 0
    )
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

-- Replace the client cache with the server's persisted pair journal. The
-- relationship service remains authoritative; this is only the UI hydration
-- boundary used after restart, reconnect, or a fresh character-window open.
function Diary.Hydrate(npcID, entries, interactionRevision)
    npcID = tostring(npcID or "")
    if npcID == "" or type(entries) ~= "table" then return false end
    local clientState = state()
    clientState.conversationDiary = clientState.conversationDiary or {}
    clientState.conversationDiaryRevisions =
        clientState.conversationDiaryRevisions or {}
    local incomingRevision = tonumber(interactionRevision) or 0
    local currentRevision = tonumber(
        clientState.conversationDiaryRevisions[npcID]
    ) or 0
    if incomingRevision < currentRevision then return false end
    local hydrated = {}
    local index
    for index = 1, #entries do
        hydrated[#hydrated + 1] = enrich(npcID, entries[index])
    end
    while #hydrated > Diary.MAX_ENTRIES do
        table.remove(hydrated, 1)
    end
    clientState.conversationDiary[npcID] = hydrated
    clientState.conversationDiaryRevisions[npcID] = incomingRevision
    clientState.conversationDiaryRevision =
        (tonumber(clientState.conversationDiaryRevision) or 0) + 1
    return true
end

function Diary.Clear(npcID)
    local clientState = state()
    if npcID == nil then
        clientState.conversationDiary = {}
        clientState.conversationDiaryRevisions = {}
    else
        clientState.conversationDiary[tostring(npcID)] = nil
        if clientState.conversationDiaryRevisions then
            clientState.conversationDiaryRevisions[tostring(npcID)] = nil
        end
    end
    clientState.conversationDiaryRevision =
        (tonumber(clientState.conversationDiaryRevision) or 0) + 1
    return true
end

return Diary
