-- Compact server-authoritative repeat/cooldown history.
if isClient and isClient() and (not isServer or not isServer()) then return end

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local History = PNC.Conversation.History or {}
PNC.Conversation.History = History
History.MODDATA_KEY = "PNC_ConversationHistory"
History.VERSION = 1
History.Registry = History.Registry or { version = History.VERSION, entries = {} }
History.Loaded = History.Loaded == true
History.Dirty = History.Dirty == true

local function copy(value)
    if type(value) ~= "table" then return value end
    local output = {}
    for key, child in pairs(value) do output[key] = copy(child) end
    return output
end

local function safe(value)
    value = tostring(value or "")
    value = string.gsub(value, "[^%w_.:@/-]", "_")
    return value
end

function History.BuildKey(scope, characterUUID, npcID, subjectID)
    scope = scope or "pair"
    if scope == "character" then
        return table.concat({ "character", safe(characterUUID), safe(subjectID) }, "|")
    end
    if scope == "npc" then
        return table.concat({ "npc", safe(npcID), safe(subjectID) }, "|")
    end
    if scope == "world" then
        return table.concat({ "world", safe(subjectID) }, "|")
    end
    return table.concat({
        "pair", safe(characterUUID), safe(npcID), safe(subjectID),
    }, "|")
end

function History.Load()
    local raw = ModData and ModData.getOrCreate
        and ModData.getOrCreate(History.MODDATA_KEY) or nil
    raw = type(raw) == "table" and raw or {}
    History.Registry = {
        version = History.VERSION,
        entries = type(raw.entries) == "table" and copy(raw.entries) or {},
    }
    History.Loaded = true
    History.Dirty = false
    return true
end

function History.EnsureLoaded()
    if not History.Loaded then History.Load() end
    return true
end

function History.Save(flush)
    History.EnsureLoaded()
    if not History.Dirty then return false, "not_dirty" end
    local target = ModData and ModData.getOrCreate
        and ModData.getOrCreate(History.MODDATA_KEY) or nil
    if type(target) ~= "table" then return false end
    target.version = History.VERSION
    target.entries = copy(History.Registry.entries)
    if flush ~= false and GlobalModData and GlobalModData.save then
        GlobalModData.save()
    end
    History.Dirty = false
    return true
end

function History.Get(subjectID, policy, context)
    History.EnsureLoaded()
    context = type(context) == "table" and context or {}
    local key = History.BuildKey(
        policy and policy.scope,
        context.characterUUID,
        context.npcID,
        subjectID
    )
    local entry = History.Registry.entries[key]
    return entry and copy(entry) or nil, key
end

function History.Check(subjectID, policy, context)
    local entry = History.Get(subjectID, policy, context)
    return PNC.Conversation.Rules.CheckRepeat(
        policy,
        entry,
        context and context.worldAgeHours
    )
end

function History.Commit(subjectID, policy, context, outcomeID)
    History.EnsureLoaded()
    context = type(context) == "table" and context or {}
    local _, key = History.Get(subjectID, policy, context)
    local entry = History.Registry.entries[key] or { useCount = 0 }
    entry.useCount = math.max(0, tonumber(entry.useCount) or 0) + 1
    entry.lastUsedWorldHour = math.max(0, tonumber(context.worldAgeHours) or 0)
    entry.lastOutcomeID = outcomeID and tostring(outcomeID) or nil
    History.Registry.entries[key] = entry
    History.Dirty = true
    return copy(entry)
end

function History.Clone()
    History.EnsureLoaded()
    return copy(History.Registry)
end

if Events and Events.OnInitGlobalModData and not History.InitHookRegistered then
    Events.OnInitGlobalModData.Add(function() History.Load() end)
    History.InitHookRegistered = true
end
return History
