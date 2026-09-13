local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "shared", "PNC/Core/")

local function item(fullType, swing, impact, zombieHit)
    return {
        IsWeapon = function() return true end,
        getFullType = function() return fullType end,
        getSwingSound = function() return swing end,
        getImpactSound = function() return impact end,
        getZombieHitSound = function() return zombieHit end,
    }
end

PNC = {
    Core = {},
    Equipment = {
        Internal = {
            buildWeaponDescriptor = function(fullType)
                return {
                    hasUsableFirearm = string.find(
                        tostring(fullType or ""),
                        "Pistol",
                        1,
                        true
                    ) ~= nil,
                }
            end,
        },
    },
    Combat = {},
}

T.load(ROOT .. "Combat/PNC_Combat.lua")
T.load(ROOT .. "Combat/PNC_Combat_Audio.lua")

local Internal = PNC.Combat.Internal
local axeRecord = { equipment = { primaryFullType = "Base.Axe" } }
local knifeRecord = { equipment = { primaryFullType = "Base.HuntingKnife" } }
local firearmRecord = { equipment = { primaryFullType = "Base.TestPistol" } }
local axe = item("Base.Axe", "AxeSwing", "AxeImpact", "AxeZombieHit")
local knife = item("Base.HuntingKnife", "KnifeSwing", "KnifeImpact", "KnifeZombieHit")
local firearm = item("Base.TestPistol", "Gunshot", "GunImpact", "GunZombieHit")

local axeAudio = Internal.resolveMeleeAudio(
    axeRecord,
    axe,
    { primaryType = "twohanded", hasUsableFirearm = false },
    "melee",
    "PNC_Attack2H1"
)
T.equal(axeAudio.swingSound, "AxeSwing", "melee swing sound comes from weapon")
T.equal(axeAudio.voiceSuffix, "MeleeAttack", "blunt melee uses attack voice")
T.equal(axeAudio.impactSound, "AxeImpact", "player impact uses weapon impact sound")
T.equal(axeAudio.zombieHitSound, "AxeZombieHit", "zombie impact uses zombie hit sound")

local knifeAudio = Internal.resolveMeleeAudio(
    knifeRecord,
    knife,
    { primaryType = "onehanded", hasUsableFirearm = false },
    "melee",
    "PNC_AttackKnife"
)
T.equal(knifeAudio.voiceSuffix, "MeleeStab", "knife uses stab voice")
T.equal(knifeAudio.swingSound, "KnifeSwing", "knife keeps its swing sound")

local firearmAudio = Internal.resolveMeleeAudio(
    firearmRecord,
    firearm,
    { primaryType = "onehanded", hasUsableFirearm = true },
    "melee",
    "PNC_AttackBareHands1"
)
T.equal(firearmAudio.swingSound, nil, "firearm has no melee swing sound")
T.equal(firearmAudio.impactSound, nil, "firearm has no melee impact sound")
T.equal(firearmAudio.voiceSuffix, "MeleeAttack", "firearm fallback still has melee voice")

local firearmGroundAudio = Internal.resolveMeleeAudio(
    firearmRecord,
    firearm,
    { primaryType = "onehanded", hasUsableFirearm = true },
    "ground",
    "PNC_Attack2HStamp"
)
T.equal(firearmGroundAudio.swingSound, "AttackStomp",
    "firearm ground fallback keeps safe stomp sound")
T.equal(firearmGroundAudio.voiceSuffix, "MeleeStomp",
    "firearm ground fallback keeps stomp voice")

local action = { attackType = "melee", audio = axeAudio }
local attackRecord = { runtime = {} }
T.truthy(
    Internal.commitMeleeImpactAudio(
        attackRecord,
        action,
        { kind = "zombie" }
    ),
    "successful zombie hit commits impact audio"
)
T.equal(action.audio.hitSound, "AxeZombieHit", "zombie hit selects zombie sound")
T.falsy(
    Internal.commitMeleeImpactAudio(
        attackRecord,
        action,
        { kind = "zombie" }
    ),
    "repeated hit pump does not commit impact twice"
)

local shoveAudio = Internal.resolveMeleeAudio(
    {},
    nil,
    nil,
    "shove",
    "PNC_Shove"
)
T.equal(shoveAudio.swingSound, "AttackShove", "shove keeps shove sound")
T.equal(shoveAudio.voiceSuffix, "MeleeAttack", "shove uses melee voice")

T.finish("pnc_combat_audio_smoke")
