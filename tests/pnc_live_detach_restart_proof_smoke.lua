local T = require "tests/support/test"
T.addPackagePaths()

PNC = {
    Const = {
        PRESENCE_LIVE = "live",
        PRESENCE_ABSTRACT = "abstract",
        PRESENCE_CORPSE = "corpse",
        BODY_SHELL_OUTFIT = "PNCShellCarrier",
    },
    Core = {
        Now = function() return 1000 end,
        GenerateID = function(prefix) return prefix .. "_test" end,
    },
    BodyLifecycle = {
        Internal = {},
    },
}

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Presence/PNC_BodyLifecycle/"
        .. "PNC_BodyLifecycle_LiveBodies.lua"
)

local capture = PNC.BodyLifecycle.Internal.CaptureDetachedBodyHint
T.truthy(capture, "detached live-body hint helper missing")

-- Clean hosted-server shutdown may detach a live record before SaveAll. Even
-- when the engine supplied no durable instance/population id, the save must
-- retain that this record genuinely owned a live carrier.
local record = {
    id = "npc_shutdown_live",
    alive = true,
    presenceState = "live",
    x = 8078.5,
    y = 11547.5,
    z = 1,
    runtime = {
        bodyLease = "body_saved_lease",
    },
}
local hint = capture(record)
T.truthy(hint, "live detach without engine id lost its restart hint")
T.equal(hint.wasLive, true,
    "live detach did not preserve saved-live ownership")
T.equal(hint.lease, "body_saved_lease",
    "live detach lost the body lease")
T.equal(hint.x, 8078.5, "live detach lost saved x")
T.equal(hint.y, 11547.5, "live detach lost saved y")
T.equal(hint.z, 1, "live detach lost saved z")

-- With an engine identity available, the same contract retains both kinds of
-- proof rather than choosing one or the other.
record.liveBodyInstanceID = "6554001"
record.liveBodyPopulationID = "pop_42"
record.liveBodyOnlineID = 11961
hint = capture(record)
T.equal(hint.instanceID, "6554001",
    "live detach lost persistent outfit/body identity")
T.equal(hint.populationId, "pop_42",
    "live detach lost population identity")
T.equal(hint.onlineID, 11961,
    "live detach lost online id hint")
T.equal(hint.wasLive, true,
    "engine identity capture cleared live ownership")

-- A death/corpse transition is not restartable live-body evidence. Even if a
-- previous weak live hint exists, capture must not leave wasLive=true.
record.alive = false
record.presenceState = "corpse"
record.liveBodyInstanceID = nil
record.liveBodyPopulationID = nil
record.liveBodyOnlineID = nil
record.runtime.bodyLease = nil
record.runtime.lastLiveBodyInstanceID = nil
record.runtime.lastLiveBodyPopulationID = nil
record.runtime.lastLiveBodyOnlineID = nil
record.runtime.lastLiveBodyLease = nil
record.runtime.startupBodyHint = {
    wasLive = true,
    lease = "old_live_lease",
    x = record.x,
    y = record.y,
    z = record.z,
}
hint = capture(record)
T.equal(hint.wasLive, false,
    "corpse detach inherited stale live-restart admission")

local candidateSource = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Presence/PNC_BodyLifecycle/"
        .. "PNC_BodyLifecycle_Startup/"
        .. "PNC_BodyLifecycle_Startup_LateStream_Candidates.lua"
)
T.contains(
    candidateSource,
    "and tonumber(hint.x) ~= nil",
    "late-stream admission still requires only engine ids"
)
T.contains(
    candidateSource,
    'and tostring(hint.lease or "") ~= ""',
    "late-stream admission lost lease proof"
)

return T.finish("pnc_live_detach_restart_proof_smoke")
