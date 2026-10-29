local T = require "tests/support/test"
T.addPackagePaths()
local B = require "PNC/PresenceSync/PNC_MultiplayerBodyBinding_Client"
PNC.Core = { GenerateID = function() return "death_session" end }
PNC.Const = { PRESENCE_LIVE = "live" }
isServer = function() return true end
for _, infected in ipairs({ false, true }) do
    local md = {PNC_UUID="a", PNC_NPC=true, PNC_BodyKind="live", PNC_BodyLease="l1"}
    local server = {getModData=function() return md end, getOnlineID=function() return 50 end}
    PNC.Registry = {GetLiveZombie=function() return server end}
    local record = {id="a", alive=true, presenceState="live", runtime={bodyLease="l1"}}
    local first = B.Build(record)
    local presented = 0
    local client = B.NewClient({ onBind=function() presented=presented+1 end })
    local replica = {alive=true}
    client.Observe(replica, 50, 0)
    client.Receive(first, 1)
    T.equal(presented, 1)
    record.alive, record.presenceState, record.runtime.bodyLease = false, "corpse", nil
    local death = B.Build(record)
    T.equal(death.operation, "unbind")
    T.truthy(client.Receive(death, 2))
    T.equal(client.Resolve("a", "l1", 3), nil, "corpse cannot retain live binding")
    replica.alive = false
    if infected then replica.alive = true; replica.trueZombie = true end
    client.Observe(replica, 50, 4)
    T.falsy(client.Receive(first, 5), "old live proof cannot repaint corpse/reanimation")
    T.equal(presented, 1)
    local joining = B.NewClient()
    joining.Receive(B.Build(record), 6)
    joining.Observe(replica, 50, 7)
    T.equal(joining.Resolve("a", "l1", 8), nil)
    T.falsy(joining.Receive(first, 9), "late join cannot revive dead NPC from stale packet")
    local removal = B.Removal("a", "l1", 50)
    T.equal(removal.operation, "remove")
    T.truthy(client.Receive(removal, 10))
    T.equal(client.Resolve("a", "l1", 11), nil)
    -- Restart/reconnect reconstruction still derives from authoritative death,
    -- never the old body online ID or a cached client's prior identity.
    joining.Reset()
    joining.Receive(B.Build(record), 12)
    joining.Observe(replica, 50, 13)
    T.equal(joining.Resolve("a", "l1", 14), nil)
end
return T.finish("pnc_mp_body_binding_death_smoke")
