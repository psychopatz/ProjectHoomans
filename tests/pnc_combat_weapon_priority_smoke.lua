local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "shared", "PNC/Core/")

local now = 1000
local mode = "armed"
local shoveCount = 0
local weaponAnimationCount = 0
local groundAnimationCount = 0
local unarmedAnimationCount = 0
local grounded = false
local action
local canSpendAttack = true
local targetZombie = { isDead = function() return false end }
local equippedWeapon = {
    IsWeapon = function() return true end,
}

PNC = {
    Core = { Now = function() return now end },
    Const = {
        MELEE_RANGE = 2,
        UNARMED_COOLDOWN_MS = 900,
        UNARMED_DAMAGE = 5,
        UNARMED_GROUND_DAMAGE = 8,
        COMBAT_SHOVE_RANGE = 1.35,
        INCAP_SHOVE_COOLDOWN_MS = 1200,
        DEBUG_COMBAT_HOLD_MS = 2500,
    },
    Combat = {
        Internal = {
            ATTACK_TIMINGS = {
                melee = { duration = 500 },
                shove = { duration = 420 },
            },
            canAttack = function() return true end,
            faceTarget = function() end,
            resolveWeaponItem = function() return mode == "armed" and equippedWeapon or nil end,
            playAttackSound = function() end,
            triggerMeleeWeaponAnim = function()
                weaponAnimationCount = weaponAnimationCount + 1
                return "PNC_Attack1H1"
            end,
            triggerUnarmedAttackAnim = function()
                unarmedAnimationCount = unarmedAnimationCount + 1
                return "PNC_AttackBareHands1"
            end,
            buildAttackAction = function(_, _, attackKind, attackType, anim)
                action = { attackKind = attackKind, attackType = attackType, anim = anim }
            end,
        },
    },
    Equipment = {
        Describe = function()
            -- A valid weapon can lack a specialized WeaponType animation
            -- classification. It must still attack instead of shoving.
            return {
                primaryType = "barehand",
                hasWeapon = mode == "armed",
            }
        end,
    },
    Perception = { FindZombieByID = function() return targetZombie end },
    CombatUnarmed = {
        IsGroundTarget = function() return grounded end,
        PlayShove = function() shoveCount = shoveCount + 1 end,
        PlayGroundAttack = function()
            groundAnimationCount = groundAnimationCount + 1
            return "PNC_Attack2HStamp"
        end,
    },
    CombatTactics = {
        ShouldUseGroundFinisher = function() return true end,
    },
    Stamina = {
        CanSpendAttack = function() return canSpendAttack end,
    },
}

T.load(ROOT .. "Combat/PNC_Combat_Melee.lua")

local function record()
    return {
        runtime = {},
        combatProfile = { meleeDamage = 10, meleeCooldownMs = 900, unarmedDamage = 5 },
        equipment = { primaryFullType = "Base.Axe" },
    }
end

local target = { kind = "zombie", zombieId = 12, distSq = 1 }
local started, reason = PNC.Combat.TryMelee(record(), {}, target)
T.equal(started, true, "armed attack starts")
T.equal(reason, "melee_attack_started", "armed attack reason")
T.equal(action.attackKind, "melee", "armed attack kind")
T.equal(action.anim, "PNC_Attack1H1", "weapon animation retained")
T.equal(weaponAnimationCount, 1, "weapon animation count")
T.equal(shoveCount, 0, "armed attack never shoves")

mode = "barehand"
action = nil
started, reason = PNC.Combat.TryMelee(record(), {}, target)
T.equal(started, true, "barehand attack starts")
T.equal(reason, "unarmed_attack_started", "barehand attack reason")
T.equal(action.attackKind, "melee", "barehand attack kind")
T.equal(action.anim, "PNC_AttackBareHands1",
    "barehand attack animation retained")
T.equal(unarmedAnimationCount, 1, "barehand animation count")
T.equal(shoveCount, 0, "ordinary barehand attack became a shove")

now = now + 1000
canSpendAttack = false
action = nil
local exhaustedRecord = record()
exhaustedRecord.runtime.emergencyMeleeUntil = now + 300
started, reason = PNC.Combat.TryMelee(
    exhaustedRecord,
    {},
    target
)
T.equal(started, true, "exhausted lone emergency attack starts")
T.equal(reason, "unarmed_attack_started",
    "exhausted lone emergency attack reason")
T.equal(action.attackKind, "melee",
    "exhausted lone emergency attack kind")
T.equal(exhaustedRecord.runtime.emergencyMeleeUntil, nil,
    "emergency melee lease was not consumed")
canSpendAttack = true

now = now + 1000
mode = "armed"
grounded = true
action = nil
started, reason = PNC.Combat.TryMelee(record(), {}, target)
T.equal(started, true, "armed ground finisher starts")
T.equal(reason, "ground_attack_started", "armed ground finisher reason")
T.equal(action.attackKind, "ground", "armed crawler uses ground attack")
T.equal(action.anim, "PNC_Attack2HStamp", "ground finisher animation retained")
T.equal(groundAnimationCount, 1, "ground finisher animation count")

now = now + 1000
grounded = false
action = nil
local shoveRecord = record()
started, reason = PNC.Combat.TryShove(
    shoveRecord,
    {},
    target,
    "pressure_shove"
)
T.equal(started, true, "armed tactical shove starts")
T.equal(reason, "pressure_shove", "tactical shove reason")
T.equal(action.attackKind, "shove", "tactical shove action kind")
T.equal(shoveCount, 1, "tactical shove animation count")

now = now + 1000
action = nil
canSpendAttack = false
started, reason = PNC.Combat.TryShove(
    record(),
    {},
    target,
    "exhausted_defensive_shove"
)
T.equal(started, true, "exhausted defensive shove was stamina-blocked")
T.equal(reason, "exhausted_defensive_shove",
    "exhausted defensive shove reason")
T.equal(action.attackKind, "shove",
    "exhausted defense did not build a shove action")

local biteSource = T.read(
    "ProjectHoomans", "shared", "PNC/Core/Zombies/PNC_ZombieAggro_Bite.lua"
)
T.truthy(not string.find(biteSource, "npc_parry", 1, true), "wound-roll rejection must not force a parry shove")

local actionSource = T.read(
    "ProjectHoomans", "shared",
    "PNC/Core/Combat/AttackExecution/PNC_AttackExecution_HitResolution.lua"
)
T.truthy(not string.find(actionSource, "pressure_shove", 1, true), "armed hits must not be replaced by pressure shoves")
T.finish("pnc_combat_weapon_priority_smoke")

T.finish("pnc_combat_weapon_priority_smoke")
