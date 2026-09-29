--[[
    End-to-end husk lifecycle.

    Simulates the exact production sequence that produced piling husks:

      1. a live shell is bound and leased (forceLive, the hostile case),
      2. the engine virtualizes it - the body loses its square and its ModData
         never returns,
      3. presence reconcile must release the record even though forceLive would
         normally keep it embodied,
      4. the loss must be recorded with an engine identity hint,
      5. the population manager hands the husk back through OnZombieCreate and
         the reaper must delete it, leaving no anonymous body behind.
]]

local T = require "tests/support/test"
T.addPackagePaths()

local SHARED = T.path("ProjectHoomans", "shared", "")
local BODY_ROOT = SHARED .. "PNC/Core/Presence/PNC_BodyLifecycle/"

local records = {}
local nowMs = 10000

PNC = {
    Core = {
        Now = function() return nowMs end,
        GenerateID = function(prefix) return prefix .. "_1" end,
        IsAuthority = function() return true end,
        LogInfo = function() end,
        LogWarn = function() end,
        LogDebug = function() end,
        IsManagedNPCBody = function() return false end,
    },
    Const = {
        PRESENCE_LIVE = "live",
        PRESENCE_ABSTRACT = "abstract",
        PRESENCE_CORPSE = "corpse",
        ORDER_FOLLOW = "follow",
        MATERIALIZE_DISTANCE = 28,
        ABSTRACT_DISTANCE = 40,
        BODY_TAG_VERSION = 1,
        BODY_LOST_GRACE_MS = 400,
        HUSK_LEDGER_MATCH_RADIUS = 2.0,
        HUSK_REAP_MAX_ATTEMPTS = 4,
    },
    BehaviorCommon = {},
    PathService = {
        Reset = function() end,
    },
    WorldCensus = {
        GetAll = function() return {} end,
    },
    Presence = {
        -- Mirrors the production early return for an already-live record: the
        -- engine body handle is handed straight back.
        Materialize = nil,
        Internal = {
            FindNearestPlayer = function()
                -- Far beyond both the materialize and abstract distances so the
                -- ordinary distance lane would keep the body either way.
                return { distSq = 100000 }
            end,
            ResolveNetwork = function() return nil end,
        },
    },
}

PNC.Presence.Materialize = function(record)
    return PNC.Registry.LiveByID[record.id]
end

PNC.Registry = {
    LiveByID = {},
    EnsureLoaded = function() end,
    MarkDirty = function() end,
    Get = function(id) return records[tostring(id)] end,
    GetLiveZombie = function(id)
        return PNC.Registry.LiveByID[tostring(id)]
    end,
    ForEach = function(callback)
        local _, record
        for _, record in pairs(records) do
            callback(record)
        end
    end,
}

getCell = function()
    return {
        getZombieList = function()
            return { size = function() return 0 end }
        end,
    }
end

getGameTime = function()
    return {
        getWorldAgeHours = function() return 50 end,
    }
end

local function makeBody(outfitId)
    local body
    body = {
        current = { x = 100, y = 200, z = 0 },
        modData = {},
        getModData = function() return body.modData end,
        getPersistentOutfitID = function() return outfitId end,
        getOnlineID = function() return 7 end,
        getX = function() return 100.4 end,
        getY = function() return 200.6 end,
        getZ = function() return 0 end,
        getCurrentSquare = function() return body.current end,
        removeFromWorld = function(self) self.removedFromWorld = true end,
        removeFromSquare = function(self)
            self.removedFromSquare = true
            self.current = nil
        end,
    }
    return body
end

T.load(BODY_ROOT .. "PNC_BodyLifecycle_State.lua")
T.load(BODY_ROOT .. "PNC_BodyLifecycle_World.lua")
T.load(BODY_ROOT .. "PNC_BodyLifecycle_HuskLedger.lua")
T.load(BODY_ROOT .. "PNC_BodyLifecycle_LiveBodies.lua")
T.load(BODY_ROOT .. "PNC_BodyLifecycle_HuskReaper.lua")
T.load(SHARED .. "PNC/Core/Behaviors/PNC_Behavior_Common.lua")
T.load(SHARED .. "PNC/Core/Presence/PNC_Presence/PNC_Presence_Decisions.lua")
T.load(SHARED .. "PNC/Core/Presence/PNC_Presence/PNC_Presence_Abstract.lua")
T.load(SHARED .. "PNC/Core/Presence/PNC_Presence/PNC_Presence_Reconcile.lua")

local Lifecycle = PNC.BodyLifecycle
local Presence = PNC.Presence
local Reaper = Lifecycle.HuskReaper

-- 1. A forceLive record with a bound, leased shell.
local record = {
    id = "npc_e2e",
    alive = true,
    presenceState = "abstract",
    x = 100,
    y = 200,
    z = 0,
    runtime = { forceLive = true },
}
records[record.id] = record
local zombie = makeBody(42)
T.equal(Lifecycle.StampLiveBody(record, zombie), "body_1",
    "live body was not leased")
PNC.Registry.LiveByID[record.id] = zombie
record.presenceState = "live"
T.equal(zombie.modData.PNC_UUID, record.id, "body was not stamped")

-- 2. The engine virtualizes the shell: `current` is cleared by removeFromSquare
-- inside ZombiePopulationManager and the ModData is not persisted anywhere.
zombie.current = nil

-- 3. Presence reconcile must release the record even though forceLive would
-- otherwise short-circuit into Materialize and never reach abstraction. The
-- first pass only arms the loss grace window; the second pass releases it.
nowMs = nowMs + 1000
Presence.Reconcile(record)
T.equal(record.presenceState, "live",
    "shell was abstracted before the loss grace window elapsed")
nowMs = nowMs + 500
Presence.Reconcile(record)
T.equal(record.presenceState, "abstract",
    "lost shell was not abstracted by reconcile")
T.equal(record.runtime.bodyLease, nil, "released shell kept its lease")
T.equal(PNC.Registry.LiveByID[record.id], nil,
    "released shell stayed in the live registry")

-- 4. The loss is remembered with the engine identity hint that survives
-- virtualization.
T.equal(Lifecycle.HuskLedgerCount(), 1,
    "virtualized shell was not recorded in the husk ledger")
local entry = Lifecycle.HuskLedger.entries[1]
T.equal(entry.npcId, record.id, "ledger entry npc id")
T.equal(entry.outfitId, "42", "ledger entry identity hint")
T.near(entry.x, 100.4, 0.001, "ledger entry x")
T.near(entry.y, 200.6, 0.001, "ledger entry y")

-- 5. The population manager hands the husk back as an unmarked body, which the
-- reaper must delete instead of letting it become a permanent world husk.
local husk = makeBody(42)
Lifecycle.OnZombieCreate(husk)
T.equal(#Reaper.pending, 1, "returned husk was not queued")
nowMs = nowMs + 1000
T.equal(Lifecycle.PumpHuskReaper(nowMs + 1, true), 1,
    "returned husk was not reaped")
T.equal(husk.removedFromWorld, true, "husk stayed in the world")
T.equal(husk.current, nil, "husk still occupies a square")
T.equal(Lifecycle.HuskLedgerCount(), 0, "reaped husk left its loss armed")
T.equal(Reaper.reaped, 1, "reap was not counted")
T.equal(Reaper.abandoned, 0, "clean reap was recorded as abandoned")

-- 6. A husk that comes back wearing a different persistent outfit is not ours
-- to delete; it must be left alone and the loss must stay armed.
local otherRecord = {
    id = "npc_e2e_other",
    alive = true,
    presenceState = "abstract",
    x = 400,
    y = 500,
    z = 0,
    runtime = { forceLive = true },
}
records[otherRecord.id] = otherRecord
local otherZombie = makeBody(42)
Lifecycle.StampLiveBody(otherRecord, otherZombie)
PNC.Registry.LiveByID[otherRecord.id] = otherZombie
otherRecord.presenceState = "live"
otherZombie.current = nil
nowMs = nowMs + 1000
Presence.Reconcile(otherRecord)
nowMs = nowMs + 500
Presence.Reconcile(otherRecord)
T.equal(Lifecycle.HuskLedgerCount(), 1, "second loss was not recorded")
local stranger = makeBody(77)
Lifecycle.OnZombieCreate(stranger)
T.equal(#Reaper.pending, 0, "unrelated outfit was queued for reaping")
Lifecycle.PumpHuskReaper(nowMs + 1, true)
T.falsy(stranger.removedFromWorld, "unrelated body was removed")
T.equal(Lifecycle.HuskLedgerCount(), 1,
    "unmatched loss did not stay armed for a later pass")

return T.finish("pnc_husk_lifecycle_end_to_end_smoke")
