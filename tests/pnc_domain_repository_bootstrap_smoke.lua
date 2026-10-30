local T = require "tests/support/test"
T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "PsychopatzCore", "common" },
    { "PsychopatzCore", "shared" },
})

local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, item in pairs(value) do result[key] = copy(item) end
    return result
end

PNC = { Core = { DeepCopy = copy }, Const = { PERSISTENCE_VERSION = 6 } }
local Store = require "PNC/Core/Persistence/PNC_ModDataStore"
local legacy = require "PNC/Core/Persistence/PNC_Persistence/PNC_Persistence_Reset"
T.equal(Store, legacy, "legacy storage import keeps the same canonical object")
T.equal(Store, PNC.Persistence.Reset, "legacy namespace has no duplicate store")
T.equal(Store, PNC.ModDataStore, "public storage mechanism is canonical")
T.falsy(PNC.Persistence.SerializeRecord, "storage cannot load record policy")
T.falsy(PNC.Conversation, "storage cannot load conversation")

local Repository = require "PNC/Core/Inventory/PNC_InventoryRepository"
local snapshot = { 2, "BASELINE_DELTA", 17, { seed = 123 }, {} }
local record = { persistenceSourceVersion = 6, persistedInventory = snapshot }
local hydrated = 0
PNC.Inventory.EnsureRecordInventory = function(value)
    hydrated = hydrated + 1
    value.inventory = { revision = 17 }
end
PNC.Inventory.Serialize = function(value)
    return { "promoted", value.inventory.revision }
end
local payload = Repository.SerializeRecord(record)
T.equal(payload[3], 17, "current deferred payload preserves inventory revision")
T.equal(hydrated, 0, "saving current deferred payload avoids hydration")
T.truthy(payload ~= snapshot, "deferred payload is copied at the save boundary")
record.persistenceSourceVersion = 5
payload = Repository.SerializeRecord(record)
T.equal(hydrated, 1, "older envelope promotes through owning inventory codec")
T.equal(payload[1], "promoted", "promotion uses the canonical codec")
Repository.RestoreRecord(record, snapshot)
T.falsy(record.inventory, "load leaves the inventory deferred")
T.truthy(record.persistedInventory ~= snapshot, "restored snapshot owns its copy")
T.equal(record.persistedInventory[3], 17, "restore preserves compact revision")
T.equal(hydrated, 1, "restore does not hydrate the saved inventory")

local MemoryRepository = require "PNC/Conversation/Memory/PNC_ConversationMemoryRepository"
local Memory = PNC.Conversation.Memory
local raw = { m = { d = 5, s = { 101, 2, 1 }, l = { 101, 2, 5, 2 } } }
MemoryRepository.RestoreRecord(record, raw)
T.equal(record.memory.s[1], 101, "repository restores short event codes")
T.equal(record.memory.l[4], 2, "repository preserves durable event flags")
local memoryPayload = MemoryRepository.SerializeRecord(record)
T.equal(memoryPayload.v, 2, "repository retains the established memory schema")
T.truthy(memoryPayload ~= record.memory, "event serializer returns an owned payload")
T.falsy(package.loaded["PNC/Conversation/Memory/PNC_ConversationMemory_BackstoryContext"],
    "repository does not load contextual realization")
T.falsy(package.loaded["PNC/Conversation/Memory/Events/PNC_ConversationMemory_Events_Recorder"],
    "repository does not load interaction recording")
T.falsy(package.loaded["PNC/Conversation/Memory/Events/PNC_ConversationMemory_Events_Targets"],
    "repository does not load speaker/target resolution")
T.falsy(package.loaded["PNC/Conversation/Memory/PNC_ConversationMemory_Gossip"],
    "repository does not load gossip selection/rendering")
T.truthy(type(Memory.RegisterGossipTemplate) == "function",
    "partial definition loading keeps its declarative gossip registration seam")

local full = require "PNC/Conversation/Memory/PNC_ConversationMemory"
T.equal(full, Memory, "full facade extends the same memory owner")
T.equal(full.Repository, MemoryRepository, "full facade retains the repository")
T.truthy(type(full.RenderGossipPacket) == "function", "full gossip behavior is available")
T.equal(PNC.Semantics.ConversationMemoryProvider.Implementation, Memory,
    "semantic adapter binds the canonical memory table")

T.finish("pnc_domain_repository_bootstrap_smoke")
