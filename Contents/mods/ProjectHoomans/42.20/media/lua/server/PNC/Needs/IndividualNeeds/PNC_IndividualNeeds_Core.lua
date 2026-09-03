if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Needs = PNC.IndividualNeeds
local Definitions = PNC.NeedsDefinitions
local Utils = PNC.NeedsUtils
local PlayerModel = PNC.PlayerNeedsModel
local EventBus = require "PsychopatzCore/Events/PC_EventBus"
local EventTypes = PNC.EventTypes
local H = Needs.Internal

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
function H.Runtime(record)
    record.runtime = record.runtime or {}
    record.runtime.needs = record.runtime.needs or { cachedLevels = {} }
    return record.runtime.needs
end
function H.Activity(record)
    local value = H.Runtime(record).activityOverride
    if Definitions.INDIVIDUAL_ACTIVITY[value] then return value end
    if tostring(record.activeJob or "") == "Sleep" then
        local activity = record.runtime and record.runtime.facilityActivity
        -- A sleep order can spend several ticks travelling or starting its
        -- scene. Only the accepted sleep scene is allowed to grant the
        -- sleeping activity rate.
        if activity and activity.sleepSceneActive == true then
            return "sleeping"
        end
        if record.travel and record.travel.state == "active" then
            return "traveling"
        end
        if record.runtime and record.runtime.pathing
            and record.runtime.pathing.phase == "active"
        then
            return "walking"
        end
        return "idle"
    end
    if tostring(record.activeBehavior or "") == "resting" then return "resting" end
    if record.runtime and record.runtime.attackAction then return "fighting" end
    if record.travel and record.travel.state == "active" then return "traveling" end
    if record.runtime and record.runtime.pathing and record.runtime.pathing.phase == "active" then return "walking" end
    if record.activeJob then return "working" end
    return "idle"
end

function H.Owned(record)
    return record and (record.recruited == true
        or record.ownerUsername ~= nil or record.ownerOnlineID ~= nil)
end

function H.Log(record, needType, before, after, reason)
    PNC.NeedsDebug = PNC.NeedsDebug or {}
    local history = PNC.NeedsDebug.individualHistory or {}
    PNC.NeedsDebug.individualHistory = history
    history[record.id] = history[record.id] or {}
    local entries = history[record.id]
    entries[#entries + 1] = { at = Utils.WorldAgeHours(), needType = needType,
        before = before, after = after, reason = reason or "unspecified" }
    while #entries > Definitions.DEBUG_HISTORY_LIMIT do table.remove(entries, 1) end
end

function Needs.IsEligible(record) return H.Owned(record) end

function Needs.Ensure(record, initial)
    if not H.Owned(record) then return nil, "not_player_owned" end
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
    H.Runtime(record)
    return entry.needs
end

function Needs.GetState(record)
    if not H.Owned(record) then return nil, "not_player_owned" end
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
        H.Log(record, needType, before, after, reason)
        local oldLevel = Definitions.GetLevel(needType, before)
        local newLevel = Definitions.GetLevel(needType, after)
        if oldLevel ~= newLevel then
            H.Runtime(record).cachedLevels[needType] = newLevel
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

function Needs.GetActivity(record) return H.Activity(record) end
function Needs.SetActivityOverride(record, value)
    value = tostring(value or "")
    if value ~= "" and not Definitions.INDIVIDUAL_ACTIVITY[value] then return false, "invalid_activity" end
    H.Runtime(record).activityOverride = value ~= "" and value or nil
    return true
end
function Needs.GetRates(record)
    local activity = H.Activity(record)
    local rates = PlayerModel.GetRates(record, Needs.Ensure(record), activity)
    local facilityActivity = record.runtime
        and record.runtime.facilityActivity or nil
    -- FacilityJobs owns the sleep effect clock. Keep the normal sleeping
    -- hunger/thirst model, but prevent its passive fatigue recovery from
    -- running in parallel with NeedFacilityEffects.ApplyRest.
    if activity == "sleeping" and facilityActivity
        and tostring(facilityActivity.capability or "") == "sleep"
    then
        rates.fatigue = 0
    end
    return rates
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

function H.WeightCategory(weight)
    weight = tonumber(weight) or Definitions.NUTRITION.defaultWeight
    if weight < 55 then return "EMACIATED" end
    if weight < 65 then return "VERY_UNDERWEIGHT" end
    if weight < 75 then return "UNDERWEIGHT" end
    if weight >= 105 then return "OBESE" end
    if weight >= 90 then return "OVERWEIGHT" end
    return "NORMAL"
end

return Needs
