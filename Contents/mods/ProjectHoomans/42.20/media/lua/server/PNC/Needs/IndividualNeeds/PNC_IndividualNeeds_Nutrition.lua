if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.NPCNutrition = PNC.NPCNutrition or {}

local Model = PNC.NPCNutrition
local Definitions = PNC.NeedsDefinitions
local Stat = PNC.DeterministicStat or require "PNC/Core/Needs/PNC_DeterministicStat"
local tuning = Definitions.NUTRITION

-- Activity burn multipliers (hours of fuel burned per elapsed world hour).
Model.ACTIVITY_BURN_MULTIPLIERS = {
    idle = 0.70,
    sleeping = 0.25,
    resting = 0.55,
    walking = 1.15,
    traveling = 1.15,
    working = 1.25,
    running = 1.80,
    fighting = 2.00,
}

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, tonumber(value) or minimum))
end

function Model.WeightCategory(weight)
    weight = tonumber(weight) or tuning.defaultWeight
    if weight <= 50 then return "EMACIATED" end
    if weight <= 65 then return "VERY_UNDERWEIGHT" end
    if weight <= 75 then return "UNDERWEIGHT" end
    if weight >= 100 then return "OBESE" end
    if weight >= 85 then return "OVERWEIGHT" end
    return "NORMAL"
end

function Model.Update(nutrition, elapsedWorldSeconds, activity,
    hasWeightGain, hasWeightLoss, actionModifier, coldEnergyModifier)
    if type(nutrition) ~= "table" then return nil, nil, false end
    local seconds = math.max(0, tonumber(elapsedWorldSeconds) or 0)
    if seconds <= 0 then
        local category = Model.WeightCategory(nutrition.weight)
        return category, category, false
    end
    local elapsedHours = seconds / 3600
    local oldCategory = Model.WeightCategory(nutrition.weight)
    local weight = clamp(nutrition.weight, tuning.minimumWeight,
        tuning.maximumWeight)
    local mode = tostring(activity or "idle")
    local burnMult = Model.ACTIVITY_BURN_MULTIPLIERS[mode] or 1.0
    local modifier = math.max(0, tonumber(actionModifier) or 1)
        * math.max(0, tonumber(coldEnergyModifier) or 1)

    local currentCalories = tonumber(nutrition.calories) or tuning.defaultCalories
    local fuelHours = tonumber(nutrition.fuelHours)
        or (currentCalories / Stat.KCAL_PER_HOUR)
    local burnedHours = elapsedHours * burnMult * (weight / 80) * modifier
    fuelHours = clamp(fuelHours - burnedHours,
        Stat.MIN_FUEL_DEFICIT_HOURS, Stat.MAX_FUEL_BANK_HOURS)

    nutrition.fuelHours = fuelHours
    nutrition.calories = clamp(Stat.FuelHoursToCalories(fuelHours),
        tuning.minimumCalories, tuning.maximumCalories)
    nutrition.calorieOverflow = 0
    nutrition.carbohydrates = 0
    nutrition.lipids = 0
    nutrition.proteins = 0

    nutrition.weight = Stat.EvaluateWeightFromFuelHours(
        weight, fuelHours, elapsedHours,
        hasWeightGain == true, hasWeightLoss == true,
        tuning.minimumWeight, tuning.maximumWeight
    )
    local newCategory = Model.WeightCategory(nutrition.weight)
    return oldCategory, newCategory, oldCategory ~= newCategory
end

return Model
