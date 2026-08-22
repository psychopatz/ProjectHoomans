local T = require "tests/support/test"

local FILE =
    T.path("ProjectHoomans", "shared", "PNC/Core/")
    .. "Combat/PNC_Combat_Defense.lua"

local now = 1000
local fitness = 2
local protection = 0
local nearby = 1
local randomValues = {}
local staggerCount = 0
local nearMissCount = 0
local broadcastCount = 0

ZombRand = function()
    return table.remove(randomValues, 1) or 0
end

local function makeZombie(x)
    return {
        isDead = function() return false end,
        getX = function() return x end,
        getY = function() return 0 end,
        getZ = function() return 0 end,
    }
end

local zombies = {}
local function refreshZombies()
    zombies = {}
    for i = 1, nearby do
        zombies[i] = makeZombie(0.3 + i * 0.2)
    end
end

PNC = {
    Const = {
        NPC_ZOMBIE_DEFENSE_RADIUS = 2.2,
        NPC_ZOMBIE_DEFENSE_FITNESS_BASE = 0.90,
        NPC_ZOMBIE_DEFENSE_FITNESS_STEP = 0.04,
        NPC_ZOMBIE_DEFENSE_FITNESS_TWO_CHANCE = 0.98,
        NPC_ZOMBIE_DEFENSE_HIGH_FITNESS_STEP = 0.0015,
        NPC_ZOMBIE_DEFENSE_CROWD_PENALTY = 0.14,
        NPC_ZOMBIE_DEFENSE_MIN_CROWD_PENALTY = 0.075,
        NPC_ZOMBIE_DEFENSE_PUSH_CHANCE = 0.50,
        NPC_ZOMBIE_DEFENSE_MIN_CHANCE = 0.05,
        NPC_ZOMBIE_DEFENSE_MAX_CHANCE = 0.995,
    },
    Core = {
        Now = function() return now end,
        DistanceSq = function(x1, y1, x2, y2)
            local dx = x2 - x1
            local dy = y2 - y1
            return dx * dx + dy * dy
        end,
        IsManagedNPCBody = function() return false end,
    },
    Skills = {
        GetLevel = function(_, skill)
            T.equal(skill, "Fitness", "defense skill")
            return fitness
        end,
    },
    SpatialIndex = {
        QueryZombies = function()
            refreshZombies()
            return zombies
        end,
    },
    NPCWounds = {
        GetProtection = function(_, _, damageType)
            T.equal(damageType, "scratch", "damage-specific armor")
            return protection
        end,
        ChooseZombieAttackPart = function()
            return { id = "Torso_Upper" }
        end,
        RollZombieAttackType = function()
            return "scratch"
        end,
    },
    CombatZombieReaction = {
        Start = function(_, target, options)
            T.truthy(target ~= nil, "stagger target missing")
            T.equal(options.stagger, true, "stagger option")
            staggerCount = staggerCount + 1
            return true
        end,
    },
    CombatTactics = {
        MarkZombieNearMiss = function()
            nearMissCount = nearMissCount + 1
        end,
    },
    Network = {
        BroadcastZombieReaction = function(target, attacker, options)
            T.truthy(target ~= nil and attacker ~= nil, "reaction replication target")
            T.equal(options.kind, "npc_zombie_parry", "reaction replication kind")
            broadcastCount = broadcastCount + 1
            return true
        end,
    },
}

T.load(FILE)

local record = {
    id = "defender",
    x = 0,
    y = 0,
    z = 0,
    runtime = {},
}
local body = {
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
}

local chance = PNC.CombatDefense.CalculateAvoidChance(
    record,
    body,
    "scratch",
    1,
    { id = "Torso_Upper" }
)
T.near(chance, 0.98, 0.00001, "fitness two single-zombie dodge")

local crowdedChance = PNC.CombatDefense.CalculateAvoidChance(
    record,
    body,
    "scratch",
    4,
    { id = "Torso_Upper" }
)
T.truthy(crowdedChance < chance, "four-zombie crowd did not lower dodge")

protection = 50
local armoredChance = PNC.CombatDefense.CalculateAvoidChance(
    record,
    body,
    "scratch",
    4,
    { id = "Torso_Upper" }
)
T.truthy(armoredChance > crowdedChance, "matching armor did not reduce harm")

protection = 0
nearby = 1
randomValues = { 100, 1000 }
local avoided, result = PNC.CombatDefense.ResolveZombieAttack(
    record,
    body,
    makeZombie(0.5),
    now
)
T.equal(avoided, true, "successful defense roll")
T.equal(result.nearbyCount, 1, "live nearby count")
T.equal(result.pushed, true, "failed zombie attack stagger roll")
T.equal(staggerCount, 1, "stagger dispatched")
T.equal(broadcastCount, 1, "stagger replicated")
T.equal(nearMissCount, 1, "reactive kite armed")

fitness = 0
nearby = 4
randomValues = { 9999 }
avoided = PNC.CombatDefense.ResolveZombieAttack(
    record,
    body,
    makeZombie(0.5),
    now + 1
)
T.equal(avoided, false, "failed defense roll")
T.equal(staggerCount, 1, "hit incorrectly staggered attacker")
T.equal(broadcastCount, 1, "hit incorrectly replicated stagger")
T.equal(nearMissCount, 1, "hit incorrectly armed near-miss kite")
T.finish("pnc_combat_defense_smoke")

T.finish("pnc_combat_defense_smoke")
