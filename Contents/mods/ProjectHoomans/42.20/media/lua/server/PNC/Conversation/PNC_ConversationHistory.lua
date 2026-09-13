-- Compact server-authoritative repeat/cooldown history.
if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local History = PNC.Conversation.History or {}
PNC.Conversation.History = History
local Reset = (PNC.Persistence and PNC.Persistence.Reset)
    or require "PNC/Core/Persistence/PNC_Persistence/PNC_Persistence_Reset"
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
    local raw = Reset.Read(History.MODDATA_KEY)
    local reason = Reset.Check(raw, History.VERSION, "version",
        function(value) return type(value.entries) == "table" end)
    History.Registry = {
        version = History.VERSION,
        entries = reason == nil and copy(raw.entries) or {},
    }
    History.Loaded = true
    History.Dirty = reason ~= nil and reason ~= "empty_state"
    if History.Dirty then
        Reset.Mark(History, raw, History.VERSION, reason,
            "conversation_history", "version")
    end
    return true
end

function History.EnsureLoaded()
    if not History.Loaded then History.Load() end
    return true
end

function History.Save(flush)
    History.EnsureLoaded()
    if not History.Dirty then return false, "not_dirty" end
    local written = Reset.Write(History.MODDATA_KEY, {
        version = History.VERSION,
        entries = copy(History.Registry.entries),
    })
    if not written then return false, "moddata_unavailable" end
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
