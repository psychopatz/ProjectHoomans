if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Needs = PNC.IndividualNeeds
local Definitions = PNC.NeedsDefinitions
local Utils = PNC.NeedsUtils
local PlayerModel = PNC.PlayerNeedsModel
local EventBus = require "PsychopatzCore/Events/PC_EventBus"
local EventTypes = PNC.EventTypes
local H = Needs.Internal

function Needs.Reset(record)
    local state = Needs.Ensure(record)
    if not state then return false end
    for _, needType in ipairs(Definitions.TYPES) do Needs.Set(record, needType, Definitions.Get(needType).default, "debug_reset") end
    local nutrition = Needs.GetNutrition(record)
    if nutrition then
        nutrition.calories = Definitions.NUTRITION.defaultCalories
        nutrition.weight = PlayerModel.GetInitialWeight(record)
    end
    PNC.NeedsRepository.SetEvaluatedAt(record, Utils.WorldAgeHours())
    PNC.NeedsRepository.MarkDirty()
    return true
end

function Needs.InitializeFromGroup(record, groupNeeds)
    return Needs.Ensure(record, groupNeeds)
end

return Needs

