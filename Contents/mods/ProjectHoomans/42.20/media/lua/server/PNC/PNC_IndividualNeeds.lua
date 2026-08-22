if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.IndividualNeeds = PNC.IndividualNeeds or {}

local Needs = PNC.IndividualNeeds
local Definitions = PNC.NeedsDefinitions
local Utils = PNC.NeedsUtils
local PlayerModel = PNC.PlayerNeedsModel
local EventBus = require "PsychopatzCore/Events/PC_EventBus"
local EventTypes = PNC.EventTypes

Needs.Commands = Needs.Commands or {}
Needs.Queries = Needs.Queries or {}

Needs.Listeners = Needs.Listeners or {}
function Needs.RegisterListener(eventName, listener)
    eventName = tostring(eventName or "")
    if eventName == "" or type(listener) ~= "function" then return false end
    Needs.Listeners[eventName] = Needs.Listeners[eventName] or {}
    Needs.Listeners[eventName][#Needs.Listeners[eventName] + 1] = listener
    return true
end
function Needs.Emit(eventName, ...)
    for _, listener in ipairs(Needs.Listeners[tostring(eventName or "")] or {}) do
        local ok, errorValue = pcall(listener, ...)
        if not ok and PNC.Core and PNC.Core.LogWarn then PNC.Core.LogWarn("PNC companion needs listener failed: " .. tostring(errorValue)) end
    end
end
local function runtime(record)
    record.runtime = record.runtime or {}
    record.runtime.needs = record.runtime.needs or { cachedLevels = {} }
    return record.runtime.needs
end
local function activity(record)
    local value = runtime(record).activityOverride
    if Definitions.INDIVIDUAL_ACTIVITY[value] then return value end
    if tostring(record.activeJob or "") == "Sleep" then return "sleeping" end
    if tostring(record.activeBehavior or "") == "resting" then return "resting" end
    if record.runtime and record.runtime.attackAction then return "fighting" end
    if record.travel and record.travel.state == "active" then return "traveling" end
    if record.runtime and record.runtime.pathing and record.runtime.pathing.phase == "active" then return "walking" end
    if record.activeJob then return "working" end
    return "idle"
end

local function owned(record)
    return record and (record.recruited == true
        or record.ownerUsername ~= nil or record.ownerOnlineID ~= nil)
end

local function log(record, needType, before, after, reason)
    PNC.NeedsDebug = PNC.NeedsDebug or {}
    local history = PNC.NeedsDebug.individualHistory or {}
    PNC.NeedsDebug.individualHistory = history
    history[record.id] = history[record.id] or {}
    local entries = history[record.id]
    entries[#entries + 1] = { at = Utils.WorldAgeHours(), needType = needType,
        before = before, after = after, reason = reason or "unspecified" }
    while #entries > Definitions.DEBUG_HISTORY_LIMIT do table.remove(entries, 1) end
end

function Needs.IsEligible(record) return owned(record) end

function Needs.Ensure(record, initial)
    if not owned(record) then return nil, "not_player_owned" end
    if PlayerModel and PlayerModel.EnsureTraits then
        PlayerModel.EnsureTraits(record)
    end
    local entry = PNC.NeedsRepository and PNC.NeedsRepository.Get(record, true)
    if not entry then return nil, "repository_unavailable" end
    if type(initial) == "table" then
        for _, needType in ipairs(Definitions.TYPES) do
            if initial[needType] ~= nil then
                entry.needs[needType] = Definitions.Clamp(needType,
                    initial[needType])
            end
        end
    end
    runtime(record)
    return entry.needs
end

function Needs.GetState(record)
    if not owned(record) then return nil, "not_player_owned" end
    return PNC.NeedsRepository and PNC.NeedsRepository.Get(record, true) or nil
end

function Needs.GetNutrition(record)
    local state = Needs.GetState(record)
    return state and state.nutrition or nil
end

function Needs.Get(record, needType)
    local state = Needs.Ensure(record)
    return state and state[tostring(needType or "")]
end

function Needs.Set(record, needType, value, reason)
    local state = Needs.Ensure(record)
    needType = tostring(needType or "")
    if not state or not Definitions.Get(needType) then return nil, "invalid_need" end
    local before = state[needType]
    local after = Definitions.Clamp(needType, value)
    state[needType] = after
    if before ~= after then
        log(record, needType, before, after, reason)
        local oldLevel = Definitions.GetLevel(needType, before)
        local newLevel = Definitions.GetLevel(needType, after)
        if oldLevel ~= newLevel then
            runtime(record).cachedLevels[needType] = newLevel
            Needs.Emit("severity_changed", record, needType, oldLevel, newLevel, reason)
            EventBus.emit(EventTypes.NPC_NEED_SEVERITY_CHANGED, record,
                needType, oldLevel, newLevel, tostring(reason or "update"))
        end
        if PNC.NeedsRepository then PNC.NeedsRepository.MarkDirty() end
    end
    return after
end

function Needs.Modify(record, needType, amount, reason)
    return Needs.Set(record, needType, (Needs.Get(record, needType) or 0) + (tonumber(amount) or 0), reason)
end

function Needs.GetLevel(record, needType)
    return Definitions.GetLevel(needType, Needs.Get(record, needType) or 0)
end

function Needs.GetActivity(record) return activity(record) end
function Needs.SetActivityOverride(record, value)
    value = tostring(value or "")
    if value ~= "" and not Definitions.INDIVIDUAL_ACTIVITY[value] then return false, "invalid_activity" end
    runtime(record).activityOverride = value ~= "" and value or nil
    return true
end
function Needs.GetRates(record)
    return PlayerModel.GetRates(record, Needs.Ensure(record), activity(record))
end

function Needs.ModifyNutrition(record, calories, reason)
    local state = Needs.GetState(record)
    if not state then return nil, "not_player_owned" end
    local tuning = Definitions.NUTRITION
    local before = state.nutrition.calories
    state.nutrition.calories = math.max(tuning.minimumCalories,
        math.min(tuning.maximumCalories, before + (tonumber(calories) or 0)))
    if before ~= state.nutrition.calories and PNC.NeedsRepository then
        PNC.NeedsRepository.MarkDirty()
    end
    return state.nutrition.calories, reason
end

local function weightCategory(weight)
    weight = tonumber(weight) or Definitions.NUTRITION.defaultWeight
    if weight < 55 then return "EMACIATED" end
    if weight < 65 then return "VERY_UNDERWEIGHT" end
    if weight < 75 then return "UNDERWEIGHT" end
    if weight >= 105 then return "OBESE" end
    if weight >= 90 then return "OVERWEIGHT" end
    return "NORMAL"
end

function Needs.Commands.ApplyFood(record, effect, source)
    effect = type(effect) == "table" and effect or {}
    Needs.Modify(record, "hunger", -(tonumber(effect.hunger) or 0),
        source or "food_consumed")
    Needs.ModifyNutrition(record, tonumber(effect.calories) or 0,
        source or "food_consumed")
    return true, Needs.GetState(record)
end

function Needs.Commands.ApplyDrink(record, effect, source)
    effect = type(effect) == "table" and effect or {}
    Needs.Modify(record, "thirst", -(tonumber(effect.thirst) or 0),
        source or "drink_consumed")
    if tonumber(effect.calories) then
        Needs.ModifyNutrition(record, tonumber(effect.calories),
            source or "drink_consumed")
    end
    return true, Needs.GetState(record)
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

function Needs.Commands.ApplyRest(record, elapsedHours, source)
    if not record or record.alive == false then return false, "NPC_UNAVAILABLE" end
    local metadata, reason = Needs.Queries.GetSleepIntent(record)
    local current = tonumber(Needs.Get(record, "fatigue")) or 0
    if not metadata and current <= Definitions.SLEEP_TASK.completion then
        return true, "REST_COMPLETE", current
    end
    if not metadata and reason ~= "NOT_ACTIONABLE" then return false, reason end
    local elapsed = math.max(0, math.min(0.25, tonumber(elapsedHours) or 0))
    local value = Needs.Modify(record, "fatigue",
        -Definitions.SLEEP_TASK.recoveryPerGameHour * elapsed,
        tostring(source or "sleep_task"))
    if value == nil then return false, "REST_FAILED" end
    return true, value <= Definitions.SLEEP_TASK.completion
        and "REST_COMPLETE" or "REST_APPLIED", value
end

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
        local oldWeightCategory = weightCategory(nutrition.weight)
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
        local newWeightCategory = weightCategory(nutrition.weight)
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
