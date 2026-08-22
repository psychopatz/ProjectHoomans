local T = require "tests/support/test"

local FILE =
    T.path("ProjectHoomans", "shared", "PNC/Core/Perception/PNC_Perception.lua")
local spatialQueries = 0

local owner = {
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
}

local passiveZombie = {
    isDead = function() return false end,
    getX = function() return 1 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
    getTarget = function() return nil end,
    getModData = function()
        return { PNC_ZombieID = "passive" }
    end,
}

local attackingZombie = {
    isDead = function() return false end,
    getX = function() return 2 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
    getTarget = function() return owner end,
    getModData = function()
        return { PNC_ZombieID = "owner_attacker" }
    end,
}

PNC = {
    Const = {
        ZOMBIE_TARGET_RADIUS = 12,
        TARGET_IMMEDIATE_THREAT_RADIUS = 6,
    },
    Core = {
        Now = function() return 1000 end,
        DistanceSq = function(x1, y1, x2, y2)
            local dx = x2 - x1
            local dy = y2 - y1
            return dx * dx + dy * dy
        end,
        IsManagedNPCBody = function() return false end,
        ResolvePlayerByOnlineID = function() return owner end,
        ResolvePlayerByUsername = function() return nil end,
    },
    SpatialIndex = {
        QueryZombies = function()
            spatialQueries = spatialQueries + 1
            return { passiveZombie, attackingZombie }
        end,
        GetZombieID = function(zombie)
            return zombie:getModData().PNC_ZombieID
        end,
    },
    Registry = {
        Get = function() return nil end,
        GetLiveZombie = function() return nil end,
    },
    Relationships = {},
    Stealth = {
        ShouldSuppressCompanionCombat = function()
            return true
        end,
    },
}

T.load(FILE)

local record = {
    id = "companion",
    ownerOnlineID = 7,
    x = 3,
    y = 0,
    z = 0,
    hostility = {
        attackZombies = true,
    },
    runtime = {
        stealthActive = true,
    },
}

local target = PNC.Perception.ResolveCompanionTarget(record)
T.truthy(target ~= nil, "owner attacker was suppressed by follow stealth")
T.truthy(target.kind == "zombie", "owner attacker target kind")
T.truthy(target.zombieId == "owner_attacker", "wrong owner-defense zombie")
T.truthy(target.threatening == true, "owner attacker was not prioritized")
T.truthy(target.defendingOwner == true, "owner-defense marker missing")

local secondRecord = {
    id = "companion_2",
    ownerOnlineID = 7,
    x = 4,
    y = 0,
    z = 0,
    hostility = {
        attackZombies = true,
    },
    runtime = {},
}
T.truthy(PNC.Perception.ResolveCompanionTarget(secondRecord).zombieId
    == "owner_attacker", "shared owner threat cache lost its target")
T.truthy(spatialQueries == 1,
    "companions with one owner repeated the same spatial threat query")
T.finish("pnc_companion_owner_defense_smoke")

T.finish("pnc_companion_owner_defense_smoke")
