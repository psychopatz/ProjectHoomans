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
local familiarity = Internal.familiarity
local MAX_JOURNAL = Internal.MAX_JOURNAL
local MAX_MANUAL_NOTES = Internal.MAX_MANUAL_NOTES
local MAX_MANUAL_LENGTH = Internal.MAX_MANUAL_LENGTH

function Knowledge.RecordJournal(characterUUID, npcID, entry)
    local at = now(entry and entry.createdAt)
    local note, reason = mutableNote(characterUUID, npcID, true, at)
    if not note then return false, reason end
    local params, ok = Shared.SanitizePayload(entry and entry.params)
    if not ok then return false, "unsafe_journal_params" end
    note.journalEntries[#note.journalEntries + 1] = {
        id = safeString(entry and entry.id, 128) or (Core.GenerateID and Core.GenerateID("knowledge_journal") or "journal:" .. tostring(at)),
        type = safeString(entry and entry.type, 64) or "knowledge", translationKey = safeString(entry and entry.translationKey, 128),
        params = params or {}, createdAt = at, sourceEventID = safeString(entry and entry.sourceEventID, 128),
        descriptorIDs = type(entry and entry.descriptorIDs) == "table" and deepCopy(entry.descriptorIDs) or {},
    }
    while #note.journalEntries > MAX_JOURNAL do table.remove(note.journalEntries, 1) end
    markDirty(note)
    return true
end

-- Relationship mutations call this only when a value changes. It creates an
-- opportunity signal/journal marker, never a magical descriptor discovery.
function Knowledge.OnFamiliarityMilestone(characterUUID, npcID, before, after, at)
    local crossed
    before, after = tonumber(before) or 0, tonumber(after) or 0
    for _, milestone in ipairs({ 10, 25, 50, 75 }) do
        if before < milestone and after >= milestone then crossed = milestone end
    end
    if not crossed then return false end
    return Knowledge.RecordJournal(characterUUID, npcID, {
        type = "familiarity_milestone", translationKey = "UI_PNC_KnowledgeJournal_FamiliarityMilestone",
        params = { milestone = crossed }, createdAt = at,
    })
end

function Knowledge.AddManualNote(characterUUID, npcID, text, at)
    if type(text) ~= "string" or #text == 0 or #text > MAX_MANUAL_LENGTH then return false, "invalid_note" end
    local note, reason = mutableNote(characterUUID, npcID, true, now(at))
    if not note then return false, reason end
    note.manualNotes[#note.manualNotes + 1] = { id = Core.GenerateID and Core.GenerateID("knowledge_note") or "note:" .. tostring(#note.manualNotes + 1), text = text, createdAt = now(at), editedAt = now(at) }
    while #note.manualNotes > MAX_MANUAL_NOTES do table.remove(note.manualNotes, 1) end
    markDirty(note)
    return true
end

function Knowledge.CanDisclose(characterUUID, npcID, descriptorID)
    local descriptor = Definitions.Get(descriptorID)
    if not descriptor then return false, "unknown_descriptor" end
    if descriptor.discovery.allowDisclosure ~= true then return false, "not_disclosable" end
    local familiarityValue, approval = familiarity(characterUUID, npcID)
    if familiarityValue < descriptor.discovery.minimumFamiliarity then return false, "insufficient_familiarity" end
    if descriptor.discovery.minimumApproval and approval < descriptor.discovery.minimumApproval then return false, "insufficient_approval" end
    return true
end

function Knowledge.PreviewDisclosure(characterUUID, npcID, descriptorID)
    local allowed, reason = Knowledge.CanDisclose(characterUUID, npcID, descriptorID)
    return { allowed = allowed, reason = reason, descriptorID = descriptorID }
end

function Knowledge.Disclose(characterUUID, npcID, descriptorID, context)
    local allowed, reason = Knowledge.CanDisclose(characterUUID, npcID, descriptorID)
    local descriptor = Definitions.Get(descriptorID)
    local record = Registry and Registry.Get and Registry.Get(tostring(npcID or "")) or nil
    if not allowed then return nil, reason end
    local truth; truth, reason = Providers.GetTruth(record, descriptor)
    if truth == nil then return nil, reason end
    return Knowledge.RecordEvidence({ characterUUID = characterUUID, npcID = npcID, descriptorID = descriptorID,
        sourceType = "direct_disclosure", strength = 1, reliability = 1, direction = 0,
        payload = { observedValue = truth }, sourceEventID = context and context.sourceEventID, worldAgeHours = context and context.worldAgeHours })
end


return Knowledge
