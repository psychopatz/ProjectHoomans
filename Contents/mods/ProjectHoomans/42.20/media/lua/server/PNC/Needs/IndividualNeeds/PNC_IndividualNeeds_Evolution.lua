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
local PASSIVE_NEED_TYPES = { "thirst", "fatigue" }

local function setPassiveValue(record, state, needType, value, reason)
    if H and H.SetStateValue then
        return H.SetStateValue(record, state, needType, value, reason, false)
    end
    return Needs.Set(record, needType, value, reason)
end

function Needs.Update(record, elapsedHours, reason, stateOverride,
    repositoryStateOverride)
    local state = stateOverride
    local repositoryState = repositoryStateOverride
    local ignoredReason
    if not state then
        state, ignoredReason, repositoryState = Needs.Ensure(record)
    end
    if not state then return false end
    if not repositoryState and PNC.NeedsRepository
        and PNC.NeedsRepository.Get
    then
        repositoryState = PNC.NeedsRepository.Get(record, true)
    end
    elapsedHours = math.max(0, math.min(Definitions.MAX_CATCHUP_HOURS,
        tonumber(elapsedHours) or 0))
    if elapsedHours <= 0 then
        if PNC.NeedsEvaluator and PNC.NeedsEvaluator.Commands then
            PNC.NeedsEvaluator.Commands.Reconcile(record, Utils.WorldAgeHours())
        end
        return true
    end
    local rates = Needs.GetRates(record, state)
    local updateReason = reason or "passive_increase"
    local consequences = PNC.NeedHealthConsequences
    local beforeState = consequences and consequences.Apply
        and Utils.CopyState(state) or nil
    local anyChanged = false

    local hungerAmount = math.max(0, tonumber(rates.hunger) or 0)
        * elapsedHours
    local reserve = repositoryState
        and math.max(0, tonumber(repositoryState.hungerOverflow) or 0) or 0
    local consumed = math.min(reserve, hungerAmount)
    if consumed > 0 and repositoryState then
        repositoryState.hungerOverflow = reserve - consumed
        anyChanged = true
    end
    local remainingHunger = hungerAmount - consumed
    if remainingHunger > 0 then
        local prevHunger = state.hunger
        local nextHunger = setPassiveValue(record, state, "hunger",
            (tonumber(prevHunger) or 0) + remainingHunger, updateReason)
        if nextHunger ~= prevHunger then anyChanged = true end
    end

    for _, needType in ipairs(PASSIVE_NEED_TYPES) do
        local amount = (tonumber(rates[needType]) or 0) * elapsedHours
        if amount ~= 0 then
            local prevValue = state[needType]
            local nextValue = setPassiveValue(record, state, needType,
                (tonumber(prevValue) or 0) + amount, updateReason)
            if nextValue ~= prevValue then anyChanged = true end
        end
    end
    if consequences and consequences.Apply then
        consequences.Apply(record, beforeState, state, rates, elapsedHours)
    end
    if PNC.NPCWounds and type(PNC.NPCWounds.UpdatePhysiology) == "function" then
        if PNC.NPCWounds.UpdatePhysiology(record, elapsedHours, nil) then
            anyChanged = true
        end
    end
    local nutrition = Needs.IsNutritionRealismEnabled()
        and Needs.EnsureNutrition(record) or nil
    if nutrition and NutritionModel then
        local prevCalories = nutrition.calories
        local oldWeightCategory, newWeightCategory, changed =
            NutritionModel.Update(nutrition, elapsedHours * 3600,
                Needs.GetActivity(record),
                PlayerModel.HasTrait(record, "weightgain"),
                PlayerModel.HasTrait(record, "weightloss"), 1, 1)
        if changed or nutrition.calories ~= prevCalories then
            anyChanged = true
        end
        if changed then
            EventBus.emit(EventTypes.NPC_WEIGHT_CATEGORY_CHANGED, record,
                oldWeightCategory, newWeightCategory, nutrition.weight)
        end
    end
    if anyChanged and PNC.NeedsRepository then
        PNC.NeedsRepository.MarkDirty()
    end
    if PNC.NeedsEvaluator and PNC.NeedsEvaluator.Commands then
        PNC.NeedsEvaluator.Commands.Reconcile(record, Utils.WorldAgeHours())
    end
    return true
end

function Needs.AdvanceTo(record, now, reason)
    local state, ignoredReason, repositoryState = Needs.Ensure(record)
    if not state then return false end
    now = math.max(0, tonumber(now) or Utils.WorldAgeHours())
    local previous = PNC.NeedsRepository.GetEvaluatedAt(record)
    local elapsed = math.max(0, now - previous)
    local updated = Needs.Update(record, elapsed, reason,
        state, repositoryState)
    if elapsed > 0 then
        PNC.NeedsRepository.SetEvaluatedAt(record, now)
    end
    return updated
end

function Needs.UpdateToNow(record, reason, worldAgeHours)
    return Needs.AdvanceTo(
        record,
        worldAgeHours ~= nil and worldAgeHours or Utils.WorldAgeHours(),
        reason
    )
end

return Needs
