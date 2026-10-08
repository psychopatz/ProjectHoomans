local T = require "tests/support/test"

local FILE = T.path(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Compatibility/PNC_Compatibility_DamageContext.lua"
)

PNC = { Compatibility = {} }
local context = T.load(FILE)

local firearm = {
    isRanged = function() return true end,
    getFullType = function() return "Base.Pistol" end,
}

local normalized = context.Normalize({
    amount = "12.5",
    attackKind = "provider_firearm_hit",
    weaponItem = firearm,
})

T.equal(normalized.contractVersion, 1,
    "damage context did not declare its contract version")
T.equal(normalized.amount, 12.5,
    "damage context did not normalize numeric damage")
T.equal(normalized.attackType, "ranged",
    "firearm context did not become a ranged attack")
T.equal(normalized.damageClass, "firearm",
    "firearm context did not preserve its damage class")
T.equal(normalized.weaponFullType, "Base.Pistol",
    "weapon full type was not captured")
T.truthy(context.IsRanged(nil, "Base.Pistol", nil, nil),
    "firearm full type was not recognized without a runtime item")

local melee = context.Normalize({
    amount = 4,
    attackKind = "provider_melee_hit",
})
T.equal(melee.attackType, "melee",
    "melee provider context did not get a stable attack type")
T.equal(melee.damageClass, "melee",
    "melee provider context did not get a stable damage class")

local explosion = context.Normalize({
    amount = 4,
    damageClass = "explosion",
    woundType = "burn",
})
T.equal(explosion.woundType, "scratch",
    "unsupported fire wound did not use the explicit safe fallback")

T.finish("pnc_compatibility_damage_context_smoke")
