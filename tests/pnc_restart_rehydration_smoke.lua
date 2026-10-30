local T = require "tests/support/test"
T.addPackagePaths()

local ROOT = T.path(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Presence/PNC_BodyLifecycle/"
)

local now = 1000
local events = {}
local removed = {}
local consumed = {}
local quarantineCount = 0
local rebindSucceeds = true
local bodyIsNaked = true

local record = {
    id = "npc_restart_rehydrate",
    alive = true,
    presenceState = "abstract",
    x = 100,
    y = 200,
    z = 0,
    runtime = {
        startupRehydrateExpected = true,
        startupBodyHint = {
            instanceID = "saved_outfit",
            populationId = nil,
            lease = "saved_lease",
            x = 100.2,
            y = 200.2,
            z = 0,
            wasLive = true,
        },
    },
}

local function makeBody(name, x, y)
    return {
        name = name,
        x = x,
        y = y,
        z = 0,
        getX = function(self) return self.x end,
        getY = function(self) return self.y end,
        getZ = function(self) return self.z end,
        getPersistentOutfitID = function() return 0 end,
        getModData = function() return {} end,
        isDead = function() return false end,
    }
end

local bodyA = makeBody("winner", 100.2, 200.2)
local bodyB = makeBody("duplicate", 100.8, 200.8)
local bodies = { bodyA, bodyB }
local entries = {
    [bodyA] = {
        npcId = record.id,
        reason = "startup_seed",
        x = bodyA.x,
        y = bodyA.y,
        z = bodyA.z,
    },
    [bodyB] = {
        npcId = record.id,
        reason = "startup_seed",
        x = bodyB.x,
        y = bodyB.y,
        z = bodyB.z,
    },
}

PNC = {
    Core = {
        Now = function() return now end,
        IsAuthority = function() return true end,
        IsManagedNPCBody = function() return false end,
    },
    Const = {
        PRESENCE_LIVE = "live",
        PRESENCE_ABSTRACT = "abstract",
        PRESENCE_CORPSE = "corpse",
    },
    BodyLifecycle = {
        Internal = {},
        StartupCleanup = {
            begun = true,
            lastBatch = nil,
        },
    },
    LiveBodyControl = {
        ApplyHumanizedBodyFlags = function()
            quarantineCount = quarantineCount + 1
        end,
        SuppressZombieSounds = function() end,
    },
}

local Registry = {
    Loaded = true,
    LiveByID = {},
}
function Registry.EnsureLoaded() end
function Registry.Get(id)
    return tostring(id) == record.id and record or nil
end
function Registry.GetLiveZombie(id)
    return Registry.LiveByID[tostring(id)]
end
function Registry.ForEach(callback)
    callback(record)
end
PNC.Registry = Registry

local Internal = PNC.BodyLifecycle.Internal
Internal.registry = function() return Registry end
Internal.IsProtectedBody = function() return false end
Internal.GetLiveShellIdentity = function()
    return nil, false, false
end
Internal.IsNakedStartupShell = function() return bodyIsNaked end
Internal.StartupDistanceSqToRecord = function(body, candidate)
    local dx = body:getX() - candidate.x
    local dy = body:getY() - candidate.y
    return dx * dx + dy * dy
end
Internal.GetStartupRecordCandidates = function()
    return {}
end
Internal.IsCanonicalStartupBody = function(candidate, body)
    return candidate.presenceState == "live"
        and Registry.LiveByID[candidate.id] == body
end
Internal.RemoveStartupShell = function(candidate, body, reason)
    removed[body] = reason
    events[#events + 1] = "remove:" .. tostring(body.name)
    return true
end
Internal.clearBodyCombat = function() end

function PNC.BodyLifecycle.FindHuskEntry(body)
    return entries[body]
end
function PNC.BodyLifecycle.IsLegacyAnonymousHusk(entry, body)
    return entry ~= nil and entries[body] == entry
end
function PNC.BodyLifecycle.ConsumeHuskEntry(entry)
    consumed[entry] = true
    return true
end

PNC.Presence = {
    RebindRestoredBody = function(candidate, body)
        events[#events + 1] = "rebind:" .. tostring(body.name)
        if not rebindSucceeds then
            return false
        end
        candidate.presenceState = "live"
        candidate.runtime.bodyLease = "saved_lease"
        Registry.LiveByID[candidate.id] = body
        return true
    end,
}

local function makeList(values)
    return {
        size = function() return #values end,
        get = function(_, index) return values[index + 1] end,
    }
end

getCell = function()
    return {
        getZombieList = function() return makeList(bodies) end,
    }
end

T.load(ROOT .. "PNC_BodyLifecycle_Startup/PNC_BodyLifecycle_Startup_Batch.lua")
T.load(ROOT .. "PNC_BodyLifecycle_Startup/PNC_BodyLifecycle_Startup_Sweep.lua")

-- Single-player restore: population identity is unavailable, but the current
-- save says the NPC owned a live body and the startup ledger proves two
-- historical shells at that saved location. Adopt one winner before cleanup.
local stats = PNC.BodyLifecycle.SweepPersistedLiveShells(now)
T.equal(stats.rebound, 1, "restored body was not rebound")
T.equal(stats.removed, 1, "duplicate restored shell was not removed")
T.equal(Registry.LiveByID[record.id], bodyA,
    "closest saved-live body was not selected as rehydration winner")
T.equal(removed[bodyA], nil, "rehydration winner was deleted")
T.equal(removed[bodyB], "startup_rehydrate_duplicate",
    "duplicate shell used the wrong cleanup lane")
T.equal(events[1], "rebind:winner",
    "duplicate cleanup ran before the rehydration claim")
T.equal(events[2], "remove:duplicate",
    "duplicate shell was not cleaned after rebind")
T.truthy(consumed[entries[bodyA]],
    "winner ledger proof was not consumed after successful rebind")
T.equal(record.runtime.startupRehydrateExpected, nil,
    "rehydration claim remained armed after successful adoption")

-- A transient rebind failure must fail closed: keep the only viable restored
-- body harmless and retry it instead of deleting it and forcing replacement.
record.presenceState = "abstract"
record.runtime.bodyLease = nil
record.runtime.startupRehydrateExpected = true
Registry.LiveByID[record.id] = nil
bodies = { bodyA }
removed = {}
events = {}
quarantineCount = 0
rebindSucceeds = false
PNC.BodyLifecycle.StartupCleanup.lastBatch = nil

stats = PNC.BodyLifecycle.SweepPersistedLiveShells(now + 1)
T.equal(stats.rebound, 0, "failed rebind was counted as successful")
T.equal(removed[bodyA], nil, "failed rebind destroyed the restored body")
T.truthy((stats.blocked or 0) > 0,
    "failed rebind did not keep startup reconciliation blocked")
T.truthy(quarantineCount > 0,
    "failed rebind body was not neutralized while awaiting retry")

-- Early zombie callbacks are quarantine-only for a current-save live-body
-- claim. They must not race the batch arbiter and destructively remove it.
removed = {}
events = {}
quarantineCount = 0
PNC.BodyLifecycle.StartupCleanup.begun = true
local intercepted = PNC.BodyLifecycle.InterceptLoadedShell(
    bodyA,
    "test_early_callback"
)
T.falsy(intercepted, "early callback claimed a destructive interception")
T.equal(removed[bodyA], nil, "early callback removed rehydration candidate")
T.truthy(quarantineCount > 0,
    "early callback did not neutralize rehydration candidate")

-- Legacy pre-token save: exact current-save live-body ownership plus one
-- unique zero-ID companion shell gets a bounded settle/rebind migration lane.
-- It is adoption-only; anonymous bodies never become duplicate-deletion proof.
entries[bodyA] = nil
record.presenceState = "abstract"
record.recruited = true
record.orderSpec = { kind = "follow" }
record.runtime.bodyLease = nil
record.runtime.startupRehydrateExpected = true
record.runtime.startupBodyHint.wasLive = true
Registry.LiveByID[record.id] = nil
bodies = { bodyA }
bodyA.x = 100.25
bodyA.y = 200.25
removed = {}
events = {}
quarantineCount = 0
rebindSucceeds = true
now = 5000
PNC.BodyLifecycle.StartupCleanup.startedAt = now
PNC.BodyLifecycle.StartupCleanup.lastBatch = nil

stats = PNC.BodyLifecycle.SweepPersistedLiveShells(now)
T.equal(stats.rebound, 0,
    "anonymous restored follower was adopted in the frame-zero race window")
T.equal(stats.unresolvedRehydrate, 1,
    "unique legacy restored follower did not hold rehydration open")
T.truthy(quarantineCount > 0,
    "legacy restored follower was not neutralized during settle")
T.equal(Registry.LiveByID[record.id], nil,
    "anonymous restored follower bound before settle")

now = now + 800
-- Engine clothing may have appeared by now while UUID/outfit identity is
-- still absent; the same quarantined body must remain adoptable.
bodyIsNaked = false
PNC.BodyLifecycle.StartupCleanup.lastBatch = nil
stats = PNC.BodyLifecycle.SweepPersistedLiveShells(now)
T.equal(stats.rebound, 1,
    "unique legacy zero-ID follower was not adopted after settle")
T.equal(Registry.LiveByID[record.id], bodyA,
    "legacy zero-ID follower did not become the canonical live body")
T.equal(removed[bodyA], nil,
    "legacy adoption winner was removed instead of rebound")
T.equal(record.runtime.startupRehydrateExpected, nil,
    "legacy adoption did not clear the rehydration claim")

-- Legacy migration is role-agnostic. A neutral/hostile/world NPC with the same
-- current-save live lease proof gets the same unique adoption lane.
record.presenceState = "abstract"
record.recruited = false
record.orderSpec = nil
record.ownerUsername = nil
record.runtime.bodyLease = nil
record.runtime.startupRehydrateExpected = true
record.runtime.startupBodyHint.wasLive = true
Registry.LiveByID[record.id] = nil
bodies = { bodyA }
removed = {}
events = {}
quarantineCount = 0
bodyIsNaked = false
now = 6200
PNC.BodyLifecycle.StartupCleanup.startedAt = now - 2000
PNC.BodyLifecycle.StartupCleanup.lastBatch = nil

stats = PNC.BodyLifecycle.SweepPersistedLiveShells(now)
T.equal(stats.rebound, 1,
    "unique saved-live world NPC was not adopted")
T.equal(Registry.LiveByID[record.id], bodyA,
    "role-agnostic legacy migration did not bind world NPC")
T.equal(removed[bodyA], nil,
    "role-agnostic legacy adoption deleted its winner")

-- Safety boundary: two anonymous bodies that could both be the saved companion
-- are ambiguous. Neither may be adopted or deleted.
entries[bodyB] = nil
record.presenceState = "abstract"
record.runtime.bodyLease = nil
record.runtime.startupRehydrateExpected = true
record.runtime.startupBodyHint.wasLive = true
Registry.LiveByID[record.id] = nil
bodyA.x, bodyA.y = 100.25, 200.25
bodyB.x, bodyB.y = 100.8, 200.8
bodies = { bodyA, bodyB }
removed = {}
events = {}
quarantineCount = 0
bodyIsNaked = false
now = 6500
PNC.BodyLifecycle.StartupCleanup.startedAt = now - 2000
PNC.BodyLifecycle.StartupCleanup.lastBatch = nil

stats = PNC.BodyLifecycle.SweepPersistedLiveShells(now)
T.equal(stats.rebound, 0,
    "ambiguous anonymous bodies produced a rehydration winner")
T.equal(Registry.LiveByID[record.id], nil,
    "ambiguous anonymous body became canonical")
T.equal(removed[bodyA], nil,
    "first ambiguous anonymous body was deleted")
T.equal(removed[bodyB], nil,
    "second ambiguous anonymous body was deleted")
T.truthy((stats.ambiguous or 0) >= 2,
    "anonymous ambiguity was not surfaced")

-- Without the persisted current-save lease/engine proof, a positional
-- ordinary zombie remains unknown even for a non-owned NPC record.
bodies = { bodyA }
record.presenceState = "abstract"
record.recruited = false
record.orderSpec = nil
record.ownerUsername = nil
record.runtime.startupRehydrateExpected = true
record.runtime.startupBodyHint.lease = nil
record.runtime.startupBodyHint.instanceID = nil
record.runtime.startupBodyHint.populationId = nil
bodyIsNaked = true
Registry.LiveByID[record.id] = nil
removed = {}
events = {}
quarantineCount = 0
now = 7000
PNC.BodyLifecycle.StartupCleanup.startedAt = now - 2000
PNC.BodyLifecycle.StartupCleanup.lastBatch = nil

stats = PNC.BodyLifecycle.SweepPersistedLiveShells(now)
T.equal(stats.rebound, 0,
    "position-only ordinary zombie was incorrectly adopted")
T.truthy((stats.ordinaryUnknown or 0) > 0,
    "ordinary anonymous zombie did not remain in the unknown lane")
T.equal(Registry.LiveByID[record.id], nil,
    "ordinary anonymous zombie became a live NPC")

-- The startup coordinator must not burn all reconciliation attempts in frame
-- zero. A unique anonymous companion keeps startup active, then a later tick
-- re-evaluates and adopts it after the settle interval.
record.presenceState = "abstract"
record.recruited = true
record.orderSpec = { kind = "follow" }
record.runtime.startupRehydrateExpected = true
record.runtime.startupBodyHint.wasLive = true
record.runtime.startupBodyHint.lease = "saved_lease"
record.runtime.startupBodyHint.instanceID = "saved_outfit"
Registry.LiveByID[record.id] = nil
removed = {}
events = {}
quarantineCount = 0
rebindSucceeds = true
now = 9000
PNC.Core.LogInfo = function() end
PNC.Core.LogWarn = function() end
PNC.BodyLifecycle.HuskLedgerSeeded = false
T.load(ROOT
    .. "PNC_BodyLifecycle_Startup/PNC_BodyLifecycle_Startup_Coordinator.lua")

local startup = PNC.BodyLifecycle.RunStartupBodyCleanupNow(
    now,
    "test_frame_zero",
    true
)
T.falsy(startup.complete,
    "frame-zero unique legacy companion incorrectly completed startup")
T.equal(startup.lastStats.unresolvedRehydrate, 1,
    "frame-zero legacy companion did not hold the startup gate")
now = now + 800
PNC.BodyLifecycle.OnStartupReconcileTick()
T.equal(Registry.LiveByID[record.id], bodyA,
    "later startup tick did not adopt unique legacy companion")
T.equal(record.presenceState, "live",
    "later startup tick did not restore live presence")

-- Persistence must distinguish a body that was live when saved from an old
-- abstract body hint; this flag is the admission contract used above.
local serializeSource = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Persistence/PNC_Persistence/PNC_Persistence_Serialize.lua"
)
local deserializeSource = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Persistence/PNC_Persistence/PNC_Persistence_DeserializeFinalization.lua"
)
T.contains(serializeSource, "wasLive = record.presenceState",
    "serializer does not persist saved-live ownership")
T.contains(deserializeSource, "startupRehydrateExpected = wasLive == true",
    "deserializer does not restore saved-live rehydration claim")

return T.finish("pnc_restart_rehydration_smoke")
