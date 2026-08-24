if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Evaluator = PNC.ProvisionEvaluator
local H = Evaluator.Internal
local Registry = PNC.ProvisionRuleRegistry
local Index = PNC.SupplyIndex

function Evaluator.MeasureStorage(storage)
    local output = {}
    if not storage or not storage.inventory then return output end
    for _, definition in ipairs(Registry.List()) do
        local request = H.RequestFor(definition)
        local entries = Index.Query(storage, request)
        local amount = 0
        local calories = 0
        local items = {}
        for index = 1, #entries do
            local descriptor = entries[index].descriptor
            local quantity = math.max(1, tonumber(descriptor.quantity) or 1)
            if definition.measure == "HUNGER_UTILITY" then
                amount = amount + descriptor.hunger * quantity
                calories = calories + (tonumber(descriptor.calories) or 0)
                    * quantity
            elseif definition.measure == "THIRST_UTILITY" then
                amount = amount + descriptor.thirst
                    * math.max(0, tonumber(descriptor.remainingUses) or 0)
                    * quantity
            elseif definition.measure == "COUNT" then
                amount = amount + quantity
            end
            if #items < 12 then
                items[#items + 1] = {
                    fullType = descriptor.fullType,
                    quantity = quantity,
                    hunger = descriptor.hunger,
                    thirst = descriptor.thirst,
                    calories = descriptor.calories,
                    remainingUses = descriptor.remainingUses,
                }
            end
        end
        output[definition.id] = {
            amount = amount,
            calories = calories,
            candidateTypes = #entries,
            items = items,
        }
    end
    return output
end
