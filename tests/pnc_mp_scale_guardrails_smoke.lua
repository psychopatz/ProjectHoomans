local T = require "tests/support/test"

T.addPackagePaths()

local players = {}
local sent = {}
local diagnostics = {}
local now = 1000
local multiplayerServer = true

local function makePlayer(id, x, y, z)
    return {
        getUsername = function() return "player_" .. tostring(id) end,
        getOnlineID = function() return id end,
        getX = function() return x end,
        getY = function() return y end,
        getZ = function() return z end,
    }
end

-- Two players are near the zombie, one is near only the NPC endpoint, one is
-- on the same tile but outside the vertical routing window, and one is remote.
-- This is the shape that can accidentally turn one directive into a server-
-- wide fan-out when the follower group is large.
players[1] = makePlayer(1, 0, 0, 0)
players[2] = makePlayer(2, 50, 0, 0)
players[3] = makePlayer(3, 100, 0, 0)
players[4] = makePlayer(4, 100, 0, 3)
players[5] = makePlayer(5, 300, 0, 0)

local function forEachPlayer(callback)
    for i = 1, #players do callback(players[i]) end
end

local zombieData = {}
local zombie = {
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
}
local npcBody = {
    x = 100,
    getX = function(self) return self.x end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
}

PNC = {
    Const = {
        MODULE = "PNC",
        CMD_ZOMBIE_PURSUIT = "ZombiePursuit",
        ZOMBIE_NPC_DIRECTIVE_RADIUS = 72,
        ZOMBIE_NPC_DIRECTIVE_SEND_MS = 400,
        ZOMBIE_NPC_DIRECTIVE_TTL_MS = 1100,
        ZOMBIE_NPC_PATH_REFRESH_DISTANCE = 0.6,
    },
    Core = {
        Now = function() return now end,
        ForEachPlayer = forEachPlayer,
        DistanceSq = function(x1, y1, x2, y2)
            local dx = x1 - x2
            local dy = y1 - y2
            return (dx * dx) + (dy * dy)
        end,
    },
    Network = {
        Internal = {},
        ServerState = { interests = {} },
        GetZombieOnlineID = function() return 41 end,
    },
    ZombieAggro = {
        Internal = {
            UpdateProviders = {
                Multiplayer = {},
            },
            getZombieModData = function()
                return zombieData
            end,
        },
    },
}

isServer = function() return multiplayerServer end
sendServerCommand = function() end

-- Keep transport calls observable without involving the native packet layer.
PNC.Network.Internal.SendChunked = function(player, module, command, payload)
    sent[#sent + 1] = {
        player = player,
        module = module,
        command = command,
        payload = payload,
    }
    return true
end

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Networking/PNC_Network_Server/PNC_Network_Server_Transport.lua"
)

local firstSend = PNC.Network.Internal.SendToNearbyPlayers(
    zombie,
    npcBody,
    PNC.Const.CMD_ZOMBIE_PURSUIT,
    { x = npcBody.x, y = 0, z = 0 }
)
T.equal(firstSend, 3,
    "zombie directive was not limited to players near either endpoint")
T.equal(#sent, 3,
    "zombie directive fanned out to every connected player")
T.equal(sent[1].player, players[1], "primary-endpoint recipient missing")
T.equal(sent[2].player, players[2], "overlapping endpoint recipient missing")
T.equal(sent[3].player, players[3], "secondary-endpoint recipient missing")
for i = 1, #sent do
    T.falsy(sent[i].player == players[4],
        "vertical-distance recipient bypassed the routing window")
    T.falsy(sent[i].player == players[5],
        "remote player received a local zombie directive")
end

-- The same transport primitive is used by the server-side Hoomans directive
-- publisher. Test the publisher's per-zombie throttle before changing any
-- runtime behavior: repeated follower updates must not become packet storms.
PNC.PerformanceScalingDiagnostics = {
    Increment = function(name)
        diagnostics[name] = (diagnostics[name] or 0) + 1
    end,
}
PNC.ZombieAggro.Internal.UpdateProviders.incrementDiagnostic =
    function(name, amount)
        diagnostics[name] = (diagnostics[name] or 0) + (tonumber(amount) or 1)
    end
PNC.ZombieAggro.Internal.UpdateProviders.isMultiplayerServer =
    function() return multiplayerServer end
PNC.ZombieAggro.Internal.UpdateProviders.logPursuitDiagnostic = function() end

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Zombies/PNC_ZombieAggro_Update_Multiplayer.lua"
)

local publish = PNC.ZombieAggro.Internal.UpdateProviders.Multiplayer.publish
local clear = PNC.ZombieAggro.Internal.UpdateProviders.Multiplayer.clear
local record = { id = "npc_scale_guard" }

sent = {}
T.equal(publish(zombie, record, npcBody, now, false), 3,
    "initial MP directive was not routed to nearby clients")
T.equal(#sent, 3, "initial directive count was not bounded by interest")

now = 1100
T.equal(publish(zombie, record, npcBody, now, false), 0,
    "unchanged MP directive ignored its send throttle")
T.equal(#sent, 3, "unchanged directive emitted a duplicate packet set")

-- After the throttle window the unchanged directive is refreshed as a
-- heartbeat so the client-side TTL cannot expire. The heartbeat remains
-- interest-scoped rather than becoming a server-wide packet storm.
npcBody.x = 100.2
now = 1500
T.equal(publish(zombie, record, npcBody, now, false), 3,
    "MP directive heartbeat did not refresh after its throttle window")
T.equal(#sent, 6, "directive heartbeat was not bounded by interest")

-- A meaningful destination change is allowed through once the throttle opens.
npcBody.x = 101
now = 1501
T.equal(publish(zombie, record, npcBody, now, false), 3,
    "meaningful NPC movement did not refresh the MP directive")
T.equal(#sent, 9, "movement refresh was not limited to nearby clients")

-- Approach-mode changes are semantic changes and must refresh immediately,
-- without waiting for another full send interval.
now = 1600
T.equal(publish(zombie, record, npcBody, now, true), 3,
    "approach-mode transition did not refresh the MP directive")
T.equal(#sent, 12, "approach transition was not locally routed")

now = 1700
T.equal(publish(zombie, record, npcBody, now, true), 0,
    "unchanged approach directive ignored its throttle")

now = 2200
T.equal(clear(zombie, now), 3,
    "MP directive clear was not routed to nearby clients")
T.equal(#sent, 15, "directive clear was not interest scoped")
T.equal(zombieData.PNC_MPAggroDirectiveNPCId, nil,
    "cleared directive remained installed on the zombie")
T.truthy((diagnostics["ZombieAggro.MPDirectiveSent"] or 0) >= 9,
    "MP directive sends were not observable through existing diagnostics")

T.finish("pnc_mp_scale_guardrails_smoke")
