if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Needs = PNC.GroupNeeds
local H = Needs.Internal
local Definitions = PNC.NeedsDefinitions
local Utils = PNC.NeedsUtils
local Factions = PNC.Factions

function H.Group(factionOrID)
    if type(factionOrID) == "table" then return factionOrID end
    return Factions and Factions.Get and Factions.Get(factionOrID) or nil
end

function H.MemberCount(faction)
    local count = 0
    for _, present in pairs(faction and faction.memberIDs or {}) do
        if present == true then count = count + 1 end
    end
    return math.max(1, count)
end

function H.Write(faction, state, reason)
    if not Factions or not Factions.SetNeeds then
        return nil, "faction_service_unavailable"
    end
    return Factions.SetNeeds(faction.id, state, reason)
end

function H.History(faction, needType, before, after, reason)
    PNC.NeedsDebug = PNC.NeedsDebug or {}
    local store = PNC.NeedsDebug.groupHistory or {}
    PNC.NeedsDebug.groupHistory = store
    store[faction.id] = store[faction.id] or {}
    local entries = store[faction.id]
    entries[#entries + 1] = {
        at = Utils.WorldAgeHours(),
        needType = needType,
        before = before,
        after = after,
        reason = reason or "unspecified",
    }
    while #entries > Definitions.DEBUG_HISTORY_LIMIT do
        table.remove(entries, 1)
    end
end

function H.PublishLevelChange(faction, needType, oldValue, newValue, reason)
    local oldLevel = Definitions.GetLevel(needType, oldValue)
    local newLevel = Definitions.GetLevel(needType, newValue)
    if oldLevel == newLevel then return end
    H.History(faction, needType .. "_level", oldLevel, newLevel,
        reason or "level_changed")
    Needs.Emit("level_changed", faction.id, needType,
        oldLevel, newLevel, reason)
end

function Needs.IsGroup(faction)
    return faction and Factions and Factions.IsMobileGroup
        and Factions.IsMobileGroup(faction) == true
end

function Needs.Ensure(factionOrID)
    local faction = H.Group(factionOrID)
    if not Needs.IsGroup(faction) then return nil, "not_mobile_group" end
    local state = faction.needs
    if type(state) ~= "table" then
        local defaults = {}
        for _, needType in ipairs(Definitions.TYPES) do
            defaults[needType] = Utils.RandomInRange(
                Definitions.GROUP_INITIAL_MIN,
                Definitions.GROUP_INITIAL_MAX,
                tostring(faction.id) .. ":" .. needType)
        end
        state = Utils.NormalizeState(nil, Utils.WorldAgeHours(), defaults)
        H.Write(faction, state, "group_needs_initialization")
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
    if not state or not faction or not Definitions.Get(needType) then
        return nil, "invalid_need"
    end
    local before = state[needType]
    local after = Definitions.Clamp(needType, value)
    state[needType] = after
    if before ~= after then
        H.History(faction, needType, before, after, reason)
        H.PublishLevelChange(faction, needType, before, after, reason)
        H.Write(faction, state,
            "group_needs_" .. tostring(reason or "update"))
    end
    return after
end

function Needs.Modify(factionOrID, needType, amount, reason)
    return Needs.Set(factionOrID, needType,
        (Needs.Get(factionOrID, needType) or 0) + (tonumber(amount) or 0),
        reason)
end

function Needs.Restore(factionOrID, needType, amount, reason)
    return Needs.Modify(factionOrID, needType,
        -math.abs(tonumber(amount) or 0), reason or "restore")
end

function Needs.GetLevel(factionOrID, needType)
    return Definitions.GetLevel(needType,
        Needs.Get(factionOrID, needType) or 0)
end

return Needs
