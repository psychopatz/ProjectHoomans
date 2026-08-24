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
local now = Internal.now
local deepCopy = Internal.deepCopy
local markDirty = Internal.markDirty
local mutableNote = Internal.mutableNote
local MAX_EVIDENCE_PER_NPC = Internal.MAX_EVIDENCE_PER_NPC
local MAX_EVIDENCE_PER_DESCRIPTOR = Internal.MAX_EVIDENCE_PER_DESCRIPTOR

local function familiarity(characterUUID, npcID)
    local character = PlayerCharacters and PlayerCharacters.GetRegistryRecord and PlayerCharacters.GetRegistryRecord(characterUUID) or nil
    local key = character and character.accountKey
        and EntityRef.ForPlayerIdentity(character.accountKey, characterUUID) or nil
    local relationship = key and Relationships and Relationships.Get and Relationships.Get(npcID, key) or nil
    return tonumber(relationship and relationship.familiarity) or 0, tonumber(relationship and relationship.approval) or 0
end

local function evidenceFor(note, descriptorID)
    local output = {}
    for _, entry in ipairs(note.evidence) do
        if entry.descriptorID == descriptorID then output[#output + 1] = entry end
    end
    return output
end

local function pruneEvidence(note)
    local function priority(entry)
        local source = Sources.Get(entry.sourceType) or {}
        return (source.mayConfirm and 100 or 0) + (tonumber(entry.strength) or 0) * 10 + (tonumber(entry.createdAt) or 0) / 1000000000
    end
    local function prune(predicate, limit)
        local entries = {}
        for index, entry in ipairs(note.evidence) do if predicate(entry) then entries[#entries + 1] = { index = index, entry = entry } end end
        table.sort(entries, function(a, b)
            local pa, pb = priority(a.entry), priority(b.entry)
            if pa == pb then return tostring(a.entry.id) < tostring(b.entry.id) end
            return pa < pb
        end)
        local remove = #entries - limit
        if remove <= 0 then return end
        local ids = {}
        for index = 1, remove do ids[entries[index].entry.id] = true end
        local kept = {}
        for _, entry in ipairs(note.evidence) do if not ids[entry.id] then kept[#kept + 1] = entry end end
        note.evidence = kept
    end
    local descriptorIDs = {}
    for _, entry in ipairs(note.evidence) do descriptorIDs[entry.descriptorID] = true end
    for descriptorID in pairs(descriptorIDs) do prune(function(entry) return entry.descriptorID == descriptorID end, MAX_EVIDENCE_PER_DESCRIPTOR) end
    prune(function() return true end, MAX_EVIDENCE_PER_NPC)
end

function Knowledge.RecalculateDescriptor(characterUUID, npcID, descriptorID, at)
    local descriptor = Definitions.Get(descriptorID)
    local note = mutableNote(characterUUID, npcID, false)
    if not note or not descriptor then return nil, "unknown_descriptor" end
    local resolver = Resolvers.Get(descriptor.resolverID)
    if not resolver then return nil, "unknown_resolver" end
    local known, reason = resolver.Resolve(descriptor, evidenceFor(note, descriptor.id), familiarity(characterUUID, npcID))
    if not known then
        if note.discovered[descriptor.id] then note.discovered[descriptor.id] = nil; markDirty(note) end
        return nil, reason or "not_discovered"
    end
    local previous = note.discovered[descriptor.id]
    note.discovered[descriptor.id] = {
        descriptorID = descriptor.id, status = known.status, value = known.value,
        confidence = Shared.Clamp(known.confidence, 0, 1),
        discoveredAt = previous and previous.discoveredAt or now(at), lastUpdatedAt = now(at),
        primarySource = known.primarySource or (evidenceFor(note, descriptor.id)[1] or {}).sourceType or "unknown",
        evidenceCount = #evidenceFor(note, descriptor.id), revision = (previous and previous.revision or 0) + 1,
    }
    markDirty(note)
    return deepCopy(note.discovered[descriptor.id])
end

function Knowledge.RecalculateNPC(characterUUID, npcID, at)
    local note = mutableNote(characterUUID, npcID, false)
    if not note then return {} end
    local changed = {}
    local IDs = {}
    for _, entry in ipairs(note.evidence) do IDs[entry.descriptorID] = true end
    for descriptorID in pairs(IDs) do changed[descriptorID] = Knowledge.RecalculateDescriptor(characterUUID, npcID, descriptorID, at) end
    return changed
end


Internal.familiarity = familiarity
Internal.evidenceFor = evidenceFor
Internal.pruneEvidence = pruneEvidence

return Knowledge
