local FILE = "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/"
    .. "Perception/PNC_Perception.lua"

local now = 1000
local enemy = true

local function body(x, y)
    return {
        getX = function() return x end,
        getY = function() return y end,
        getZ = function() return 0 end,
        isDead = function() return false end,
        isAlive = function() return true end,
    }
end

local npcBody = body(12, 10)
local playerBody = body(13, 10)
local zombieBody = body(14, 10)
local npcRecord = {
    id = "enemy-npc",
    alive = true,
    x = 12,
    y = 10,
    z = 0,
}

PNC = {
    Const = {
        TARGET_RECENT_ATTACKER_MS = 5000,
        ROAM_TARGET_RADIUS = 12,
        ZOMBIE_TARGET_RADIUS = 12,
    },
    Core = {
        Now = function() return now end,
        DistanceSq = function(ax, ay, bx, by)
            return ((ax - bx) ^ 2) + ((ay - by) ^ 2)
        end,
        ResolvePlayerByOnlineID = function(id)
            return id == 42 and playerBody or nil
        end,
        ResolvePlayerByUsername = function(name)
            return name == "attacker" and playerBody or nil
        end,
    },
    SpatialIndex = {
        FindZombieByID = function(id)
            return id == "zed-1" and zombieBody or nil
        end,
    },
    Registry = {
        Get = function(id)
            return id == npcRecord.id and npcRecord or nil
        end,
        GetLiveZombie = function(id)
            return id == npcRecord.id and npcBody or nil
        end,
    },
    Relationships = {
        AreNPCsEnemies = function()
            return enemy
        end,
    },
    Stealth = {},
    Perception = {},
}

dofile(FILE)

local record = {
    id = "traveler",
    x = 10,
    y = 10,
    z = 0,
    runtime = {},
}

assert(PNC.Perception.RememberAttacker(record, {
    attackerKind = "npc",
    attackerID = "enemy-npc",
}, now), "NPC attacker was not remembered")
local target = PNC.Perception.ResolveRecentAttacker(record, now)
assert(target and target.kind == "npc" and target.id == "enemy-npc", "hostile NPC attacker was not resolved")
assert(target.distSq == 4 and target.threatening == true, "NPC attacker target metadata was incomplete")

enemy = false
assert(PNC.Perception.ResolveRecentAttacker(record, now) == nil, "friendly NPC damage became a combat target")
enemy = true

assert(PNC.Perception.RememberAttacker(record, {
    attackerKind = "player",
    attackerOnlineID = 42,
    attackerUsername = "attacker",
}, now), "player attacker was not remembered")
target = PNC.Perception.ResolveRecentAttacker(record, now)
assert(target and target.kind == "player" and target.player == playerBody, "player attacker was not resolved")

assert(PNC.Perception.RememberAttacker(record, {
    attackerKind = "zombie",
    attackerZombieId = "zed-1",
}, now), "zombie attacker was not remembered")
target = PNC.Perception.ResolveRecentAttacker(record, now)
assert(target and target.kind == "zombie" and target.zombieId == "zed-1", "zombie attacker was not resolved")

record.hostility = { attackZombies = false, attackNPCs = false }
target = PNC.Perception.ResolveRoamingTarget(record, 12)
assert(target and target.zombieId == "zed-1",
    "roaming self-defense ignored a recent zombie attacker")
target = PNC.Perception.ResolveCompanionTarget(record)
assert(target and target.zombieId == "zed-1",
    "companion self-defense ignored a recent zombie attacker")
target = PNC.Perception.ResolveHostileTarget(record)
assert(target and target.zombieId == "zed-1",
    "hostile resolver ignored a recent zombie attacker")

now = 7000
assert(PNC.Perception.ResolveRecentAttacker(record, now) == nil, "expired attacker remained active")
assert(record.runtime.recentThreat == nil, "expired attacker state was not cleared")

print("pnc_recent_attacker_resolution_smoke: ok")
