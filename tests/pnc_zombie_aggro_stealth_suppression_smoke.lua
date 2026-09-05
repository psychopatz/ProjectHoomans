local T = require "tests/support/test"

T.addPackagePaths({ { "ProjectHoomans", "shared" } })

local now = 1000
local target
local noLungeAttack
local zombie = {
    getTarget = function() return target end,
    setTarget = function(_, value) target = value end,
    setTargetSeenTime = function() end,
    setEatBodyTarget = function() end,
    setThumpTarget = function() end,
    clearAggroList = function() end,
    setAttackedBy = function() end,
    setVariable = function(_, name, value)
        if name == "NoLungeAttack" then
            noLungeAttack = value
        end
    end,
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
    isDead = function() return false end,
}
local npcBody = {}
local record = { runtime = {} }

PNC = {
    Core = {
        IsAuthority = function() return true end,
        IsManagedNPCBody = function() return false end,
        DistanceSq = function() return 100 end,
        Now = function() return now end,
    },
    Const = {
        ZOMBIE_AGGRO_RADIUS = 12,
        ZOMBIE_NPC_PATH_REFRESH_MS = 350,
        ZOMBIE_NPC_PATH_REFRESH_DISTANCE = 0.6,
        ZOMBIE_BITE_DISTANCE = 1.0,
        ZOMBIE_AGGRO_KEEP_RADIUS = 3.0,
    },
    Registry = {},
    Sandbox = {
        CanZombieTargetRecord = function() return true end,
    },
    Stealth = {
        ShouldSuppressZombieAggro = function() return true end,
        IsTravelStealthActive = function() return false end,
    },
    ZombieAggro = {
        Internal = {
            clearZombieTarget = function(body)
                body:setTarget(nil)
                return true
            end,
            getForcedNPCBodyTarget = function()
                return record, npcBody
            end,
            isManagedNPCBody = function() return false end,
        },
        ClearBiteEntryForZombie = function() end,
        ClearBiteEntriesForNPCBody = function() end,
        UpdateBiteState = function() return false end,
        RefreshActiveSet = function() end,
        PumpActiveSet = function(_, process)
            process(zombie, now)
            return 1
        end,
    },
}

PNC.CombatZombieReaction = {
    Pump = function() end,
    IsEngineHitSettling = function() return false end,
}

require "PNC/Core/Zombies/PNC_ZombieAggro_Update"

PNC.ZombieAggro.Pump(now)
T.equal(target, nil, "stealth suppression did not clear the native target")
T.equal(noLungeAttack, true,
    "stealth suppression re-enabled native lunge attacks")
T.equal(record.runtime.combatBlockReason, "follow_stealth_hidden",
    "stealth suppression did not record its block reason")

T.finish("pnc_zombie_aggro_stealth_suppression_smoke")
