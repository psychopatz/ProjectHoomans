PNC = PNC or {}
PNC.Equipment = PNC.Equipment or {}
PNC.Equipment.Internal = PNC.Equipment.Internal or {}

local Equipment = PNC.Equipment
local Internal = Equipment.Internal
local Core = PNC.Core
local Visuals = PNC.Visuals
local Inventory = PNC.Inventory

function Equipment.Describe(record)
    local configuredMode
    local fullType
    local descriptor
    local combatModeResolved
    local weaponStatus
    local runtime
    local cacheKey
    local cached
    local result

    configuredMode = tostring(record and record.weaponMode or "melee")
    fullType = record and record.equipment and record.equipment.primaryFullType or nil
    runtime = record and (record.runtime or {}) or nil
    if record then
        record.runtime = runtime
    end
    cacheKey = configuredMode .. "|" .. tostring(fullType or "")
    cached = runtime and runtime.equipmentDescribeCache or nil
    if cached and cached.key == cacheKey and cached.value then
        return cached.value
    end

    descriptor = Internal.buildWeaponDescriptor(fullType, false)
    combatModeResolved = configuredMode
    weaponStatus = descriptor.weaponStatus

    if configuredMode == "ranged" then
        if descriptor.hasUsableFirearm then
            combatModeResolved = "ranged"
            weaponStatus = "ranged_ready"
        else
            combatModeResolved = "melee"
            if descriptor.weaponStatus ~= "barehand" and descriptor.hasWeapon ~= true and descriptor.fullType then
                weaponStatus = descriptor.weaponStatus .. "_fallback_melee"
            elseif descriptor.fullType and descriptor.hasWeapon then
                weaponStatus = "ranged_missing_firearm_fallback_melee"
            else
                weaponStatus = "ranged_unarmed_fallback_melee"
            end
        end
    elseif configuredMode == "mixed" then
        if descriptor.hasUsableFirearm then
            combatModeResolved = "mixed"
            weaponStatus = "mixed_ranged_ready"
        elseif descriptor.weaponStatus ~= "barehand" and descriptor.hasWeapon ~= true and descriptor.fullType then
            combatModeResolved = "melee"
            weaponStatus = descriptor.weaponStatus .. "_fallback_melee"
        elseif descriptor.hasWeapon then
            combatModeResolved = "melee"
            weaponStatus = "mixed_melee_only"
        else
            combatModeResolved = "melee"
            weaponStatus = "mixed_unarmed_fallback_melee"
        end
    elseif configuredMode == "melee" then
        combatModeResolved = "melee"
        if descriptor.hasWeapon then
            weaponStatus = "melee_ready"
        else
            weaponStatus = "melee_unarmed"
        end
    end

    result = {
        configuredMode = configuredMode,
        combatModeResolved = combatModeResolved,
        weaponStatus = weaponStatus,
        primaryType = descriptor.primaryType,
        hasWeapon = descriptor.hasWeapon,
        hasUsableFirearm = descriptor.hasUsableFirearm,
        fullType = descriptor.fullType,
    }
    if runtime then
        runtime.equipmentDescribeCache = {
            key = cacheKey,
            value = result,
        }
    end
    return result
end
