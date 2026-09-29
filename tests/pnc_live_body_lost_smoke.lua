local T = require "tests/support/test"
T.addPackagePaths()

local SHARED = T.path("ProjectHoomans", "shared", "")
local BODY_ROOT = SHARED .. "PNC/Core/Presence/PNC_BodyLifecycle/"

local records = {}
local nowMs = 2000

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
    },
    BehaviorCommon = {},
    Presence = {
        Internal = {
            FindNearestPlayer = function()
                return { distSq = 100 }
            end,
        },
    },
}

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
        getWorldAgeHours = function() return 100 end,
    }
end

local function makeBody(id, outfitId, attached)
    local body
    body = {
        current = attached and { x = 0, y = 0, z = 0 } or nil,
        modData = {
            PNC_UUID = id,
            PNC_BodyKind = "live",
            PNC_BodyLease = "body_1",
            PNC_NPC = true,
        },
        getModData = function() return body.modData end,
        getPersistentOutfitID = function() return outfitId end,
        getX = function() return 12.5 end,
        getY = function() return 34.5 end,
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

local function makeRecord(id)
    local record = {
        id = id,
        alive = true,
        x = 10,
        y = 20,
        z = 0,
        presenceState = "live",
        presenceRevision = 1,
        runtime = { bodyLease = "body_1" },
    }
    records[id] = record
    return record
end

T.load(BODY_ROOT .. "PNC_BodyLifecycle_State.lua")
T.load(BODY_ROOT .. "PNC_BodyLifecycle_World.lua")
T.load(BODY_ROOT .. "PNC_BodyLifecycle_HuskLedger.lua")
T.load(BODY_ROOT .. "PNC_BodyLifecycle_LiveBodies.lua")
T.load(SHARED .. "PNC/Core/Behaviors/PNC_Behavior_Common.lua")
T.load(SHARED .. "PNC/Core/Presence/PNC_Presence/PNC_Presence_Decisions.lua")

local Lifecycle = PNC.BodyLifecycle
local Internal = Lifecycle.Internal
local Presence = PNC.Presence

-- 1. Attachment detection is what distinguishes a live shell from a body the
-- engine already virtualized away.
local attachedRecord = makeRecord("npc_attached")
local attachedBody = makeBody("npc_attached", 42, true)
PNC.Registry.LiveByID.npc_attached = attachedBody
T.falsy(Lifecycle.IsRecordBodyLost(attachedRecord),
    "attached live shell was reported as lost")
T.truthy(Internal.isBodyAttached(attachedBody), "attached body read as detached")
T.falsy(Internal.isBodyDetached(attachedBody), "attached body read as removed")

-- A transient square-less frame (engine cull, teleport in progress) must not
-- abstract the record or arm a reap; only a persistent loss may.
local function assertLost(record, label)
    T.falsy(Lifecycle.IsRecordBodyLost(record),
        label .. ": lost on the first square-less frame")
    nowMs = nowMs + 500
    T.truthy(Lifecycle.IsRecordBodyLost(record), label)
end

local lostRecord = makeRecord("npc_lost")
local lostBody = makeBody("npc_lost", 42, false)
PNC.Registry.LiveByID.npc_lost = lostBody
assertLost(lostRecord, "virtualized live shell was not reported as lost")
T.falsy(Internal.isBodyAttached(lostBody), "virtualized body read as attached")

-- An attached body clears the pending loss so a recovered shell cannot be
-- abstracted by a stale grace window.
nowMs = nowMs + 500
T.falsy(Lifecycle.IsRecordBodyLost(attachedRecord), "attached shell read as lost")
T.equal(attachedRecord.runtime.bodyLostSince, nil,
    "attachment did not clear the pending loss marker")

local orphanRecord = makeRecord("npc_orphan")
assertLost(orphanRecord,
    "record without a live body handle was not reported as lost")

local passengerRecord = makeRecord("npc_passenger")
passengerRecord.runtime.vehiclePassenger = { active = true }
T.falsy(Lifecycle.IsRecordBodyLost(passengerRecord),
    "vehicle passenger without a body was reported as lost")

-- 2. Presence must release a record whose shell is gone even when forceLive or
-- a combat target would otherwise keep it embodied.
local forceLiveLost = makeRecord("npc_force_live_lost")
forceLiveLost.runtime.forceLive = true
forceLiveLost.runtime.bodyLease = nil
PNC.Registry.LiveByID.npc_force_live_lost = nil
T.equal(Presence.ShouldAbstract(forceLiveLost), true,
    "lost shell did not override forceLive")

local forceLiveAttached = makeRecord("npc_force_live_attached")
forceLiveAttached.runtime.forceLive = true
PNC.Registry.LiveByID.npc_force_live_attached =
    makeBody("npc_force_live_attached", 42, true)
T.equal(Presence.ShouldAbstract(forceLiveAttached), false,
    "forceLive protection was lost for an attached shell")

local targetLost = makeRecord("npc_target_lost")
targetLost.runtime.target = { kind = "zombie", zombieId = 7 }
assertLost(targetLost, "lost shell was not detected against a combat target")
T.equal(Presence.ShouldAbstract(targetLost), true,
    "lost shell did not override a combat target")

local targetAttached = makeRecord("npc_target_attached")
targetAttached.runtime.target = { kind = "zombie", zombieId = 7 }
PNC.Registry.LiveByID.npc_target_attached =
    makeBody("npc_target_attached", 42, true)
T.equal(Presence.ShouldAbstract(targetAttached), false,
    "combat target protection was lost for an attached shell")

-- 3. Releasing a virtualized shell records the loss so the reaper can delete
-- the body the population manager hands back.
PNC.Registry.LiveByID.npc_lost = lostBody
T.equal(Lifecycle.HuskLedgerCount(), 0, "ledger started dirty")
Lifecycle.RemoveLiveBody(lostRecord, lostBody, "range_exit")
T.equal(lostRecord.presenceState, "abstract", "lost shell was not abstracted")
T.equal(lostRecord.runtime.bodyLease, nil, "lost shell kept its lease")
T.equal(PNC.Registry.LiveByID.npc_lost, nil, "lost shell stayed registered")
T.equal(Lifecycle.HuskLedgerCount(), 1,
    "virtualized shell was not recorded in the husk ledger")
local lossEntry = Lifecycle.FindHuskEntry(makeBody("npc_lost", 42, true))
T.truthy(lossEntry, "recorded loss was not matchable by identity")
T.near(lossEntry.x, 12.5, 0.001, "recorded loss x")
T.near(lossEntry.y, 34.5, 0.001, "recorded loss y")

-- 4. A handle the record no longer leases must never be removed: the engine
-- recycles removed IsoZombie objects, so a stale reference can point at an
-- unrelated body.
local staleRecord = makeRecord("npc_stale")
staleRecord.runtime.bodyLease = "body_1"
local staleBody = makeBody("someone_else", 42, true)
PNC.Registry.LiveByID.npc_stale = nil
Lifecycle.RemoveLiveBody(staleRecord, staleBody, "range_exit")
T.falsy(staleBody.removedFromWorld, "stale handle was removed from the world")
T.falsy(staleBody.removedFromSquare, "stale handle was removed from its square")
T.equal(staleRecord.presenceState, "abstract",
    "stale handle left the record live")
T.equal(Lifecycle.HuskLedgerCount(), 2,
    "stale handle loss was not recorded in the husk ledger")

return T.finish("pnc_live_body_lost_smoke")
