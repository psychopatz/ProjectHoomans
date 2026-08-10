local ROOT = "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected) .. " actual=" .. tostring(actual))
    end
end

local now = 1000
local mode = "armed"
local shoveCount = 0
local weaponAnimationCount = 0
local groundAnimationCount = 0
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

dofile(ROOT .. "Combat/PNC_Combat_Melee.lua")

local function record()
    return {
        runtime = {},
        combatProfile = { meleeDamage = 10, meleeCooldownMs = 900, unarmedDamage = 5 },
        equipment = { primaryFullType = "Base.Axe" },
    }
end

local target = { kind = "zombie", zombieId = 12, distSq = 1 }
local started, reason = PNC.Combat.TryMelee(record(), {}, target)
assertEqual(started, true, "armed attack starts")
assertEqual(reason, "melee_attack_started", "armed attack reason")
assertEqual(action.attackKind, "melee", "armed attack kind")
assertEqual(action.anim, "PNC_Attack1H1", "weapon animation retained")
assertEqual(weaponAnimationCount, 1, "weapon animation count")
assertEqual(shoveCount, 0, "armed attack never shoves")

mode = "barehand"
action = nil
started, reason = PNC.Combat.TryMelee(record(), {}, target)
assertEqual(started, true, "barehand attack starts")
assertEqual(reason, "shove_started", "barehand shove reason")
assertEqual(action.attackKind, "shove", "barehand attack kind")
assertEqual(shoveCount, 1, "barehand shove retained")

now = now + 1000
mode = "armed"
grounded = true
action = nil
started, reason = PNC.Combat.TryMelee(record(), {}, target)
assertEqual(started, true, "armed ground finisher starts")
assertEqual(reason, "ground_attack_started", "armed ground finisher reason")
assertEqual(action.attackKind, "ground", "armed crawler uses ground attack")
assertEqual(action.anim, "PNC_Attack2HStamp", "ground finisher animation retained")
assertEqual(groundAnimationCount, 1, "ground finisher animation count")

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
assertEqual(started, true, "armed tactical shove starts")
assertEqual(reason, "pressure_shove", "tactical shove reason")
assertEqual(action.attackKind, "shove", "tactical shove action kind")
assertEqual(shoveCount, 2, "tactical shove animation count")

now = now + 1000
action = nil
canSpendAttack = false
started, reason = PNC.Combat.TryShove(
    record(),
    {},
    target,
    "exhausted_defensive_shove"
)
assertEqual(started, true, "exhausted defensive shove was stamina-blocked")
assertEqual(reason, "exhausted_defensive_shove",
    "exhausted defensive shove reason")
assertEqual(action.attackKind, "shove",
    "exhausted defense did not build a shove action")

local biteFile = assert(io.open(ROOT .. "Zombies/PNC_ZombieAggro_Bite.lua", "r"))
local biteSource = biteFile:read("*a")
biteFile:close()
assert(not string.find(biteSource, "npc_parry", 1, true), "wound-roll rejection must not force a parry shove")

local actionFile = assert(io.open(ROOT .. "Combat/PNC_Combat_AttackActions.lua", "r"))
local actionSource = actionFile:read("*a")
actionFile:close()
assert(not string.find(actionSource, "pressure_shove", 1, true), "armed hits must not be replaced by pressure shoves")

print("pnc_combat_weapon_priority_smoke: ok")
