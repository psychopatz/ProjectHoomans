if isClient and isClient() and (not isServer or not isServer()) then return end

PNC = PNC or {}
PNC.IndividualNeeds = PNC.IndividualNeeds or {}

local Needs = PNC.IndividualNeeds
local Definitions = PNC.NeedsDefinitions
local Utils = PNC.NeedsUtils

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
        if PNC.Registry and PNC.Registry.MarkDirty then PNC.Registry.MarkDirty(record, "individual_needs_" .. tostring(reason or "update")) end
    end
    return after
end

function Needs.Modify(record, needType, amount, reason)
    return Needs.Set(record, needType, (Needs.Get(record, needType) or 0) + (tonumber(amount) or 0), reason)
end

function Needs.GetLevel(record, needType)
    return Definitions.GetLevel(Needs.Get(record, needType) or 0)
end

function Needs.Update(record, elapsedHours, reason)
    local state = Needs.Ensure(record)
    if not state then return false end
    elapsedHours = math.max(0, tonumber(elapsedHours) or 0)
    for _, needType in ipairs(Definitions.TYPES) do
        Needs.Modify(record, needType, -Definitions.INDIVIDUAL_RATES_PER_HOUR[needType] * elapsedHours, reason or "passive_decay")
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
