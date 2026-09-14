-- Server-authoritative NPC firearm cadence and accuracy resolution.

local Resolution = PNC.CombatResolution
local Core = PNC.Core
local Const = PNC.Const
local Skills = PNC.Skills
local TraitEffects = PNC.NPCTraitEffects

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, tonumber(value) or minimum))
end

local function number(value, fallback)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then
        return fallback
    end
    return value
end

local function targetDistance(record, target)
    local distanceSq = target and tonumber(target.distSq) or nil
    local dx
    local dy
    if distanceSq ~= nil then return math.sqrt(math.max(0, distanceSq)) end
    if not record or not target
        or record.x == nil or record.y == nil
        or target.x == nil or target.y == nil
    then
        return 0
    end
    dx = tonumber(target.x) - tonumber(record.x)
    dy = tonumber(target.y) - tonumber(record.y)
    return math.sqrt(math.max(0, (dx * dx) + (dy * dy)))
end

local function randomUnit(options)
    local value
    if type(options) == "table" and type(options.random) == "function" then
        value = options.random()
    elseif type(options) == "table" and options.roll ~= nil then
        value = options.roll
    elseif type(ZombRandFloat) == "function" then
        value = ZombRandFloat(0, 1)
    elseif type(ZombRand) == "function" then
        value = ZombRand(1000001) / 1000000
    elseif math and type(math.random) == "function" then
        value = math.random()
    end
    if value == nil then value = 0.5 end
    return clamp(value, 0, 1)
end

function Resolution.GetRangedCooldown(record, baseCooldown, modifiers, options)
    local base = math.max(250, number(baseCooldown, 1800))
    local rate = number(modifiers and modifiers.fireRateMultiplier, 1) or 1
    local actionDuration = number(options and options.actionDurationMs, 620)
    local minimum = math.max(250, actionDuration + 40)
    return clamp(base / clamp(rate, 0.50, 3.00), minimum, 10000)
end

function Resolution.BuildRangedShotProfile(record, target, options)
    options = type(options) == "table" and options or {}
    local modifiers = options.modifiers
        or TraitEffects and TraitEffects.ResolveFirearmModifiers(record)
        or {}
    local range = number(Const and Const.RANGED_RANGE, 8.5) or 8.5
    local distance = number(options.distance, targetDistance(record, target)) or 0
    local aiming = Skills and Skills.GetLevel
        and number(Skills.GetLevel(record, "Aiming"), 0) or 0
    local aimConfidence = clamp(number(options.aimConfidence,
        record and record.runtime and record.runtime.combatAim
            and record.runtime.combatAim.confidence or 0), 0, 1)
    local pressure = math.max(0, math.floor(
        number(options.pressureCount,
            record and record.runtime and record.runtime.combatAim
                and record.runtime.combatAim.visiblePressureCount or 0) or 0
    ))
    local baseChance = number(options.baseHitChance, 0.48) or 0.48
    local chance = baseChance
        + aimConfidence * 0.30
        + math.min(aiming, 10) * 0.025
        - math.min(0.25, distance / math.max(1, range) * 0.25)
        - math.min(pressure, 4) * 0.04
        + (number(modifiers.hitChanceBias, 0) or 0)
        + (number(modifiers.pressureAccuracyBias, 0) or 0)
            * math.min(pressure, 4)
    return {
        hitChance = clamp(chance, 0.05, 0.98),
        distance = distance,
        aimingLevel = aiming,
        aimConfidence = aimConfidence,
        pressureCount = pressure,
        traitFingerprint = tostring(modifiers.traitFingerprint or ""),
        registryRevision = number(modifiers.registryRevision, 0),
    }
end

function Resolution.ResolveRangedShot(record, target, options)
    options = type(options) == "table" and options or {}
    if Core and Core.IsAuthority and not Core.IsAuthority() then
        return false, "not_authority"
    end
    local profile = options.profile
        or Resolution.BuildRangedShotProfile(record, target, options)
    local roll = randomUnit(options)
    profile.roll = roll
    if roll <= profile.hitChance then
        return true, "ranged_hit", profile
    end
    return false, "ranged_miss", profile
end

return Resolution
