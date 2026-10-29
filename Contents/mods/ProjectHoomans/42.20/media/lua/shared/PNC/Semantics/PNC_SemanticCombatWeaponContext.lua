-- Bounded projection of the authoritative weapon/hit facts already available
-- at combat resolution. This module never scans inventory or creates items.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Weapon = PNC.Semantics.CombatWeaponContext or {}
PNC.Semantics.CombatWeaponContext = Weapon

Weapon.VERSION = 1
Weapon.SCHEMA = "semantic.combat.weapon_context.v1"

local function safeMethod(object, methodName)
    if not object or type(object[methodName]) ~= "function" then return nil end
    local ok, value = pcall(object[methodName], object)
    return ok and value or nil
end

local function clean(value, limit)
    if value == nil then return nil end
    value = tostring(value)
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    if value == "" then return nil end
    if #value > (tonumber(limit) or 96) then
        value = string.sub(value, 1, tonumber(limit) or 96)
    end
    return value
end

local function skillFamily(skillID, fullType, attackType)
    skillID = tostring(skillID or "")
    if skillID == "Aiming" or tostring(attackType or "") == "ranged" then
        return "firearm"
    end
    if skillID == "Axe" then return "axe" end
    if skillID == "LongBlade" then return "long_blade" end
    if skillID == "ShortBlade" then return "short_blade" end
    if skillID == "Spear" then return "spear" end
    if skillID == "LongBlunt" then return "long_blunt" end
    if skillID == "ShortBlunt" then return "short_blunt" end
    if skillID == "Strength" then
        return clean(fullType) and "other_melee" or "unarmed"
    end
    return tostring(attackType or "") == "ranged"
        and "firearm" or clean(fullType) and "other_melee" or "unarmed"
end

local function skillBand(level)
    level = math.max(0, math.min(10, math.floor(tonumber(level) or 0)))
    if level <= 2 then return "low" end
    if level <= 5 then return "trained" end
    if level <= 8 then return "high" end
    return "expert"
end

local function hitZone(partID)
    local part = string.lower(tostring(partID or ""))
    if part == "head" or part == "neck" then return "head_neck" end
    if string.find(part, "torso", 1, true)
        or part == "groin"
    then return "torso" end
    if part ~= "" then return "limb" end
    return "unknown"
end

local function sanitizedDisplayName(item, fullType)
    local value = safeMethod(item, "getDisplayName")
        or safeMethod(item, "getName")
    value = clean(value, 64)
    if not value then return nil end
    local raw = clean(fullType, 128)
    if raw and value == raw then return nil end
    -- Internal item IDs are module-qualified. Human display names may contain
    -- punctuation/spaces, but never expose a raw module.type token as flavor.
    if string.match(value, "^[%w_]+%.[%w_]+$") then return nil end
    if string.find(value, string.char(10), 1, true)
        or string.find(value, string.char(13), 1, true)
    then return nil end
    return value
end

function Weapon.Build(record, spec)
    spec = type(spec) == "table" and spec or {}
    local item = spec.weaponItem
    local fullType = clean(
        spec.weaponFullType
            or safeMethod(item, "getFullType"),
        128
    )
    local attackType = clean(spec.attackType, 32)
    local skills = PNC.Skills
    local skillID = skills and type(skills.ResolveWeaponSkill) == "function"
        and skills.ResolveWeaponSkill(record, fullType, attackType)
        or attackType == "ranged" and "Aiming"
        or fullType and "Strength" or "Strength"
    local level = skills and type(skills.GetLevel) == "function"
        and skills.GetLevel(record, skillID) or 0
    local family = skillFamily(skillID, fullType, attackType)
    local displayName = sanitizedDisplayName(item, fullType)
    return {
        schemaVersion = Weapon.VERSION,
        schema = Weapon.SCHEMA,
        attackType = attackType or (family == "firearm" and "ranged" or "melee"),
        attackKind = clean(spec.attackKind, 48),
        weaponFullType = fullType,
        weaponDisplayName = displayName,
        weaponNameEligible = displayName ~= nil,
        weaponFamily = family,
        weaponSkill = skillID,
        weaponSkillLevel = math.max(
            0, math.min(10, math.floor(tonumber(level) or 0))
        ),
        weaponSkillBand = skillBand(level),
        partID = clean(spec.partID or spec.partId, 48),
        hitZone = hitZone(spec.partID or spec.partId),
        woundType = clean(spec.woundType, 48),
        source = clean(spec.source, 64),
    }
end

function Weapon.Snapshot(value)
    if type(value) ~= "table" then return nil end
    local copy = {}
    for key, item in pairs(value) do
        if type(item) ~= "table" then copy[key] = item end
    end
    return copy
end

return Weapon
