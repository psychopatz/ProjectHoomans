local T = require "tests/support/test"

local CORE_DIR = T.path("ProjectHoomans", "shared", "PNC/Core/")

T.addPackagePaths()

SandboxVars = {
    XpMultiplier = 1.0,
    XpMultiplierAffectsPassive = true,
}

local markDirtyCalls = 0
PNC = {
    Const = {
        STAMINA_MELEE_COST = 20,
        STAMINA_RANGED_COST = 10,
        STAMINA_DOWNED_SHOVE_COST = 8,
        STAMINA_ATTACK_MIN_RESERVE = 10,
    },
    Core = {
        Now = function() return 1000 end,
    },
    Registry = {
        MarkDirty = function() markDirtyCalls = markDirtyCalls + 1 end,
    },
    Identity = {
        Index = function(_, _, n) return 1 end,
        Range = function(_, _, lo, _) return lo end,
    },
    Types = {
        IsColonist = function(r) return r and r.recruited == true end,
    },
    CombatResolution = {
        IsWeaponDamageEnabled = function() return true end,
    },
}

T.load(CORE_DIR .. "Skills/PNC_SkillCatalog.lua")
T.load(CORE_DIR .. "Skills/PNC_Skills.lua")
T.load(CORE_DIR .. "Combat/CombatResolution/PNC_CombatResolution_Weapon.lua")
T.load(CORE_DIR .. "Combat/CombatResolution/PNC_CombatResolution_MeleeOutcome.lua")
T.load(CORE_DIR .. "Stamina/PNC_Stamina.lua")

-- 1. Non-player-owned NPC cannot gain XP, exercise, or mood (zero delta bloat)
local stranger = {
    id = "stranger_1",
    identitySeed = 10,
    recruited = false,
}
T.equal(PNC.Skills.GetLevel(stranger, "Carpentry"), 0, "stranger reads level cleanly")
T.equal(stranger.progression, nil, "reading GetLevel does not allocate progression on stranger")
T.equal(PNC.Skills.AddXP(stranger, "Carpentry", 500), false, "stranger cannot earn XP")
T.equal(PNC.Exercise.PerformRep(stranger, "pushups", 10), false, "stranger cannot exercise")
T.equal(PNC.Mood.Set(stranger, "stress", 0.5), false, "stranger cannot mutate mood")
T.equal(stranger.progression, nil, "stranger progression stays nil for delta compression")

-- 2. Player-owned colonist uses Build 42 XP curve & multipliers
local colonist = {
    id = "colonist_1",
    identitySeed = 11,
    recruited = true,
    skillBaseLevels = { Carpentry = 1, Strength = 2, Fitness = 2, Axe = 0 },
    traits = { "FastLearner" },
    stamina = { current = 100, max = 100 },
    runtime = {},
}
T.equal(PNC.Skills.GetNextLevelXP(colonist, "Carpentry"), 150, "Level 1->2 active threshold is 150 (Build 42)")
T.equal(PNC.Skills.GetNextLevelXP(colonist, "Fitness"), 6000, "Level 2->3 passive threshold is 6000 (Build 42)")

-- Level 1 Carpentry + FastLearner (1.3x): 100 raw -> 130 XP; +20 raw -> 156 XP -> Level 2 with 6 XP remaining
T.equal(PNC.Skills.AddXP(colonist, "Carpentry", 100), true, "colonist earns Carpentry XP")
T.near(PNC.Skills.GetXP(colonist, "Carpentry"), 130, 0.01, "FastLearner 1.3x multiplier applied")
T.equal(PNC.Skills.GetLevel(colonist, "Carpentry"), 1, "still level 1 before 150")
T.equal(PNC.Skills.AddXP(colonist, "Carpentry", 20), true, "colonist crosses level threshold")
T.equal(PNC.Skills.GetLevel(colonist, "Carpentry"), 2, "leveled up to Carpentry 2")
T.near(PNC.Skills.GetXP(colonist, "Carpentry"), 6, 0.01, "overflow XP preserved")

-- 3. Native weaponItem:getCategories() resolves modded & vanilla weapons
local moddedWeapon = {
    getCategories = function() return { "SmallBlunt" } end,
    isRanged = function() return false end,
}
T.equal(
    PNC.Skills.ResolveWeaponSkill(colonist, "Mod.CustomPipeWrench", "melee", moddedWeapon),
    "ShortBlunt",
    "native getCategories maps SmallBlunt -> ShortBlunt"
)

-- 4. Dirty-mark coalescing on AddXPBatch
markDirtyCalls = 0
colonist.runtime.skillDirtyAccum = 0
colonist.runtime.skillDirtyMarkedAt = 1000
PNC.Skills.AddXPBatch(colonist, {
    { skillId = "Axe", amount = 4 },       -- 0.25x * 1.3 = 1.3 XP
    { skillId = "Maintenance", amount = 1 }, -- 0.25x * 1.3 = 0.325 XP
})
T.equal(markDirtyCalls, 0, "small fractional XP coalesced without immediate MarkDirty")

-- 5. Exercise grants Fitness/Strength XP, builds regularity, and causes delayed stiffness + pain debuff
local baseWeapon = {
    getMinDamage = function() return 1.0 end,
    getMaxDamage = function() return 1.0 end,
}
local freshDmg = PNC.CombatResolution.GetAttackDamage(colonist, "melee", baseWeapon, 1, 2)
local freshCd = PNC.CombatResolution.GetMeleeCooldown(colonist, 1000, {}, {})
local freshDrain = PNC.Stamina.GetAttackDrain(colonist, "melee", "Strength")

local exOK, exInfo = PNC.Exercise.PerformRep(colonist, "burpees", 100)
T.equal(exOK, true, "colonist performed burpees")
T.truthy(PNC.Skills.GetXP(colonist, "Fitness") > 0, "burpees awarded Fitness XP")
T.truthy(PNC.Skills.GetXP(colonist, "Strength") > 0, "burpees awarded Strength XP")
T.truthy(exInfo.regularity > 0, "regularity increased")
T.truthy(exInfo.pendingStiffness > 0, "pending stiffness queued")

-- Advance 12+ hours so delayed exercise stiffness sets in (just like vanilla Fitness.java)
PNC.Exercise.Update(colonist, 12, false)
PNC.Exercise.Update(colonist, 6, false)
local stiffNow = PNC.Exercise.GetStiffness(colonist)
T.truthy(stiffNow >= 50, "delayed exercise stiffness peaked after 12h onset")
T.truthy(PNC.Mood.Get(colonist, "pain") >= 0.50, "exercise stiffness raised mood pain")

local soreDmg = PNC.CombatResolution.GetAttackDamage(colonist, "melee", baseWeapon, 1, 2)
local soreCd = PNC.CombatResolution.GetMeleeCooldown(colonist, 1000, {}, {})
local soreDrain = PNC.Stamina.GetAttackDrain(colonist, "melee", "Strength")
T.truthy(soreDmg < freshDmg, "over-exercised stiffness/pain lowers melee damage")
T.truthy(soreCd > freshCd, "over-exercised stiffness/pain slows melee cooldown")
T.truthy(soreDrain > freshDrain, "over-exercised stiffness/pain increases stamina drain")

-- 6. Compact serialization roundtrip preserves exercise & mood for colonist, nil for stranger
local serializedStranger = PNC.Skills.Repository.SerializeRecord(stranger)
T.equal(serializedStranger, nil, "stranger serializes to nil (zero ModData)")
local serializedColonist = PNC.Skills.Repository.SerializeRecord(colonist)
T.truthy(serializedColonist and serializedColonist.exercise and serializedColonist.mood,
    "colonist serializes exercise and mood compactly")

T.finish("pnc_skills_xp_exercise_mood_smoke")
