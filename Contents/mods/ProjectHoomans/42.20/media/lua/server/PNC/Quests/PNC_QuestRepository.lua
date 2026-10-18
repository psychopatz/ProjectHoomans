-- Compact authoritative quest instances. Native objects, transcripts, and
-- inventories are deliberately excluded from ModData.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.QuestRepository = PNC.QuestRepository or {}

local Repository = PNC.QuestRepository
local Core = PNC.Core
local Reset = (PNC.Persistence and PNC.Persistence.Reset)
    or require "PNC/Core/Persistence/PNC_Persistence/PNC_Persistence_Reset"
local Definitions = PNC.QuestDefinitions
    or require "PNC/Quests/PNC_QuestDefinitions"

Repository.SCHEMA_VERSION = 1
Repository.MODDATA_KEY = "PNC_QuestInstances_V1"
Repository.STATUS = {
    ACTIVE = "ACTIVE",
    READY_TO_TURN_IN = "READY_TO_TURN_IN",
    COMPLETED = "COMPLETED",
    REWARDED = "REWARDED",
    FAILED = "FAILED",
    EXPIRED = "EXPIRED",
    ABANDONED = "ABANDONED",
    QUARANTINED = "QUARANTINED",
}
Repository.TERMINAL = {
    REWARDED = true,
    FAILED = true,
    EXPIRED = true,
    ABANDONED = true,
    QUARANTINED = true,
}
Repository.State = Repository.State or {
    schemaVersion = Repository.SCHEMA_VERSION,
    nextId = 1,
    byKey = {},
}
Repository.Loaded = Repository.Loaded == true
Repository.Dirty = Repository.Dirty == true

local function copy(value)
    return Core and Core.DeepCopy and Core.DeepCopy(value) or value
end

local function text(value)
    value = tostring(value or "")
    return value ~= "" and value or nil
end

local function numberOr(value, fallback)
    local number = tonumber(value)
    return number == nil and fallback or number
end

local function definitionFor(questID)
    return Definitions and Definitions.Get
        and Definitions.Get(questID) or nil
end

local function normalizeObjective(raw, definition)
    local source = type(raw) == "table" and raw or {}
    local expected = definition and definition.objective or {}
    return {
        id = text(source.id) or text(expected.id) or "objective",
        required = math.max(1, math.floor(numberOr(
            source.required, expected.quantity or 1))),
        delivered = math.max(0, math.floor(numberOr(source.delivered, 0))),
        itemFullType = text(source.itemFullType)
            or text(expected.itemFullType),
        direction = text(source.direction) or text(expected.direction),
        lastEventID = text(source.lastEventID),
    }
end

local function normalize(raw, key)
    if type(raw) ~= "table" then return nil end
    local questID = text(raw.questID)
    local characterUUID = text(raw.ownerCharacterUUID)
    local giverNPCID = text(raw.giverNPCID)
    local definition = definitionFor(questID)
    if not questID or not characterUUID or not giverNPCID then return nil end
    local status = tostring(raw.status or Repository.STATUS.ACTIVE)
    if not Repository.STATUS[status] then status = Repository.STATUS.QUARANTINED end
    if not definition then status = Repository.STATUS.QUARANTINED end
    local objective = normalizeObjective(raw.objective, definition)
    return {
        schemaVersion = Repository.SCHEMA_VERSION,
        id = text(raw.id) or tostring(key or ""),
        scopeKey = text(raw.scopeKey) or table.concat({
            characterUUID, questID, giverNPCID,
        }, "\31"),
        questID = questID,
        definitionVersion = math.max(1, math.floor(numberOr(
            raw.definitionVersion, definition and definition.version or 1))),
        ownerCharacterUUID = characterUUID,
        giverNPCID = giverNPCID,
        status = status,
        revision = math.max(0, math.floor(numberOr(raw.revision, 0))),
        objective = objective,
        sourceTaskID = text(raw.sourceTaskID),
        sourceRequestID = text(raw.sourceRequestID),
        acceptedAt = numberOr(raw.acceptedAt, 0),
        updatedAt = numberOr(raw.updatedAt, 0),
        completedAt = numberOr(raw.completedAt, 0),
        rewardID = text(raw.rewardID),
        rewardClaimed = raw.rewardClaimed == true,
        rewardClaimedAt = numberOr(raw.rewardClaimedAt, 0),
        failureReason = text(raw.failureReason),
    }
end

function Repository.Import(raw)
    local state = {
        schemaVersion = Repository.SCHEMA_VERSION,
        nextId = 1,
        byKey = {},
    }
    if type(raw) == "table"
        and tonumber(raw.schemaVersion) == Repository.SCHEMA_VERSION
    then
        state.nextId = math.max(1, math.floor(numberOr(raw.nextId, 1)))
        for key, value in pairs(raw.byKey or {}) do
            local instance = normalize(value, key)
            if instance then state.byKey[instance.scopeKey] = instance end
        end
    end
    Repository.State = state
    Repository.Loaded = true
    Repository.Dirty = false
    return state
end

function Repository.Load(force)
    if Repository.Loaded and force ~= true then return Repository.State end
    local raw = Reset.Read(Repository.MODDATA_KEY)
    local reason = Reset.Check(raw, Repository.SCHEMA_VERSION, nil,
        function(value) return type(value.byKey) == "table" end)
    Repository.Import(reason == nil and raw or nil)
    if reason ~= nil and reason ~= "empty_state" then
        Reset.Mark(Repository, raw, Repository.SCHEMA_VERSION, reason, "quest")
    else
        Repository.Dirty = false
    end
    return Repository.State
end

function Repository.NextId()
    Repository.Load()
    local id = "quest:" .. tostring(Repository.State.nextId)
    Repository.State.nextId = Repository.State.nextId + 1
    Repository.Dirty = true
    return id
end

function Repository.Get(scopeKey)
    Repository.Load()
    return Repository.State.byKey[tostring(scopeKey or "")]
end

function Repository.Put(instance)
    Repository.Load()
    local normalized = normalize(instance, instance and instance.scopeKey)
    if not normalized then return false, "INVALID_QUEST_INSTANCE" end
    Repository.State.byKey[normalized.scopeKey] = normalized
    Repository.Dirty = true
    return normalized
end

function Repository.Remove(scopeKey)
    Repository.Load()
    scopeKey = tostring(scopeKey or "")
    if not Repository.State.byKey[scopeKey] then return false end
    Repository.State.byKey[scopeKey] = nil
    Repository.Dirty = true
    return true
end

function Repository.Save()
    Repository.Load()
    if not Repository.Dirty then return false, "not_dirty" end
    local payload = copy(Repository.State)
    local written = Reset.Write(Repository.MODDATA_KEY, payload)
    if not written then return false, "moddata_unavailable" end
    Repository.Dirty = false
    return true, "saved"
end

if Events and Events.OnInitGlobalModData and not Repository.LoadHookRegistered then
    Events.OnInitGlobalModData.Add(function() Repository.Load(true) end)
    Repository.LoadHookRegistered = true
end

return Repository
