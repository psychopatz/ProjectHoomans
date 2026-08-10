local FILE =
    "Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/"
    .. "PresenceSync/PNC_ClientZombieAggroController.lua"

local now = 1000
local registered
local pathRequests = 0
local target
local attackedBy
local forbiddenCharacterCalls = 0
local faced = 0
local noLunge
local managed = false
local playerIsTarget = false

local npcBody = {
    x = 5,
    y = 0,
    z = 0,
    getX = function(self) return self.x end,
    getY = function(self) return self.y end,
    getZ = function(self) return self.z end,
    isDead = function() return false end,
    setZombiesDontAttack = function(_, value)
        assert(value == false)
    end,
}

local player = {
    x = 20,
    y = 0,
    getX = function(self) return self.x end,
    getY = function(self) return self.y end,
}

local modData = {}
local zombie = {
    x = 0,
    y = 0,
    z = 0,
    actionState = "idle",
    getX = function(self) return self.x end,
    getY = function(self) return self.y end,
    getZ = function(self) return self.z end,
    getActionStateName = function(self)
        return self.actionState
    end,
    isDead = function() return false end,
    isProne = function() return false end,
    isUseless = function() return false end,
    getModData = function() return modData end,
    getTarget = function()
        return playerIsTarget and player or target
    end,
    pathToLocationF = function(_, x, y, z)
        assert(x == npcBody.x and y == npcBody.y and z == npcBody.z)
        pathRequests = pathRequests + 1
    end,
    pathToCharacter = function()
        forbiddenCharacterCalls = forbiddenCharacterCalls + 1
    end,
    setTarget = function(_, value)
        target = value
        if value == npcBody then
            forbiddenCharacterCalls = forbiddenCharacterCalls + 1
        end
    end,
    getAttackedBy = function() return attackedBy end,
    setAttackedBy = function(_, value)
        attackedBy = value
        if value == npcBody then
            forbiddenCharacterCalls = forbiddenCharacterCalls + 1
        end
    end,
    spotted = function()
        forbiddenCharacterCalls = forbiddenCharacterCalls + 1
    end,
    addAggro = function()
        forbiddenCharacterCalls = forbiddenCharacterCalls + 1
    end,
    faceLocation = function(_, x, y)
        assert(x == npcBody.x and y == npcBody.y)
        faced = faced + 1
    end,
    setVariable = function(_, key, value)
        if key == "NoLungeAttack" then noLunge = value end
    end,
}

PNC = {
    Const = {
        PRESENCE_LIVE = "live",
        ZOMBIE_AGGRO_RADIUS = 12,
        ZOMBIE_NPC_PATH_REFRESH_MS = 350,
        ZOMBIE_NPC_PATH_REFRESH_DISTANCE = 0.6,
    },
    Core = {
        Now = function() return now end,
        IsManagedNPCBody = function(candidate)
            return managed and candidate == zombie
        end,
    },
    Network = {
        ClientState = {
            snapshots = {
                npc = {
                    id = "npc",
                    presenceState = "live",
                    zombieTargetable = true,
                },
            },
        },
    },
    ClientPresenceSync = {
        BodyByID = { npc = npcBody },
        Internal = {
            IsLocalZombieController = function()
                return true
            end,
        },
    },
}

instanceof = function(value, className)
    return className == "IsoPlayer" and value == player
end
isClient = function() return true end
Events = {
    OnZombieUpdate = {
        Add = function(handler) registered = handler end,
        Remove = function() end,
    },
}

dofile(FILE)

assert(registered,
    "client zombie-aggro controller was not registered")
registered(zombie)
assert(pathRequests == 1,
    "owning client did not submit proactive zombie pursuit")
assert(target == nil and attackedBy == nil,
    "distant pursuit mixed PathFindState with target state")
assert(forbiddenCharacterCalls == 0 and noLunge == true,
    "distant pursuit installed an invalid character goal")

now = 1100
registered(zombie)
assert(pathRequests == 1,
    "unchanged NPC destination ignored pursuit refresh throttle")

npcBody.x = 2
now = 1600
registered(zombie)
assert(pathRequests == 2,
    "coordinate pursuit stopped outside bite range")
assert(target == nil and attackedBy == nil
        and forbiddenCharacterCalls == 0,
    "MP pursuit bound the IsoZombie NPC as a character target")

npcBody.x = 0.8
now = 2000
registered(zombie)
assert(pathRequests == 2 and faced == 1,
    "bite-range pursuit submitted another path instead of facing")
assert(forbiddenCharacterCalls == 0,
    "bite-range pursuit installed an invalid network mind goal")

playerIsTarget = true
player.x = 0.5
target = nil
now = 2200
registered(zombie)
assert(pathRequests == 2 and target == nil,
    "closer live player target was incorrectly replaced")
assert(noLunge == false,
    "player targeting retained the NPC no-lunge override")

playerIsTarget = false
managed = true
now = 2400
registered(zombie)
assert(pathRequests == 2,
    "managed NPC body entered vanilla zombie aggro control")

local serverFile = assert(io.open(
    "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/"
        .. "Zombies/PNC_ZombieAggro_Update.lua",
    "rb"
))
local serverSource = serverFile:read("*a")
serverFile:close()
assert(string.find(
    serverSource,
    "elseif not isMultiplayerServer() then",
    1,
    true
), "MP server still owns zombie movement alongside the client")
assert(not string.find(
    serverSource,
    "zombie:setTarget(npcBody)",
    1,
    true
), "MP server binds the IsoZombie NPC as a network character goal")

local biteFile = assert(io.open(
    "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/"
        .. "Zombies/PNC_ZombieAggro_Bite.lua",
    "rb"
))
local biteSource = biteFile:read("*a")
biteFile:close()
assert(not string.find(
    biteSource,
    "zombie:setTarget(npcBody)",
    1,
    true
), "scripted bite binds the NPC as a network character goal")

print("pnc_mp_zombie_aggro_controller_smoke: ok")
