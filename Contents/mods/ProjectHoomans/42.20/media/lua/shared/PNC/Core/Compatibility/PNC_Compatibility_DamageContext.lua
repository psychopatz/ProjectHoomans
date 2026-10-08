-- Canonical cross-mod damage context.
--
-- Provider adapters may use different hit APIs, but Hoomans needs one bounded
-- shape before a hit enters the authoritative wound pipeline. Runtime item
-- references stay local to the current process; only stable metadata is safe
-- to carry across a network command.

PNC = PNC or {}
PNC.Compatibility = PNC.Compatibility or {}
PNC.Compatibility.DamageContext =
    PNC.Compatibility.DamageContext or {}

local DamageContext = PNC.Compatibility.DamageContext
DamageContext.VERSION = 1

local function safeMethod(object, methodName)
    local method
    local ok
    local value
    if not object then return nil end
    method = object[methodName]
    if type(method) ~= "function" then return nil end
    ok, value = pcall(method, object)
    return ok and value or nil
end

function DamageContext.WeaponFullType(weaponItem)
    local value = safeMethod(weaponItem, "getFullType")
    value = value and tostring(value) or nil
    return value ~= "" and value or nil
end

function DamageContext.IsRanged(
    weaponItem,
    fullType,
    attackType,
    attackKind,
    damageClass
)
    local normalizedType = string.lower(tostring(attackType or ""))
    local normalizedKind = string.lower(tostring(attackKind or ""))
    local normalizedClass = string.lower(tostring(damageClass or ""))
    local weaponType
    local normalized

    if normalizedType == "ranged" then return true end
    if normalizedKind == "ranged"
        or string.find(normalizedKind, "ranged", 1, true)
        or string.find(normalizedKind, "firearm", 1, true)
        or string.find(normalizedKind, "bullet", 1, true)
    then
        return true
    end
    if normalizedClass == "firearm"
        or normalizedClass == "ballistic"
        or normalizedClass == "ranged"
    then
        return true
    end

    if safeMethod(weaponItem, "isRanged") == true
        or safeMethod(weaponItem, "isRangedWeapon") == true
        or safeMethod(weaponItem, "isAimedFirearm") == true
    then
        return true
    end

    weaponType = safeMethod(weaponItem, "getWeaponType")
    normalized = string.lower(tostring(weaponType or ""))
    if normalized ~= ""
        and (string.find(normalized, "firearm", 1, true)
            or string.find(normalized, "handgun", 1, true)
            or string.find(normalized, "pistol", 1, true)
            or string.find(normalized, "rifle", 1, true)
            or string.find(normalized, "shotgun", 1, true)
            or string.find(normalized, "revolver", 1, true))
    then
        return true
    end

    normalized = string.lower(tostring(
        fullType or DamageContext.WeaponFullType(weaponItem) or ""
    ))
    return normalized ~= ""
        and (string.find(normalized, "firearm", 1, true)
            or string.find(normalized, "handgun", 1, true)
            or string.find(normalized, "pistol", 1, true)
            or string.find(normalized, "rifle", 1, true)
            or string.find(normalized, "shotgun", 1, true)
            or string.find(normalized, "revolver", 1, true)
            or string.find(normalized, "smg", 1, true))
        or false
end

function DamageContext.Normalize(context)
    local input = type(context) == "table" and context or {}
    local normalized = {}
    local key
    local ranged

    for key, value in pairs(input) do
        normalized[key] = value
    end

    normalized.contractVersion = tonumber(normalized.contractVersion)
        or DamageContext.VERSION
    normalized.amount = tonumber(normalized.amount or normalized.damage) or 0
    if not normalized.weaponFullType then
        normalized.weaponFullType = DamageContext.WeaponFullType(
            normalized.weaponItem
        )
    end

    ranged = DamageContext.IsRanged(
        normalized.weaponItem,
        normalized.weaponFullType,
        normalized.attackType,
        normalized.attackKind,
        normalized.damageClass
    )
    if not normalized.attackType then
        if ranged then
            normalized.attackType = "ranged"
        elseif normalized.weaponItem or normalized.attackKind then
            normalized.attackType = "melee"
        end
    end
    if not normalized.damageClass then
        normalized.damageClass = ranged and "firearm" or "melee"
    end
    if normalized.woundType == "burn"
        or normalized.woundType == "fire"
        or normalized.woundType == "explosion"
    then
        -- Hoomans currently has no separate burn wound stat. Preserve the
        -- old safe fallback explicitly instead of letting providers create an
        -- unsupported wound type in the health record.
        normalized.woundType = "scratch"
    end
    return normalized
end

return DamageContext
