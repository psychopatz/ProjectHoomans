local T = require "tests/support/test"
T.addPackagePaths()

local now = 1000
local strong = {
    id = "npc_legacy_strong",
    alive = true,
    presenceState = "abstract",
    x = 10,
    y = 20,
    z = 0,
    runtime = {
        startupBodyHint = {
            wasLive = false,
            lease = "legacy_lease",
            instanceID = "6554001",
            populationId = nil,
            x = 10,
            y = 20,
            z = 0,
        },
    },
}
local weak = {
    id = "npc_legacy_weak",
    alive = true,
    presenceState = "abstract",
    x = 30,
    y = 40,
    z = 0,
    runtime = {
        startupBodyHint = {
            wasLive = false,
            lease = "weak_lease",
            instanceID = nil,
            populationId = nil,
            x = 30,
            y = 40,
            z = 0,
        },
    },
}

local registry = {}
function registry.ForEach(callback)
    callback(strong)
    callback(weak)
end

PNC = {
    Const = {
        PRESENCE_LIVE = "live",
        BODY_SHELL_STARTUP_PASSES = 1,
        BODY_SHELL_STARTUP_SETTLE_MS = 0,
        BODY_SHELL_MAINTENANCE_MS = 1000,
    },
    Core = {
        Now = function() return now end,
        IsAuthority = function() return true end,
        LogInfo = function() end,
        LogWarn = function() end,
    },
    BodyLifecycle = {
        Internal = {
            registry = function() return registry end,
        },
        StartupCleanup = {
            begun = false,
            active = false,
            complete = false,
            startedAt = 0,
        },
    },
}
isServer = function() return true end

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Presence/PNC_BodyLifecycle/"
        .. "PNC_BodyLifecycle_Startup/"
        .. "PNC_BodyLifecycle_Startup_LateStream_Candidates.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Presence/PNC_BodyLifecycle/"
        .. "PNC_BodyLifecycle_Startup/"
        .. "PNC_BodyLifecycle_Startup_LateStream.lua"
)

PNC.BodyLifecycle.SweepPersistedLiveShells = function()
    return {
        available = true,
        removed = 0,
        pendingRehydrate = 0,
        unresolvedRehydrate = 0,
        ambiguous = 0,
        ordinaryUnknown = 0,
        blockedRecords = 0,
    }
end
PNC.BodyLifecycle.SeedHuskLedgerFromRecords = function() end

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Presence/PNC_BodyLifecycle/"
        .. "PNC_BodyLifecycle_Startup/"
        .. "PNC_BodyLifecycle_Startup_Coordinator.lua"
)

T.truthy(
    PNC.BodyLifecycle.Internal.IsLegacyStrongLateStreamHint(strong),
    "exact legacy carrier hint not recognized"
)
T.falsy(
    PNC.BodyLifecycle.Internal.IsLegacyStrongLateStreamHint(weak),
    "position-only legacy hint gained strong admission"
)

PNC.BodyLifecycle.BeginStartupBodyCleanup(now, true)
PNC.BodyLifecycle.PumpStartupBodyCleanup(now, true)
PNC.BodyLifecycle.PumpStartupBodyCleanup(now, true)

T.truthy(strong.runtime.lateStreamRehydrateExpected,
    "M11-era exact carrier hint was not migrated to late-stream claim")
T.equal(strong.runtime.lifecycle.lastReason,
    "startup_legacy_carrier_late_stream",
    "legacy carrier used wrong lifecycle reason")
T.falsy(weak.runtime.lateStreamRehydrateExpected,
    "weak historical hint was incorrectly armed")
T.equal(weak.runtime.lifecycle, nil,
    "weak historical hint mutated lifecycle state")

return T.finish("pnc_mp_legacy_strong_restart_claim_smoke")
