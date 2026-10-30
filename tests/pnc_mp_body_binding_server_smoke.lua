local T = require "tests/support/test"
T.addPackagePaths()
local live
PNC = {
    Core = { GenerateID = function() return "session_one" end },
    Const = { PRESENCE_LIVE = "live" },
    Registry = { GetLiveZombie = function() return live end },
}
isServer = function() return true end
local B = require "PNC/Core/Networking/PNC_MultiplayerBodyBinding"
local r = { id = "a", alive = true, presenceState = "live",
    runtime = { bodyLease = "lease_a" } }
local onlineID = 50
local md = { PNC_NPC = true, PNC_UUID = "a", PNC_BodyKind = "live",
    PNC_BodyLease = "lease_a" }
live = { getModData = function() return md end,
    getOnlineID = function() return onlineID end }
r.liveBodyOnlineID = 12
local projected, projectedOnline, projectedLease = B.Projection(r)
T.equal(projected.operation, "bind")
T.equal(projected.onlineId, 50,
    "binding projection did not use the current shell online id")
T.equal(projectedOnline, 50,
    "projection exposed stale cached online id")
T.equal(projectedLease, "lease_a",
    "projection exposed the wrong incarnation")
T.equal(r.liveBodyOnlineID, 50,
    "projection did not repair the authoritative online-id cache")

local a = B.Build(r)
T.equal(a.operation, "bind")
T.equal(a.incarnation, "lease_a")
T.equal(a.onlineId, 50)
local repeatA = B.Build(r)
T.equal(repeatA.incarnation, a.incarnation, "unchanged shell keeps incarnation")
T.truthy(repeatA.revision > a.revision, "publication renews authoritative proof")
r.runtime.bodyLease = "lease_b"
md.PNC_BodyLease = "lease_b"
onlineID = 60
local b = B.Build(r)
T.truthy(b.revision > a.revision)
T.equal(b.previousIncarnation, "lease_a")
T.equal(b.previousOnlineId, 50)
T.equal(b.incarnation, "lease_b")
for _, invalid in ipairs({ -1, 32768, 1.5, "bad" }) do
    onlineID = invalid
    T.equal(B.Build(r).operation, "unbind", "invalid online ID fails closed")
end
onlineID = 60
T.equal(B.Build(r).operation, "bind")
md.PNC_UUID = "ordinary_or_other_npc"
T.equal(B.Build(r).operation, "unbind", "identity conflict fails closed")
md.PNC_UUID = "a"
r.alive = false
T.equal(B.Build(r).operation, "unbind", "dead actor cannot bind")
r.alive = true
r.presenceState = "abstract"
T.equal(B.Build(r).operation, "unbind", "abstract actor cannot bind")
r.presenceState = "live"
local c = B.Build(r)
live = nil
local removed = B.Build(r)
T.equal(removed, nil, "live shell grace does not publish premature retirement")
r.presenceState = "abstract"
removed = B.Build(r)
T.equal(removed.operation, "unbind")
T.equal(removed.previousIncarnation, c.incarnation)
T.equal(removed.previousOnlineId, c.onlineId)
T.truthy(removed.revision > c.revision)
local repeatedUnbind = B.Build(r)
T.equal(repeatedUnbind.previousIncarnation, c.incarnation,
    "every client receives exact predecessor even on repeated unbind publication")
isServer = function() return false end
T.equal(B.Build(r), nil, "SP payload has no MP binding")
return T.finish("pnc_mp_body_binding_server_smoke")
