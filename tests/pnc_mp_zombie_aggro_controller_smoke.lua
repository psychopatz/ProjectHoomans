local T = require "tests/support/test"

local FILE =
    T.path("ProjectHoomans", "client", "PNC/")
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
local targetSeenTime
local aggroCleared = 0
local stateChanges = 0
local managed = false
local playerIsTarget = false
local managedSafetyCalls = 0

local npcBody = {
    x = 5,
    y = 0,
    z = 0,
    getX = function(self) return self.x end,
    getY = function(self) return self.y end,
    getZ = function(self) return self.z end,
    isDead = function() return false end,
    setZombiesDontAttack = function(_, value)
        T.truthy(value == false)
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
    getOnlineID = function() return 17 end,
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
        T.truthy(x == npcBody.x and y == npcBody.y and z == npcBody.z)
        pathRequests = pathRequests + 1
    end,
    CanSee = function(_, value)
        return value == npcBody
    end,
    pathToCharacter = function(_, value)
        T.truthy(value == npcBody)
        pathRequests = pathRequests + 1
        nativeCharacterPaths = nativeCharacterPaths + 1
    end,
    setTarget = function(_, value)
        target = value
    end,
    setTargetSeenTime = function(_, value)
        targetSeenTime = value
    end,
    clearAggroList = function()
        aggroCleared = aggroCleared + 1
    end,
    getAttackedBy = function() return attackedBy end,
    setAttackedBy = function(_, value)
        attackedBy = value
    end,
    spotted = function(_, value, immediate)
        T.truthy(value == npcBody and immediate == true)
        spottedCalls = spottedCalls + 1
    end,
    addAggro = function(_, value, amount)
        T.truthy(value == npcBody and amount == 1)
        aggroCalls = aggroCalls + 1
    end,
    faceLocation = function(_, x, y)
        T.truthy(x == npcBody.x and y == npcBody.y)
        faced = faced + 1
    end,
    faceThisObject = function(_, value)
        T.truthy(value == npcBody)
        faced = faced + 1
    end,
    setNoTeeth = function() end,
    setVariable = function(_, key, value)
        if key == "NoLungeAttack" then noLunge = value end
    end,
    changeState = function(self, value)
        stateChanges = stateChanges + 1
        self.actionState = value and value.name or "idle"
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
        DistanceSq = function(x1, y1, x2, y2)
            local dx = x1 - x2
            local dy = y1 - y2
            return (dx * dx) + (dy * dy)
        end,
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
            zombiePursuitDirectives = {
                ["17"] = {
                    npcId = "npc",
                    x = 5,
                    y = 0,
                    z = 0,
                    expiresAt = math.huge,
                    revision = 1,
                },
            },
        },
        GetZombieOnlineID = function() return 17 end,
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

ZombieIdleState = {
    instance = function()
        return { name = "idle" }
    end,
}

T.load(FILE)

T.truthy(registered,
    "client zombie-aggro controller was not registered")
registered(zombie)
T.truthy(pathRequests == 0,
    "multiplayer controller should defer to vanilla zombie movement")
T.truthy(target == nil and attackedBy == nil,
    "multiplayer controller installed a native NPC combat target")

-- Singleplayer must use the same targetless contract for PNC's IsoZombie
-- shells. Native target assignment lets Build 42's window-lunge animation
-- call player-only methods such as getMoodles() on the shell.
isClient = function() return false end
isServer = function() return false end
zombie.actionState = "idle"
target = nil
attackedBy = nil
now = 1000
registered(zombie)
T.truthy(pathRequests == 1,
    "singleplayer NPC pursuit did not submit a coordinate path")
T.truthy(nativeCharacterPaths == 0,
    "singleplayer NPC pursuit used a native character goal")
T.truthy(target == nil and attackedBy == nil,
    "singleplayer pursuit installed an IsoZombie shell as native target")
T.truthy(noLunge == true,
    "singleplayer NPC pursuit did not suppress native lunge attacks")

now = 1100
registered(zombie)
T.truthy(pathRequests == 1,
    "unchanged NPC destination ignored pursuit refresh throttle")

npcBody.x = 2
now = 1400
registered(zombie)
T.truthy(pathRequests == 2,
    "moving NPC destination did not refresh coordinate pursuit")
T.truthy(target == nil and attackedBy == nil,
    "singleplayer pursuit retained native NPC combat state")

npcBody.x = 0.8
now = 1600
registered(zombie)
T.truthy(pathRequests == 2 and faced == 1,
    "bite-range pursuit did not face the NPC without native targeting")

managed = true
PNC.LiveBodyControl = {
    EnforceManagedSafety = function(_, source)
        T.equal(source, "client_zombie_aggro_guard",
            "managed shell uses the late client safety guard")
        managedSafetyCalls = managedSafetyCalls + 1
    end,
}
now = 2000
registered(zombie)
T.truthy(pathRequests == 2,
    "managed NPC body entered vanilla zombie aggro control")
T.equal(managedSafetyCalls, 1,
    "managed NPC body bypassed the late client safety guard")
PNC.LiveBodyControl = nil

-- The multiplayer lane must yield to an engine-owned action and must not
-- rewrite the native player target while that action is active.
managed = false
isClient = function() return true end
zombie.actionState = "attack"
target = player
attackedBy = nil
targetSeenTime = 22
now = 2800
registered(zombie)
T.truthy(target == player and attackedBy == nil,
    "engine-owned MP action was rewritten by the aggro controller")
T.equal(targetSeenTime, 22,
    "engine-owned MP action changed target memory")

local serverSource = T.read(
    "ProjectHoomans", "shared", "PNC/Core/Zombies/PNC_ZombieAggro_Update.lua"
)
T.truthy(string.find(
    serverSource,
    "publishMPTargetDirective",
    1,
    true
), "MP server does not publish zombie movement directives")
T.truthy(string.find(
    serverSource,
    "if isMultiplayerServer() then",
    1,
    true
), "MP server movement branch is not explicit")

local stateSource = T.read(
    "ProjectHoomans", "shared", "PNC/Core/Zombies/PNC_ZombieAggro_State.lua"
)
T.truthy(string.find(
    stateSource,
    "if not (isServer and isServer() == true) then",
    1,
    true
), "MP server still clears the owning client's native target")

local biteSource = T.read(
    "ProjectHoomans", "shared", "PNC/Core/Zombies/PNC_ZombieAggro_Bite.lua"
)
T.truthy(not string.find(
    biteSource,
    "zombie:setTarget(npcBody)",
    1,
    true
), "scripted bite binds the NPC as a network character goal")
T.finish("pnc_mp_zombie_aggro_controller_smoke")
