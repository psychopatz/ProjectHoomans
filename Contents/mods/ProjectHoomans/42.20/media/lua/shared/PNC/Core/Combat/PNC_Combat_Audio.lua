--
-- PNC Combat Audio
-- Resolves weapon-aware melee audio on the authority and stores only
-- serializable presentation data on the attack action.
--

PNC = PNC or {}
PNC.Combat = PNC.Combat or {}

local Combat = PNC.Combat
local Internal = Combat.Internal or {}

Combat.Internal = Internal

local function safeMethod(object, methodName, ...)
    local method
    local ok
    local result
    if not object then return nil end
    method = object[methodName]
    if type(method) ~= "function" then return nil end
    ok, result = pcall(method, object, ...)
    if ok then return result end
    return nil
end

local function normalizeSound(value)
    value = value and tostring(value) or nil
    if value == nil or value == "" then return nil end
    return value
end

local function isFirearm(record, weaponItem, equipmentInfo)
    if equipmentInfo and equipmentInfo.hasUsableFirearm == true then
        return true
    end
    if Internal.isFirearmWeapon then
        return Internal.isFirearmWeapon(record, weaponItem, equipmentInfo) == true
    end
    return false
end

local function weaponFamily(record, equipmentInfo)
    if Internal.resolveMeleeAnimFamily then
        return Internal.resolveMeleeAnimFamily(record, equipmentInfo)
    end
    return "onehanded"
end

local function baseAudio(voiceSuffix, swingSound)
    return {
        voiceSuffix = voiceSuffix,
        swingSound = normalizeSound(swingSound),
        impactSound = nil,
        zombieHitSound = nil,
        hitSequence = nil,
        hitSound = nil,
    }
end

function Internal.resolveMeleeAudio(
    record,
    weaponItem,
    equipmentInfo,
    attackKind,
    anim
)
    local audio
    local family
    local firearm
    local isStamp
    if attackKind == "ground" then
        isStamp = tostring(anim or "") == "PNC_Attack2HStamp"
        if isStamp then
            return baseAudio("MeleeStomp", "AttackStomp")
        end
    end
    if attackKind == "shove" then
        return baseAudio("MeleeAttack", "AttackShove")
    end

    firearm = isFirearm(record, weaponItem, equipmentInfo)
    if firearm then
        -- A firearm can enter the unarmed fallback lane when close combat
        -- takes over. Its getSwingSound() is the gunshot in PZ and must never
        -- be emitted as a melee swing.
        return baseAudio("MeleeAttack", nil)
    end

    family = weaponFamily(record, equipmentInfo)
    audio = baseAudio(
        family == "knife" and "MeleeStab" or "MeleeAttack",
        safeMethod(weaponItem, "getSwingSound")
    )
    audio.impactSound = normalizeSound(
        safeMethod(weaponItem, "getImpactSound")
    )
    audio.zombieHitSound = normalizeSound(
        safeMethod(weaponItem, "getZombieHitSound")
    )
    return audio
end

function Internal.commitMeleeImpactAudio(record, action, target)
    local audio
    local targetKind
    local sound
    local runtime
    if not action or action.attackType ~= "melee" then
        return false
    end
    audio = action.audio
    if not audio or audio.hitSequence ~= nil then
        return false
    end
    targetKind = target and tostring(target.kind or "") or ""
    sound = targetKind == "zombie"
        and (audio.zombieHitSound or audio.impactSound)
        or audio.impactSound
    sound = normalizeSound(sound)
    if not sound then
        -- Mark the phase as consumed even when a modded weapon has no impact
        -- sound, so a repeated attack pump cannot re-enter this branch.
        audio.hitSequence = 0
        return false
    end
    audio.hitSequence = 1
    audio.hitSound = sound
    runtime = record and record.runtime or nil
    if runtime and runtime.forceSyncEvent == nil then
        runtime.forceSyncEvent = "attack_hit"
    end
    return true
end

return Combat
