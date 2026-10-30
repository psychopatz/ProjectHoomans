local T = require "tests/support/test"
T.addPackagePaths()

local SHARED = T.path("ProjectHoomans", "shared", "")
local BODY_ROOT = SHARED .. "PNC/Core/Presence/PNC_BodyLifecycle/"

local nowMs = 2000
local records = {}
local auditBodies = {}

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
        BODY_TAG_VERSION = 1,
        BODY_AUDIT_INTERVAL_MS = 250,
        CORPSE_AUDIT_INTERVAL_MS = 1000,
        CORPSE_AUDIT_BATCH_SIZE = 4,
        HUSK_LEDGER_MATCH_RADIUS = 2.0,
    },
    Presence = {
        Internal = {
            ResolveNetwork = function() return nil end,
        },
    },
    PathService = {
        Commands = {
            Reset = function() end,
        },
        Reset = function() end,
    },
    Registry = {
        LiveByID = {},
        MarkDirty = function() end,
        GetLiveZombie = function(id)
            return PNC.Registry.LiveByID[tostring(id)]
        end,
        Get = function(id) return records[tostring(id)] end,
        EnsureLoaded = function() end,
        ForEach = function(callback)
            local _, record
            for _, record in pairs(records) do
                callback(record)
            end
        end,
    },
}

getGameTime = function()
    return {
        getWorldAgeHours = function() return 100 end,
    }
end

getCell = function()
    return {
        getGridSquare = function() return nil end,
        getZombieList = function()
            return {
                size = function() return #auditBodies end,
                get = function(_, index) return auditBodies[index + 1] end,
            }
        end,
    }
end

local function makeBody(id, blockRemoval)
    local body
    body = {
        current = { x = 12, y = 34, z = 0 },
        blockRemoval = blockRemoval == true,
        modData = {
            PNC_NPC = true,
            PNC_UUID = id,
            PNC_BodyKind = "live",
            PNC_BodyLease = "body_1",
            PNC_TagVersion = 1,
        },
        getModData = function() return body.modData end,
        getPersistentOutfitID = function() return 42 end,
        getX = function() return 12 end,
        getY = function() return 34 end,
        getZ = function() return 0 end,
        getCurrentSquare = function() return body.current end,
        removeFromWorld = function(self)
            self.removedFromWorld = true
        end,
        removeFromSquare = function(self)
            self.removedFromSquare = true
            if not self.blockRemoval then
                self.current = nil
            end
        end,
    }
    return body
end

local function makeRecord(id)
    local record = {
        id = id,
        alive = true,
        presenceState = "live",
        x = 12,
        y = 34,
        z = 0,
        runtime = { bodyLease = "body_1" },
    }
    records[id] = record
    return record
end

T.load(BODY_ROOT .. "PNC_BodyLifecycle_State.lua")
T.load(BODY_ROOT .. "PNC_BodyLifecycle_World.lua")
T.load(BODY_ROOT .. "PNC_BodyLifecycle_HuskLedger.lua")
T.load(BODY_ROOT .. "PNC_BodyLifecycle_LiveBodies.lua")
T.load(BODY_ROOT .. "PNC_BodyLifecycle_Audit.lua")
T.load(SHARED .. "PNC/Core/Presence/PNC_Presence/PNC_Presence_Abstract.lua")

local Lifecycle = PNC.BodyLifecycle
local Presence = PNC.Presence
local Internal = Lifecycle.Internal
Internal.pumpPendingCorpses = function() end
Internal.auditCorpseBatch = function() end

-- A failed engine removal must not become an abstract, ownerless marked body.
local record = makeRecord("npc_release_retry")
local body = makeBody(record.id, true)
PNC.Registry.LiveByID[record.id] = body

T.falsy(
    Lifecycle.RemoveLiveBody(record, body, "range_exit"),
    "unverified attached removal was reported as successful"
)
T.equal(record.presenceState, "live",
    "failed removal abstracted the record prematurely")
T.equal(record.runtime.bodyLease, "body_1",
    "failed removal discarded the body lease")
T.equal(PNC.Registry.LiveByID[record.id], body,
    "failed removal discarded the live registry handle")
T.truthy(record.runtime.bodyReleasePending,
    "failed removal did not arm a retry")
T.truthy(body.getCurrentSquare(),
    "failed removal unexpectedly detached the body")

-- The same release becomes idempotent once the engine accepts removal.
body.blockRemoval = false
T.truthy(
    Lifecycle.RemoveLiveBody(record, body, "release_retry"),
    "verified retry did not release the body"
)
T.equal(record.presenceState, "abstract",
    "verified retry did not abstract the record")
T.equal(record.runtime.bodyLease, nil,
    "verified retry kept the body lease")
T.equal(PNC.Registry.LiveByID[record.id], nil,
    "verified retry kept the live registry handle")
T.equal(body.getCurrentSquare(), nil,
    "verified retry left the body in a square")
T.equal(record.runtime.bodyReleasePending, nil,
    "verified retry left the retry marker armed")
T.equal(Lifecycle.HuskLedgerCount(), 0,
    "verified attached release incorrectly armed the husk ledger")

-- The periodic loaded-body audit must use the same retry lane. It must not
-- clear the registry/lease merely because a direct engine removal failed.
local auditRecord = makeRecord("npc_audit_release_retry")
local auditBody = makeBody(auditRecord.id, true)
PNC.Registry.LiveByID[auditRecord.id] = auditBody
auditBodies = { auditBody }
T.falsy(
    Lifecycle.RemoveLiveBody(auditRecord, auditBody, "range_exit"),
    "audit setup did not produce a pending release"
)
local firstAudit = Lifecycle.AuditLoadedBodies(nowMs, true)
T.equal(firstAudit.deferred, 1,
    "audit did not report the unverified release as deferred")
T.equal(auditRecord.presenceState, "live",
    "audit abstracted a body it failed to remove")
T.equal(PNC.Registry.LiveByID[auditRecord.id], auditBody,
    "audit discarded the retry handle")

auditBody.blockRemoval = false
local secondAudit = Lifecycle.AuditLoadedBodies(nowMs + 500, true)
T.truthy(secondAudit.removed >= 1,
    "audit retry did not remove the body after the engine recovered")
T.equal(auditRecord.presenceState, "abstract",
    "audit retry did not finalize abstraction")
T.equal(PNC.Registry.LiveByID[auditRecord.id], nil,
    "audit retry left the body registered")

-- Presence.Abstract must also preserve LIVE state while direct cleanup is
-- unverified; callers must not broadcast a completed abstraction early.
local abstractRecord = makeRecord("npc_abstract_retry")
local abstractBody = makeBody(abstractRecord.id, true)
PNC.Registry.LiveByID[abstractRecord.id] = abstractBody
T.falsy(Presence.Abstract(abstractRecord, "range_exit"),
    "abstract reported success before body cleanup was verified")
T.equal(abstractRecord.presenceState, "live",
    "abstract transition discarded a failed body release")
T.equal(PNC.Registry.LiveByID[abstractRecord.id], abstractBody,
    "abstract transition discarded the retry handle")

abstractBody.blockRemoval = false
T.truthy(Presence.Abstract(abstractRecord, "range_exit"),
    "abstract retry did not complete after body removal succeeded")
T.equal(abstractRecord.presenceState, "abstract",
    "abstract retry left the record live")
T.equal(PNC.Registry.LiveByID[abstractRecord.id], nil,
    "abstract retry left the body registered")

return T.finish("pnc_body_release_retry_smoke")
