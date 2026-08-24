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
local markDirty = Internal.markDirty
local mutableNote = Internal.mutableNote
local pruneEvidence = Internal.pruneEvidence

function Knowledge.RecordEvidence(spec)
    spec = type(spec) == "table" and spec or {}
    local descriptor = Definitions.Get(spec.descriptorID)
    local source = Sources.Get(spec.sourceType)
    if not descriptor then return nil, "unknown_descriptor" end
    if not source then return nil, "unknown_evidence_source" end
    if spec.sourceType == "direct_disclosure" and descriptor.discovery.allowDisclosure ~= true then return nil, "disclosure_not_allowed" end
    if spec.sourceType ~= "direct_disclosure" and spec.sourceType ~= "debug"
        and source.bypassDiscovery ~= true
        and descriptor.discovery.allowObservation ~= true and descriptor.discovery.allowInference ~= true
    then return nil, "discovery_not_allowed" end
    local payload, payloadOK = Shared.SanitizePayload(spec.payload)
    if not payloadOK then return nil, "unsafe_payload" end
    local at = now(spec.worldAgeHours)
    local note, reason = mutableNote(spec.characterUUID, spec.npcID, true, at)
    if not note then return nil, reason end
    local id = safeString(spec.id, 128) or (Core and Core.GenerateID and Core.GenerateID("knowledge") or "knowledge:" .. tostring(at) .. ":" .. tostring(#note.evidence + 1))
    local evidence = {
        id = id, descriptorID = descriptor.id, sourceType = spec.sourceType,
        direction = math.max(-1, math.min(1, math.floor(tonumber(spec.direction) or 0))),
        strength = Shared.Clamp(spec.strength or 1, 0, 1),
        reliability = Shared.Clamp(spec.reliability or source.reliability, 0, 1),
        createdAt = at, sourceEventID = safeString(spec.sourceEventID, 128),
        sourceEntityKey = safeString(spec.sourceEntityKey, 256), payload = payload or {}, tags = type(spec.tags) == "table" and deepCopy(spec.tags) or {},
    }
    note.evidence[#note.evidence + 1] = evidence
    note.lastInteractionAt = at
    pruneEvidence(note)
    markDirty(note)
    local fact = Knowledge.RecalculateDescriptor(spec.characterUUID, spec.npcID, descriptor.id, at)
    return { evidence = deepCopy(evidence), discovered = fact }
end

function Knowledge.RemoveEvidence(characterUUID, npcID, evidenceID)
    local note = mutableNote(characterUUID, npcID, false)
    local kept, descriptorID = {}, nil
    if not note then return false, "note_not_found" end
    for _, entry in ipairs(note.evidence) do
        if entry.id == evidenceID then descriptorID = entry.descriptorID else kept[#kept + 1] = entry end
    end
    if not descriptorID then return false, "evidence_not_found" end
    note.evidence = kept; markDirty(note)
    Knowledge.RecalculateDescriptor(characterUUID, npcID, descriptorID)
    return true
end

function Knowledge.Clear(characterUUID, npcID, descriptorID)
    local note = mutableNote(characterUUID, npcID, false)
    if not note then return false, "note_not_found" end
    if descriptorID then
        local kept = {}
        for _, entry in ipairs(note.evidence) do if entry.descriptorID ~= descriptorID then kept[#kept + 1] = entry end end
        note.evidence, note.discovered[descriptorID] = kept, nil
    else
        note.evidence, note.discovered, note.journalEntries, note.manualNotes = {}, {}, {}, {}
    end
    markDirty(note)
    return true
end


return Knowledge
