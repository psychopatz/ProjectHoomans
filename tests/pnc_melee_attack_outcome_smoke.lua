local T = require "tests/support/test"

local damages = 0
local wears = 0
local stamina = 0

PNC = {
    Core = {
        IsAuthority = function() return true end,
    },
    Const = { MELEE_RANGE = 1.3 },
    Skills = { AddXP = function() end },
    Stamina = {
        SpendAttack = function() stamina = stamina + 1 end,
    },
    Perception = {},
    CombatUnarmed = {},
    Combat = { Internal = { AttackExecution = {} } },
    CombatResolution = {},
}

local Resolution = PNC.CombatResolution
local Internal = PNC.Combat.Internal
local AttackExecution = Internal.AttackExecution
Resolution.ApplyTargetDamage = function()
    damages = damages + 1
    return true, "hit_player"
end
Internal.resolveWeaponItem = function() return nil end
AttackExecution.applyWeaponWear = function() wears = wears + 1 end

T.load(
    "ProjectHoomans", "shared",
    "PNC/Core/Combat/CombatResolution/PNC_CombatResolution_MeleeOutcome.lua")
T.load(
    "ProjectHoomans", "shared",
    "PNC/Core/Combat/AttackExecution/PNC_AttackExecution_HitResolution.lua")

local record = { id = "melee_outcome_test", runtime = {} }
local target = { kind = "player", player = {} }
local missAction = {
    attackType = "melee",
    attackKind = "melee",
    skillID = "Axe",
    meleeStrikeProfile = { hitChance = 0.05 },
}
local hitAction = {
    attackType = "melee",
    attackKind = "melee",
    skillID = "Axe",
    meleeStrikeProfile = { hitChance = 0.95 },
}

ZombRandFloat = function() return 1 end
local missed, missReason = Internal.applyAttackActionHit(
    record, {}, missAction, target)
T.falsy(missed, "an inaccurate melee strike does not apply damage")
T.equal(missReason, "melee_miss", "melee misses are reported explicitly")
T.equal(damages, 0, "a melee miss never reaches target damage")
T.equal(wears, 1, "a committed weapon swing wears on a miss")
T.equal(stamina, 1, "a committed melee swing spends stamina on a miss")

Internal.applyAttackActionHit(record, {}, missAction, target)
T.equal(wears, 1, "a melee outcome is rolled and committed only once")
T.equal(stamina, 1, "melee miss resources are committed only once")

ZombRandFloat = function() return 0 end
local hit, hitReason = Internal.applyAttackActionHit(
    record, {}, hitAction, target)
T.truthy(hit, "an accurate melee strike applies damage")
T.equal(hitReason, "hit_player", "successful melee damage keeps its reason")
T.equal(damages, 1, "a successful melee strike reaches target damage")

local groundAction = {
    attackType = "melee",
    attackKind = "ground",
    skillID = "Strength",
    damage = 10,
}
ZombRandFloat = function() return 1 end
local groundHit, groundReason = Internal.applyAttackActionHit(
    record, {}, groundAction, target)
T.truthy(groundHit, "ground finishers remain outside normal strike accuracy")
T.equal(groundReason, "hit_player", "ground finisher damage is applied")
T.equal(damages, 2, "ground finishers bypass ordinary melee accuracy")

T.finish("pnc_melee_attack_outcome_smoke")
