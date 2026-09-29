local T = require "tests/support/test"
T.addPackagePaths()

local SHARED = T.path("ProjectHoomans", "shared", "")

local worldHours = 100
local store = {}

PNC = {
    Core = {
        Now = function() return 1000 end,
        LogDebug = function() end,
        LogInfo = function() end,
        LogWarn = function() end,
        IsManagedNPCBody = function() return false end,
        IsAuthority = function() return true end,
    },
    Const = {
        HUSK_LEDGER_MODDATA_KEY = "Test_HuskLedger",
        HUSK_LEDGER_LAYOUT_VERSION = 1,
        HUSK_LEDGER_MAX_ENTRIES = 4,
        HUSK_LEDGER_MAX_PER_RECORD = 2,
        HUSK_LEDGER_TTL_HOURS = 72,
        HUSK_LEDGER_MATCH_RADIUS = 2.0,
    },
}

ModData = {
    getOrCreate = function()
        return store
    end,
}

getGameTime = function()
    return {
        getWorldAgeHours = function()
            return worldHours
        end,
    }
end

local function makeZombie(x, y, z, outfitId)
    return {
        getX = function() return x end,
        getY = function() return y end,
        getZ = function() return z end,
        getPersistentOutfitID = function() return outfitId end,
    }
end

local function makeRecord(id, x, y, z, hint)
    return {
        id = id,
        x = x,
        y = y,
        z = z,
        liveBodyInstanceID = hint,
        runtime = {},
    }
end

T.load(SHARED
    .. "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_State.lua")
T.load(SHARED
    .. "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_HuskLedger.lua")

local Lifecycle = PNC.BodyLifecycle
local Ledger = Lifecycle.HuskLedger

local record = makeRecord("npc_a", 100, 200, 0, "42")
local loss = makeZombie(100.4, 200.6, 0, 42)

local entry = Lifecycle.NoteLostBody(record, loss, "removal_after_virtualization")
T.truthy(entry, "lost body was not recorded")
T.near(entry.x, 100.4, 0.001, "recorded husk x")
T.near(entry.y, 200.6, 0.001, "recorded husk y")
T.equal(entry.outfitId, "42", "recorded outfit identity hint")
T.equal(entry.npcId, "npc_a", "recorded npc id")
T.equal(#Ledger.entries, 1, "ledger entry count")
-- Persistence is a compact positional payload, not the live entry tables, so
-- the global ModData does not repeat a key name per field per entry.
T.equal(#store.entries, 1, "persisted husk row count")
T.near(store.entries[1][1], 100.4, 0.001, "packed husk x")
T.equal(store.entries[1][4], "42", "packed outfit identity hint")
T.equal(store.entries[1][7], "npc_a", "packed npc id")
T.falsy(store.entries[1].x, "packed rows must not repeat field names")
T.equal(Ledger.writes, 1, "ledger write count")

-- Round trip: reloading from ModData reconstructs the same losses.
Ledger.loaded = false
Ledger.store = nil
Ledger.entries = {}
Ledger.index = {}
T.equal(Lifecycle.HuskLedgerCount(), 1, "packed ledger did not reload")
T.truthy(Lifecycle.FindHuskEntry(makeZombie(100.4, 200.6, 0, 42)),
    "reloaded loss is not matchable")
local reloaded = Ledger.entries[1]
T.equal(reloaded.npcId, "npc_a", "reloaded npc id")
T.equal(reloaded.outfitId, "42", "reloaded outfit hint")
T.falsy(reloaded.chunkKey == nil, "reloaded entries must be indexed")

-- A second loss for the same record in the same chunk refreshes the entry
-- instead of arming a second reap.
Lifecycle.NoteLostBody(record, makeZombie(101.2, 201.1, 0, 42), "removal_unverified")
T.equal(#Ledger.entries, 1, "same-chunk loss duplicated the ledger entry")
T.near(Ledger.entries[1].x, 101.2, 0.001, "refreshed husk x")
T.equal(Ledger.writes, 1, "refresh counted as a new write")
T.near(store.entries[1][1], 101.2, 0.001, "refresh was not re-persisted")

-- Without an engine identity hint a husk cannot be told apart from an ordinary
-- zombie, so no reap may be armed.
local hintless = Lifecycle.NoteLostBody(
    makeRecord("npc_hintless", 300, 300, 0, nil),
    makeZombie(300, 300, 0, nil),
    "audit_body_missing"
)
T.falsy(hintless, "identity-less loss armed a reap")
T.equal(Ledger.skipped, 1, "identity-less loss was not counted as skipped")

-- Matching is strict: outfit identity, radius and level must all agree.
T.equal(Lifecycle.FindHuskEntry(makeZombie(101.2, 201.1, 0, 42)),
    Ledger.entries[1], "matching husk body was not found")
T.falsy(Lifecycle.FindHuskEntry(makeZombie(100.4, 200.6, 0, 77)),
    "husk matched with the wrong persistent outfit")
T.falsy(Lifecycle.FindHuskEntry(makeZombie(110, 200.6, 0, 42)),
    "husk matched outside the recorded radius")
T.truthy(Lifecycle.FindHuskEntry(makeZombie(100.4, 200.6, 1, 42)),
    "husk on an adjacent level was not tolerated")
T.falsy(Lifecycle.FindHuskEntry(makeZombie(100.4, 200.6, 2, 42)),
    "husk matched on another level")

T.equal(Lifecycle.HuskLedgerCount(), 1, "ledger count before consuming")
local entry = Ledger.entries[1]
T.truthy(Lifecycle.ConsumeHuskEntry(entry), "ledger entry was not consumed")
T.equal(Lifecycle.HuskLedgerCount(), 0, "ledger count after consuming")
T.falsy(Lifecycle.FindHuskEntry(makeZombie(100.4, 200.6, 0, 42)),
    "consumed husk still matched")

-- Rearming after a failed removal keeps the loss without duplicating it.
T.truthy(Lifecycle.HuskLedgerRearm(entry), "ledger rearm was rejected")
T.truthy(Lifecycle.HuskLedgerRearm(entry), "ledger rearm duplicated the entry")
T.equal(Lifecycle.HuskLedgerCount(), 1, "ledger count after rearm")
Lifecycle.ConsumeHuskEntry(entry)

-- Per-record bound: a presence loop cannot accumulate unbounded losses.
local index
for index = 1, 5 do
    Lifecycle.NoteLostBody(
        makeRecord("npc_loop", index * 64, 0, 0, "42"),
        makeZombie(index * 64, 0, 0, 42),
        "loop"
    )
end
local loopEntries = 0
for index = 1, #Ledger.entries do
    if Ledger.entries[index].npcId == "npc_loop" then
        loopEntries = loopEntries + 1
    end
end
T.equal(loopEntries, 2, "per-record ledger bound was not enforced")

-- Total bound: oldest entries are evicted once the ledger is full.
for index = 1, 6 do
    Lifecycle.NoteLostBody(
        makeRecord("npc_fill_" .. tostring(index), index * 96, 500, 0, "42"),
        makeZombie(index * 96, 500, 0, 42),
        "fill"
    )
end
T.truthy(#Ledger.entries <= 4, "ledger total bound was not enforced")

-- TTL: world time moving forward expires stale losses.
worldHours = worldHours + 200
Lifecycle.PumpHuskLedger(2000)
T.equal(Lifecycle.HuskLedgerCount(), 0,
    "expired losses stayed armed after the ttl")
T.truthy(Ledger.expired > 0, "expiry was not counted")

-- Startup seeding: a save created before this lifecycle existed carries husks
-- whose loss was never observed. The persisted body hint is enough to arm the
-- reap for them, once per session.
local seededRecord = makeRecord("npc_seed", 600, 700, 0, nil)
seededRecord.presenceState = "abstract"
seededRecord.runtime.startupBodyHint = {
    instanceID = "42",
    x = 600.5,
    y = 700.5,
    z = 0,
}
PNC.Registry = {
    Loaded = true,
    LiveByID = {},
    EnsureLoaded = function() end,
    GetLiveZombie = function() return nil end,
    ForEach = function(callback) callback(seededRecord) end,
}
T.falsy(Lifecycle.HuskLedgerSeeded, "ledger was seeded before it was asked to")
T.equal(Lifecycle.SeedHuskLedgerFromRecords(3000), 1,
    "persisted body hint was not seeded")
T.equal(Lifecycle.SeedHuskLedgerFromRecords(3000), 0,
    "seeding was not once per session")
local seededEntry = Lifecycle.FindHuskEntry(makeZombie(600.5, 700.5, 0, 42))
T.truthy(seededEntry, "seeded loss is not matchable")
T.equal(seededEntry.npcId, "npc_seed", "seeded loss npc id")
T.near(seededEntry.x, 600.5, 0.001, "seeded loss uses the persisted position")

local diagnostics = Lifecycle.BuildHuskLedgerDiagnostics()
T.equal(diagnostics.entries, 1, "ledger diagnostics entry count")
T.equal(diagnostics.skipped, 1, "ledger diagnostics skip count")

-- Debug snapshot bounds: this feeds the World Effects window and a multiplayer
-- payload, so entries and outfit rows are capped and clearing is persisted.
Lifecycle.NoteShellOutfitID(42)
for index = 1, 6 do
    Lifecycle.NoteLostBody(
        makeRecord("npc_dbg_" .. tostring(index), 2000 + index * 64, 3000, 0, "42"),
        makeZombie(2000 + index * 64, 3000, 0, 42),
        "debug_fill"
    )
end
local snapshot = Lifecycle.BuildHuskDebugSnapshot({
    entryLimit = 3, outfitLimit = 2,
})
T.equal(#snapshot.entries, 3, "debug snapshot entry bound")
T.truthy(snapshot.truncated, "debug snapshot truncation flag")
T.truthy(snapshot.ledger.estimatedBytes > 0, "debug snapshot size estimate")
T.equal(snapshot.shellOutfits.count, 1, "debug snapshot shell outfit count")
T.equal(snapshot.shellOutfits.ids, "42", "debug snapshot shell outfit ids")
T.falsy(snapshot.bodies.disabled, "debug snapshot spawn gate default")
T.equal(snapshot.bodies.orphans, 0,
    "orphan census must be inert without a zombie-disabled world")

-- The learned shell outfit set is bounded so the persisted diagnostics cannot
-- grow every session (the engine picks an outfit id per call).
for index = 100, 160 do
    Lifecycle.NoteShellOutfitID(index)
end
T.truthy(Lifecycle.ShellOutfitCount() <= 32,
    "learned shell outfit set was not bounded")

T.truthy(Lifecycle.ClearHuskLedger(), "ledger clear failed")
T.equal(Lifecycle.HuskLedgerCount(), 0, "ledger clear left entries behind")
T.equal(#store.entries, 0, "ledger clear was not persisted")

return T.finish("pnc_husk_ledger_smoke")
