local Model = PNC.PlayerNeedsModel

function Model.AppetiteMultiplier(record)
    local value = 1
    if Model.HasTrait(record, Model.TRAITS.HEARTY_APPETITE) then
        value = value * 1.5
    end
    if Model.HasTrait(record, Model.TRAITS.LIGHT_EATER) then
        value = value * 0.75
    end
    return value
end

function Model.GetRateModifiers(record)
    local calorieBurnRate = 1
    if Model.HasTrait(record, Model.TRAITS.OBESE) then
        calorieBurnRate = 1.10
    elseif Model.HasTrait(record, Model.TRAITS.OVERWEIGHT) then
        calorieBurnRate = 1.05
    elseif Model.HasTrait(record, Model.TRAITS.EMACIATED) then
        calorieBurnRate = 0.85
    elseif Model.HasTrait(record, Model.TRAITS.VERY_UNDERWEIGHT) then
        calorieBurnRate = 0.90
    elseif Model.HasTrait(record, Model.TRAITS.UNDERWEIGHT) then
        calorieBurnRate = 0.95
    end
    return {
        hungerRate = Model.AppetiteMultiplier(record),
        thirstRate = Model.ThirstMultiplier(record),
        fatigueRate = Model.FatigueGainMultiplier(record),
        calorieBurnRate = calorieBurnRate,
    }
end

function Model.GetInitialWeight(record)
    local traits = Model.GetTraits(record)
    if traits[Model.TRAITS.OBESE] then return 110 end
    if traits[Model.TRAITS.OVERWEIGHT] then return 95 end
    if traits[Model.TRAITS.EMACIATED] then return 50 end
    if traits[Model.TRAITS.VERY_UNDERWEIGHT] then return 60 end
    if traits[Model.TRAITS.UNDERWEIGHT] then return 70 end
    return PNC.NeedsDefinitions.NUTRITION.defaultWeight
end

function Model.ThirstMultiplier(record)
    local value = 1
    if Model.HasTrait(record, Model.TRAITS.HIGH_THIRST) then
        value = value * 2
    end
    if Model.HasTrait(record, Model.TRAITS.LOW_THIRST) then
        value = value * 0.5
    end
    return value
end

function Model.FatigueGainMultiplier(record)
    if Model.HasTrait(record, Model.TRAITS.NEEDS_LESS_SLEEP) then return 0.7 end
    if Model.HasTrait(record, Model.TRAITS.NEEDS_MORE_SLEEP) then return 1.3 end
    return 1
end

function Model.SleepRecoveryMultiplier(record)
    local value = 1
    if Model.HasTrait(record, Model.TRAITS.INSOMNIAC) then
        value = value * 0.5
    end
    if Model.HasTrait(record, Model.TRAITS.NIGHT_OWL) then
        value = value * 1.4
    end
    if Model.HasTrait(record, Model.TRAITS.NEEDS_LESS_SLEEP) then
        value = value / 0.75
    elseif Model.HasTrait(record, Model.TRAITS.NEEDS_MORE_SLEEP) then
        value = value / 1.18
    end
    return value
end

local function fatigueActivity(activity)
    if activity == "resting" then return 1 / 1.5 end
    if activity == "walking" then return 1.05 end
    if activity == "working" or activity == "traveling" then return 1.25 end
    if activity == "running" then return 1.6 end
    if activity == "fighting" then return 1.85 end
    return 1
end

function Model.GetRates(record, state, activity)
    state = type(state) == "table" and state or {}
    activity = tostring(activity or "idle")
    local Definitions = PNC.NeedsDefinitions
    local base = Definitions.VANILLA_RATES_PER_HOUR
    local hungerBase = activity == "sleeping" and base.hungerSleeping
        or activity == "running" and base.hungerRunning
        or activity == "fighting" and base.hungerFighting or base.hunger
    local modifiers = Model.GetRateModifiers(record)
    local hunger = hungerBase * modifiers.hungerRate
    local thirst = base.thirst * modifiers.thirstRate
    if activity == "running" then thirst = thirst * 1.2 end
    local fatigue
    if activity == "sleeping" then
        local high = (tonumber(state.fatigue) or 0) > 0.3
        fatigue = -(high and 0.0875 or 0.0268)
            * Model.SleepRecoveryMultiplier(record)
    else
        fatigue = base.fatigue * modifiers.fatigueRate
            * fatigueActivity(activity)
    end
    if PNC.ConditionStats and PNC.ConditionStats.GetNeedRateMultiplier then
        hunger = hunger * PNC.ConditionStats.GetNeedRateMultiplier(
            record, "hunger", state, activity)
        thirst = thirst * PNC.ConditionStats.GetNeedRateMultiplier(
            record, "thirst", state, activity)
        fatigue = fatigue * PNC.ConditionStats.GetNeedRateMultiplier(
            record, "fatigue", state, activity)
    end
    local scale = Definitions.INDIVIDUAL_RATE_SCALE
    hunger = hunger * scale.hunger
    thirst = thirst * scale.thirst
    if fatigue > 0 then fatigue = fatigue * scale.fatigue end
    return {
        hunger = hunger,
        thirst = thirst,
        fatigue = fatigue,
        calorieBurnRate = Definitions.NUTRITION.calorieBurnPerHour
            * modifiers.calorieBurnRate,
        modifiers = modifiers,
    }
end

return Model
