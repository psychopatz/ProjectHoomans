-- Pure NPC trait effect composition. Definitions are data; this module owns
-- the combination rules used by needs, sleep, behavior, and personality.

PNC = PNC or {}
PNC.NPCTraitEffects = PNC.NPCTraitEffects or {}

local Effects = PNC.NPCTraitEffects
local Traits = PNC.NPCTraits

local function finite(value, fallback)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then
        return fallback
    end
    return value
end

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function copy(value)
    local output = {}
    local key
    local item
    for key, item in pairs(value or {}) do
        output[key] = type(item) == "table" and copy(item) or item
    end
    return output
end

local function selectedTraits(source)
    if type(source) ~= "table" then return {} end
    if source.npcTraits ~= nil or source.dynamicTraits ~= nil then
        return Traits.Collect(source)
    end
    return Traits.ResolveSet(source)
end

local function eachDefinition(source, callback)
    local selected = selectedTraits(source)
    local definitions = Traits.GetDefinitions()
    local index
    local definition
    if type(callback) ~= "function" then return selected end
    for index = 1, #definitions do
        definition = definitions[index]
        if selected[definition.id] then callback(definition) end
    end
    return selected
end

local function multiply(current, value)
    return current * (finite(value, 1) or 1)
end

local function clampMultiplier(value)
    return clamp(value, 0.10, 3.00)
end

local function traitCacheKey(source)
    local revision = tonumber(Traits and Traits.Revision) or 0
    local npcFingerprint
    local dynamicFingerprint
    if type(source) ~= "table"
        or (source.npcTraits == nil and source.dynamicTraits == nil)
    then
        return nil
    end
    npcFingerprint = source.npcTraitFingerprint
    if npcFingerprint == nil and Traits and Traits.Fingerprint then
        npcFingerprint = Traits.Fingerprint(source.npcTraits or {})
    end
    dynamicFingerprint = source.dynamicTraitFingerprint
    if dynamicFingerprint == nil and Traits and Traits.Fingerprint then
        dynamicFingerprint = Traits.Fingerprint(source.dynamicTraits or {})
    end
    return table.concat({
        tostring(revision),
        tostring(npcFingerprint or ""),
        tostring(dynamicFingerprint or ""),
    }, ":")
end

local function multiplyFirearm(output, field, value)
    value = finite(value, nil)
    if value ~= nil then
        output[field] = output[field] * value
    end
end

local function addFirearmBias(output, field, value)
    value = finite(value, nil)
    if value ~= nil then
        output[field] = output[field] + value
    end
end

local function multiplyMelee(output, field, value)
    value = finite(value, nil)
    if value ~= nil then
        output[field] = output[field] * value
    end
end

local function addMeleeBias(output, field, value)
    value = finite(value, nil)
    if value ~= nil then
        output[field] = output[field] + value
    end
end

function Effects.ResolveFirearmModifiers(source)
    local cacheKey = traitCacheKey(source)
    local runtime = type(source) == "table" and source.runtime or nil
    local cached = runtime and runtime.npcFirearmModifiers or nil
    local output
    local selected
    local definitions
    local personality = { aggression = 0.5, bravery = 0.5 }
    local index
    local definition
    local effects
    local firearm
    local field
    local value
    if cached and cacheKey and cached.key == cacheKey then
        return cached.value
    end

    output = {
        fireRateMultiplier = 1.0,
        aimTimeMultiplier = 1.0,
        hitChanceBias = 0.0,
        pressureAccuracyBias = 0.0,
        confidenceThresholdBias = 0.0,
        traitFingerprint = cacheKey or "",
        registryRevision = tonumber(Traits and Traits.Revision) or 0,
    }
    selected = selectedTraits(source)
    definitions = Traits.GetDefinitions()
    for index = 1, #definitions do
        definition = definitions[index]
        if selected[definition.id] then
            effects = definition.effects or {}
            firearm = effects.combat and effects.combat.firearm or nil
            if type(firearm) == "table" then
                multiplyFirearm(output, "fireRateMultiplier",
                    firearm.fireRateMultiplier)
                multiplyFirearm(output, "aimTimeMultiplier",
                    firearm.aimTimeMultiplier)
                addFirearmBias(output, "hitChanceBias",
                    firearm.hitChanceBias)
                addFirearmBias(output, "pressureAccuracyBias",
                    firearm.pressureAccuracyBias)
                addFirearmBias(output, "confidenceThresholdBias",
                    firearm.confidenceThresholdBias)
            end
            for field, value in pairs(effects.personality or {}) do
                if personality[field] ~= nil then
                    personality[field] = clamp(
                        personality[field] + (finite(value, 0) or 0), 0, 1)
                end
            end
        end
    end

    -- Personality contributes a small, centralized combat projection. Direct
    -- firearm effects remain available for traits such as trigger happy, but
    -- callers do not need to interpret personality fields themselves.
    output.pressureAccuracyBias = output.pressureAccuracyBias
        + (personality.bravery - 0.5) * 0.10
    output.confidenceThresholdBias = output.confidenceThresholdBias
        - (personality.aggression - 0.5) * 0.06
        - (personality.bravery - 0.5) * 0.04
    output.fireRateMultiplier = clampMultiplier(output.fireRateMultiplier)
    output.aimTimeMultiplier = clampMultiplier(output.aimTimeMultiplier)
    output.hitChanceBias = clamp(output.hitChanceBias, -0.75, 0.75)
    output.pressureAccuracyBias = clamp(output.pressureAccuracyBias, -0.50, 0.50)
    output.confidenceThresholdBias = clamp(
        output.confidenceThresholdBias, -0.15, 0.15)

    if cacheKey and type(source) == "table" then
        source.runtime = source.runtime or {}
        source.runtime.npcFirearmModifiers = {
            key = cacheKey,
            value = output,
        }
    end
    return output
end

function Effects.ResolveMeleeModifiers(source)
    local cacheKey = traitCacheKey(source)
    local runtime = type(source) == "table" and source.runtime or nil
    local cached = runtime and runtime.npcMeleeModifiers or nil
    local output
    local selected
    local definitions
    local personality = { aggression = 0.5, bravery = 0.5 }
    local index
    local definition
    local effects
    local melee
    local field
    local value
    if cached and cacheKey and cached.key == cacheKey then
        return cached.value
    end

    output = {
        attackRateMultiplier = 1.0,
        windupTimeMultiplier = 1.0,
        hitChanceBias = 0.0,
        pressureAccuracyBias = 0.0,
        traitFingerprint = cacheKey or "",
        registryRevision = tonumber(Traits and Traits.Revision) or 0,
    }
    selected = selectedTraits(source)
    definitions = Traits.GetDefinitions()
    for index = 1, #definitions do
        definition = definitions[index]
        if selected[definition.id] then
            effects = definition.effects or {}
            melee = effects.combat and effects.combat.melee or nil
            if type(melee) == "table" then
                multiplyMelee(output, "attackRateMultiplier",
                    melee.attackRateMultiplier)
                multiplyMelee(output, "windupTimeMultiplier",
                    melee.windupTimeMultiplier)
                addMeleeBias(output, "hitChanceBias",
                    melee.hitChanceBias)
                addMeleeBias(output, "pressureAccuracyBias",
                    melee.pressureAccuracyBias)
            end
            for field, value in pairs(effects.personality or {}) do
                if personality[field] ~= nil then
                    personality[field] = clamp(
                        personality[field] + (finite(value, 0) or 0), 0, 1)
                end
            end
        end
    end

    -- Personality is projected centrally so direct trait effects and the
    -- resulting personality compound without callers interpreting traits.
    output.hitChanceBias = output.hitChanceBias
        + (personality.aggression - 0.5) * 0.04
    output.pressureAccuracyBias = output.pressureAccuracyBias
        + (personality.bravery - 0.5) * 0.12
    output.attackRateMultiplier = clampMultiplier(output.attackRateMultiplier)
    output.windupTimeMultiplier = clampMultiplier(output.windupTimeMultiplier)
    output.hitChanceBias = clamp(output.hitChanceBias, -0.75, 0.75)
    output.pressureAccuracyBias = clamp(output.pressureAccuracyBias, -0.50, 0.50)

    if cacheKey and type(source) == "table" then
        source.runtime = source.runtime or {}
        source.runtime.npcMeleeModifiers = {
            key = cacheKey,
            value = output,
        }
    end
    return output
end

function Effects.GetTraitSet(source)
    return selectedTraits(source)
end

function Effects.GetFingerprint(source)
    return Traits.Fingerprint(selectedTraits(source))
end

function Effects.GetNeedRateMultiplier(record, needType, state, activity)
    local value = 1
    local sleeping = tostring(activity or "") == "sleeping"
    local need = tostring(needType or "")
    local fatigue = finite(state and state.fatigue, 0) or 0
    eachDefinition(record, function(definition)
        local needs = definition.effects and definition.effects.needs or {}
        local effect = needs[need]
        local multiplier
        local threshold
        if effect then
            threshold = finite(effect.threshold, nil)
            if threshold == nil or fatigue >= threshold then
                multiplier = sleeping and effect.sleepingMultiplier
                    or not sleeping and effect.awakeMultiplier or nil
                if multiplier ~= nil then value = multiply(value, multiplier) end
            end
        end
    end)
    return clampMultiplier(value)
end

function Effects.GetConditionRateMultiplier(record, condition, rate)
    local value = 1
    local key = tostring(condition or "")
    local positive = (finite(rate, 0) or 0) > 0
    eachDefinition(record, function(definition)
        local conditions = definition.effects and definition.effects.conditions
            or {}
        local effect = conditions[key]
        if effect then
            value = multiply(value, positive
                and effect.positiveMultiplier or effect.negativeMultiplier)
        end
    end)
    return clampMultiplier(value)
end

function Effects.ResolveSleepPolicy(record, base)
    local source = base
    local policy = {
        actionable = finite(source and source.actionable, 0.70),
        critical = finite(source and source.critical, 0.80),
        completion = finite(source and source.completion, 0.12),
        recoveryPerGameHour = finite(
            source and source.recoveryPerGameHour, 0.45),
    }
    local actionMultiplier = 1
    local criticalMultiplier = 1
    local completionMultiplier = 1
    local recoveryMultiplier = 1
    eachDefinition(record, function(definition)
        local needs = definition.effects and definition.effects.needs or {}
        local effect = needs.sleepPolicy
        if effect then
            actionMultiplier = multiply(actionMultiplier,
                effect.actionThresholdMultiplier)
            criticalMultiplier = multiply(criticalMultiplier,
                effect.criticalThresholdMultiplier)
            completionMultiplier = multiply(completionMultiplier,
                effect.wakeThresholdMultiplier)
            recoveryMultiplier = multiply(recoveryMultiplier,
                effect.recoveryMultiplier)
        end
    end)
    policy.actionable = clamp(policy.actionable * actionMultiplier, 0, 1)
    policy.critical = clamp(policy.critical * criticalMultiplier, 0, 1)
    policy.completion = clamp(policy.completion * completionMultiplier, 0, 1)
    policy.recoveryPerGameHour = math.max(0,
        policy.recoveryPerGameHour * recoveryMultiplier)
    return policy
end

function Effects.GetBehaviorModifier(record, behaviorID)
    local total = 0
    local key = tostring(behaviorID or "")
    eachDefinition(record, function(definition)
        local behavior = definition.effects and definition.effects.behavior
            or {}
        total = total + (finite(behavior[key], 0) or 0)
    end)
    return total
end

function Effects.ApplyPersonality(profile, source)
    local output = copy(profile)
    local categoryBiases = {}
    local field
    local value
    local category
    local biases
    local candidate
    local best
    local bestValue
    if type(output) ~= "table" then output = {} end
    eachDefinition(source, function(item)
        local effects = item.effects or {}
        local personality = effects.personality or {}
        for field, value in pairs(personality) do
            output[field] = clamp(
                (finite(output[field], 0.5) or 0.5)
                    + (finite(value, 0) or 0), 0, 1)
        end
        for category, biases in pairs(effects.categoryBiases or {}) do
            categoryBiases[category] = categoryBiases[category] or {}
            for candidate, value in pairs(biases) do
                categoryBiases[category][candidate] =
                    (categoryBiases[category][candidate] or 0)
                    + (finite(value, 0) or 0)
            end
        end
    end)
    for category, biases in pairs(categoryBiases) do
        best = output[category]
        bestValue = 0
        for candidate, value in pairs(biases) do
            if value > bestValue then
                best = candidate
                bestValue = value
            end
        end
        if bestValue >= 1 and best ~= nil then output[category] = best end
    end
    return output
end

return Effects
