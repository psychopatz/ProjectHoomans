if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Needs = PNC.GroupNeeds
local H = Needs.Internal
local Definitions = PNC.NeedsDefinitions
local Utils = PNC.NeedsUtils

local function ratesFor(state, faction)
    local activityKey = state and state.debugActivity or "idle"
    local activity = Definitions.GROUP_ACTIVITY[activityKey]
        or Definitions.GROUP_ACTIVITY.idle
    local size = Utils.GroupSizeModifier(H.MemberCount(faction))
    local output = {}
    for _, needType in ipairs(Definitions.TYPES) do
        output[needType] = Definitions.GROUP_RATES_PER_HOUR[needType]
            * size * (activity[needType] or 1)
    end
    return output
end

function Needs.GetActivity(factionOrID)
    local state = Needs.Ensure(factionOrID)
    return state and state.debugActivity or "idle"
end

function Needs.GetRates(factionOrID)
    local state, faction = Needs.Ensure(factionOrID)
    if not state or not faction then return nil end
    return ratesFor(state, faction)
end

function Needs.Update(factionOrID, elapsedHours, reason, stateOverride,
    factionOverride)
    local state, faction = stateOverride, factionOverride
    if not state or not faction then
        state, faction = Needs.Ensure(factionOrID)
    end
    if not state or not faction then return false end
    elapsedHours = math.max(0, tonumber(elapsedHours) or 0)
    if elapsedHours <= 0 then return true end
    local rates = ratesFor(state, faction)
    local anyChanged = false
    for _, needType in ipairs(Definitions.TYPES) do
        local before = state[needType]
        local after = Definitions.Clamp(
            needType, before + rates[needType] * elapsedHours)
        state[needType] = after
        if before ~= after then
            anyChanged = true
            H.History(faction, needType, before, after,
                reason or "passive_increase")
            H.PublishLevelChange(faction, needType, before, after,
                reason or "passive_increase")
        end
    end
    if anyChanged then
        state.lastUpdateWorldAge = Utils.WorldAgeHours()
        H.Write(faction, state, "group_needs_update")
    end
    return true
end

function Needs.UpdateToNow(factionOrID, reason)
    local state, faction = Needs.Ensure(factionOrID)
    if not state or not faction then return false end
    local now = Utils.WorldAgeHours()
    return Needs.Update(faction,
        math.max(0, now - (tonumber(state.lastUpdateWorldAge) or now)),
        reason, state, faction)
end

return Needs
