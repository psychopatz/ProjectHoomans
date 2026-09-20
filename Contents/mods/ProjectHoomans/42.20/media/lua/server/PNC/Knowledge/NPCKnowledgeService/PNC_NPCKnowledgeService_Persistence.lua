if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.NPCKnowledge = PNC.NPCKnowledge or {}
PNC.NPCKnowledge.Internal = PNC.NPCKnowledge.Internal or {}

local Knowledge = PNC.NPCKnowledge
local Internal = Knowledge.Internal
local Core = PNC.Core
local Registry = PNC.Registry
local PlayerCharacters = PNC.PlayerCharacters
local Relationships = PNC.Relationships
local EntityRef = PNC.EntityRef
local Definitions = PNC.KnowledgeDescriptors
local Providers = PNC.KnowledgeProviders
local Resolvers = PNC.KnowledgeResolvers
local Sources = PNC.KnowledgeEvidenceSources
local Shared = PNC.KnowledgeRegistry
local Reset = (PNC.Persistence and PNC.Persistence.Reset)
    or require "PNC/Core/Persistence/PNC_Persistence/PNC_Persistence_Reset"
local deepCopy = Internal.deepCopy
local safeString = Internal.safeString
local now = Internal.now
local normalizeNote = Internal.normalizeNote
local normalizeGiftPreference = Internal.normalizeGiftPreference
local MAX_GIFT_PREFERENCES = Internal.MAX_GIFT_PREFERENCES or 256
local KEY = Internal.KEY

function Knowledge.Load()
    local raw = Reset.Read(KEY)
    local reason = Reset.Check(raw, Internal.SCHEMA, nil,
        function(value) return type(value.byCharacter) == "table" end)
    Knowledge.Registry = Knowledge.NormalizeRegistry(reason == nil and raw or nil)
    Knowledge.Loaded = true
    Knowledge.Dirty = reason ~= nil and reason ~= "empty_state"
    if Knowledge.Dirty then
        Reset.Mark(Knowledge, raw, Internal.SCHEMA, reason,
            "npc_knowledge")
    end
    return true
end

function Knowledge.EnsureLoaded()
    if not Knowledge.Loaded then Knowledge.Load() end
    return true
end

function Knowledge.Save(flushGlobal)
    Knowledge.EnsureLoaded()
    if not Knowledge.Dirty then return false, "not_dirty" end
    local written = Reset.Write(KEY, deepCopy(Knowledge.Registry))
    if not written then return false, "moddata_unavailable" end
    if flushGlobal ~= false and GlobalModData and GlobalModData.save then
        GlobalModData.save()
    end
    Knowledge.Dirty = false
    return true
end

local function markDirty(note)
    note.revision = (tonumber(note.revision) or 0) + 1
    Knowledge.Registry.revision = (tonumber(Knowledge.Registry.revision) or 0) + 1
    Knowledge.Dirty = true
end

local function mutableNote(characterUUID, npcID, create, at)
    Knowledge.EnsureLoaded()
    characterUUID, npcID = safeString(characterUUID, 128), safeString(npcID, 128)
    if not characterUUID or not npcID then return nil, "invalid_identity" end
    local character = Knowledge.Registry.byCharacter[characterUUID]
    if not character and create then
        character = { byNPC = {} }
        Knowledge.Registry.byCharacter[characterUUID] = character
    end
    local note = character and character.byNPC[npcID] or nil
    if not note and create then
        note = normalizeNote({ firstMetAt = at, lastInteractionAt = at }, npcID)
        character.byNPC[npcID] = note
        markDirty(note)
    end
    return note, note and nil or "note_not_found"
end

function Knowledge.Get(characterUUID, npcID)
    local note = mutableNote(characterUUID, npcID, false)
    return note and deepCopy(note) or nil
end

function Knowledge.GetGiftPreference(characterUUID, npcID, itemType)
    local fullType = safeString(itemType, 160)
    if not fullType then return nil end
    local note = mutableNote(characterUUID, npcID, false)
    local preference = note and note.giftPreferences
        and note.giftPreferences[fullType] or nil
    return preference and deepCopy(preference) or nil
end

function Knowledge.RecordGiftPreferences(
    characterUUID, npcID, preferences, sourceType, sourceEventID, at
)
    if sourceType ~= "gift_reaction"
        and sourceType ~= "direct_disclosure"
    then
        return false, "invalid_gift_preference_source"
    end
    if type(preferences) ~= "table" then
        return false, "invalid_gift_preferences"
    end
    local note, reason = mutableNote(
        characterUUID, npcID, true, now(at)
    )
    if not note then return false, reason end
    note.giftPreferences = note.giftPreferences or {}
    local changed = false
    for itemType, value in pairs(preferences) do
        local disposition = type(value) == "table"
            and value.disposition or value
        local normalized = normalizeGiftPreference(itemType, {
            disposition = disposition,
            sourceType = sourceType,
            sourceEventID = sourceEventID,
            createdAt = at,
        })
        local existing = normalized
            and note.giftPreferences[normalized.fullType] or nil
        if normalized and (not existing
            or existing.disposition ~= normalized.disposition)
        then
            note.giftPreferences[normalized.fullType] = normalized
            changed = true
        end
    end
    if not changed then return false end
    local entries = {}
    for itemType, preference in pairs(note.giftPreferences) do
        entries[#entries + 1] = {
            fullType = itemType,
            createdAt = tonumber(preference.createdAt) or 0,
        }
    end
    if #entries > MAX_GIFT_PREFERENCES then
        table.sort(entries, function(left, right)
            if left.createdAt ~= right.createdAt then
                return left.createdAt < right.createdAt
            end
            return left.fullType < right.fullType
        end)
        for index = 1, #entries - MAX_GIFT_PREFERENCES do
            note.giftPreferences[entries[index].fullType] = nil
        end
    end
    note.lastInteractionAt = now(at)
    markDirty(note)
    return true
end

function Knowledge.GetDescriptor(characterUUID, npcID, descriptorID)
    local note = mutableNote(characterUUID, npcID, false)
    return note and deepCopy(note.discovered[tostring(descriptorID or "")]) or nil
end

function Knowledge.GetKnownDescriptors(characterUUID, npcID)
    local note = mutableNote(characterUUID, npcID, false)
    local output = {}
    if not note then return output end
    for descriptorID, fact in pairs(note.discovered) do
        if Definitions.Get(descriptorID) then output[#output + 1] = deepCopy(fact) end
    end
    table.sort(output, function(a, b) return a.descriptorID < b.descriptorID end)
    return output
end


Internal.markDirty = markDirty
Internal.mutableNote = mutableNote

return Knowledge
