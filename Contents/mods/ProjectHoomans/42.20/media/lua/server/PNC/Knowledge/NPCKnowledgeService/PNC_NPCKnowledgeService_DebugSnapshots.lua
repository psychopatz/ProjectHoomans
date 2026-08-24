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
local evidenceFor = Internal.evidenceFor
local SCHEMA = Internal.SCHEMA

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

return Knowledge
