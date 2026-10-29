local T = require "tests/support/test"
T.addPackagePaths()
local B = require "PNC/PresenceSync/PNC_MultiplayerBodyBinding_Client"
local bound, unbound = 0, 0
local c = B.NewClient({ ttl = 100, limit = 3,
    onBind = function() bound = bound + 1 end,
    onUnbind = function() unbound = unbound + 1 end })
local function msg(rev, lease, online, id)
    return { protocol = 1, session = "s1", revision = rev, npcId = id or "a",
        incarnation = lease, onlineId = online, operation = "bind" }
end
local first, second = {}, {}
T.truthy(c.Receive(msg(1, "l1", 50), 0))
T.equal(c.Resolve("a", "l1", 0), nil)
c.Observe(first, 50, 1)
T.equal(c.Resolve("a", "l1", 1), first, "message first")
T.truthy(c.Receive(msg(1, "l1", 50), 2))
T.equal(bound, 1, "duplicate must not rebuild presentation")
c.Observe(second, 60, 3)
T.truthy(c.Receive(msg(2, "l2", 60), 4))
T.equal(c.Resolve("a", "l2", 4), second, "replica first")
T.equal(unbound, 1, "replacement releases previous presentation")
T.falsy(c.Receive(msg(1, "l1", 50), 5), "late incarnation rejected")
T.falsy(c.Receive(msg(3, "other", 60, "b"), 5), "online ID conflict rejected")
local recycled = {}
c.Observe(recycled, 60, 6)
T.equal(c.Resolve("a", "l2", 6), nil, "old proof cannot transfer to recycled ID")
T.truthy(c.Receive(msg(3, "l2", 60), 7))
T.equal(c.Resolve("a", "l2", 7), recycled, "fresh server proof permits reappearance")
T.equal(bound, 3)
c.Sweep(108)
T.equal(c.Counts(), 0)
T.falsy(c.Receive(msg(2, "l2", 60), 109), "expired proof cannot revive")
T.truthy(c.Receive(msg(4, "l3", 70), 110))
c.Observe({}, 70, 211)
T.equal(c.Resolve("a", "l3", 211), nil, "pending proof expires before late zombie")
c.Sweep(211)
local sessionOther = msg(5, "l4", 80)
sessionOther.session = "old_session"
T.falsy(c.Receive(sessionOther, 212), "session cannot change without connection reset")
c.Reset()
T.truthy(c.Receive(sessionOther, 213))
T.truthy(c.Receive({protocol=1, session="old_session", revision=6,
    npcId="a", operation="unbind"}, 214))
T.equal(c.Resolve("a", "l4", 214), nil)
for n=1,10 do c.Receive({protocol=1, session="old_session", revision=6+n,
    npcId="npc"..n, operation="unbind"}, 215) end
local entries, observations = c.Counts()
T.truthy(entries <= 3 and observations <= 3, "all client state capped")
local removes = 0
local retirement = B.NewClient({onRemove=function() removes=removes+1 end})
retirement.Observe({}, 50, 0)
retirement.Receive(msg(1, "l1", 50), 1)
T.falsy(retirement.Receive({protocol=1,session="s1",revision=2,npcId="a",
    operation="unbind",previousIncarnation="old",previousOnlineId=50}, 2),
    "late old-incarnation unbind cannot release current shell")
T.truthy(retirement.Receive({protocol=1,session="s1",revision=3,npcId="a",
    operation="unbind",previousIncarnation="l1",previousOnlineId=50}, 3))
T.equal(removes, 1, "unbind arriving before remove retires its exact predecessor")
retirement.Receive({protocol=1,session="s1",revision=4,npcId="a",
    operation="unbind",previousIncarnation="l1",previousOnlineId=50}, 4)
T.equal(removes, 1, "repeated unbind cannot remove twice")
local diagnostics = c.Diagnostics()
T.truthy(diagnostics.rejected > 0 and diagnostics.entries <= diagnostics.limit)
return T.finish("pnc_mp_body_binding_client_smoke")
