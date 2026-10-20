-- B6 bounded persistence, lazy-generation, and synthetic scaling acceptance.
-- This exercises the real production record serializer and uses the same
-- bounded JSON encoder as the semantic worker to measure the emitted payload.
local T = require "tests/support/test"

T.addPackagePaths()
package.path = "./tools/semantic_harness/lua/?.lua;" .. package.path
local Protocol = require "worker/Protocol"

T.load("tests/pnc_npc_foundation_parity_baseline_smoke.lua")
T.load(
    "ProjectHoomans",
    "common_lua",
    "PNC/Conversation/Definitions/Memory/00_PNC_ConversationMemoryDefinitions.lua"
)

local Memory = PNC.Conversation.Memory
local Persistence = PNC.Persistence

local function newRecord(index)
    return PNC.Types.NewRecord({
        id = "npc:b6:scale:" .. tostring(index),
        displayName = "B6 Scale NPC " .. tostring(index),
        identitySeed = 700000 + index,
        archetypeID = "parity_merchant",
        tacticalClass = index % 3 == 0 and "neutral" or "colonist",
        x = index,
        y = index * 2,
        z = 0,
        equipment = { worn = {}, attached = {} },
    })
end

local function encodedPayload(record)
    local payload = Persistence.SerializeRecord(record)
    T.truthy(payload, "B6 record did not serialize")
    local encoded = Protocol.encode(payload)
    local restored = Protocol.decode(encoded)
    T.truthy(restored and restored.identity,
        "serialized persistence payload did not round-trip")
    return payload, encoded
end

local record = newRecord(1)
local payload, encoded = encodedPayload(record)
local metadata = payload.identity and payload.identity.backstory
T.truthy(metadata, "serialized NPC omitted identity backstory metadata")
T.equal(metadata.schemaVersion, 1, "backstory metadata schema changed")
T.truthy(metadata.selections and metadata.selections.hometown,
    "serialized NPC omitted the stable hometown selection")
T.equal(metadata.value, nil, "serialized metadata leaked a resolved value")
T.equal(metadata.facts, nil, "serialized metadata leaked the biography table")
T.equal(metadata.textKey, nil, "serialized metadata leaked localized prose")
T.truthy(#encoded < 20000,
    "single serialized NPC payload exceeded the bounded footprint")
T.truthy(#Protocol.encode(metadata) < 2048,
    "identity backstory metadata exceeded the sparse footprint")

-- Saving an unqueried NPC pins only its stable selection IDs.  It must not
-- call the profile materializer, which remains a dialogue/provider read.
local profileCalls = 0
local originalProfile = Memory.GetBackstoryProfile
Memory.GetBackstoryProfile = function(value)
    profileCalls = profileCalls + 1
    return originalProfile(value)
end
local unqueried = newRecord(2)
local unqueriedPayload = Persistence.SerializeRecord(unqueried)
T.truthy(unqueriedPayload and unqueriedPayload.identity.backstory,
    "save did not pin an unqueried NPC's backstory metadata")
T.equal(profileCalls, 0,
    "persistence eagerly materialized a complete backstory profile")
local queried = Memory.GetBackstoryProfile(unqueried)
T.truthy(queried and queried.facts and queried.facts.hometown,
    "lazy backstory read could not reconstruct the pinned selection")
T.equal(profileCalls, 1, "backstory profile read was not demand-driven")
Memory.GetBackstoryProfile = originalProfile

local function measurePopulation(count)
    local records = {}
    for index = 1, count do
        local current = newRecord(index + 10)
        records[current.id] = current
    end
    local saved = Persistence.SaveAll(records)
    local encodedCollection = Protocol.encode(saved)
    local firstPayload = saved["npc:b6:scale:11"]
    return #encodedCollection, records,
        firstPayload and firstPayload.identity.backstory or nil
end

local baselineBytes, baselineRecords, baselineMetadata = measurePopulation(100)
T.truthy(baselineBytes >= #encoded * 90,
    "100-NPC serialized baseline was unexpectedly truncated")
T.truthy(baselineBytes <= #encoded * 140,
    "100-NPC serialized footprint grew superlinearly")
T.equal(baselineMetadata.value, nil,
    "100-NPC metadata leaked a generated value")
T.equal(baselineMetadata.facts, nil,
    "100-NPC metadata leaked generated biographies")

local syntheticStart = os.clock()
local syntheticBytes = measurePopulation(1000)
local syntheticSeconds = os.clock() - syntheticStart
T.truthy(syntheticBytes > baselineBytes,
    "larger synthetic population emitted no additional persistence payload")
T.truthy(syntheticBytes <= baselineBytes * 12,
    "larger synthetic persistence footprint was not approximately linear")
T.truthy(syntheticSeconds < 20,
    "larger synthetic persistence probe exceeded its bounded runtime")

-- The 100-persistent-NPC baseline is intentionally retained as live records
-- only for this bounded test.  No backstory profile is attached to any
-- record, and the existing serializer remains the only durable projection.
local baselineCount = 0
for _ in pairs(baselineRecords) do baselineCount = baselineCount + 1 end
T.equal(baselineCount, 100, "100-NPC persistent baseline was not built")

if os.getenv("PZ_TEST_VERBOSE") == "1" then
    print("b6_persistence_metrics single_bytes=" .. tostring(#encoded)
        .. " metadata_bytes=" .. tostring(#Protocol.encode(metadata))
        .. " baseline_100_bytes=" .. tostring(baselineBytes)
        .. " synthetic_1000_bytes=" .. tostring(syntheticBytes)
        .. " synthetic_seconds=" .. tostring(syntheticSeconds))
end

T.finish("pnc_grounded_personal_dialogue_b6_smoke")
