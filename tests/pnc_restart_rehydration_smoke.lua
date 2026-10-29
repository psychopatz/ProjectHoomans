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
Internal.IsNakedStartupShell = function() return true end
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
