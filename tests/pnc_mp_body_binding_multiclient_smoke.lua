local T = require "tests/support/test"
T.addPackagePaths()
local B = require "PNC/PresenceSync/PNC_MultiplayerBodyBinding_Client"
local current
PNC.Core = { GenerateID = function() return "server_session" end }
PNC.Const = { PRESENCE_LIVE = "live" }
PNC.Registry = { GetLiveZombie = function() return current end }
isServer = function() return true end
local function serverBody(id, lease, online)
    local md = {PNC_NPC=true, PNC_UUID=id, PNC_BodyKind="live", PNC_BodyLease=lease}
    return { getModData=function() return md end, getOnlineID=function() return online end }
end
for _, role in ipairs({"companion", "neutral", "raider", "faction"}) do
    local record = {id=role, alive=true, presenceState="live", runtime={bodyLease=role.."_1"}}
    current = serverBody(role, record.runtime.bodyLease, 50)
    local clients, replicas = {}, {}
    for i=1,3 do
        clients[i] = B.NewClient({ttl=100, limit=8})
        replicas[i] = { isRemoteZombie = i ~= 1, x=0 }
    end
    local proof = B.Build(record)
    clients[1].Receive(proof, 0)
    clients[1].Observe(replicas[1], 50, 1)
    clients[2].Observe(replicas[2], 50, 0)
    clients[2].Receive(proof, 1)
    -- C enters interest later and receives a fresh authoritative publication.
    clients[3].Receive(B.Build(record), 10)
    clients[3].Observe(replicas[3], 50, 11)
    for i=1,3 do
        T.equal(clients[i].Resolve(role, role.."_1", 12), replicas[i])
        replicas[i].isRemoteZombie = not replicas[i].isRemoteZombie
        replicas[i].x = 20
        T.equal(clients[i].Resolve(role, role.."_1", 13), replicas[i],
            "vanilla owner/movement changes must not change logical binding")
    end
    clients[1].Reset()
    T.equal(clients[1].Resolve(role, role.."_1", 14), nil)
    T.equal(clients[2].Resolve(role, role.."_1", 14), replicas[2],
        "one client disconnect cannot unbind another")
    clients[1].Observe(replicas[1], 50, 15)
    clients[1].Receive(B.Build(record), 16)
    T.equal(clients[1].Resolve(role, role.."_1", 17), replicas[1], "reconnect reconstructs without server respawn")
    record.runtime.bodyLease = role.."_2"
    current = serverBody(role, record.runtime.bodyLease, 60)
    local replacement = B.Build(record)
    for i=1,3 do
        local nextReplica = {}
        clients[i].Receive(replacement, 20)
        clients[i].Observe(nextReplica, 60, 21)
        T.equal(clients[i].Resolve(role, role.."_1", 22), nil)
        T.equal(clients[i].Resolve(role, role.."_2", 22), nextReplica)
        T.falsy(clients[i].Receive(proof, 23), "old client data cannot revive prior incarnation")
    end
    T.equal(record.runtime.bodyLease, role.."_2", "clients cannot mutate server incarnation")
    T.equal(B.Build(record).incarnation, role.."_2", "server remains canonical")
end
return T.finish("pnc_mp_body_binding_multiclient_smoke")
