local T = require "tests/support/test"

local ROOT =
    T.path("ProjectHoomans", "shared", "PNC/Core/")

local now = 1000
local animation
local animationTarget
local heldReason
local action
local actionState = "pathfind"
local liveTargetX = 1.35
local modData = {}
local variables = {}
local handoffEvents = {}
local weapon = {
    IsWeapon = function() return true end,
    getSwingSound = function() return nil end,
}
local liveTarget = {
    isDead = function() return false end,
    getX = function() return liveTargetX end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
}
local forward = {
    set = function() end,
}
local body = {
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
    getForwardDirection = function() return forward end,
    getPrimaryHandItem = function() return weapon end,
    faceThisObject = function() end,
    getActionStateName = function() return actionState end,
    getModData = function() return modData end,
    setVariable = function(_, key, value)
        variables[key] = value
    end,
    setWalkType = function() end,
    setSpeedMod = function() end,
    setAnimatingBackwards = function() end,
    setMoving = function() end,
    setSneaking = function() end,
    setCrawler = function() end,
    setUseless = function() end,
    setRunning = function() end,
    setBumpDone = function() end,
    setBumpFall = function() end,
    setBumpType = function(_, bumpType)
        animation = bumpType
    end,
    getEmitter = function()
        return { playSound = function() end }
    end,
}

PNC = {
    Core = {
        Now = function() return now end,
    },
    Const = {
        PRESENCE_LIVE = "LIVE",
        MELEE_RANGE = 1.3,
        MELEE_HIT_TOLERANCE = 0.12,
        MELEE_COMMIT_RANGE = 1.0,
        UNARMED_COOLDOWN_MS = 900,
        UNARMED_DAMAGE = 5,
        UNARMED_GROUND_DAMAGE = 8,
        DEBUG_COMBAT_HOLD_MS = 2500,
    },
    Registry = {
        GetLiveZombie = function() return nil end,
    },
    Animation = {},
    Equipment = {
        Describe = function()
            return {
                primaryType = "onehanded",
                hasWeapon = true,
            }
        end,
    },
    Perception = {
        FindZombieByID = function() return liveTarget end,
    },
    Skills = {
        ResolveWeaponSkill = function() return "Axe" end,
        GetLevel = function() return 4 end,
    },
    Stamina = {
        CanSpendAttack = function() return true end,
    },
    PathService = {
        IsTraversalActive = function() return false end,
        Reset = function()
            handoffEvents[#handoffEvents + 1] = "path_reset"
        end,
    },
    Stealth = {
        SuspendForCombat = function(record)
            handoffEvents[#handoffEvents + 1] =
                "stealth_suspended"
            record.runtime.stealthActive = false
            return true
        end,
    },
    CombatResolution = {
        IsWeaponDamageEnabled = function() return false end,
    },
    CombatUnarmed = {
        IsGroundTarget = function() return false end,
    },
    CombatTactics = {},
    BehaviorMoveIntent = {
        Hold = function(_, reason)
            heldReason = reason
            return true
        end,
    },
}

ZombRand = function() return 0 end
T.load(ROOT .. "Visuals/PNC_Animation.lua")
T.load(ROOT .. "Combat/PNC_Combat.lua")

PNC.Combat.HasActiveAttack = function() return false end
PNC.Combat.Internal.buildAttackAction = function(
    _,
    _,
    attackKind,
    attackType,
    anim
)
    handoffEvents[#handoffEvents + 1] = "action_built"
    action = {
        attackKind = attackKind,
        attackType = attackType,
        anim = anim,
    }
end

T.load(ROOT .. "Combat/PNC_Combat_Melee.lua")

local record = {
    x = 0,
    y = 0,
    z = 0,
    runtime = {},
    equipment = {
        primaryFullType = "Base.Axe",
    },
    combatProfile = {
        meleeDamage = 10,
        meleeCooldownMs = 900,
    },
}
local target = {
    kind = "zombie",
    zombieId = "zed",
    x = 10,
    y = 0,
    z = 0,
    distSq = 100,
}

record.runtime.lastAttackAt = now
local started, reason = PNC.Combat.TryMelee(
    record,
    body,
    target
)
T.equal(started, false, "outer hit radius started melee windup")
T.equal(reason, "target_out_of_range", "outer hit radius reason")
T.equal(action, nil, "outer hit radius committed an attack")

record.runtime.lastAttackAt = 0
record.runtime.stealthActive = true
liveTargetX = 0.95
target.distSq = 100
started, reason = PNC.Combat.TryMelee(
    record,
    body,
    target
)
T.equal(started, true, "live distance opens melee commit")
T.equal(reason, "melee_attack_started", "melee commit reason")
T.truthy(
    math.abs(target.distSq - (0.95 * 0.95)) < 0.0001,
    "stale target distance was not refreshed from live body"
)
T.equal(heldReason, "melee_windup", "movement held before attack")
T.equal(handoffEvents[1], "path_reset",
    "native movement was not released before melee")
T.equal(handoffEvents[2], "stealth_suspended",
    "follow stealth was not released before melee")
T.equal(handoffEvents[3], "action_built",
    "attack action was published before movement released")
T.equal(record.runtime.stealthActive, false,
    "melee retained the sneak locomotion branch")
T.equal(animation, nil, "server directly rendered the melee bump")
T.equal(
    variables.BumpDone,
    nil,
    "server wrote client-owned BumpDone variable"
)
T.equal(variables.BumpFall, nil, "server wrote client-owned BumpFall")
T.equal(
    variables.BumpFallType,
    nil,
    "server wrote client-owned BumpFallType"
)
T.equal(actionState, "pathfind", "state is not forced from Lua")
T.equal(
    record.runtime.lastAnimationTrigger,
    nil,
    "server recorded a client-owned animation trigger"
)
T.equal(
    animationTarget,
    nil,
    "setter-driven bump does not bind BumpedChr"
)
T.equal(action.attackKind, "melee", "melee action committed")
T.equal(
    action.anim,
    "PNC_Attack1H1",
    "selected animation was not snapshotted"
)

record.runtime.lastAttackAt = now + 60000
T.equal(
    PNC.Combat.Internal.canAttack(record, now, 900),
    true,
    "future session timestamp suppressed melee"
)
T.equal(
    record.runtime.lastAttackAt,
    0,
    "future session timestamp was not normalized"
)
T.finish("pnc_melee_live_commit_smoke")

T.finish("pnc_melee_live_commit_smoke")
