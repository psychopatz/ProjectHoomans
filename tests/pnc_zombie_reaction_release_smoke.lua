local T = require "tests/support/test"

local FILE =
    T.path("ProjectHoomans", "shared", "PNC/Core/")
    .. "Combat/PNC_Combat_ZombieReaction.lua"

local now = 1000
local actionState = "staggerback"
local staggerBack = false
local bumpDone = true
local bumpType = ""
local hitReaction = ""
local delayTimer = 1
local modData = {}

PNC = {
    Core = {
        Now = function() return now end,
    },
}

local attacker = {
    getX = function() return 0 end,
    getY = function() return 0 end,
}
local target = {
    isDead = function() return false end,
    getModData = function() return modData end,
    getX = function() return 1 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
    getHealth = function() return 1 end,
    setHealth = function() end,
    getActionStateName = function() return actionState end,
    setAttackedBy = function() end,
    setHitForce = function() end,
    setHitReaction = function(_, value) hitReaction = value end,
    setStaggerBack = function(_, value) staggerBack = value end,
    setBumpDone = function(_, value) bumpDone = value end,
    setVariable = function() end,
    setBumpType = function(_, value) bumpType = value end,
    getBumpType = function() return bumpType end,
    setStateEventDelayTimer = function(_, value) delayTimer = value end,
}

T.load(FILE)

T.truthy(PNC.CombatZombieReaction.ApplyReplicatedHit(
    attacker,
    target,
    {
        kind = "melee",
        hitReaction = "HitReaction",
        stagger = true,
        settleMs = 520,
    }
))
T.truthy(staggerBack and not bumpDone and bumpType == "stagger",
    "replicated reaction did not enter its transient stagger")
T.truthy(modData.PNC_CombatReaction ~= nil,
    "replicated reaction did not register a release lease")
T.truthy(PNC.CombatZombieReaction.Pump(target, 1050),
    "reaction ended before its minimum engine ownership window")

actionState = "walktoward"
T.truthy(not PNC.CombatZombieReaction.Pump(target, 1120),
    "reaction retained AI ownership after the engine returned to walking")
T.truthy(not staggerBack and bumpDone and bumpType == "",
    "reaction release left zombie stagger/bump flags active")
T.truthy(hitReaction == "" and delayTimer == 0,
    "reaction release left engine hit state inputs latched")
T.truthy(modData.PNC_CombatReaction == nil,
    "reaction lease survived its engine-state exit")

now = 2000
actionState = "staggerback"
PNC.CombatZombieReaction.ApplyReplicatedHit(
    attacker,
    target,
    {
        kind = "melee",
        hitReaction = "HitReaction",
        stagger = true,
        settleMs = 200,
    }
)
T.truthy(not PNC.CombatZombieReaction.Pump(target, 2201),
    "stuck reaction survived its hard timeout")
T.truthy(not staggerBack and bumpDone and bumpType == "",
    "hard timeout did not restore zombie AI inputs")
T.finish("pnc_zombie_reaction_release_smoke")

T.finish("pnc_zombie_reaction_release_smoke")
