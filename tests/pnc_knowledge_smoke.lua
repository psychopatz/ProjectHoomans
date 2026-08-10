local SHARED = "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/"
local SERVER = "Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/"

local function eq(actual, expected, label)
    if actual ~= expected then error((label or "assert") .. " expected=" .. tostring(expected) .. " actual=" .. tostring(actual)) end
end
local function truth(value, label) eq(value == true, true, label) end
local function safe(value, seen)
    if type(value) ~= "table" then return end
    if getmetatable(value) then error("metatable persisted") end
    seen = seen or {}; if seen[value] then error("cycle persisted") end; seen[value] = true
    for key, item in pairs(value) do
        if type(key) ~= "string" and type(key) ~= "number" then error("unsafe key") end
        safe(item, seen)
    end
    seen[value] = nil
end

PNC = { Core = {
    GenerateID = (function() local id = 0; return function(prefix) id = id + 1; return prefix .. ":" .. id end end)(),
    DeepCopy = function(value) if type(value) ~= "table" then return value end local out = {}; for key, item in pairs(value) do out[key] = PNC.Core.DeepCopy(item) end; return out end,
} }
ModData = { store = {}, getOrCreate = function(key) ModData.store[key] = ModData.store[key] or {}; return ModData.store[key] end }
dofile(SHARED .. "Relationships/PNC_EntityRef.lua")
dofile(SHARED .. "Knowledge/PNC_KnowledgeRegistry.lua")
dofile(SHARED .. "Knowledge/PNC_KnowledgeBuiltins.lua")

local npc = { id = "npc_russell", name = "Burton Gilmore",
    generation = { relationshipKind = "brother" }, social = { personality = {
    orientation = "gay", foodPreference = "spicy", romanceStyle = "reserved", jealousyStyle = "normal", socialStyle = "friendly",
    compassion = .82, sociability = .31, forgiveness = .60, bravery = .91, materialism = .20, aggression = .15, loyalty = .88,
} } }
PNC.Registry = { Get = function(id) return tostring(id) == npc.id and npc or nil end }
PNC.Identity = {
    GetCharacterSummary = function(record)
        return { displayName = record and record.name }
    end,
}
local characterUUID
local identityEnsureCalls = 0
local identitySaveCalls = 0
PNC.PlayerCharacters = {
    GetRegistryRecord = function(uuid)
        return (uuid == "char_a" or uuid == "char_recovered")
            and { accountKey = "Patrick", accountIdentity = "Patrick" } or nil
    end,
    GetCharacterUUID = function() return characterUUID end,
    EnsureIdentity = function(_, context)
        identityEnsureCalls = identityEnsureCalls + 1
        eq(context.callback, "knowledge_disclosure",
            "disclosure owns identity recovery callback")
        characterUUID = "char_a"
        return characterUUID, "new_identity"
    end,
    Save = function()
        identitySaveCalls = identitySaveCalls + 1
        return true
    end,
}
PNC.PlayerContext = {
    Resolve = function(_, reason)
        if not characterUUID then
            identityEnsureCalls = identityEnsureCalls + 1
            eq(reason, "knowledge_disclosure",
                "disclosure owns identity recovery callback")
            characterUUID = "char_a"
        end
        return {
            accountKey = "Patrick",
            characterUUID = characterUUID,
            entityKey = "player:Patrick:" .. characterUUID,
            bindingRevision = 1,
        }
    end,
}
PNC.Relationships = { Get = function() return { familiarity = 50, approval = 25 } end }
dofile(SERVER .. "PNC_NPCKnowledgeService.lua")
local Knowledge = PNC.NPCKnowledge
PNC.PersistenceCoordinator = {
    Commit = function()
        PNC.PlayerCharacters.Save(false)
        local saved, reason = Knowledge.Save(false)
        return saved == true or reason == "not_dirty", reason or "committed"
    end,
}

-- Asking a stranger's name must be a real persisted disclosure even at zero
-- familiarity. This is the restart regression that previously showed the raw
-- dialogue answer while silently rejecting the learned fact.
PNC.Relationships.Get = function()
    return { familiarity = 0, approval = 0 }
end
local introduction = Knowledge.DiscoverTopicForPlayer(
    {}, npc.id, "identity_name", 5, "direct_disclosure"
)
truth(introduction and introduction.revealed[1] == "identity.name",
    "stranger introduction reveals identity name")
eq(identityEnsureCalls, 1,
    "disclosure recovers identity when lifecycle has not bound it")
truth(identitySaveCalls >= 1,
    "recovered identity commits before learned knowledge")
eq(Knowledge.GetDescriptor("char_a", npc.id, "identity.name").value,
    "Burton Gilmore", "introduced name is recorded")
eq(Knowledge.Dirty, false, "introduction commits immediately")
PNC.Relationships.Get = function()
    return { familiarity = 50, approval = 25 }
end

local lifelong = Knowledge.DiscoverAllForPlayer(
    {}, npc.id, 6, "lifelong_relationship"
)
truth(lifelong and #lifelong.revealed >= 13,
    "lifelong companion initializes every available dossier fact")
eq(Knowledge.GetDescriptor(
    "char_a", npc.id, "history.relationship"
).value, "brother", "dossier identifies the family relationship")
eq(Knowledge.GetDescriptor(
    "char_a", npc.id, "personality.orientation"
).value, "gay", "lifelong dossier includes private facts")

-- Registration is generic and duplicate IDs reject safely.
truth(PNC.KnowledgeProviders.Register("test_provider", { GetValue = function() return "blue" end }), "provider registration")
truth(PNC.KnowledgeResolvers.Register("test_direct", { Resolve = function(_, evidence) return evidence[1] and { value = evidence[1].payload.observedValue, confidence = 1, status = "confirmed" } or nil end }), "resolver registration")
truth(PNC.KnowledgeDescriptors.Register({ id = "test.favorite_color", category = "misc", providerID = "test_provider", resolverID = "test_direct", valueType = "categorical", privacy = "personal", discovery = { allowDisclosure = true } }), "descriptor registration")
eq(PNC.KnowledgeDescriptors.Register({ id = "test.favorite_color", category = "misc", providerID = "test_provider", resolverID = "test_direct", valueType = "categorical", privacy = "personal" }), false, "duplicate descriptor rejected")

local forced = Knowledge.ForceRevealForPlayer({}, npc.id, "test.favorite_color", 10)
truth(forced ~= nil, "fake descriptor reveals through provider")
eq(Knowledge.GetDescriptor("char_a", npc.id, "test.favorite_color").value, "blue", "fake descriptor resolved")

-- Private orientation cannot be inferred by observations; it becomes known only by disclosure.
eq(Knowledge.RecordEvidence({ characterUUID = "char_a", npcID = npc.id, descriptorID = "personality.orientation", sourceType = "observed_behavior", strength = 1 }), nil, "private descriptor rejects observation")
local disclosed = Knowledge.Disclose("char_a", npc.id, "personality.orientation", { worldAgeHours = 20 })
truth(disclosed ~= nil, "orientation disclosure")
eq(Knowledge.GetDescriptor("char_a", npc.id, "personality.orientation").value, "gay", "orientation truth only copied on disclosure")

-- Observable personality takes generic evidence and normal snapshots never leak truth.
for index = 1, 5 do
    Knowledge.RecordEvidence({ characterUUID = "char_a", npcID = npc.id, descriptorID = "personality.compassion", sourceType = "observed_behavior", direction = 1, strength = .8, worldAgeHours = 30 + index })
end
truth(Knowledge.GetDescriptor("char_a", npc.id, "personality.compassion") ~= nil, "personality inferred")
local normal = Knowledge.BuildPlayerSnapshot("char_a", npc.id)
safe(normal)
eq(normal.truth, nil, "normal snapshot contains no truth")
-- Presentation consumes generic descriptor rows; no descriptor-specific UI code.
dofile("Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/UI/Knowledge/PNC_KnowledgePresentation.lua")
local dossierRows = PNC.KnowledgePresentation.BuildDossierRows(normal)
truth(#dossierRows > 0, "generic dossier model displays discovered descriptors")
local dossierModel = PNC.KnowledgePresentation.BuildDossierModel(normal)
truth(#dossierModel.tabs > 1 and dossierModel.tabs[1].id == "overview",
    "dossier tabs are generated from safe descriptor categories")
local debug = Knowledge.BuildDebugSnapshot("char_a", npc.id, true)
local found = false
for _, row in ipairs(debug.rows) do if row.descriptorID == "personality.compassion" then found = row.truth == .82 end end
truth(found, "debug snapshot is descriptor driven and can show truth")
truth(#PNC.KnowledgePresentation.BuildDebugRows(debug, { showTruth = true }) >= 13,
    "generic debug model displays registered descriptors")
for _, row in ipairs(debug.rows) do
    eq(row.evidence, nil, "debug summary defers raw evidence")
end
local debugDetail = Knowledge.BuildDebugSnapshot("char_a", npc.id, true, "personality.compassion")
local detailedEvidence = nil
for _, row in ipairs(debugDetail.rows) do
    if row.descriptorID == "personality.compassion" then detailedEvidence = row.evidence end
end
truth(type(detailedEvidence) == "table", "debug detail request includes selected evidence only")
local debugAction = Knowledge.ExecuteDebugForPlayer({}, {
    knowledgeAction = "add_evidence", npcID = npc.id,
    descriptorID = "personality.bravery", direction = 1, strength = 1,
})
truth(debugAction and debugAction.actionResult ~= nil,
    "generic debug action uses separate outer and inner action identifiers")
local topicDiscovery = Knowledge.ExecuteDebugForPlayer({}, {
    knowledgeAction = "discover_topic", npcID = npc.id, topicID = "personality", showTruth = false,
})
truth(topicDiscovery and topicDiscovery.actionResult and #topicDiscovery.actionResult.revealed == 10,
    "debug discovery reveals only the selected conversational topic")
eq(Knowledge.Dirty, false,
    "topic disclosure commits learned facts immediately")
local debugCompassion = Knowledge.GetDescriptor("char_a", npc.id, "personality.compassion")
eq(debugCompassion.status, "confirmed", "debug discovery confirms numeric trait bands")
eq(debugCompassion.value, "high", "debug discovery resolves numeric trait direction")
for index = 1, 20 do
    Knowledge.RecordEvidence({ characterUUID = "char_a", npcID = npc.id, descriptorID = "personality.loyalty",
        sourceType = "observed_behavior", direction = 1, strength = .4, worldAgeHours = 40 + index })
end
local loyaltyEvidence = 0
for _, evidence in ipairs(Knowledge.Get("char_a", npc.id).evidence) do
    if evidence.descriptorID == "personality.loyalty" then loyaltyEvidence = loyaltyEvidence + 1 end
end
eq(loyaltyEvidence, 16, "evidence per descriptor limit")

-- Unknown/orphaned descriptors survive normalization but are absent from normal UI.
local normalized = Knowledge.NormalizeRegistry({ byCharacter = { char_a = { byNPC = { npc_russell = { discovered = { ["removed.mod.fact"] = { status = "known", value = "x", confidence = .8 } }, evidence = { { id = "old", descriptorID = "removed.mod.fact", sourceType = "old", payload = {} } } } } } } })
truth(normalized.byCharacter.char_a.byNPC.npc_russell.discovered["removed.mod.fact"] ~= nil, "orphaned fact preserved")

-- New characters remain isolated; no all-character matrix is created.
eq(Knowledge.Get("char_b", npc.id), nil, "new survivor has no inherited notes")

-- Sparse scale proxy: 100 NPCs x 4 survivors x 50 registered descriptors,
-- while each survivor learns only five descriptors for each encountered NPC.
for descriptorIndex = 1, 50 do
    PNC.KnowledgeDescriptors.Register({
        id = "test.scale_" .. descriptorIndex, category = "misc", providerID = "test_provider",
        resolverID = "test_direct", valueType = "categorical", privacy = "personal",
        discovery = { allowDisclosure = true },
    })
end
local learned = 0
for npcIndex = 1, 100 do
    for characterIndex = 1, 4 do
        for descriptorIndex = 1, 5 do
            local stored = Knowledge.RecordEvidence({
                characterUUID = "scale_char_" .. characterIndex, npcID = "scale_npc_" .. npcIndex,
                descriptorID = "test.scale_" .. descriptorIndex, sourceType = "debug",
                payload = { observedValue = "v" .. descriptorIndex }, strength = 1,
            })
            if stored then learned = learned + 1 end
        end
    end
end
eq(learned, 2000, "sparse scale evidence count")
eq(#PNC.KnowledgeDescriptors.List(), 67, "scale descriptors registered without schema migration")
safe(Knowledge.Registry)

-- Learned facts are world ModData, keyed by persistent character UUID. A
-- reload must retain them for single-player and multiplayer server startup.
truth(Knowledge.Save(), "knowledge writes through the normal world-save path")
Knowledge.Registry = { schemaVersion = 1, revision = 0, byCharacter = {} }
Knowledge.Loaded = false
Knowledge.Dirty = false
truth(Knowledge.Load(), "knowledge reloads from world ModData")
eq(Knowledge.GetDescriptor("char_a", npc.id, "identity.name").value,
    "Burton Gilmore", "introduced identity survives reload")
eq(Knowledge.GetDescriptor("char_a", npc.id, "test.favorite_color").value,
    "blue", "learned fact survives reload")
local restored = Knowledge.BuildKnownSnapshotsForPlayer({})
truth(#restored > 0, "known snapshots hydrate a reconnecting client")
safe(Knowledge.Registry)
print("pnc_knowledge_smoke: ok")
