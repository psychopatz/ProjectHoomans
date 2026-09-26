-- Server-authoritative persistence for the cross-provider relation policy.
-- Only bounded, normalized stance and conflict data is written to ModData.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.Compatibility = PNC.Compatibility or {}

local Policy = PNC.Compatibility.ProjectALifePolicy
if not Policy then return false end

local Reset = (PNC.Persistence and PNC.Persistence.Reset)
    or require "PNC/Core/Persistence/PNC_Persistence/PNC_Persistence_Reset"

local MODDATA_KEY = "PNC_ProjectALifeRelations"
local SCHEMA_VERSION = 1
local MAX_RELATIONS = 512
local MAX_CONFLICTS = 128

local VALID_RELATIONS = {
    friendly = true,
    neutral = true,
    careful = true,
    hostile = true,
}

Policy.RELATION_MODDATA_KEY = MODDATA_KEY
Policy.RELATION_SCHEMA_VERSION = SCHEMA_VERSION
Policy.Loaded = Policy.Loaded or false
Policy.Dirty = Policy.Dirty or false

local function normalizeRelation(value)
    value = string.lower(tostring(value or "neutral"))
    return VALID_RELATIONS[value] and value or "neutral"
end

local function normalizeRelations(raw)
    local source = type(raw) == "table" and raw or {}
    local normalized = {}
    local changed = type(raw) ~= "table"
    local count = 0

    for key, value in pairs(source) do
        local normalizedKey = tostring(key or "")
        local normalizedValue = normalizeRelation(value)
        if normalizedKey ~= "" and VALID_RELATIONS[normalizedValue]
            and count < MAX_RELATIONS
        then
            count = count + 1
            normalized[normalizedKey] = normalizedValue
            if normalizedKey ~= key or normalizedValue ~= value then
                changed = true
            end
        else
            changed = true
        end
    end

    return normalized, changed
end

local function normalizeConflict(entry)
    if type(entry) ~= "table" then return nil end

    local sourceProvider = tostring(entry.sourceProvider or "")
    local targetProvider = tostring(entry.targetProvider or "")
    if sourceProvider == "" or targetProvider == "" then return nil end

    local sourceFaction = tostring(entry.sourceFaction or "*")
    local targetFaction = tostring(entry.targetFaction or "*")
    if sourceFaction == "" then sourceFaction = "*" end
    if targetFaction == "" then targetFaction = "*" end

    return {
        id = tostring(entry.id or ""),
        sourceProvider = sourceProvider,
        sourceFaction = sourceFaction,
        targetProvider = targetProvider,
        targetFaction = targetFaction,
        reason = tostring(entry.reason or "confirmed_damage"),
        atMs = math.max(0, tonumber(entry.atMs) or 0),
    }
end

local function normalizeConflicts(raw)
    local source = type(raw) == "table" and raw or {}
    local normalized = {}
    local changed = type(raw) ~= "table"

    for index, entry in ipairs(source) do
        local normalizedEntry = normalizeConflict(entry)
        if normalizedEntry and #normalized < MAX_CONFLICTS then
            normalized[#normalized + 1] = normalizedEntry
            if normalizedEntry.id ~= tostring(entry.id or "")
                or normalizedEntry.sourceProvider
                    ~= tostring(entry.sourceProvider or "")
                or normalizedEntry.sourceFaction
                    ~= tostring(entry.sourceFaction or "*")
                or normalizedEntry.targetProvider
                    ~= tostring(entry.targetProvider or "")
                or normalizedEntry.targetFaction
                    ~= tostring(entry.targetFaction or "*")
                or normalizedEntry.reason ~= tostring(
                    entry.reason or "confirmed_damage")
                or normalizedEntry.atMs ~= math.max(0, tonumber(entry.atMs) or 0)
            then
                changed = true
            end
        else
            changed = true
        end
    end

    if #normalized ~= #source then changed = true end
    return normalized, changed
end

local function normalizeData(value)
    local source = type(value) == "table" and value or {}
    local relations, relationsChanged = normalizeRelations(source.relations)
    local conflicts, conflictsChanged = normalizeConflicts(source.conflicts)
    local sequence = math.max(0, math.floor(
        tonumber(source.conflictSequence) or 0
    ))
    local sequenceChanged = sequence ~= (tonumber(source.conflictSequence) or 0)

    return {
        schemaVersion = SCHEMA_VERSION,
        relations = relations,
        conflicts = conflicts,
        conflictSequence = math.max(sequence, #conflicts),
    }, relationsChanged or conflictsChanged or sequenceChanged
end

function Policy.Load()
    if Policy.Loaded then return true end

    local raw = Reset.Read(MODDATA_KEY)
    local reason = Reset.Check(raw, SCHEMA_VERSION, nil, function(value)
        return type(value.relations) == "table"
            and type(value.conflicts) == "table"
    end)
    local source = raw

    -- Preserve code-configured defaults on a first run. Invalid persisted
    -- state is reset to an empty normalized store by the reset contract.
    if reason == "empty_state" then
        source = {
            relations = Policy.relations,
            conflicts = Policy.conflicts,
            conflictSequence = Policy.conflictSequence,
        }
    elseif reason ~= nil then
        source = nil
    end

    local normalized, changed = normalizeData(source)
    Policy.relations = normalized.relations
    Policy.conflicts = normalized.conflicts
    Policy.conflictSequence = normalized.conflictSequence
    Policy.Loaded = true
    Policy.Dirty = (reason ~= nil and reason ~= "empty_state") or changed

    if reason ~= nil and reason ~= "empty_state" then
        Reset.Mark(Policy, raw, SCHEMA_VERSION, reason,
            "projectalife_relations")
    end
    return true
end

function Policy.EnsureLoaded()
    if not Policy.Loaded then return Policy.Load() end
    return true
end

function Policy.Save(flushGlobal)
    Policy.EnsureLoaded()
    if not Policy.Dirty then return false, "not_dirty" end

    local normalized = normalizeData({
        relations = Policy.relations,
        conflicts = Policy.conflicts,
        conflictSequence = Policy.conflictSequence,
    })
    local written, reason = Reset.Write(MODDATA_KEY, normalized)
    if not written then return false, reason or "moddata_unavailable" end

    Policy.relations = normalized.relations
    Policy.conflicts = normalized.conflicts
    Policy.conflictSequence = normalized.conflictSequence
    Policy.Dirty = false

    if flushGlobal ~= false and GlobalModData and GlobalModData.save then
        local ok, saveError = pcall(GlobalModData.save)
        if not ok then
            Policy.Dirty = true
            return false, tostring(saveError)
        end
    end
    return true, "saved"
end

if Events and Events.OnInitGlobalModData
    and not Policy.RelationLoadHookRegistered
then
    Events.OnInitGlobalModData.Add(function() Policy.Load() end)
    Policy.RelationLoadHookRegistered = true
end

return Policy
