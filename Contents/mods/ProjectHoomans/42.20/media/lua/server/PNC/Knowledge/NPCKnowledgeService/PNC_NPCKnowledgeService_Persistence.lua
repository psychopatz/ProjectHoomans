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
local deepCopy = Internal.deepCopy
local safeString = Internal.safeString
local normalizeNote = Internal.normalizeNote
local KEY = Internal.KEY

function Knowledge.Load()
    local raw = ModData and ModData.getOrCreate and ModData.getOrCreate(KEY) or {}
    Knowledge.Registry = Knowledge.NormalizeRegistry(raw)
    Knowledge.Loaded = true
    return true
end

function Knowledge.EnsureLoaded()
    if not Knowledge.Loaded then Knowledge.Load() end
    return true
end

function Knowledge.Save(flushGlobal)
    Knowledge.EnsureLoaded()
    if not Knowledge.Dirty then return false, "not_dirty" end
    local target = ModData and ModData.getOrCreate and ModData.getOrCreate(KEY) or nil
    if not target then return false, "moddata_unavailable" end
    for key in pairs(target) do target[key] = nil end
    for key, value in pairs(Knowledge.Registry) do target[key] = deepCopy(value) end
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
