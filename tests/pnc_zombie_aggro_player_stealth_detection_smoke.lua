local T = require "tests/support/test"

T.addPackagePaths({ { "ProjectHoomans", "shared" } })

local currentTarget
local playerVisible = false
local players = {}

local function makePlayer(x, sneaking)
    return {
        getX = function() return x end,
        getY = function() return 0 end,
        getZ = function() return 0 end,
        isDead = function() return false end,
        isSneaking = function() return sneaking end,
    }
end

local sneakingPlayer = makePlayer(2, true)
local closeSneakingPlayer = makePlayer(1, true)
local distantVisibleSneakingPlayer = makePlayer(11, true)
local walkingPlayer = makePlayer(3, false)
local zombie = {
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
    getTarget = function() return currentTarget end,
    CanSee = function() return playerVisible end,
}

PNC = {
    Core = {
        ForEachPlayer = function(callback)
            for index = 1, #players do
                callback(players[index])
            end
        end,
    },
    Const = {},
    Registry = {},
    Sandbox = {},
    Stealth = {},
    ZombieAggro = { Internal = {} },
}

instanceof = function(value, className)
    return className == "IsoPlayer" and value ~= nil
end

T.load("ProjectHoomans", "shared", "PNC/Core/Zombies/PNC_ZombieAggro_State.lua")

players = { sneakingPlayer }
local target = PNC.ZombieAggro.Internal.findNearestLivePlayer(zombie, 12)
T.equal(target, nil,
    "an undetected sneaking player was incorrectly offered as a zombie target")

playerVisible = true
target = PNC.ZombieAggro.Internal.findNearestLivePlayer(zombie, 12)
T.equal(target, sneakingPlayer,
    "a sneaking player detected by the zombie was not offered as a target")

players = { distantVisibleSneakingPlayer }
target = PNC.ZombieAggro.Internal.findNearestLivePlayer(zombie, 12)
T.equal(target, distantVisibleSneakingPlayer,
    "a visible sneaking player outside the stealth-break radius was filtered")

playerVisible = false
players = { closeSneakingPlayer }
target = PNC.ZombieAggro.Internal.findNearestLivePlayer(zombie, 12)
T.equal(target, closeSneakingPlayer,
    "a sneaking player in direct contact was incorrectly hidden from the zombie")

players = { walkingPlayer }
target = PNC.ZombieAggro.Internal.findNearestLivePlayer(zombie, 12)
T.equal(target, walkingPlayer,
    "a non-sneaking player was incorrectly filtered from zombie targeting")

players = { sneakingPlayer }
currentTarget = sneakingPlayer
target = PNC.ZombieAggro.Internal.findNearestLivePlayer(zombie, 12)
T.equal(target, sneakingPlayer,
    "the zombie dropped its already-established native player target")

T.finish("pnc_zombie_aggro_player_stealth_detection_smoke")
