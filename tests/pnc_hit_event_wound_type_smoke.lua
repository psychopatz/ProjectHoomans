local T = require "tests/support/test"

T.addPackagePaths()

PNC = {
    CombatResolution = {},
    Equipment = {
        Internal = {
            buildWeaponDescriptor = function(fullType)
                return {
                    hasUsableFirearm = tostring(fullType or "")
                        == "Base.Pistol",
                }
            end,
        },
    },
}

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Combat/CombatResolution/PNC_CombatResolution_HitEvent.lua"
)

local gun = {
    getFullType = function() return "Base.Pistol" end,
    isRanged = function() return true end,
}
local knife = {
    getFullType = function() return "Base.HuntingKnife" end,
    IsWeapon = function() return true end,
}

local hit = PNC.CombatResolution.BuildHitEvent(
    { id = "shooter" },
    { kind = "npc" },
    {
        damage = 12,
        attackType = "ranged",
        attackKind = "ranged",
        woundType = "laceration",
        weaponItem = gun,
    }
)
T.equal(hit.woundType, "bullet",
    "ranged attack cannot degrade into a laceration")
T.equal(hit.weaponFullType, "Base.Pistol",
    "firearm full type is retained on the hit event")

hit = PNC.CombatResolution.BuildHitEvent(
    { id = "shooter" },
    { kind = "npc" },
    {
        damage = 12,
        attackType = "melee",
        attackKind = "melee",
        woundType = "laceration",
        weaponFullType = "Base.Pistol",
    }
)
T.equal(hit.woundType, "bullet",
    "stale firearm action metadata is normalized to a bullet wound")

hit = PNC.CombatResolution.BuildHitEvent(
    { id = "shooter" },
    { kind = "npc" },
    {
        damage = 8,
        attackType = "melee",
        attackKind = "ranged_windup",
        woundType = "scratch",
        weaponItem = gun,
    }
)
T.equal(hit.woundType, "bullet",
    "ranged windup metadata survives the delayed hit boundary")

hit = PNC.CombatResolution.BuildHitEvent(
    { id = "shooter" },
    { kind = "npc" },
    {
        damage = 8,
        attackType = "melee",
        attackKind = "melee",
        weaponItem = knife,
    }
)
T.equal(hit.woundType, "laceration",
    "ordinary weapon melee remains a laceration")

T.finish("pnc_hit_event_wound_type_smoke")
