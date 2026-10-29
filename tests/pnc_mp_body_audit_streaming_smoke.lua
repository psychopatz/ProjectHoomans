local T = require "tests/support/test"
T.addPackagePaths()

local now = 1000
local removals = 0

local function body(id, lease, onlineID, attached)
    local value = {
        current = attached and {} or nil,
        modData = {
            PNC_UUID = id,
            PNC_NPC = true,
            PNC_BodyKind = "live",
            PNC_BodyLease = lease,
            PNC_TagVersion = 1,
        },
    }
    value.getModData = function(self) return self.modData end
    value.getCurrentSquare = function(self) return self.current end
    value.getOnlineID = function() return onlineID end
    return value
end

local recordA = {
    id = "player_a_companion",
    alive = true,
    presenceState = "live",
    runtime = { bodyLease = "lease_a", bodyLostSince = 900 },
}
local recordB = {
    id = "player_b_companion",
    alive = true,
    presenceState = "live",
    runtime = { bodyLease = "lease_b", bodyLostSince = 900 },
}

local bodyA = body(recordA.id, "lease_a", 11, true)
local bodyB = body(recordB.id, "lease_b", 22, true)
local census = { bodyA }

local Registry = {
    LiveByID = {
        [recordA.id] = bodyA,
        [recordB.id] = bodyB,
    },
}
function Registry.EnsureLoaded() end
function Registry.Get(id)
    if tostring(id) == recordA.id then return recordA end
    if tostring(id) == recordB.id then return recordB end
    return nil
end
function Registry.ForEach(callback)
    callback(recordA)
    callback(recordB)
end

PNC = {
    Core = {
        Now = function() return now end,
        IsAuthority = function() return true end,
        IsManagedNPCBody = function() return true end,
    },
    Const = {
        PRESENCE_LIVE = "live",
        PRESENCE_CORPSE = "corpse",
        BODY_TAG_VERSION = 1,
        BODY_AUDIT_INTERVAL_MS = 250,
        CORPSE_AUDIT_INTERVAL_MS = 1000,
    },
    Registry = Registry,
    WorldCensus = {
        GetLifecycleCandidates = function() return census end,
    },
    BodyLifecycle = {
        Internal = {},
    },
}

local Lifecycle = PNC.BodyLifecycle
local Internal = Lifecycle.Internal
Internal.registry = function() return Registry end
Internal.IsProtectedBody = function() return false end
Internal.isBodyAttached = function(value)
    return value and value.current ~= nil
end
Internal.matchesRecordBody = function(record, value)
    local data = value and value:getModData() or nil
    return data
        and tostring(data.PNC_UUID or "") == tostring(record.id)
        and tostring(data.PNC_BodyLease or "")
            == tostring(record.runtime and record.runtime.bodyLease or "")
end
Internal.ensureRuntime = function(record)
    record.runtime = record.runtime or {}
    return record.runtime
end
Internal.mark = function(record, phase, state, reason)
    record.runtime = record.runtime or {}
    record.runtime.lastAuditMark = reason
end
Internal.pumpPendingCorpses = function() end
Internal.auditCorpseBatch = function() end
Internal.normalizeOnlineID = function(value)
    return value and value.getOnlineID and value:getOnlineID() or nil
end
Internal.removeZombie = function() return true end
Internal.noteCleanup = function() end

Lifecycle.RefreshLiveBodyIdentity = function() return true end
Lifecycle.RemoveLiveBody = function(record)
    removals = removals + 1
    record.presenceState = "abstract"
    return true
end

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_Audit.lua"
)

-- Simulate two players in different streamed MP areas. The shared census
-- currently observes player A's companion only, while player B's authoritative
-- registry handle remains attached and lease-valid.
local stats = Lifecycle.AuditLoadedBodies(now, true)
T.equal(removals, 0,
    "off-census attached MP companion was incorrectly released")
T.equal(recordB.presenceState, "live",
    "off-census attached MP companion became abstract")
T.equal(recordB.runtime.bodyLostSince, nil,
    "off-census attached body did not clear stale loss timing")
T.equal(recordB.runtime.lastAuditMark, "body_audit_off_census",
    "off-census attached body was not explicitly retained")
T.equal(stats.offCensusRetained, 1,
    "MP audit did not report the retained off-census body")

-- When that same authoritative handle is genuinely detached, absence from the
-- census becomes actionable and the normal verified loss lane may release it.
bodyB.current = nil
now = now + 500
stats = Lifecycle.AuditLoadedBodies(now, true)
T.equal(removals, 1,
    "genuinely detached MP companion was not released")
T.equal(recordB.presenceState, "abstract",
    "detached MP companion remained falsely live")

T.finish("pnc_mp_body_audit_streaming_smoke")
