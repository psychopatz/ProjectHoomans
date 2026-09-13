local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "shared", "PNC/Core/")
local emittedSounds = {}

local function item(fullType, sound)
    return {
        IsWeapon = function() return true end,
        getFullType = function() return fullType end,
        getSwingSound = function() return sound end,
    }
end

PNC = {
    Core = {},
    Registry = {},
    Perception = {},
    Equipment = {
        Internal = {
            buildWeaponDescriptor = function(fullType)
                local firearm = string.find(
                    tostring(fullType or ""),
                    "Pistol",
                    1,
                    true
                ) ~= nil
                return {
                    hasUsableFirearm = firearm,
                }
            end,
        },
        CreateItem = function(fullType)
            return item(fullType, "melee_swing")
        end,
    },
}

T.load(ROOT .. "Combat/PNC_Combat.lua")

local firearm = item("Base.TestPistol", "firearm_shot")
local melee = item("Base.HuntingKnife", "melee_swing")
local zombie = {
    getPrimaryHandItem = function() return firearm end,
    getEmitter = function()
        return {
            playSound = function(_, sound)
                emittedSounds[#emittedSounds + 1] = sound
            end,
        }
    end,
}

local firearmRecord = {
    equipment = { primaryFullType = "Base.TestPistol" },
}
local resolved = PNC.Combat.Internal.resolveWeaponItem(
    firearmRecord,
    zombie
)
T.equal(resolved, firearm, "matching firearm hand item resolves")

firearmRecord.equipment.primaryFullType = "Base.HuntingKnife"
resolved = PNC.Combat.Internal.resolveWeaponItem(
    firearmRecord,
    zombie
)
T.equal(resolved:getFullType(), "Base.HuntingKnife",
    "stale firearm hand item is rejected after melee switch")

PNC.Combat.Internal.playAttackSound(zombie, firearmRecord, firearm)
T.equal(#emittedSounds, 0,
    "firearm cannot emit shot audio through the melee sound path")
PNC.Combat.Internal.playAttackSound(zombie, firearmRecord, melee)
T.equal(emittedSounds[1], "melee_swing",
    "melee weapon retains its swing audio")

firearmRecord.equipment.primaryFullType = nil
resolved = PNC.Combat.Internal.resolveWeaponItem(firearmRecord, zombie)
T.equal(resolved, nil, "barehand fallback rejects stale firearm hand item")

T.finish("pnc_combat_firearm_melee_guard_smoke")
