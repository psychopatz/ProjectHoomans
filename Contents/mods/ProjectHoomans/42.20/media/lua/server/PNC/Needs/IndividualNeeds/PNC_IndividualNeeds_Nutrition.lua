if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.NPCNutrition = PNC.NPCNutrition or {}

local Model = PNC.NPCNutrition
local Definitions = PNC.NeedsDefinitions
local tuning = Definitions.NUTRITION

-- Coefficients taken from zombie.characters.BodyDamage.Nutrition. The NPC
-- service advances these in world seconds, so catch-up and live ticking use
-- the same math without attaching an engine Nutrition object to each NPC.
Model.METABOLIC_RATES = {
    idle = 0.016,
    sleeping = 0.003,
    walking = 0.13 * 0.60,
    traveling = 0.13 * 0.60,
    working = 0.13 * 0.60,
    resting = 0.016,
    running = 0.13,
    fighting = 0.13,
}
Model.MACRO_DRAIN = {
    carbohydrates = 0.0035,
    lipids = 0.00113,
    proteins = 0.00086,
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

local function gainThreshold(weight, hasWeightGain)
    local threshold = hasWeightGain and weight < 90 and 700 or 1000
    return threshold + (weight - 80) * 40
end

local function lossThreshold(weight, hasWeightLoss)
    local threshold = hasWeightLoss and weight > 70 and -1800 or -1000
    -- Heavier bodies need a larger deficit before losing weight. Keep the
    -- threshold at or below zero, as in the player implementation.
    return math.min(0, threshold + (weight - 70) * 30)
end

local function macroWeightFactor(nutrition)
    local carbohydrates = tonumber(nutrition.carbohydrates) or 0
    local lipids = tonumber(nutrition.lipids) or 0
    local highest = math.max(carbohydrates, lipids)
    if highest > 700 then return 3 end
    if highest > 400 then return 2 end
    return 1
end

function Model.Update(nutrition, elapsedWorldSeconds, activity,
    hasWeightGain, hasWeightLoss, actionModifier, coldEnergyModifier)
    if type(nutrition) ~= "table" then return nil, nil, false end
    local seconds = math.max(0, tonumber(elapsedWorldSeconds) or 0)
    if seconds <= 0 then
        local category = Model.WeightCategory(nutrition.weight)
        return category, category, false
    end
    local oldCategory = Model.WeightCategory(nutrition.weight)
    local weight = clamp(nutrition.weight, tuning.minimumWeight,
        tuning.maximumWeight)
    local mode = tostring(activity or "idle")
    local burnRate = Model.METABOLIC_RATES[mode] or Model.METABOLIC_RATES.idle
    local modifier = math.max(0, tonumber(actionModifier) or 1)
        * math.max(0, tonumber(coldEnergyModifier) or 1)
    local calorieBurn = burnRate * seconds * (weight / 80) * modifier

    nutrition.calories = clamp((tonumber(nutrition.calories)
        or tuning.defaultCalories) - calorieBurn,
        tuning.minimumCalories, tuning.maximumCalories)
    nutrition.calorieOverflow = 0
    nutrition.carbohydrates = clamp((tonumber(nutrition.carbohydrates)
        or tuning.defaultCarbohydrates)
        - Model.MACRO_DRAIN.carbohydrates * seconds,
        tuning.minimumMacro, tuning.maximumMacro)
    nutrition.lipids = clamp((tonumber(nutrition.lipids)
        or tuning.defaultLipids) - Model.MACRO_DRAIN.lipids * seconds,
        tuning.minimumMacro, tuning.maximumMacro)
    nutrition.proteins = clamp((tonumber(nutrition.proteins)
        or tuning.defaultProteins) - Model.MACRO_DRAIN.proteins * seconds,
        tuning.minimumMacro, tuning.maximumMacro)

    local calories = tonumber(nutrition.calories) or 0
    local weightDelta = 0
    if calories > gainThreshold(weight, hasWeightGain == true) then
        local delta = math.min(1, calories / 4000)
        weightDelta = 1.3e-5 * delta * macroWeightFactor(nutrition) * seconds
    elseif calories < lossThreshold(weight, hasWeightLoss == true) then
        local delta = math.min(1, math.abs(calories) / 2500)
        weightDelta = -8.5e-6 * delta * seconds
    end
    nutrition.weight = clamp(weight + weightDelta,
        tuning.minimumWeight, tuning.maximumWeight)
    local newCategory = Model.WeightCategory(nutrition.weight)
    return oldCategory, newCategory, oldCategory ~= newCategory
end

return Model
