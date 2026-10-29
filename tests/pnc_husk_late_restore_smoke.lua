local T = require "tests/support/test"
T.addPackagePaths()

local ROOT = T.path("ProjectHoomans", "shared", "PNC/Core/")
local store = {
    -- Production is v2; this deliberately exercises migration of the v1
    -- nine-field row instead of silently dropping an existing-save husk.
    layoutVersion = 1,
    entries = {},
}
local records = {}
local now = 1000

local function makeList(count)
    return {
        size = function() return count or 0 end,
    }
end

PNC = {
    Core = {
        Now = function() return now end,
        IsAuthority = function() return true end,
        IsManagedNPCBody = function() return false end,
        GenerateID = function(prefix) return prefix .. "_late_restore" end,
        LogWarn = function() end,
        LogInfo = function() end,
        LogDebug = function() end,
    },
    Const = {
        HUSK_LEDGER_MODDATA_KEY = "PNC_LateRestoreTest",
        HUSK_LEDGER_LAYOUT_VERSION = 2,
        HUSK_LEDGER_MATCH_RADIUS = 2,
        HUSK_LEDGER_MAX_ENTRIES = 8,
        HUSK_LEDGER_MAX_PER_RECORD = 2,
        HUSK_LEDGER_TTL_HOURS = 72,
        PRESENCE_LIVE = "live",
        PRESENCE_ABSTRACT = "abstract",
        PRESENCE_CORPSE = "corpse",
        ORDER_FOLLOW = "follow",
        BODY_SHELL_REHYDRATE_ANON_RADIUS = 1.0,
        BODY_TAG_VERSION = 1,
        BODY_SHELL_VERSION = 1,
        BODY_SHELL_RESPAWN_DELAY_MS = 50,
        BODY_SHELL_MAINTENANCE_MS = 1000,
        BODY_SHELL_STARTUP_PASSES = 3,
        BODY_SHELL_STARTUP_SETTLE_MS = 1500,
    },
    Network = {
        BroadcastBodyRemoval = function() end,
    },
    LiveBodyControl = {
        ApplyHumanizedBodyFlags = function() end,
        SuppressZombieSounds = function() end,
    },
}

ModData = {
    getOrCreate = function() return store end,
}

getGameTime = function()
    return {
        getWorldAgeHours = function() return 100 end,
    }
end

PNC.Registry = {
    LiveByID = {},
    Loaded = true,
    EnsureLoaded = function() end,
    Get = function(id) return records[tostring(id)] end,
    ForEach = function(callback)
        for _, record in pairs(records) do callback(record) end
    end,
}

local function makeBody(spec)
    local body
    local modData = spec.modData or {}
    local removed = false
    body = {
        getX = function() return spec.x end,
        getY = function() return spec.y end,
        getZ = function() return spec.z or 0 end,
        getPersistentOutfitID = function() return spec.outfitID end,
        getModData = function() return modData end,
        getWornItems = function() return makeList(spec.clothed and 1 or 0) end,
        getItemVisuals = function() return makeList(spec.clothed and 1 or 0) end,
        isDead = function() return removed end,
        removeFromWorld = function() removed = true end,
        removeFromSquare = function() removed = true end,
    }
    body.wasRemoved = function() return removed end
    return body
end

T.load(ROOT .. "Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_State.lua")
T.load(ROOT .. "Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_World.lua")
T.load(ROOT .. "Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_HuskLedger.lua")
T.load(ROOT .. "Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_Startup.lua")

local Lifecycle = PNC.BodyLifecycle

-- Legacy row: the old implementation persisted outfit id 0. It must still be
-- recoverable when the NPC is abstract and the restored body arrives late,
-- even after the startup coordinator has already gone quiet.
records.legacy = {
    id = "legacy",
    alive = true,
    presenceState = "abstract",
    x = 100,
    y = 200,
    z = 0,
    runtime = {},
}
store.entries = {
    { 100.4, 200.6, 0, "0", 100, 0, "legacy",
        "audit_after_virtualization" },
}
local legacyBody = makeBody({
    x = 100.4, y = 200.6, z = 0, clothed = true, outfitID = 0,
})
T.equal(Lifecycle.HuskLedgerCount(), 1, "legacy ledger row did not load")
T.truthy(Lifecycle.FindHuskEntry(legacyBody),
    "zero-identity legacy row was not position matched")
T.truthy(Lifecycle.InterceptLoadedShell(legacyBody, "late_restore"),
    "late restored legacy shell was not intercepted")
T.equal(legacyBody.wasRemoved(), true,
    "late restored legacy shell remained in the world")
T.equal(Lifecycle.HuskLedgerCount(), 0,
    "legacy row was not consumed after verified removal")

-- Some older startup seeds contain the historical nonzero outfit id even
-- though the body restored by PZ now reports zero. That mixed row is also a
-- migration case, not a new identity proof.
Lifecycle.HuskLedger.loaded = false
Lifecycle.HuskLedger.entries = {}
Lifecycle.HuskLedger.index = {}
store.entries = {
    { 150.4, 250.6, 0, "777", 100, 0, "legacy_seed", "startup_seed" },
}
records.legacy_seed = {
    id = "legacy_seed",
    alive = true,
    presenceState = "abstract",
    x = 150,
    y = 250,
    z = 0,
    runtime = {},
}
local legacySeedBody = makeBody({ x = 150.4, y = 250.6, z = 0 })
T.truthy(Lifecycle.InterceptLoadedShell(legacySeedBody, "late_seed_restore"),
    "mixed startup seed shell was not intercepted")
T.equal(legacySeedBody.wasRemoved(), true,
    "mixed startup seed shell remained in the world")

-- Multiplayer can finish startup before this chunk is streamed. A replacement
-- companion may already be canonical when the old zero-ID startup shell later
-- enters the server census. That old shell is still a duplicate, but only the
-- narrow owned/following startup_seed lane may reclaim it.
Lifecycle.HuskLedger.loaded = false
Lifecycle.HuskLedger.entries = {}
Lifecycle.HuskLedger.index = {}
store.entries = {
    { 175.25, 275.25, 0, "888", 100, 0, "mp_late_companion",
        "startup_seed" },
}
records.mp_late_companion = {
    id = "mp_late_companion",
    alive = true,
    recruited = true,
    ownerUsername = "alice",
    ownerOnlineID = 41,
    orderSpec = { kind = "follow" },
    presenceState = "live",
    x = 180,
    y = 280,
    z = 0,
    runtime = { bodyLease = "new_mp_lease" },
}
local mpCanonical = makeBody({
    x = 180, y = 280, z = 0, outfitID = 999,
    modData = {
        PNC_UUID = "mp_late_companion",
        PNC_NPC = true,
        PNC_BodyKind = "live",
        PNC_BodyLease = "new_mp_lease",
    },
})
PNC.Registry.LiveByID.mp_late_companion = mpCanonical
local mpLateHusk = makeBody({
    x = 175.25, y = 275.25, z = 0, outfitID = 0, clothed = true,
})
T.truthy(Lifecycle.FindHuskEntry(mpLateHusk),
    "late-stream MP startup shell was hidden by the replacement canonical body")
T.truthy(Lifecycle.InterceptLoadedShell(mpLateHusk, "mp_late_stream"),
    "late-stream MP startup shell was not reclaimed")
T.equal(mpLateHusk.wasRemoved(), true,
    "late-stream MP startup shell survived beside the replacement companion")

-- The same positional evidence is not sufficient for an unowned neutral.
Lifecycle.HuskLedger.loaded = false
Lifecycle.HuskLedger.entries = {}
Lifecycle.HuskLedger.index = {}
store.entries = {
    { 190.25, 290.25, 0, "777", 100, 0, "mp_neutral",
        "startup_seed" },
}
records.mp_neutral = {
    id = "mp_neutral",
    alive = true,
    recruited = false,
    presenceState = "live",
    x = 195,
    y = 295,
    z = 0,
    runtime = { bodyLease = "neutral_lease" },
}
local neutralCanonical = makeBody({
    x = 195, y = 295, z = 0, outfitID = 778,
    modData = {
        PNC_UUID = "mp_neutral",
        PNC_NPC = true,
        PNC_BodyKind = "live",
        PNC_BodyLease = "neutral_lease",
    },
})
PNC.Registry.LiveByID.mp_neutral = neutralCanonical
local ordinaryNearOldNeutral = makeBody({
    x = 190.25, y = 290.25, z = 0, outfitID = 0, clothed = true,
})
T.falsy(Lifecycle.FindHuskEntry(ordinaryNearOldNeutral),
    "position-only ordinary zombie was attributed to an unowned neutral")
T.equal(ordinaryNearOldNeutral.wasRemoved(), false,
    "ordinary zombie near an old neutral position was removed")

-- Vehicle reservation: an anonymous stale shell may be removed, but a marked
-- canonical passenger body must remain owned by the vehicle lane.
Lifecycle.HuskLedger.loaded = false
Lifecycle.HuskLedger.entries = {}
Lifecycle.HuskLedger.index = {}
store.entries = {
    { 300.4, 400.6, 0, "0", 100, 0, "passenger",
        "audit_after_virtualization" },
}
records.passenger = {
    id = "passenger",
    alive = true,
    presenceState = "live",
    x = 300,
    y = 400,
    z = 0,
    runtime = { vehiclePassenger = { active = true } },
}
local passengerShell = makeBody({ x = 300.4, y = 400.6, z = 0 })
T.truthy(Lifecycle.InterceptLoadedShell(passengerShell, "vehicle_shell"),
    "anonymous vehicle shell was not reclaimed")
T.equal(passengerShell.wasRemoved(), true,
    "anonymous vehicle shell remained in the world")

Lifecycle.HuskLedger.loaded = false
Lifecycle.HuskLedger.entries = {}
Lifecycle.HuskLedger.index = {}
store.entries = {
    { 500.4, 600.6, 0, "0", 100, 0, "canonical_passenger",
        "audit_after_virtualization" },
}
records.canonical_passenger = {
    id = "canonical_passenger",
    alive = true,
    presenceState = "live",
    x = 500,
    y = 600,
    z = 0,
    runtime = {
        bodyLease = "lease_passenger",
        vehiclePassenger = { active = true },
    },
}
local canonical = makeBody({
    x = 500.4,
    y = 600.6,
    z = 0,
    modData = {
        PNC_UUID = "canonical_passenger",
        PNC_NPC = true,
        PNC_BodyKind = "live",
        PNC_BodyLease = "lease_passenger",
    },
})
PNC.Registry.LiveByID.canonical_passenger = canonical
T.falsy(Lifecycle.InterceptLoadedShell(canonical, "vehicle_canonical"),
    "canonical vehicle passenger was intercepted as a husk")
T.equal(canonical.wasRemoved(), false,
    "canonical vehicle passenger body was removed")

T.finish("pnc_husk_late_restore_smoke")
