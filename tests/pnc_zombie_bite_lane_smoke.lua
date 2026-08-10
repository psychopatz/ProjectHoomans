local FILE =
    "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/"
    .. "Zombies/PNC_ZombieAggro_Bite.lua"

local now = 1000
local laneClear = false
local laneReason = "wall"
local visibilityKind = "blocked"
local damageCount = 0
local bumpType = ""

local npcBody = {
    x = 1,
    y = 0,
    z = 0,
    getX = function(self) return self.x end,
    getY = function(self) return self.y end,
    getZ = function(self) return self.z end,
    isDead = function() return false end,
    isProne = function() return false end,
    isCrawling = function() return false end,
    setZombiesDontAttack = function() end,
}

local zombie = {
    x = 0,
    y = 0,
    z = 0,
    getX = function(self) return self.x end,
    getY = function(self) return self.y end,
    getZ = function(self) return self.z end,
    isDead = function() return false end,
    getOnlineID = function() return 44 end,
    getActionStateName = function() return "idle" end,
    getBumpType = function() return bumpType end,
    setBumpType = function(_, value) bumpType = value end,
    setBumpedChr = function() end,
    setBumpDone = function() end,
    setVariable = function() end,
}

local record = {
    id = "wall_npc",
    alive = true,
    presenceState = "live",
    runtime = {},
    health = { state = "normal" },
}

PNC = {
    Const = {
        PRESENCE_LIVE = "live",
        ZOMBIE_BITE_APPLY_DELAY_MS = 200,
        ZOMBIE_BITE_CLEAR_DELAY_MS = 500,
        ZOMBIE_BITE_DISTANCE = 1.2,
        BITE_RELEASE_TIMEOUT_MS = 650,
        ZOMBIE_ATTACK_DAMAGE = 10,
    },
    Core = {
        Now = function() return now end,
        Distance = function(x1, y1, x2, y2)
            local dx = x2 - x1
            local dy = y2 - y1
            return math.sqrt((dx * dx) + (dy * dy))
        end,
        DistanceSq = function(x1, y1, x2, y2)
            local dx = x2 - x1
            local dy = y2 - y1
            return (dx * dx) + (dy * dy)
        end,
        LogRecordDebug = function() end,
        Log = function() end,
    },
    Registry = {
        Get = function(id)
            return id == record.id and record or nil
        end,
    },
    Health = {
        ApplyDamage = function()
            damageCount = damageCount + 1
            return true
        end,
    },
    Sandbox = {
        CanZombieTargetRecord = function() return true end,
    },
    Perception = {
        CanSeeWorldObject = function()
            return visibilityKind == "clear"
                or visibilityKind == "clearthroughopendoor",
                visibilityKind
        end,
    },
    TraversalQuery = {
        CanStep = function()
            return laneClear, laneReason
        end,
    },
    ZombieAggro = {
        State = { bites = {} },
        Internal = {
            ensureZombieID = function() return "z44" end,
            canZombieAttack = function() return true end,
            rememberZombieAttacker = function() end,
        },
        Activate = function() end,
    },
}

getCell = function() return {} end

dofile(FILE)

assert(
    PNC.ZombieAggro.TryStartBite(zombie, npcBody, record) == false,
    "wall-separated zombie started a bite"
)
assert(bumpType == "", "blocked bite entered the bump graph")
assert(record.runtime.zombieAttackLane.reason == "bite_lane_wall",
    "blocked wall lane was not diagnosed")

laneClear = true
laneReason = "clear"
visibilityKind = "clear"
assert(PNC.ZombieAggro.TryStartBite(zombie, npcBody, record) == true,
    "clear adjacent lane did not start a bite")
assert(bumpType == "Bite", "clear bite did not enter windup")

laneClear = false
laneReason = "wall"
visibilityKind = "blocked"
now = 1250
assert(PNC.ZombieAggro.UpdateBiteState(zombie, now) == true,
    "blocked in-flight bite was not handled")
assert(damageCount == 0,
    "bite applied damage after a wall closed the attack lane")
assert(PNC.ZombieAggro.State.bites.z44.phase == "release",
    "blocked in-flight bite did not enter release")
assert(PNC.ZombieAggro.State.bites.z44.releaseReason == "bite_lane_wall",
    "blocked in-flight bite lost its wall reason")

print("pnc_zombie_bite_lane_smoke: ok")
