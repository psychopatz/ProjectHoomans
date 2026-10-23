local T = require "tests/support/test"

T.load("tests/pnc_npc_foundation_parity_baseline_smoke.lua")
T.load(
    "ProjectHoomans",
    "common_lua",
    "PNC/Conversation/Definitions/Memory/00_PNC_ConversationMemoryDefinitions.lua"
)

local Memory = PNC.Conversation.Memory

local function copy(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local output = {}
    seen[value] = output
    for key, item in pairs(value) do
        output[copy(key, seen)] = copy(item, seen)
    end
    return output
end

local function profileFact(profile, kind)
    local fact = profile and profile.facts and profile.facts[kind]
    T.truthy(fact, "missing backstory fact: " .. tostring(kind))
    return fact
end

local record = PNC.Types.NewRecord({
    id = "npc:backstory:stable",
    displayName = "Stable Backstory NPC",
    identitySeed = 90210,
    archetypeID = "parity_merchant",
    tacticalClass = "colonist",
    x = 10,
    y = 20,
    z = 0,
})
record.currentResidence = "Rosewood"
record.medicalStatus = "healthy"

local initial = Memory.GetBackstoryProfile(record)
T.truthy(initial.saveSeed ~= nil,
    "backstory profile exposes the deterministic save seed projection")
local initialHometown = profileFact(initial, "hometown")
local initialJob = profileFact(initial, "former_job")
local payload = PNC.Persistence.SerializeRecord(record)
T.truthy(payload and payload.identity, "backstory persistence payload missing")
T.truthy(payload.identity.backstory, "stable backstory metadata missing")
T.equal(payload.identity.backstory.schemaVersion, 1,
    "backstory metadata schema changed")
T.equal(payload.identity.backstory.selectionClass, "colonist",
    "backstory selection class changed")
T.equal(payload.identity.backstory.selections.hometown, initialHometown.id,
    "hometown stable ID was not serialized")
T.equal(payload.identity.backstory.selections.former_job, initialJob.id,
    "former job stable ID was not serialized")
T.falsy(payload.identity.backstory.value,
    "resolved backstory value leaked into persistence")
T.falsy(payload.identity.backstory.textKey,
    "localized backstory text leaked into persistence")
T.falsy(payload.identity.backstory.facts,
    "complete generated biography leaked into persistence")
T.falsy(payload.identity.currentResidence,
    "mutable residence was persisted as immutable identity")
T.falsy(payload.identity.medicalStatus,
    "mutable medical status was persisted as immutable identity")

local saveOnly = PNC.Types.NewRecord({
    id = "npc:backstory:save-only",
    displayName = "Save Only Backstory NPC",
    identitySeed = 90211,
    archetypeID = "parity_merchant",
    tacticalClass = "colonist",
    x = 11,
    y = 21,
    z = 0,
})
local saveOnlyPayload = PNC.Persistence.SerializeRecord(saveOnly)
T.truthy(saveOnlyPayload.identity.backstory,
    "durable save did not pin an unqueried backstory")
T.truthy(saveOnlyPayload.identity.backstory.selections.hometown,
    "durable save omitted the hometown stable ID")

-- Catalog growth and a new catalog epoch must keep an established ID pinned.
local originalCatalogVersion = Memory.BACKSTORY_CATALOG_VERSION
Memory.RegisterBackstory({
    id = "backstory.shared.hometown.catalog_growth_probe",
    class = "shared",
    kind = "hometown",
    value = "catalog_growth_probe",
    textKey = "hometown.rosewood",
})
Memory.BACKSTORY_CATALOG_VERSION = originalCatalogVersion + 1
local afterCatalogChange = Memory.GetBackstoryProfile(record)
T.equal(profileFact(afterCatalogChange, "hometown").id, initialHometown.id,
    "catalog growth rerolled established hometown")
T.equal(profileFact(afterCatalogChange, "former_job").id, initialJob.id,
    "catalog growth rerolled established former job")

local restored = PNC.Persistence.DeserializeRecord(payload, record.id)
T.truthy(restored, "stable backstory payload did not reload")
local reloaded = Memory.GetBackstoryProfile(restored)
T.equal(profileFact(reloaded, "hometown").id, initialHometown.id,
    "save/reload changed established hometown")
T.equal(profileFact(reloaded, "former_job").id, initialJob.id,
    "save/reload changed established former job")
T.equal(reloaded.identitySeed, initial.identitySeed,
    "save/reload changed identity seed")

-- Authored identity definitions may override a fact by stable ID, without
-- embedding its prose or resolved value.
local authored = PNC.Types.NewRecord({
    id = "npc:backstory:authored",
    displayName = "Authored Backstory NPC",
    identitySeed = 77,
    archetypeID = "parity_merchant",
    tacticalClass = "colonist",
    identity = {
        backstory = {
            schemaVersion = 1,
            catalogVersion = originalCatalogVersion,
            selectionClass = "colonist",
            overrides = {
                hometown = "backstory.shared.hometown.rosewood",
            },
        },
    },
})
local authoredProfile = Memory.GetBackstoryProfile(authored)
T.equal(profileFact(authoredProfile, "hometown").id,
    "backstory.shared.hometown.rosewood",
    "authored stable-ID override was ignored")
local authoredPayload = PNC.Persistence.SerializeRecord(authored)
T.equal(authoredPayload.identity.backstory.overrides.hometown,
    "backstory.shared.hometown.rosewood",
    "authored stable-ID override was not persisted")
T.falsy(authoredPayload.identity.backstory.value,
    "authored resolved backstory value leaked into persistence")

-- Legacy records without metadata can still reconstruct from the current
-- seed/catalog, then become pinned on their next durable write.
local legacyPayload = copy(payload)
legacyPayload.identity.backstory = nil
local legacy = PNC.Persistence.DeserializeRecord(legacyPayload, record.id)
T.truthy(legacy, "legacy identity without backstory metadata was rejected")
local legacyProfile = Memory.GetBackstoryProfile(legacy)
T.truthy(profileFact(legacyProfile, "hometown").id,
    "legacy seed reconstruction produced no hometown")
T.truthy(legacy.identity.backstory,
    "legacy profile was not pinned after reconstruction")

Memory.BACKSTORY_CATALOG_VERSION = originalCatalogVersion

-- Unpinned profiles use the Core save-seed boundary in addition to the NPC
-- identity seed.  This keeps the same identity coherent across one save while
-- allowing another save to produce a different authored biography.
local seededA = PNC.Types.NewRecord({
    id = "npc:backstory:seed-a",
    displayName = "Seed A",
    identitySeed = 90212,
    tacticalClass = "colonist",
})
seededA.saveSeed = "projection-save-a"
local seededProfileA = Memory.GetBackstoryProfile(seededA)
local selectedA = profileFact(seededProfileA, "hometown").id
local changedProjection = false
for index = 1, 32 do
    local candidate = PNC.Types.NewRecord({
        id = "npc:backstory:seed-b:" .. tostring(index),
        displayName = "Seed B " .. tostring(index),
        identitySeed = 90212,
        tacticalClass = "colonist",
    })
    candidate.saveSeed = "projection-save-b:" .. tostring(index)
    local candidateProfile = Memory.GetBackstoryProfile(candidate)
    if profileFact(candidateProfile, "hometown").id ~= selectedA then
        changedProjection = true
        break
    end
end
T.truthy(changedProjection,
    "save seed participates in unpinned backstory selection")

T.finish("pnc_backstory_persistence_stability_smoke")
