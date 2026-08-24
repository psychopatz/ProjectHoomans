if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Needs = PNC.GroupNeeds
local H = Needs.Internal
local Definitions = PNC.NeedsDefinitions
local Utils = PNC.NeedsUtils

function Needs.SetDebugActivity(factionOrID, activity)
    local state, faction = Needs.Ensure(factionOrID)
    activity = tostring(activity or "idle")
    if not state or not faction or not Definitions.GROUP_ACTIVITY[activity] then
        return false, "invalid_activity"
    end
    state.debugActivity = activity == "idle" and nil or activity
    return H.Write(faction, state, "group_needs_debug_activity")
end

function Needs.Reset(factionOrID)
    local state, faction = Needs.Ensure(factionOrID)
    if not state or not faction then return false end
    for _, needType in ipairs(Definitions.TYPES) do
        Needs.Set(faction, needType, Definitions.Get(needType).default,
            "debug_reset")
    end
    state.lastUpdateWorldAge = Utils.WorldAgeHours()
    return H.Write(faction, state, "group_needs_reset")
end

function Needs.DebugAbstractScavenge(factionOrID)
    local state, faction = Needs.Ensure(factionOrID)
    if not state or not faction then return nil, "not_mobile_group" end
    local hunger = Utils.RandomInRange(
        Definitions.ABSTRACT_SCAVENGE.hungerGainMin,
        Definitions.ABSTRACT_SCAVENGE.hungerGainMax)
    local thirst = Utils.RandomInRange(
        Definitions.ABSTRACT_SCAVENGE.thirstGainMin,
        Definitions.ABSTRACT_SCAVENGE.thirstGainMax)
    Needs.Restore(faction, "hunger", hunger, "debug_abstract_scavenge")
    Needs.Restore(faction, "thirst", thirst, "debug_abstract_scavenge")
    return { hunger = hunger, thirst = thirst }
end

return Needs
