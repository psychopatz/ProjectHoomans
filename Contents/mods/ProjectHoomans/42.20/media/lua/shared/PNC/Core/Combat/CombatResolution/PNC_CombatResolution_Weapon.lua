local Resolution = PNC.CombatResolution

local function clamp(value, low, high)
    value = tonumber(value) or low
    return math.max(low, math.min(high, value))
end

local function roll(minimum, maximum)
    if ZombRandFloat then
        return ZombRandFloat(minimum, maximum)
    end
    return (minimum + maximum) * 0.5
end

function Resolution.RollWeaponDamage(weaponItem, fallback)
    local minimum
    local maximum
    if not weaponItem then
        return math.max(0, tonumber(fallback) or 0)
    end
    minimum = weaponItem.getMinDamage and tonumber(weaponItem:getMinDamage()) or nil
    maximum = weaponItem.getMaxDamage and tonumber(weaponItem:getMaxDamage()) or nil
    minimum = minimum and minimum > 0 and minimum or maximum or tonumber(fallback) or 0.5
    maximum = maximum and maximum >= minimum and maximum or minimum
    return roll(minimum, maximum)
end

function Resolution.GetAttackDamage(record, attackType, weaponItem, fallback, skillLevel)
    local vars
    local base
    local normalized
    local attackMultiplier
    local dealtMultiplier
    if not Resolution.IsWeaponDamageEnabled() or not weaponItem then
        return math.max(0, tonumber(fallback) or 0)
    end
    base = Resolution.RollWeaponDamage(weaponItem, fallback)
    normalized = clamp(skillLevel, 0, 10) / 10
    if attackType == "ranged" then
        attackMultiplier = 15 + (10 * normalized)
    else
        attackMultiplier = 8 + (6 * normalized)
    end
    vars = SandboxVars and SandboxVars.ProjectHoomans or nil
    dealtMultiplier = math.max(0, tonumber(vars and vars.NPCDamageDealtMultiplier) or 1)
    return base * attackMultiplier * dealtMultiplier
end

return Resolution
