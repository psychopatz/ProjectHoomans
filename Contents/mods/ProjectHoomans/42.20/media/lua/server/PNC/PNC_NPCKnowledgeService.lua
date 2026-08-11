-- Server-authoritative, sparse NPC knowledge store. Truth remains in NPC
-- records; this file stores only what one player-character learned and why.

if isClient and isClient() and (not isServer or not isServer()) then return end

PNC = PNC or {}
PNC.NPCKnowledge = PNC.NPCKnowledge or {}

local Knowledge = PNC.NPCKnowledge
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

local KEY = "PNC_NPCKnowledge"
local SCHEMA = 1
local MAX_EVIDENCE_PER_NPC = 64
local MAX_EVIDENCE_PER_DESCRIPTOR = 16
local MAX_JOURNAL = 64
local MAX_MANUAL_NOTES = 16
local MAX_MANUAL_LENGTH = 512

Knowledge.Registry = Knowledge.Registry or { schemaVersion = SCHEMA, byCharacter = {}, revision = 0 }
Knowledge.Loaded = Knowledge.Loaded == true
Knowledge.Dirty = Knowledge.Dirty == true

local function now(value)
    value = tonumber(value)
    if value ~= nil then return math.max(0, value) end
    local time = getGameTime and getGameTime() or nil
    return time and time.getWorldAgeHours and math.max(0, tonumber(time:getWorldAgeHours()) or 0) or 0
end

local function deepCopy(value)
    if Core and Core.DeepCopy then return Core.DeepCopy(value) end
    if type(value) ~= "table" then return value end
    local out = {}
    for key, item in pairs(value) do out[key] = deepCopy(item) end
    return out
end

local function validID(value)
    return Shared and Shared.IsID and Shared.IsID(value)
end

local function safeString(value, limit)
    if type(value) ~= "string" or value == "" or #value > (limit or 128)
        or string.find(value, "%c") then return nil end
    return value
end

-- Knowledge is keyed by the persistent player-character UUID, never by a
-- transient IsoPlayer instance or username.  Lifecycle callbacks normally
-- establish this binding first, but client commands can race those callbacks
-- during single-player startup and multiplayer reconnects.  Resolve it at the
-- authoritative boundary and commit a newly recovered/created identity before
-- storing knowledge under it.
local function characterUUIDForPlayer(player, callback)
    if not PNC.PlayerContext or not PNC.PlayerContext.Resolve then
        return nil, "character_identity_service_unavailable"
    end
    local context, reason = PNC.PlayerContext.Resolve(
        player, callback or "npc_knowledge"
    )
    if not context then
        return nil, reason or "character_identity_unavailable"
    end
    return context.characterUUID
end

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
    local knownFaction = Knowledge.GetDescriptor(characterUUID, npcID, "faction.identity")
    snapshot.identity = {
        displayName = identity.displayName or record.name or "Unknown",
        archetypeLabel = identity.archetypeLabel,
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

-- Login/full-sync hydration is deliberately sparse: only NPCs this character
-- already knows are sent back to that player. This restores client-side name
-- presentation after a reload without exposing an all-NPC knowledge matrix.
function Knowledge.BuildKnownSnapshotsForPlayer(player, requestedNPCIDs)
    local characterUUID, identityReason = characterUUIDForPlayer(
        player,
        "knowledge_full_sync"
    )
    local character
    local ids = {}
    local snapshots = {}
    if not characterUUID then return nil, identityReason end
    Knowledge.EnsureLoaded()
    character = Knowledge.Registry.byCharacter[characterUUID]
    if type(requestedNPCIDs) == "table" then
        local seen = {}
        for index = 1, math.min(#requestedNPCIDs, 512) do
            local requestedID = tostring(requestedNPCIDs[index] or "")
            if requestedID ~= "" and #requestedID <= 128
                and not string.find(requestedID, "%c")
                and not seen[requestedID]
            then
                seen[requestedID] = true
                ids[#ids + 1] = requestedID
            end
        end
    else
        for npcID in pairs(character and character.byNPC or {}) do
            ids[#ids + 1] = tostring(npcID)
        end
    end
    table.sort(ids)
    for _, npcID in ipairs(ids) do
        local snapshot = Knowledge.BuildPlayerSnapshotForPlayer(player, npcID)
        if snapshot then snapshots[#snapshots + 1] = snapshot end
    end
    return snapshots
end

function Knowledge.BuildDebugSnapshot(characterUUID, npcID, showTruth, detailDescriptorID)
    local note = mutableNote(characterUUID, npcID, false)
    local record = Registry and Registry.Get and Registry.Get(tostring(npcID or "")) or nil
    local rows = {}
    for _, descriptor in ipairs(Definitions.List()) do
        local fact = note and note.discovered[descriptor.id] or nil
        local truth, reason
        if showTruth ~= false then truth, reason = Providers.GetTruth(record, descriptor) end
        local evidence = note and evidenceFor(note, descriptor.id) or {}
        rows[#rows + 1] = { descriptorID = descriptor.id, category = descriptor.category, providerID = descriptor.providerID,
            resolverID = descriptor.resolverID, valueType = descriptor.valueType, privacy = descriptor.privacy,
            capabilities = deepCopy(descriptor.capabilities), discovery = deepCopy(descriptor.discovery), truth = truth,
            truthReason = reason, known = fact and deepCopy(fact) or nil, evidenceCount = #evidence,
            evidence = detailDescriptorID == descriptor.id and deepCopy(evidence) or nil, orphaned = false }
    end
    if note then
        for descriptorID in pairs(note.discovered) do
            if not Definitions.Get(descriptorID) then
                local evidence = evidenceFor(note, descriptorID)
                rows[#rows + 1] = { descriptorID = descriptorID, orphaned = true, known = deepCopy(note.discovered[descriptorID]),
                    evidenceCount = #evidence, evidence = detailDescriptorID == descriptorID and deepCopy(evidence) or nil }
            end
        end
    end
    table.sort(rows, function(a, b) return a.descriptorID < b.descriptorID end)
    return { schemaVersion = SCHEMA, characterUUID = characterUUID, npcID = tostring(npcID or ""), rows = rows,
        detailDescriptorID = detailDescriptorID, revision = note and note.revision or 0 }
end

function Knowledge.BuildDebugSnapshotForPlayer(player, npcID, showTruth, detailDescriptorID)
    local characterUUID, identityReason = characterUUIDForPlayer(
        player,
        "knowledge_debug_snapshot"
    )
    if not characterUUID then return nil, identityReason end
    return Knowledge.BuildDebugSnapshot(characterUUID, npcID, showTruth, detailDescriptorID)
end

function Knowledge.ForceRevealForPlayer(player, npcID, descriptorID, at, sourceType)
    local characterUUID, identityReason = characterUUIDForPlayer(
        player,
        "knowledge_disclosure"
    )
    local descriptor = Definitions.Get(descriptorID)
    local record = Registry and Registry.Get and Registry.Get(tostring(npcID or "")) or nil
    if not characterUUID then return nil, identityReason end
    if not descriptor then return nil, "unknown_descriptor" end
    local truth, reason = Providers.GetTruth(record, descriptor)
    if truth == nil then return nil, reason end
    return Knowledge.RecordEvidence({ characterUUID = characterUUID, npcID = npcID, descriptorID = descriptor.id,
        sourceType = sourceType or "debug", strength = 1, reliability = 1, direction = 0,
        payload = { observedValue = truth }, worldAgeHours = at })
end


-- Trusted initialization path for NPCs the character knew before the game
-- began. It reveals every descriptor that currently has authoritative truth;
-- future descriptor packs automatically participate without changing this
-- service or the starting-companion feature.
function Knowledge.DiscoverAllForPlayer(
    player, npcID, at, sourceType, deferCommit
)
    local revealed = {}
    local failures = {}
    for _, descriptor in ipairs(Definitions.List()) do
        local result
        local reason
        result, reason = Knowledge.ForceRevealForPlayer(
            player, npcID, descriptor.id, at,
            sourceType or "lifelong_relationship"
        )
        if result then
            revealed[#revealed + 1] = descriptor.id
        else
            failures[#failures + 1] = descriptor.id .. ":" .. tostring(reason)
        end
    end
    if #revealed > 0 and deferCommit ~= true then
        if PNC.PersistenceCoordinator and PNC.PersistenceCoordinator.Commit then
            local committed, reason = PNC.PersistenceCoordinator.Commit(
                "lifelong_knowledge_disclosure"
            )
            if not committed then return nil, reason end
        else
            local saved, reason = Knowledge.Save()
            if saved == false and reason ~= "not_dirty" then
                return nil, reason
            end
        end
    end
    return { revealed = revealed, failures = failures }
end

-- Temporary debug counterpart to future conversational disclosures. A topic
-- only reveals descriptors the NPC would reasonably discuss in that topic;
-- it never turns the whole dossier into an omniscient dump.
function Knowledge.DiscoverTopicForPlayer(
    player, npcID, topicID, at, sourceType, deferCommit
)
    local topic = tostring(topicID or "")
    local revealed = {}
    local failures = {}
    if topic == "" then return nil, "unknown_knowledge_topic" end
    for _, descriptor in ipairs(Definitions.List()) do
        local presentation = descriptor.presentation or {}
        if tostring(presentation.topicID or "") == topic then
            local result, reason = Knowledge.ForceRevealForPlayer(player, npcID, descriptor.id, at, sourceType or "direct_disclosure")
            if result then
                revealed[#revealed + 1] = descriptor.id
            else
                failures[#failures + 1] = descriptor.id .. ":" .. tostring(reason)
            end
        end
    end
    if #revealed == 0 and #failures == 0 then return nil, "unknown_knowledge_topic" end
    -- A direct answer changes player-facing identity immediately. Commit at
    -- the disclosure boundary so learned names survive a restart even when no
    -- later periodic world save occurs.
    if #revealed > 0 and deferCommit ~= true then
        if PNC.PersistenceCoordinator and PNC.PersistenceCoordinator.Commit then
            local committed, saveReason = PNC.PersistenceCoordinator.Commit(
                "knowledge_disclosure"
            )
            if not committed then return nil, saveReason or "knowledge_save_failed" end
        else
            local saved, saveReason = Knowledge.Save()
            if saved == false and saveReason ~= "not_dirty" then
                return nil, saveReason or "knowledge_save_failed"
            end
        end
    end
    return { topicID = topic, revealed = revealed, failures = failures }
end

function Knowledge.ExecuteDebugForPlayer(player, args)
    args = type(args) == "table" and args or {}
    local characterUUID, identityReason = characterUUIDForPlayer(
        player,
        "knowledge_debug_action"
    )
    local action = tostring(args.knowledgeAction or args.action or "")
    local npcID = tostring(args.npcID or "")
    local descriptorID = tostring(args.descriptorID or "")
    local result, reason
    if not characterUUID or npcID == "" then
        return nil, characterUUID and "invalid_npc_id" or identityReason
    end
    if action == "reveal" or action == "force_disclosure" then
        result, reason = Knowledge.ForceRevealForPlayer(player, npcID, descriptorID, args.worldAgeHours)
    elseif action == "discover_topic" then
        result, reason = Knowledge.DiscoverTopicForPlayer(player, npcID, args.topicID, args.worldAgeHours, "debug")
    elseif action == "forget" then
        result, reason = Knowledge.Clear(characterUUID, npcID, descriptorID)
    elseif action == "add_evidence" then
        result, reason = Knowledge.RecordEvidence({ characterUUID = characterUUID, npcID = npcID, descriptorID = descriptorID,
            sourceType = "debug", direction = args.direction, strength = args.strength, reliability = args.reliability,
            payload = args.payload, worldAgeHours = args.worldAgeHours })
    elseif action == "remove_evidence" then
        result, reason = Knowledge.RemoveEvidence(characterUUID, npcID, args.evidenceID)
    elseif action == "clear_evidence" then
        result, reason = Knowledge.Clear(characterUUID, npcID, descriptorID)
    elseif action == "recalculate" then
        result, reason = Knowledge.RecalculateDescriptor(characterUUID, npcID, descriptorID, args.worldAgeHours)
    elseif action == "validate" then
        result, reason = Knowledge.Validate(characterUUID, npcID), nil
    else
        return nil, "unsupported_knowledge_debug_action"
    end
    local snapshot = Knowledge.BuildDebugSnapshot(characterUUID, npcID, args.showTruth ~= false)
    snapshot.actionResult = result
    snapshot.actionReason = reason
    return snapshot, reason
end

function Knowledge.Validate(characterUUID, npcID)
    local note = mutableNote(characterUUID, npcID, false)
    local issues = {}
    if not note then return issues end
    for _, evidence in ipairs(note.evidence) do if not Definitions.Get(evidence.descriptorID) then issues[#issues + 1] = "orphaned_descriptor:" .. evidence.descriptorID end end
    return issues
end

if Events and Events.OnInitGlobalModData then
    Events.OnInitGlobalModData.Add(function() Knowledge.Load() end)
end
return Knowledge
