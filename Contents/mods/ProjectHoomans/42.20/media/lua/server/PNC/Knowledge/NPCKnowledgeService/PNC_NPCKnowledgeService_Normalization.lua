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
local safeString = Internal.safeString
local SCHEMA = Internal.SCHEMA
local MAX_MANUAL_LENGTH = Internal.MAX_MANUAL_LENGTH

local function normalizeDiscovered(raw, descriptorID)
    local value = type(raw) == "table" and raw or {}
    local status = tostring(value.status or "")
    if status ~= "suspected" and status ~= "known" and status ~= "confirmed" then return nil end
    local knownValue, okay = Shared.SanitizePayload(value.value)
    if not okay or knownValue == nil then return nil end
    return {
        descriptorID = descriptorID,
        status = status,
        value = knownValue,
        confidence = Shared.Clamp(value.confidence, 0, 1),
        discoveredAt = now(value.discoveredAt),
        lastUpdatedAt = now(value.lastUpdatedAt),
        primarySource = safeString(value.primarySource, 64) or "unknown",
        evidenceCount = math.max(0, math.floor(tonumber(value.evidenceCount) or 0)),
        revision = math.max(1, math.floor(tonumber(value.revision) or 1)),
    }
end

local function normalizeEvidence(raw)
    local entry = type(raw) == "table" and raw or {}
    local descriptorID = safeString(entry.descriptorID, 128)
    local sourceType = safeString(entry.sourceType, 64)
    local payload, okay = Shared.SanitizePayload(entry.payload)
    if not descriptorID or not sourceType or not okay then return nil end
    return {
        id = safeString(entry.id, 128) or "knowledge:orphan",
        descriptorID = descriptorID,
        sourceType = sourceType,
        direction = math.max(-1, math.min(1, math.floor(tonumber(entry.direction) or 0))),
        strength = Shared.Clamp(entry.strength, 0, 1),
        reliability = Shared.Clamp(entry.reliability, 0, 1),
        createdAt = now(entry.createdAt),
        sourceEventID = safeString(entry.sourceEventID, 128),
        sourceEntityKey = safeString(entry.sourceEntityKey, 256),
        payload = payload or {},
        tags = type(entry.tags) == "table" and deepCopy(entry.tags) or {},
    }
end

local function normalizeNote(raw, npcID)
    local source = type(raw) == "table" and raw or {}
    local note = {
        npcID = npcID, firstMetAt = now(source.firstMetAt), lastInteractionAt = now(source.lastInteractionAt),
        discovered = {}, evidence = {}, journalEntries = {}, manualNotes = {},
        revision = math.max(0, math.floor(tonumber(source.revision) or 0)),
    }
    for descriptorID, fact in pairs(type(source.discovered) == "table" and source.discovered or {}) do
        descriptorID = safeString(descriptorID, 128)
        if descriptorID then
            local descriptor = Definitions.Get(descriptorID)
            descriptorID = descriptor and descriptor.id or descriptorID
            local normalized = normalizeDiscovered(fact, descriptorID)
            if normalized then note.discovered[descriptorID] = normalized end
        end
    end
    for _, evidence in ipairs(type(source.evidence) == "table" and source.evidence or {}) do
        local normalized = normalizeEvidence(evidence)
        if normalized then
            local descriptor = Definitions.Get(normalized.descriptorID)
            normalized.descriptorID = descriptor and descriptor.id
                or normalized.descriptorID
            note.evidence[#note.evidence + 1] = normalized
        end
    end
    for _, entry in ipairs(type(source.journalEntries) == "table" and source.journalEntries or {}) do
        if type(entry) == "table" and safeString(entry.id, 128) then
            note.journalEntries[#note.journalEntries + 1] = {
                id = entry.id, type = safeString(entry.type, 64) or "knowledge",
                translationKey = safeString(entry.translationKey, 128), params = Shared.SanitizePayload(entry.params) or {},
                createdAt = now(entry.createdAt), sourceEventID = safeString(entry.sourceEventID, 128),
                descriptorIDs = type(entry.descriptorIDs) == "table" and deepCopy(entry.descriptorIDs) or {},
            }
        end
    end
    for _, entry in ipairs(type(source.manualNotes) == "table" and source.manualNotes or {}) do
        if type(entry) == "table" and type(entry.text) == "string" and #entry.text <= MAX_MANUAL_LENGTH then
            note.manualNotes[#note.manualNotes + 1] = {
                id = safeString(entry.id, 128) or "note", text = entry.text,
                createdAt = now(entry.createdAt), editedAt = now(entry.editedAt),
            }
        end
    end
    return note
end

function Knowledge.NormalizeRegistry(raw)
    local source = type(raw) == "table" and raw or {}
    local result = { schemaVersion = SCHEMA, revision = math.max(0, math.floor(tonumber(source.revision) or 0)), byCharacter = {} }
    for characterUUID, characterNotes in pairs(type(source.byCharacter) == "table" and source.byCharacter or {}) do
        characterUUID = safeString(characterUUID, 128)
        if characterUUID then
            local output = { byNPC = {} }
            for npcID, note in pairs(type(characterNotes) == "table" and characterNotes.byNPC or {}) do
                npcID = safeString(npcID, 128)
                if npcID then output.byNPC[npcID] = normalizeNote(note, npcID) end
            end
            result.byCharacter[characterUUID] = output
        end
    end
    return result
end


Internal.normalizeDiscovered = normalizeDiscovered
Internal.normalizeEvidence = normalizeEvidence
Internal.normalizeNote = normalizeNote

return Knowledge
