-- Multiplayer visual-presentation replication smoke test for Puppet Opera.
-- Verifies compact event-driven packets, late-joiner/out-of-range handling,
-- local moving detection, client-side visual tether lockstep, and zero ModData.

local T = dofile("tests/support/test.lua")

local nowMs = 1000
local serverMode = false
local clientMode = false
local sentCommands = {}
local onlinePlayers = {}
local cellZombies = {}

_G.isServer = function() return serverMode end
_G.isClient = function() return clientMode end
_G.sendServerCommand = function(player, moduleName, command, payload)
    sentCommands[#sentCommands + 1] = {
        player = player,
        module = moduleName,
        command = command,
        payload = payload,
    }
end
_G.getOnlinePlayers = function()
    return {
        size = function() return #onlinePlayers end,
        get = function(_, idx) return onlinePlayers[idx + 1] end,
    }
end
_G.getCell = function()
    return {
        getZombieList = function()
            return {
                size = function() return #cellZombies end,
                get = function(_, idx) return cellZombies[idx + 1] end,
            }
        end,
        getGridSquare = function() return nil end,
    }
end
_G.getPlayer = function() return nil end

PNC = PNC or {}
PNC.Const = {
    MODULE = "ProjectHoomans",
    CMD_PUPPET_OPERA_VISUAL = "PuppetOperaVisual",
}
PNC.Core = {
    Now = function() return nowMs end,
    IsClientOnly = function() return clientMode and not serverMode end,
}

T.load("ProjectHoomans", "shared", "PNC/Core/PuppetOpera/PNC_PuppetOpera_AnimVarAdapter.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/PuppetOpera/PNC_PuppetOpera_Tether.lua")
local ServerSync = T.load("ProjectHoomans", "server", "PNC/PuppetOpera/PNC_PuppetOpera_Authority_VisualSync.lua")
local ClientSync = T.load("ProjectHoomans", "client", "PNC/PuppetOpera/PNC_PuppetOpera_Client_VisualSync.lua")

local function makeBody(kind, oid, x, y, name)
    local vars = {}
    local modData = {}
    local fx, fy = 0, 1
    local collidable = true
    local body = {
        _vars = vars,
        _modData = modData,
        _x = x,
        _y = y,
        _z = 0,
        _collidable = true,
        getOnlineID = function() return oid end,
        getUsername = function() return name end,
        getX = function(self) return self._x end,
        getY = function(self) return self._y end,
        getZ = function(self) return self._z end,
        setX = function(self, v) self._x = v end,
        setY = function(self, v) self._y = v end,
        setZ = function(self, v) self._z = v end,
        setLastX = function() end,
        setLastY = function() end,
        setLastZ = function() end,
        isDead = function() return false end,
        isMoving = function() return false end,
        -- IsoZombie inherits isPlayerMoving() from IsoGameCharacter in PZ Java!
        isPlayerMoving = function() return false end,
        getActionStateName = function() return "idle" end,
        getForwardDirection = function()
            return { getX = function() return fx end, getY = function() return fy end }
        end,
        faceLocationF = function() end,
        setVariable = function(_, k, v) vars[k] = v end,
        clearVariable = function(_, k) vars[k] = nil end,
        getModData = function() return modData end,
        setCollidable = function(self, v)
            collidable = v == true
            self._collidable = collidable
        end,
    }
    if kind == "player" then
        body.isPlayerMoving = function() return false end
    end
    return body
end

-- 1. Singleplayer sends 0 packets
local carrier = makeBody("zombie", 101, 100, 100)
local passenger = makeBody("zombie", 102, 100, 100)
local nearObs = makeBody("player", 1, 110, 100, "NearAlice")
local farObs = makeBody("player", 2, 200, 200, "FarBob")
onlinePlayers = { nearObs, farObs }

local session = {
    sessionId = "puppet:mp:1",
    beatIndex = 2,
    revision = 4,
    blueprint = {
        actors = {
            actor_1 = { id = "actor_1" },
            actor_2 = {
                id = "actor_2",
                coupling = {
                    attachTo = "actor_1",
                    offsetRight = 0.0,
                    offsetForward = 0.35,
                    facingMode = "match",
                },
            },
        },
    },
    actors = {
        actor_1 = { id = "actor_1", kind = "nearby_live_npc", body = carrier },
        actor_2 = { id = "actor_2", kind = "nearby_live_npc", body = passenger },
    },
}
local beat = {
    id = "carry",
    mode = "locomotive",
    tetherActive = true,
    disableCollision = true,
    actorTracks = {
        actor_1 = { route = "anim_vars", style = "carry_princess", role = "Carrier", phase = "carry" },
        actor_2 = { route = "anim_vars", style = "carry_princess", role = "Passenger", phase = "carry" },
    },
}

serverMode = false
assert(ServerSync.SyncBeat(session, beat, false) == 0, "SP must send 0 visual packets")
assert(#sentCommands == 0, "SP sent unexpected command")

-- 2. Dedicated server sends ONLY to near observer, once (no per-tick spam)
serverMode = true
assert(ServerSync.SyncBeat(session, beat, false) == 1, "Expected 1 packet to NearAlice")
assert(#sentCommands == 1 and sentCommands[1].player == nearObs, "Wrong recipient")
assert(sentCommands[1].command == "PuppetOperaVisual", "Wrong command name")

-- Repeated calls on same beat send 0 packets
nowMs = 1100
assert(ServerSync.SyncBeat(session, beat, false) == 0, "Same beat must not spam")
nowMs = 3000
assert(ServerSync.SyncBeat(session, beat, false) == 0, "In-range observer already synced")

-- 3. Late-joining observer walks into range -> receives 1 packet after scan interval
farObs._x, farObs._y = 105, 100
nowMs = 4600
assert(ServerSync.SyncBeat(session, beat, false) == 1, "Late joiner should sync")
assert(sentCommands[2].player == farObs, "Expected sync to FarBob")

-- 4. Client receives packet, applies AnimVars + detects movement + tethers passenger
local syncPayload = sentCommands[1].payload
local remoteCarrier = makeBody("zombie", 101, 100.0, 100.0)
local remotePassenger = makeBody("zombie", 102, 98.0, 98.0)
cellZombies = { remoteCarrier, remotePassenger }

serverMode = false
clientMode = true
assert(ClientSync.Receive(syncPayload) == true, "Client Receive failed")
assert(ClientSync.ActiveCount == 1, "Expected 1 active remote scene")

assert(ClientSync.Pump() == 2, "Expected 2 actors pumped")
assert(remoteCarrier._vars.PNC_AnimActive == true, "Carrier AnimActive missing")
assert(remoteCarrier._vars.PNC_AnimStyle == "carry_princess", "Carrier style mismatch")
assert(remoteCarrier._vars.PNC_AnimMoving == false, "Carrier should start idle")
assert(remotePassenger._vars.PNC_AnimRole == "Passenger", "Passenger role mismatch")
assert(remoteCarrier._collidable == false and remotePassenger._collidable == false, "Collision not disabled")
-- Tether snapped passenger to carrier + offsetForward(0.35) along (0, 1)
assert(math.abs(remotePassenger._x - 100.0) < 0.001, "Tether X mismatch")
assert(math.abs(remotePassenger._y - 100.35) < 0.001, "Tether Y mismatch")

-- Carrier moves locally on client -> both actors flip PNC_AnimMoving = true with 0 packets!
remoteCarrier._x = 100.2
remoteCarrier._y = 100.5
ClientSync.Pump()
assert(remoteCarrier._vars.PNC_AnimMoving == true, "Carrier should detect movement")
assert(remotePassenger._vars.PNC_AnimMoving == true, "Passenger should follow leader moving")
assert(math.abs(remotePassenger._y - 100.85) < 0.001, "Tether did not follow carrier")

-- Zero ModData written anywhere
local modCount = 0
for _ in pairs(remoteCarrier._modData) do modCount = modCount + 1 end
for _ in pairs(remotePassenger._modData) do modCount = modCount + 1 end
assert(modCount == 0, "Client visual sync must write zero ModData")

-- 5. Server ClearSession -> sends clear to synced observers -> client restores cleanly
serverMode = true
clientMode = false
assert(ServerSync.ClearSession(session) == 2, "Clear should notify both observers")
local clearPayload = sentCommands[#sentCommands].payload
assert(clearPayload.op == "clear", "Expected clear op")

serverMode = false
clientMode = true
assert(ClientSync.Receive(clearPayload) == true, "Client clear failed")
assert(ClientSync.ActiveCount == 0, "ActiveCount must return to 0")
assert(remoteCarrier._vars.PNC_AnimActive == nil, "Carrier AnimActive not cleared")
assert(remotePassenger._vars.PNC_AnimActive == nil, "Passenger AnimActive not cleared")
assert(remoteCarrier._collidable == true and remotePassenger._collidable == true, "Collision not restored")
assert(ClientSync.Pump() == 0, "Idle pump must do 0 work")

print("PASS: PuppetOpera MP visual sync smoke test")
