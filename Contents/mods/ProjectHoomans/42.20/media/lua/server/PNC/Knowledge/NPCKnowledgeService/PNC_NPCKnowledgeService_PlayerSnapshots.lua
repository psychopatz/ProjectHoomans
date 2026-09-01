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
local characterUUIDForPlayer = Internal.characterUUIDForPlayer
local mutableNote = Internal.mutableNote
local SCHEMA = Internal.SCHEMA

function Knowledge.BuildPlayerSnapshot(characterUUID, npcID)
    local note = mutableNote(characterUUID, npcID, false)
    local output = { schemaVersion = SCHEMA, npcID = tostring(npcID or ""), categories = {}, revision = note and note.revision or 0,
        firstMetAt = note and note.firstMetAt or nil, lastInteractionAt = note and note.lastInteractionAt or nil }
    if not note then return output end
    for descriptorID, fact in pairs(note.discovered) do
        local descriptor = Definitions.Get(descriptorID)
        if descriptor then
            local category = output.categories[descriptor.category] or { id = descriptor.category, descriptors = {} }
            category.descriptors[#category.descriptors + 1] = { descriptorID = descriptorID, category = descriptor.category, valueType = descriptor.valueType,
                presentation = deepCopy(descriptor.presentation), status = fact.status, value = deepCopy(fact.value), confidence = fact.confidence,
                primarySource = fact.primarySource, evidenceCount = fact.evidenceCount }
            output.categories[descriptor.category] = category
        end
    end
    local ordered = {}
    for _, category in pairs(output.categories) do
        table.sort(category.descriptors, function(a, b) return a.descriptorID < b.descriptorID end)
        ordered[#ordered + 1] = category
    end
    table.sort(ordered, function(a, b) return a.id < b.id end)
    output.categories = ordered
    output.journalEntries = deepCopy(note.journalEntries)
    output.manualNotes = deepCopy(note.manualNotes)
    return output
end

function Knowledge.BuildPlayerSnapshotForPlayer(player, npcID)
    local characterUUID, identityReason = characterUUIDForPlayer(
        player,
        "knowledge_snapshot"
    )
    if not characterUUID then return nil, identityReason end
    local snapshot = Knowledge.BuildPlayerSnapshot(characterUUID, npcID)
    local record = Registry and Registry.Get and Registry.Get(tostring(npcID or "")) or nil
    if not record then return nil, "npc_not_found" end
    local identity = PNC.Identity and PNC.Identity.GetCharacterSummary
        and PNC.Identity.GetCharacterSummary(record) or {}
    local faction = record.affiliation and PNC.Factions
        and PNC.Factions.GetPresentation
        and PNC.Factions.GetPresentation(record.affiliation.factionID) or nil
    local knownName = Knowledge.GetDescriptor(characterUUID, npcID, "identity.name")
    local knownArchetype = Knowledge.GetDescriptor(
        characterUUID, npcID, "identity.archetype"
    )
    local knownFaction = Knowledge.GetDescriptor(characterUUID, npcID, "faction.identity")
    snapshot.identity = {
        displayName = knownName and knownName.value or nil,
        archetypeLabel = knownArchetype and identity.archetypeLabel or nil,
        factionName = knownFaction and faction and faction.name or nil,
        factionRole = knownFaction and record.affiliation and record.affiliation.role or nil,
        firstMetAt = snapshot.firstMetAt,
        lastInteractionAt = snapshot.lastInteractionAt,
    }
    snapshot.portrait = PNC.Identity and PNC.Identity.BuildPortraitSummary
        and PNC.Identity.BuildPortraitSummary(record) or nil
    if snapshot.portrait then
        snapshot.portrait.preferDescriptor = true
        snapshot.portrait.faceOnly = true
    end
    if knownFaction and faction then
        snapshot.knownFaction = deepCopy(faction)
    end
    if PNC.RelationshipPresentation and PNC.RelationshipPresentation.BuildForConversation then
        snapshot.relationship = PNC.RelationshipPresentation.BuildForConversation(player, npcID)
    end
    return snapshot
end


return Knowledge
