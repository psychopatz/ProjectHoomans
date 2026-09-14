-- Server-authoritative NPC melee timing and strike outcome resolution.

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
    if distanceSq ~= nil then
        return math.sqrt(math.max(0, distanceSq))
    end
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

local function pressureCount(record, options)
    local runtime = record and record.runtime or {}
    local tactical = runtime.combatTactical or {}
    local assessment = runtime.combatThreatAssessment or {}
    return math.max(0, math.floor(number(
        options and options.pressureCount,
        assessment.pressureCount or tactical.pressure or 0
    ) or 0))
end

function Resolution.GetMeleeCooldown(record, baseCooldown, modifiers, options)
    local base = math.max(250, number(baseCooldown, 900))
    local rate = number(modifiers and modifiers.attackRateMultiplier, 1) or 1
    local actionDuration = number(options and options.actionDurationMs, 760)
    local minimum = math.max(250, actionDuration)
    return clamp(base / clamp(rate, 0.50, 3.00), minimum, 10000)
end

function Resolution.GetMeleeTiming(baseHitDelay, baseDuration, modifiers)
    local hitDelay = math.max(100, number(baseHitDelay, 320))
        * clamp(number(modifiers and modifiers.windupTimeMultiplier, 1),
            0.50, 3.00)
    local duration = math.max(100, number(baseDuration, 760))
    duration = math.max(duration, hitDelay + 80)
    return hitDelay, duration
end

function Resolution.BuildMeleeStrikeProfile(record, target, options)
    options = type(options) == "table" and options or {}
    local modifiers = options.modifiers
        or TraitEffects and TraitEffects.ResolveMeleeModifiers(record)
        or {}
    local distance = number(options.distance, targetDistance(record, target)) or 0
    local range = number(Const and Const.MELEE_RANGE, 1.3) or 1.3
    local skill = number(options.skillLevel,
        Skills and Skills.GetLevel and Skills.GetLevel(
            record, options.skillID or "Strength") or 0) or 0
    local strength = number(options.strengthLevel,
        Skills and Skills.GetLevel and Skills.GetLevel(record, "Strength") or 0)
        or 0
    local pressure = pressureCount(record, options)
    local baseChance = number(options.baseHitChance, 0.68) or 0.68
    local chance = baseChance
        + math.min(skill, 10) * 0.025
        + math.min(strength, 10) * 0.010
        - math.min(0.14, distance / math.max(1, range) * 0.14)
        - math.min(pressure, 4) * 0.035
        + (number(modifiers.hitChanceBias, 0) or 0)
        + (number(modifiers.pressureAccuracyBias, 0) or 0)
            * math.min(pressure, 4)
    return {
        hitChance = clamp(chance, 0.10, 0.98),
        distance = distance,
        skillLevel = skill,
        strengthLevel = strength,
        pressureCount = pressure,
        traitFingerprint = tostring(modifiers.traitFingerprint or ""),
        registryRevision = number(modifiers.registryRevision, 0),
    }
end

function Resolution.ResolveMeleeStrike(record, target, options)
    options = type(options) == "table" and options or {}
    if Core and Core.IsAuthority and not Core.IsAuthority() then
        return false, "not_authority"
    end
    local profile = options.profile
        or Resolution.BuildMeleeStrikeProfile(record, target, options)
    local roll = randomUnit(options)
    profile.roll = roll
    if roll <= profile.hitChance then
        return true, "melee_hit", profile
    end
    return false, "melee_miss", profile
end

return Resolution
