if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.IndividualNeeds = PNC.IndividualNeeds or {}

local Needs = PNC.IndividualNeeds
local Definitions = PNC.NeedsDefinitions
local Utils = PNC.NeedsUtils
local PlayerModel = PNC.PlayerNeedsModel

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
    local at = Utils.WorldAgeHours()
    if type(record.needs) ~= "table" then
        local defaults = initial or {}
        for _, needType in ipairs(Definitions.TYPES) do
            if defaults[needType] == nil then
                defaults[needType] = Utils.RandomInRange(
                    Definitions.INDIVIDUAL_INITIAL_MIN,
                    Definitions.INDIVIDUAL_INITIAL_MAX,
                    tostring(record.id) .. ":" .. needType
                )
            end
        end
        record.needs = Utils.NormalizeState(nil, at, defaults)
        if PNC.Registry and PNC.Registry.MarkDirty then
            PNC.Registry.MarkDirty(record, "individual_needs_initialization")
        end
    else
        record.needs = Utils.NormalizeState(record.needs, at)
    end
    runtime(record)
    return record.needs
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
            Needs.Emit("level_changed", record, needType, oldLevel, newLevel, reason)
        end
        if PNC.Registry and PNC.Registry.MarkDirty then PNC.Registry.MarkDirty(record, "individual_needs_" .. tostring(reason or "update")) end
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

function Needs.Update(record, elapsedHours, reason)
    local state = Needs.Ensure(record)
    if not state then return false end
    elapsedHours = math.max(0, tonumber(elapsedHours) or 0)
    local rates = Needs.GetRates(record)
    for _, needType in ipairs(Definitions.TYPES) do
        Needs.Modify(record, needType, rates[needType] * elapsedHours,
            reason or "passive_increase")
    end
    if PNC.NeedHealthConsequences and PNC.NeedHealthConsequences.Apply then
        PNC.NeedHealthConsequences.Apply(record, elapsedHours)
    end
    state.lastUpdateWorldAge = Utils.WorldAgeHours()
    return true
end

function Needs.UpdateToNow(record, reason)
    local state = Needs.Ensure(record)
    if not state then return false end
    local now = Utils.WorldAgeHours()
    return Needs.Update(record, math.max(0, now - (tonumber(state.lastUpdateWorldAge) or now)), reason)
end

function Needs.Reset(record)
    local state = Needs.Ensure(record)
    if not state then return false end
    for _, needType in ipairs(Definitions.TYPES) do Needs.Set(record, needType, Definitions.Get(needType).default, "debug_reset") end
    state.lastUpdateWorldAge = Utils.WorldAgeHours()
    return true
end

function Needs.InitializeFromGroup(record, groupNeeds)
    return Needs.Ensure(record, groupNeeds)
end

return Needs
