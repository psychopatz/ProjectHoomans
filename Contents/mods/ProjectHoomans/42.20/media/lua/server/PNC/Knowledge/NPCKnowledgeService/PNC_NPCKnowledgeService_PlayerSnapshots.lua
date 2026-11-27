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
        firstMetAt = note and note.firstMetAt or nil, lastInteractionAt = note and note.lastInteractionAt or nil,
        giftPreferences = {} }
    if not note then return output end
    local memory = PNC.Conversation and PNC.Conversation.Memory
    for descriptorID, fact in pairs(note.discovered) do
        local descriptor = Definitions.Get(descriptorID)
        if descriptor then
            local category = output.categories[descriptor.category] or { id = descriptor.category, descriptors = {} }
            local value = fact.value
            if descriptorID == "history.backstory.family_background" and value == "only_child"
                and memory and memory.HasStartingSibling and Registry and Registry.Get
            then
                local record = Registry.Get(output.npcID)
                if memory.HasStartingSibling(record) then
                    value = Providers.GetTruth(record, descriptor)
                end
            end
            category.descriptors[#category.descriptors + 1] = { descriptorID = descriptorID, category = descriptor.category, valueType = descriptor.valueType,
                presentation = deepCopy(descriptor.presentation), status = fact.status, value = deepCopy(value), confidence = fact.confidence,
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
    for fullType, preference in pairs(note.giftPreferences or {}) do
        if preference and (preference.disposition == "like"
            or preference.disposition == "dislike"
            or preference.disposition == "neutral")
        then
            output.giftPreferences[fullType] = preference.disposition
        end
    end
    return output
end

local reciprocalFamilyKind = {
    brother = "Sibling",
    sister = "Sibling",
    mother = "Child",
    father = "Child",
    lover = "Spouse",
}

local function knownStartingFamily(record, characterUUID)
    local generation = record and record.generation
    if type(generation) ~= "table" or generation.source ~= "starting_companion_trait" then return nil end
    local kind = reciprocalFamilyKind[generation.relationshipKind]
    local relativeID = generation.playerCharacterUUID
    if not kind or not relativeID or not PlayerCharacters or not PlayerCharacters.GetRegistryRecord then
        return nil
    end
    if characterUUID ~= relativeID then
        local fact = Knowledge.GetDescriptor(characterUUID, record.id, "history.relationship")
        if not fact or fact.status ~= "confirmed" or fact.value ~= generation.relationshipKind then
            return nil
        end
    end
    local relative = PlayerCharacters.GetRegistryRecord(relativeID)
    if not relative then return nil end
    local name = (tostring(relative.forename or "") .. " " .. tostring(relative.surname or ""))
        :gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then return nil end
    local deceased = PlayerCharacters.IsCharacterDead and PlayerCharacters.IsCharacterDead(relativeID)
    return { kind = kind, name = name, deceased = deceased == true }
end

function Knowledge.BuildPlayerSnapshotForPlayer(player, npcID)
    local characterUUID, identityReason = characterUUIDForPlayer(
        player,
        "knowledge_snapshot"
    )
    if not characterUUID then return nil, identityReason end
    local snapshot = Knowledge.BuildPlayerSnapshot(characterUUID, npcID)
    local targetID = tostring(npcID or "")
    local record = Registry and Registry.Get and Registry.Get(targetID) or nil
    local deathMarker = (not record) and Registry and Registry.GetDeathMarker
        and Registry.GetDeathMarker(targetID) or nil
    local coreActors = PsychopatzCore and PsychopatzCore.Actors or nil
    local coreLifecycleProj = nil
    if not record and coreActors and coreActors.DefaultRegistry
        and type(coreActors.DefaultRegistry.ProjectIdentity) == "function"
    then
        coreLifecycleProj = coreActors.DefaultRegistry:ProjectIdentity(targetID)
    end
    local hasHistoricalNote = #(snapshot.categories or {}) > 0
        or snapshot.firstMetAt ~= nil
    local isHistoricalTombstone = coreLifecycleProj ~= nil
        and coreLifecycleProj.status == "RETIRED"
    if not record and not deathMarker and not isHistoricalTombstone
        and not hasHistoricalNote
    then
        return nil, "npc_not_found"
    end
    local identity = record and PNC.Identity and PNC.Identity.GetCharacterSummary
        and PNC.Identity.GetCharacterSummary(record) or {}
    local factionID = record and record.affiliation and record.affiliation.factionID
        or (deathMarker and deathMarker.factionID) or nil
    local faction = factionID and PNC.Factions
        and PNC.Factions.GetPresentation
        and PNC.Factions.GetPresentation(factionID) or nil
    local knownName = Knowledge.GetDescriptor(characterUUID, npcID, "identity.name")
    local knownFullName = Knowledge.GetDescriptor(
        characterUUID, npcID, "identity.full_name"
    )
    local knownNickname = Knowledge.GetDescriptor(
        characterUUID, npcID, "identity.nickname"
    )
    local knownForename = Knowledge.GetDescriptor(
        characterUUID, npcID, "identity.forename"
    )
    local knownSurname = Knowledge.GetDescriptor(
        characterUUID, npcID, "identity.surname"
    )
    local knownArchetype = Knowledge.GetDescriptor(
        characterUUID, npcID, "identity.archetype"
    )
    local knownFaction = Knowledge.GetDescriptor(characterUUID, npcID, "faction.identity")
    local fallbackName = (coreLifecycleProj and coreLifecycleProj.displayName)
        or (deathMarker and deathMarker.name) or nil
    snapshot.identity = {
        displayName = knownName and knownName.value
            or knownFullName and knownFullName.value
            or (not record and fallbackName) or nil,
        nickname = knownNickname and knownNickname.value or nil,
        forename = knownForename and knownForename.value or nil,
        surname = knownSurname and knownSurname.value or nil,
        archetypeLabel = knownArchetype and identity.archetypeLabel or nil,
        factionName = knownFaction and faction and faction.name
            or (deathMarker and deathMarker.factionName) or nil,
        factionRole = knownFaction and record and record.affiliation
            and record.affiliation.role or nil,
        firstMetAt = snapshot.firstMetAt,
        lastInteractionAt = snapshot.lastInteractionAt,
    }
    if not record then
        snapshot.historical = true
        snapshot.lifecycleStatus = coreLifecycleProj and coreLifecycleProj.status
            or (deathMarker and "RETIRED" or "FORGOTTEN")
        snapshot.lifecycleRevision = coreLifecycleProj and coreLifecycleProj.lifecycleRevision or 0
        snapshot.retiredAt = coreLifecycleProj and coreLifecycleProj.retiredAt or nil
    elseif coreLifecycleProj then
        snapshot.lifecycleStatus = coreLifecycleProj.status
        snapshot.lifecycleRevision = coreLifecycleProj.lifecycleRevision
    else
        snapshot.lifecycleStatus = "LIVE"
    end
    snapshot.startingFamily = knownStartingFamily(record, characterUUID)
    snapshot.portrait = (record and PNC.Identity and PNC.Identity.BuildPortraitSummary
        and PNC.Identity.BuildPortraitSummary(record))
        or (deathMarker and deathMarker.portrait) or nil
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
