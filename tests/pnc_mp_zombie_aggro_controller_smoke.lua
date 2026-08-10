local FILE =
    "Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/"
    .. "PresenceSync/PNC_ClientZombieAggroController.lua"

local now = 1000
local registered
local pathRequests = 0
local target
local attackedBy
local nativeCharacterPaths = 0
local spottedCalls = 0
local aggroCalls = 0
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
    CanSee = function(_, value)
        return value == npcBody
    end,
    pathToCharacter = function(_, value)
        assert(value == npcBody)
        pathRequests = pathRequests + 1
        nativeCharacterPaths = nativeCharacterPaths + 1
    end,
    setTarget = function(_, value)
        target = value
    end,
    getAttackedBy = function() return attackedBy end,
    setAttackedBy = function(_, value)
        attackedBy = value
    end,
    spotted = function(_, value, immediate)
        assert(value == npcBody and immediate == true)
        spottedCalls = spottedCalls + 1
    end,
    addAggro = function(_, value, amount)
        assert(value == npcBody and amount == 1)
        aggroCalls = aggroCalls + 1
    end,
    faceLocation = function(_, x, y)
        assert(x == npcBody.x and y == npcBody.y)
        faced = faced + 1
    end,
    faceThisObject = function(_, value)
        assert(value == npcBody)
        faced = faced + 1
    end,
    setNoTeeth = function() end,
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
            return candidate == npcBody
                or (managed and candidate == zombie)
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
assert(nativeCharacterPaths == 1 and noLunge == true,
    "distant pursuit did not use Bandits-style character pathing")

now = 1100
registered(zombie)
assert(pathRequests == 1,
    "unchanged NPC destination ignored pursuit refresh throttle")

npcBody.x = 2
now = 1600
registered(zombie)
assert(pathRequests == 1,
    "near pursuit unexpectedly submitted another path")
assert(target == npcBody and attackedBy == npcBody,
    "near pursuit did not bind the native NPC target")
assert(spottedCalls == 1 and aggroCalls == 1,
    "near pursuit did not establish native zombie aggro")

npcBody.x = 0.8
now = 2000
registered(zombie)
assert(pathRequests == 1 and faced == 1,
    "bite-range pursuit submitted another path instead of facing")
assert(target == npcBody and attackedBy == npcBody,
    "bite-range pursuit released the native NPC target")

playerIsTarget = true
player.x = 0.5
target = nil
now = 2200
registered(zombie)
assert(pathRequests == 1,
    "closer live player target was incorrectly replaced")
assert(noLunge == false,
    "player targeting retained the NPC no-lunge override")

playerIsTarget = false
managed = true
now = 2400
registered(zombie)
assert(pathRequests == 1,
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

local stateFile = assert(io.open(
    "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/"
        .. "Zombies/PNC_ZombieAggro_State.lua",
    "rb"
))
local stateSource = stateFile:read("*a")
stateFile:close()
assert(string.find(
    stateSource,
    "if not (isServer and isServer() == true) then",
    1,
    true
), "MP server still clears the owning client's native target")

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
