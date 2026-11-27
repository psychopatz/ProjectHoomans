local T = require "tests/support/test"
T.load("tests/pnc_npc_foundation_parity_baseline_smoke.lua")
T.load("ProjectHoomans", "server", "PNC/Director/PNC_AbstractCombatProfile.lua")

local function assertTrue(cond, label)
    if not cond then error((label or "assertTrue") .. " failed") end
end

local Profile = PNC.AbstractCombatProfile
assertTrue(type(Profile.ScoreActor) == "function", "ScoreActor exists")
assertTrue(type(Profile.BuildForParticipants) == "function", "BuildForParticipants exists")

local armedColonist = {
    id = "col_armed_1",
    alive = true,
    affiliation = { role = "guard" },
    health = { current = 100, max = 100 },
    equipment = {
        primaryFullType = "Base.AssaultRifle",
        primaryCondition = 10,
        primaryConditionMax = 10,
        ammoCount = 60,
        wornItems = { "Base.Vest_BulletArmy", "Base.Hat_Army", "Base.Jacket_ArmyCamoGreen" },
    },
    skills = { Aiming = 7, Reloading = 5, Doctor = 3, Fitness = 6 },
    inventory = {
        { fullType = "Base.Bandage", count = 3 },
    },
}

local wornOutColonist = {
    id = "col_worn_1",
    alive = true,
    affiliation = { role = "guard" },
    health = { current = 100, max = 100 },
    equipment = {
        primaryFullType = "Base.AssaultRifle",
        primaryCondition = 1,
        primaryConditionMax = 10,
        ammoCount = 60,
    },
    skills = { Aiming = 7, Reloading = 5 },
}

local civilian = {
    id = "civ_1",
    alive = true,
    affiliation = { role = "civilian" },
    health = { current = 50, max = 100 },
    equipment = {},
}

local sArmed = Profile.ScoreActor(armedColonist, { applyPersonalAmmo = true })
local sWorn = Profile.ScoreActor(wornOutColonist, { applyPersonalAmmo = true })
local sCiv = Profile.ScoreActor(civilian, { applyPersonalAmmo = true })

assertTrue(sArmed ~= nil and sWorn ~= nil and sCiv ~= nil, "all actors scored")
assertTrue(sArmed.armorRating > 0.7, "bulletproof vest + helmet + army jacket gives strong armorRating")
assertTrue(sArmed.defense > sWorn.defense, "armored colonist has higher defense than unarmored")
assertTrue(sArmed.ranged > sWorn.ranged, "full-condition rifle outscores degraded rifle")
assertTrue(sArmed.ranged > sCiv.ranged and sArmed.defense > sCiv.defense, "armed guard outscores injured civilian")
assertTrue(sArmed.medical > 0, "doctor skill + bandages contribute to medical score")

-- Test BuildForParticipants on a 2-colonist squad (no AbstractGroup required).
local squadProfile = Profile.BuildForParticipants({ armedColonist, civilian }, { ammo = 20 })
assertTrue(squadProfile.memberCount == 2, "squad memberCount == 2")
assertTrue(squadProfile.ammoState == 80, "pool ammo (20) + personal ammo (60) == 80")
assertTrue(squadProfile.rangedPower > 0, "squad rangedPower > 0")
assertTrue(squadProfile.overallPower > 0, "squad overallPower > 0")

-- Test unpromoted PsychopatzCore actor resolution.
local prevActors = PsychopatzCore and PsychopatzCore.Actors
PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Actors = {
    DefaultRegistry = {
        Get = function(_, id)
            if id == "core_unpromoted_1" then
                return {
                    actorId = "core_unpromoted_1",
                    status = "active",
                    role = "raider",
                    equipment = { primaryFullType = "Base.Shotgun", ammoCount = 30 },
                    outfit = "BulletproofVest",
                }
            end
            return nil
        end,
    },
}

local coreScore = Profile.ScoreActor("core_unpromoted_1", { applyPersonalAmmo = true })
assertTrue(coreScore ~= nil and coreScore.source == "core_actor", "unpromoted Core actor resolved")
assertTrue(coreScore.weaponClass == "shotgun", "unpromoted Core actor shotgun detected")
assertTrue(coreScore.armorRating > 0, "unpromoted Core actor outfit armor detected")

PsychopatzCore.Actors = prevActors
print("PASS: pnc_abstract_combat_scorer_smoke")
