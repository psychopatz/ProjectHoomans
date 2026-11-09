local T = require "tests/support/test"
T.addPackagePaths()
local Registry = require "PNC/PresenceSync/PNC_ClientPresenceBodies_Registry"
local md = { PNC_UUID = "companion", PNC_NPC = true, PNC_BodyLease = "lease1" }
local square = {}
local dead = false
local body = {
    getModData = function() return md end,
    getCurrentSquare = function() return square end,
    isDead = function() return dead end,
}
local snapshot = { id = "companion", liveBodyLease = "lease1",
    liveBodyInstanceID = 6553607, liveBodyOnlineID = 4,
    presenceState = "live", alive = true }
local indexes = { BodyByID = { companion = body },
    BodyByLease = { ["companion:lease1"] = body },
    BodyByInstanceID = { ["6553607"] = body },
    BodyByOnlineID = { ["4"] = body } }
T.equal(Registry.ResolveSnapshotBody(indexes, snapshot), body, "valid companion did not resolve")
square = nil
T.equal(Registry.ResolveSnapshotBody(indexes, snapshot), nil, "detached body resolved")
square = {}
-- Same Java object, now an ordinary zombie after resetForReuse wiped ModData.
md = {}
T.equal(Registry.ResolveSnapshotBody(indexes, snapshot), nil, "recycled anonymous zombie resolved")
md = { PNC_UUID = "companion", PNC_NPC = true }
T.equal(Registry.ResolveSnapshotBody(indexes, snapshot), nil, "missing lease was accepted")
md.PNC_BodyLease = "lease2"
T.equal(Registry.ResolveSnapshotBody(indexes, snapshot), nil, "stale incarnation was accepted")
md.PNC_BodyLease = "lease1"
md.PNC_UUID = "other"
T.equal(Registry.ResolveSnapshotBody(indexes, snapshot), nil, "another NPC was accepted")
md.PNC_UUID = "companion"
dead = true
T.equal(Registry.ResolveSnapshotBody(indexes, snapshot), nil, "dead body was accepted")
dead = false
md.PNC_DeathMarkerID = "corpse"
T.equal(Registry.ResolveSnapshotBody(indexes, snapshot), nil, "corpse marker was accepted")
md.PNC_DeathMarkerID = nil
T.equal(Registry.ResolveSnapshotBody(indexes, snapshot), body, "valid live body was blocked")

PNC = { Registry = { GetLiveZombie = function() return {} end } }
T.equal(Registry.ResolveSnapshotBody(indexes, snapshot), nil, "superseded body beat authority registry")
PNC.Registry.GetLiveZombie = function() return body end
T.equal(Registry.ResolveSnapshotBody(indexes, snapshot), body, "authority body rejected")

-- Reproduce the presentation feedback loop: resolver rejects an old cache,
-- but the old and/or fallback still applied identity and duplicate cleanup.
local applications, prunes = 0, 0
local accepted = false
PNC = {
    Const = { PRESENCE_LIVE = "live" },
    Network = { ClientState = { snapshots = { companion = snapshot } } },
    ClientPresenceSync = indexes,
}
indexes.Internal = {
    PresenceTick = { RemoteSnapshots = {} },
    ResolveSnapshotBody = function() return accepted and body or nil end,
    ApplySnapshotToBody = function(_, appliedBody, remote)
        T.equal(appliedBody, body)
        T.falsy(remote)
        applications = applications + 1
    end,
    PruneSnapshotDuplicates = function() prunes = prunes + 1 end,
    IsSnapshotDebugEnabled = function() return false end,
}
T.load("ProjectHoomans", "client", "PNC/PresenceSync/PNC_ClientPresenceTick_Apply.lua")
local apply = indexes.Internal.PresenceTick.Presentation.ApplySnapshots
apply(1000, false, true, true, { companion = true })
T.equal(applications, 0, "rejected body reached presentation through fallback")
T.equal(prunes, 0, "rejected body triggered duplicate cleanup")
accepted = true
apply(1250, false, true, true, { companion = true })
T.equal(applications, 1, "accepted live companion lost presentation")
T.equal(prunes, 1)
return T.finish("pnc_local_body_reuse_smoke")
