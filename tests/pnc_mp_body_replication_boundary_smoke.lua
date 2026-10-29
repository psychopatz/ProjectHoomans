local T = require "tests/support/test"

-- Engine contract: installed 42.22 NetworkZombieSimulator.parseZombie creates
-- a fresh local zombie for an unknown packet.id, then assigns onlineId. Custom
-- server ModData is not transported by that creation path. This fixture models
-- that boundary, not native packet execution or the future binding service.
local server = {
    onlineId = 50,
    modData = { PNC_UUID = "npc_a", PNC_BodyLease = "body_a" },
}
local function receiveVanillaZombie(packet, replicas)
    local replica = replicas[packet.id]
    if not replica then
        replica = { onlineId = packet.id, modData = {} }
        replicas[packet.id] = replica
    end
    return replica
end
local packet = { id = server.onlineId }
local clients = { {}, {} }
local a = receiveVanillaZombie(packet, clients[1])
local b = receiveVanillaZombie(packet, clients[2])
T.truthy(a ~= server and b ~= server and a ~= b,
    "each client must own a distinct engine replica")
T.equal(a.onlineId, server.onlineId)
T.equal(a.modData.PNC_UUID, nil,
    "vanilla online ID must not imply durable NPC identity")
T.equal(b.modData.PNC_BodyLease, nil,
    "server lease must not be assumed to cross vanilla replication")
T.equal(receiveVanillaZombie(packet, clients[1]), a,
    "duplicate packet updates the existing local replica")
server.modData.PNC_UUID = "changed_server_cache"
T.equal(a.modData.PNC_UUID, nil,
    "server cache mutations must not alias client cache")
return T.finish("pnc_mp_body_replication_boundary_smoke")
