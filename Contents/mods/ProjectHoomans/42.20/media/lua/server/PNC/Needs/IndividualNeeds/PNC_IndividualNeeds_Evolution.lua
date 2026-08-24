if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Needs = PNC.IndividualNeeds
local Definitions = PNC.NeedsDefinitions
local Utils = PNC.NeedsUtils
local PlayerModel = PNC.PlayerNeedsModel
local EventBus = require "PsychopatzCore/Events/PC_EventBus"
local EventTypes = PNC.EventTypes
local H = Needs.Internal

function Needs.Update(record, elapsedHours, reason)
    local state = Needs.Ensure(record)
    if not state then return false end
    elapsedHours = math.max(0, math.min(Definitions.MAX_CATCHUP_HOURS,
        tonumber(elapsedHours) or 0))
    local rates = Needs.GetRates(record)
    local beforeState = Utils.CopyState(state)
    for _, needType in ipairs(Definitions.TYPES) do
        Needs.Modify(record, needType, rates[needType] * elapsedHours,
            reason or "passive_increase")
    end
    if PNC.NeedHealthConsequences and PNC.NeedHealthConsequences.Apply then
        PNC.NeedHealthConsequences.Apply(record, beforeState, state, rates,
            elapsedHours)
    end
    local nutrition = Needs.GetNutrition(record)
    if nutrition then
        local tuning = Definitions.NUTRITION
        local oldWeightCategory = H.WeightCategory(nutrition.weight)
        local balanceBefore = nutrition.calories
        local burn = math.max(0, tonumber(rates.calorieBurnRate) or 0)
            * elapsedHours
        nutrition.calories = math.max(tuning.minimumCalories,
            math.min(tuning.maximumCalories, balanceBefore - burn))
        local averageBalance = (balanceBefore + nutrition.calories) / 2
        nutrition.weight = math.max(tuning.minimumWeight,
            math.min(tuning.maximumWeight, nutrition.weight
                + (averageBalance / tuning.caloriesPerKilogram)
                    * (elapsedHours / 24)))
        local newWeightCategory = H.WeightCategory(nutrition.weight)
        if oldWeightCategory ~= newWeightCategory then
            EventBus.emit(EventTypes.NPC_WEIGHT_CATEGORY_CHANGED, record,
                oldWeightCategory, newWeightCategory, nutrition.weight)
        end
    end
    if PNC.NeedsRepository then PNC.NeedsRepository.MarkDirty() end
    if PNC.NeedsEvaluator and PNC.NeedsEvaluator.Commands then
        PNC.NeedsEvaluator.Commands.Reconcile(record, Utils.WorldAgeHours())
    end
    return true
end

function Needs.AdvanceTo(record, now, reason)
    if not Needs.Ensure(record) then return false end
    now = math.max(0, tonumber(now) or Utils.WorldAgeHours())
    local previous = PNC.NeedsRepository.GetEvaluatedAt(record)
    local updated = Needs.Update(record, math.max(0, now - previous), reason)
    PNC.NeedsRepository.SetEvaluatedAt(record, now)
    return updated
end

function Needs.UpdateToNow(record, reason)
    return Needs.AdvanceTo(record, Utils.WorldAgeHours(), reason)
end

return Needs

