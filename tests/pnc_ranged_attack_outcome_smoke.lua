local T = require "tests/support/test"

local effects = 0
local damages = 0

PNC = {
    Core = {
        IsAuthority = function() return true end,
    },
    Const = { RANGED_RANGE = 8.5 },
    Skills = {
        AddXP = function() end,
    },
    Stamina = {
        SpendAttack = function() end,
    },
    Perception = {},
    CombatUnarmed = {},
    Combat = { Internal = { AttackExecution = {} } },
    CombatResolution = {},
    FirearmEffects = {
        Emit = function() effects = effects + 1 end,
    },
}

T.load(
    "ProjectHoomans", "shared",
    "PNC/Core/Traits/PNC_NPCTraitRegistry.lua")
T.load(
    "ProjectHoomans", "shared",
    "PNC/Core/Traits/PNC_NPCTraitEffects.lua")
T.load(
    "ProjectHoomans", "shared",
    "PNC/Core/Combat/CombatResolution/PNC_CombatResolution_RangedOutcome.lua")

local Resolution = PNC.CombatResolution
local Internal = PNC.Combat.Internal
local AttackExecution = Internal.AttackExecution
Resolution.ApplyTargetDamage = function()
    damages = damages + 1
    return true, "hit_player"
end
Internal.resolveWeaponItem = function() return nil end
AttackExecution.applyWeaponWear = function() end

T.load(
    "ProjectHoomans", "shared",
    "PNC/Core/Combat/AttackExecution/PNC_AttackExecution_HitResolution.lua")

local record = { id = "outcome_test", runtime = {} }
local target = { kind = "player", player = {} }
local missAction = {
    attackType = "ranged",
    attackKind = "ranged",
    ammoConsumed = true,
    rangedShotProfile = { hitChance = 0.05 },
}
local hitAction = {
    attackType = "ranged",
    attackKind = "ranged",
    ammoConsumed = true,
    rangedShotProfile = { hitChance = 0.95 },
}

ZombRandFloat = function() return 1 end
local missed, missReason = Internal.applyAttackActionHit(
    record, {}, missAction, target)
T.falsy(missed, "an inaccurate ranged shot does not apply damage")
T.equal(missReason, "ranged_miss", "ranged misses are reported explicitly")
T.equal(effects, 1, "a miss still emits the firearm effect")
T.equal(damages, 0, "a miss never reaches target damage")

Internal.applyAttackActionHit(record, {}, missAction, target)
T.equal(effects, 1, "a committed shot is rolled only once")

ZombRandFloat = function() return 0 end
local hit, hitReason = Internal.applyAttackActionHit(
    record, {}, hitAction, target)
T.truthy(hit, "an accurate ranged shot applies damage")
T.equal(hitReason, "hit_player", "successful ranged damage keeps its reason")
T.equal(effects, 2, "a successful shot emits the firearm effect")
T.equal(damages, 1, "a successful shot reaches target damage")

T.finish("pnc_ranged_attack_outcome_smoke")
