if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Needs = PNC.IndividualNeeds
local Definitions = PNC.NeedsDefinitions
local Utils = PNC.NeedsUtils
local PlayerModel = PNC.PlayerNeedsModel
local EventBus = require "PsychopatzCore/Events/PC_EventBus"
local EventTypes = PNC.EventTypes
local H = Needs.Internal

local function applyConsumable(record, effect, source)
    effect = type(effect) == "table" and effect or {}
    Needs.Modify(record, "hunger", -(tonumber(effect.hunger) or 0),
        source or "food_consumed")
    Needs.Modify(record, "thirst", -(tonumber(effect.thirst) or 0),
        source or "food_consumed")
    Needs.ModifyNutrition(record, tonumber(effect.calories) or 0,
        source or "food_consumed")
    return true, Needs.GetState(record)
end

-- Both food and drink can restore both primitive needs.  Keep the two public
-- commands for their existing callers, but make the effect application
-- vector-aware so an apple consumed through the food lane also hydrates.
function Needs.Commands.ApplyFood(record, effect, source)
    return applyConsumable(record, effect, source or "food_consumed")
end

function Needs.Commands.ApplyDrink(record, effect, source)
    return applyConsumable(record, effect, source or "drink_consumed")
end
function Needs.GetPriority(record, needType)
    local value = Needs.Get(record, needType) or 0
    return math.max(0, math.min(100, value * 100))
end
function Needs.GetHighestPriority(record)
    local bestType, bestValue
    for _, needType in ipairs(Definitions.TYPES) do
        local value = Needs.GetPriority(record, needType)
        if not bestValue or value > bestValue then bestType, bestValue = needType, value end
    end
    return bestType, bestValue
end

function Needs.Queries.GetSleepIntent(record)
    if not record or record.alive == false then return nil, "NPC_UNAVAILABLE" end
    local fatigue = tonumber(Needs.Get(record, "fatigue")) or 0
    local policy = Definitions.SLEEP_TASK
    if fatigue < policy.actionable then return nil, "NOT_ACTIONABLE" end
    return {
        precedence = fatigue >= policy.critical
            and "CRITICAL_NEED" or "NORMAL_NEED",
        urgency = math.max(0, math.min(1, fatigue)),
        completionThreshold = policy.completion,
        recoveryPerGameHour = policy.recoveryPerGameHour,
    }
end

function Needs.Commands.ApplyRest(record, elapsedHours, source, options)
    if not record or record.alive == false then return false, "NPC_UNAVAILABLE" end
    options = type(options) == "table" and options or {}
    local elapsed = math.max(0, math.min(0.25, tonumber(elapsedHours) or 0))
    if options.ignoreCompletion == true then
        local value = Needs.Modify(record, "fatigue",
            -(tonumber(options.recoveryPerGameHour)
                or Definitions.SLEEP_TASK.recoveryPerGameHour) * elapsed,
            tostring(source or "sleep_task"))
        if value == nil then return false, "REST_FAILED" end
        return true, "REST_APPLIED", value
    end
    local metadata, reason = Needs.Queries.GetSleepIntent(record)
    local current = tonumber(Needs.Get(record, "fatigue")) or 0
    if not metadata and current <= Definitions.SLEEP_TASK.completion then
        return true, "REST_COMPLETE", current
    end
    if not metadata and reason ~= "NOT_ACTIONABLE" then return false, reason end
    local value = Needs.Modify(record, "fatigue",
        -Definitions.SLEEP_TASK.recoveryPerGameHour * elapsed,
        tostring(source or "sleep_task"))
    if value == nil then return false, "REST_FAILED" end
    return true, value <= Definitions.SLEEP_TASK.completion
        and "REST_COMPLETE" or "REST_APPLIED", value
end

return Needs
