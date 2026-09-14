if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Needs = PNC.IndividualNeeds
local Definitions = PNC.NeedsDefinitions
local Utils = PNC.NeedsUtils
local PlayerModel = PNC.PlayerNeedsModel
local EventBus = require "PsychopatzCore/Events/PC_EventBus"
local EventTypes = PNC.EventTypes
local H = Needs.Internal
local NutritionModel = PNC.NPCNutrition

function Needs.Update(record, elapsedHours, reason)
    local state = Needs.Ensure(record)
    if not state then return false end
    elapsedHours = math.max(0, math.min(Definitions.MAX_CATCHUP_HOURS,
        tonumber(elapsedHours) or 0))
    local rates = Needs.GetRates(record)
    local beforeState = Utils.CopyState(state)
    Needs.IncreaseHunger(record, rates.hunger * elapsedHours,
        reason or "passive_increase")
    for _, needType in ipairs({ "thirst", "fatigue" }) do
        Needs.Modify(record, needType, rates[needType] * elapsedHours,
            reason or "passive_increase")
    end
    if PNC.NeedHealthConsequences and PNC.NeedHealthConsequences.Apply then
        PNC.NeedHealthConsequences.Apply(record, beforeState, state, rates,
            elapsedHours)
    end
    local nutrition = Needs.IsNutritionRealismEnabled()
        and Needs.EnsureNutrition(record) or nil
    if nutrition and NutritionModel then
        local oldWeightCategory, newWeightCategory, changed =
            NutritionModel.Update(nutrition, elapsedHours * 3600,
                Needs.GetActivity(record),
                PlayerModel.HasTrait(record, "weightgain"),
                PlayerModel.HasTrait(record, "weightloss"), 1, 1)
        if changed then
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
