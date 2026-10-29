local T = require "tests/support/test"
T.addPackagePaths({ { "ProjectHoomans", "shared" } })

PNC = {
    Semantics = {},
    Skills = {
        ResolveWeaponSkill = function(_, fullType, attackType)
            local value = string.lower(tostring(fullType or ""))
            if attackType == "ranged" then return "Aiming" end
            if string.find(value, "machete", 1, true) then return "LongBlade" end
            if string.find(value, "axe", 1, true) then return "Axe" end
            if string.find(value, "spear", 1, true) then return "Spear" end
            if string.find(value, "bat", 1, true) then return "LongBlunt" end
            return "Strength"
        end,
        GetLevel = function(record, skillID)
            return record.levels and record.levels[skillID] or 0
        end,
    },
}
local Weapon = T.load(
    "ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticCombatWeaponContext.lua"
)

local record = { levels = { Aiming = 8, LongBlade = 5 } }
local pistol = {
    getFullType = function() return "Base.Pistol" end,
    getDisplayName = function() return "M9 Pistol" end,
}
local firearm = Weapon.Build(record, {
    weaponItem = pistol,
    attackType = "ranged",
    partId = "Head",
    woundType = "gunshot",
    source = "test",
})
T.equal(firearm.weaponFamily, "firearm", "ranged hit normalizes to firearm")
T.equal(firearm.weaponSkill, "Aiming", "firearm reuses Aiming skill authority")
T.equal(firearm.weaponSkillLevel, 8, "actual skill level is projected")
T.equal(firearm.weaponSkillBand, "high", "skill level has bounded band")
T.equal(firearm.hitZone, "head_neck", "head hit uses head/neck semantic zone")
T.equal(firearm.weaponDisplayName, "M9 Pistol",
    "human-readable actual item display name is retained")
T.truthy(firearm.weaponNameEligible, "safe display name is eligible")

local machete = {
    getFullType = function() return "Base.Machete" end,
    getDisplayName = function() return "Machete" end,
}
local blade = Weapon.Build(record, {
    weaponItem = machete,
    attackType = "melee",
    partId = "Torso_Upper",
    woundType = "cut",
})
T.equal(blade.weaponFamily, "long_blade", "machete uses existing weapon skill map")
T.equal(blade.hitZone, "torso", "torso blade hit cannot claim a head result")

local rawName = {
    getFullType = function() return "ExampleMod.CustomCarbine" end,
    getDisplayName = function() return "ExampleMod.CustomCarbine" end,
}
local modded = Weapon.Build({ levels = { Aiming = 1 } }, {
    weaponItem = rawName,
    attackType = "ranged",
})
T.equal(modded.weaponFamily, "firearm",
    "unknown modded ranged weapon degrades to firearm family")
T.equal(modded.weaponDisplayName, nil,
    "module-qualified internal item ID is never eligible as display flavor")
T.falsy(modded.weaponNameEligible, "unsafe raw item name is suppressed")

local bare = Weapon.Build({ levels = { Strength = 3 } }, {
    attackType = "melee",
})
T.equal(bare.weaponFamily, "unarmed", "missing actual weapon is unarmed")
T.equal(bare.weaponDisplayName, nil, "unarmed context has no invented weapon")

T.finish("pnc_semantic_combat_weapon_context_smoke")
