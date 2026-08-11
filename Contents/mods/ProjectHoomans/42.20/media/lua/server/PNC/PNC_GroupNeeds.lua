if isClient and isClient() and (not isServer or not isServer()) then return end

PNC = PNC or {}
PNC.GroupNeeds = PNC.GroupNeeds or {}

local Needs = PNC.GroupNeeds
local Definitions = PNC.NeedsDefinitions
local Utils = PNC.NeedsUtils
local Factions = PNC.Factions

-- Project Zomboid's triggerEvent only accepts engine-declared events. Needs
-- therefore exposes a local listener API for future AI modules instead of
-- attempting to register a dynamic engine event name.
Needs.Listeners = Needs.Listeners or {}

function Needs.RegisterListener(eventName, listener)
    eventName = tostring(eventName or "")
    if eventName == "" or type(listener) ~= "function" then return false end
    Needs.Listeners[eventName] = Needs.Listeners[eventName] or {}
    Needs.Listeners[eventName][#Needs.Listeners[eventName] + 1] = listener
    return true
end

function Needs.UnregisterListener(eventName, listener)
    local listeners = Needs.Listeners[tostring(eventName or "")]
    if type(listeners) ~= "table" or type(listener) ~= "function" then return false end
    for index = #listeners, 1, -1 do
        if listeners[index] == listener then
            table.remove(listeners, index)
            if #listeners <= 0 then Needs.Listeners[tostring(eventName)] = nil end
            return true
        end
    end
    return false
end

function Needs.Emit(eventName, ...)
    for index, listener in ipairs(Needs.Listeners[tostring(eventName or "")] or {}) do
        local ok, listenerError = pcall(listener, ...)
        if not ok and PNC.Core and PNC.Core.LogWarn then
            PNC.Core.LogWarn("PNC group needs listener failed event="
                .. tostring(eventName) .. " index=" .. tostring(index)
                .. " error=" .. tostring(listenerError))
        end
    end
end

local function group(factionOrID)
    if type(factionOrID) == "table" then return factionOrID end
    return Factions and Factions.Get and Factions.Get(factionOrID) or nil
end

local function memberCount(faction)
    local count = 0
    for _, present in pairs(faction and faction.memberIDs or {}) do
        if present == true then count = count + 1 end
    end
    return math.max(1, count)
end

local function write(faction, state, reason)
    if not Factions or not Factions.SetNeeds then return nil, "faction_service_unavailable" end
    return Factions.SetNeeds(faction.id, state, reason)
end

local function history(faction, needType, before, after, reason)
    PNC.NeedsDebug = PNC.NeedsDebug or {}
    local store = PNC.NeedsDebug.groupHistory or {}
    PNC.NeedsDebug.groupHistory = store
    store[faction.id] = store[faction.id] or {}
    local entries = store[faction.id]
    entries[#entries + 1] = { at = Utils.WorldAgeHours(), needType = needType,
        before = before, after = after, reason = reason or "unspecified" }
    while #entries > Definitions.DEBUG_HISTORY_LIMIT do table.remove(entries, 1) end
end

local function publishLevelChange(faction, needType, oldValue, newValue, reason)
    local oldLevel = Definitions.GetLevel(needType, oldValue)
    local newLevel = Definitions.GetLevel(needType, newValue)
    if oldLevel == newLevel then return end
    history(faction, needType .. "_level", oldLevel, newLevel, reason or "level_changed")
    Needs.Emit("level_changed", faction.id, needType, oldLevel, newLevel, reason)
end

function Needs.IsGroup(faction)
    return faction and Factions and Factions.IsMobileGroup
        and Factions.IsMobileGroup(faction) == true
end

function Needs.Ensure(factionOrID)
    local faction = group(factionOrID)
    if not Needs.IsGroup(faction) then return nil, "not_mobile_group" end
    local state = faction.needs
    if type(state) ~= "table" then
        local defaults = {}
        for _, needType in ipairs(Definitions.TYPES) do
            defaults[needType] = Utils.RandomInRange(
                Definitions.GROUP_INITIAL_MIN, Definitions.GROUP_INITIAL_MAX,
                tostring(faction.id) .. ":" .. needType
            )
        end
        state = Utils.NormalizeState(nil, Utils.WorldAgeHours(), defaults)
        write(faction, state, "group_needs_initialization")
    else
        state = Utils.NormalizeState(state, Utils.WorldAgeHours())
    end
    return state, faction
end

function Needs.Get(factionOrID, needType)
    local state = Needs.Ensure(factionOrID)
    return state and state[tostring(needType or "")]
end

function Needs.Set(factionOrID, needType, value, reason)
    local state, faction = Needs.Ensure(factionOrID)
    needType = tostring(needType or "")
    if not state or not faction or not Definitions.Get(needType) then return nil, "invalid_need" end
    local before = state[needType]
    local after = Definitions.Clamp(needType, value)
    state[needType] = after
    if before ~= after then
        history(faction, needType, before, after, reason)
        publishLevelChange(faction, needType, before, after, reason)
        write(faction, state, "group_needs_" .. tostring(reason or "update"))
    end
    return after
end

function Needs.Modify(factionOrID, needType, amount, reason)
    return Needs.Set(factionOrID, needType, (Needs.Get(factionOrID, needType) or 0) + (tonumber(amount) or 0), reason)
end

function Needs.Restore(factionOrID, needType, amount, reason)
    return Needs.Modify(factionOrID, needType,
        -math.abs(tonumber(amount) or 0), reason or "restore")
end

function Needs.GetLevel(factionOrID, needType)
    return Definitions.GetLevel(needType,
        Needs.Get(factionOrID, needType) or 0)
end

function Needs.GetActivity(factionOrID)
    local state = Needs.Ensure(factionOrID)
    return state and state.debugActivity or "idle"
end

function Needs.SetDebugActivity(factionOrID, activity)
    local state, faction = Needs.Ensure(factionOrID)
    activity = tostring(activity or "idle")
    if not state or not faction or not Definitions.GROUP_ACTIVITY[activity] then return false, "invalid_activity" end
    state.debugActivity = activity == "idle" and nil or activity
    return write(faction, state, "group_needs_debug_activity")
end

function Needs.GetRates(factionOrID)
    local state, faction = Needs.Ensure(factionOrID)
    if not state or not faction then return nil end
    local activity = Definitions.GROUP_ACTIVITY[Needs.GetActivity(faction)] or Definitions.GROUP_ACTIVITY.idle
    local size = Utils.GroupSizeModifier(memberCount(faction))
    local output = {}
    for _, needType in ipairs(Definitions.TYPES) do
        output[needType] = Definitions.GROUP_RATES_PER_HOUR[needType] * size * (activity[needType] or 1)
    end
    return output
end

function Needs.Update(factionOrID, elapsedHours, reason)
    local state, faction = Needs.Ensure(factionOrID)
    if not state or not faction then return false end
    elapsedHours = math.max(0, tonumber(elapsedHours) or 0)
    local rates = Needs.GetRates(faction)
    for _, needType in ipairs(Definitions.TYPES) do
        local before = state[needType]
        local after = Definitions.Clamp(
            needType, before + rates[needType] * elapsedHours
        )
        state[needType] = after
        if before ~= after then
            history(faction, needType, before, after,
                reason or "passive_increase")
            publishLevelChange(faction, needType, before, after,
                reason or "passive_increase")
        end
    end
    state.lastUpdateWorldAge = Utils.WorldAgeHours()
    write(faction, state, "group_needs_update")
    return true
end

function Needs.UpdateToNow(factionOrID, reason)
    local state = Needs.Ensure(factionOrID)
    if not state then return false end
    local now = Utils.WorldAgeHours()
    return Needs.Update(factionOrID, math.max(0, now - (tonumber(state.lastUpdateWorldAge) or now)), reason)
end

function Needs.Reset(factionOrID)
    local state, faction = Needs.Ensure(factionOrID)
    if not state or not faction then return false end
    for _, needType in ipairs(Definitions.TYPES) do Needs.Set(faction, needType, Definitions.Get(needType).default, "debug_reset") end
    state.lastUpdateWorldAge = Utils.WorldAgeHours()
    return write(faction, state, "group_needs_reset")
end

function Needs.DebugAbstractScavenge(factionOrID)
    local state, faction = Needs.Ensure(factionOrID)
    if not state or not faction then return nil, "not_mobile_group" end
    local hunger = Utils.RandomInRange(Definitions.ABSTRACT_SCAVENGE.hungerGainMin, Definitions.ABSTRACT_SCAVENGE.hungerGainMax)
    local hydration = Utils.RandomInRange(Definitions.ABSTRACT_SCAVENGE.hydrationGainMin, Definitions.ABSTRACT_SCAVENGE.hydrationGainMax)
    Needs.Restore(faction, "hunger", hunger, "debug_abstract_scavenge")
    Needs.Restore(faction, "hydration", hydration, "debug_abstract_scavenge")
    return { hunger = hunger, hydration = hydration }
end

return Needs
