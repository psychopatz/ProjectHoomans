-- Server-authoritative debug transitions for mobile-group lifecycle testing.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.MobileGroupDirector = PNC.MobileGroupDirector or {}
PNC.MobileGroupDirectorInternal = PNC.MobileGroupDirectorInternal or {}

local Director = PNC.MobileGroupDirector
local H = PNC.MobileGroupDirectorInternal
local Constants = PNC.FactionConstants
local Factions = PNC.Factions

local function groupFor(factionID)
    local groups = PNC.AbstractGroups
    return groups and groups.FindByFactionID
        and groups.FindByFactionID(factionID) or nil
end

local function clearAbstractTravel(group, at)
    if not group or group.state ~= "TRAVELING" then return end
    group.targetLocation = nil
    local groups = PNC.AbstractGroups
    if groups and groups.SetState then
        local live = groups.HasLiveMembers
            and groups.HasLiveMembers(group) == true
        groups.SetState(group, live and "ACTIVE" or "ARRIVED", at, at)
    else
        group.state = "ARRIVED"
    end
end

local function mobileFaction(factionID)
    local faction = Factions and Factions.Get(factionID) or nil
    if not faction then return nil, "faction_not_found" end
    if not Factions.IsMobileGroup(faction) then
        return nil, "not_mobile_group"
    end
    return faction
end

function Director.ResetSettlementTravel(factionID, at)
    if not H.Authority() then return false, "not_authority" end
    local faction, reason = mobileFaction(factionID)
    if not faction then return false, reason end
    if faction.mobile.activity
        ~= Constants.MOBILE_ACTIVITY_TRAVELING_TO_SETTLEMENT
    then
        return false, "mobile_group_not_traveling"
    end
    at = H.WorldAge(at)
    local group = groupFor(faction.id)
    clearAbstractTravel(group, at)
    local ok, updateReason, mobile = Factions.UpdateMobileGroup(
        faction.id,
        {
            activity = Constants.MOBILE_ACTIVITY_STREET_ROAMING,
            travel = nil,
            ambient = nil,
        },
        "mobile_debug_travel_reset"
    )
    if not ok then return false, updateReason end
    if group then
        group.mobileAmbient = false
        group.ambientObjective = nil
        if PNC.AbstractGroupManagerInternal
            and PNC.AbstractGroupManagerInternal.Touch
        then
            PNC.AbstractGroupManagerInternal.Touch(
                group, "mobile_debug_travel_reset")
        end
        if H.RepairMobileOrders then
            H.RepairMobileOrders(Factions.Get(faction.id))
        end
    end
    return true, "mobile_travel_reset", mobile
end

function Director.ForceRoadRoaming(factionID, at)
    if not H.Authority() then return false, "not_authority" end
    local faction, reason = mobileFaction(factionID)
    if not faction then return false, reason end
    at = H.WorldAge(at)
    local target, targetReason = H.FindRoadTarget(faction)
    if not target then return false, targetReason or "no_road_target" end

    local ambient = faction.mobile.ambient or {}
    local ok, updateReason, mobile = Factions.UpdateMobileGroup(
        faction.id,
        {
            activity = Constants.MOBILE_ACTIVITY_STREET_ROAMING,
            travel = nil,
            pathMode = Constants.MOBILE_PATH_RANDOM,
            controlMode = Constants.MOBILE_CONTROL_AMBIENT,
            strategicTarget = nil,
            ambient = {
                phase = H.AmbientPhase(at),
                objective = Constants.MOBILE_AMBIENT_ROAD,
                target = target,
                nextCheckAt = at + Constants.MOBILE_AMBIENT_CHECK_HOURS,
                nextObjectiveAt = at
                    + Constants.MOBILE_AMBIENT_OBJECTIVE_HOURS,
                retryAt = 0,
                revision = (tonumber(ambient.revision) or 0) + 1,
            },
        },
        "mobile_debug_force_road"
    )
    if not ok then return false, updateReason end

    local group = groupFor(faction.id)
    if group then
        clearAbstractTravel(group, at)
        group.mobileAmbient = true
        group.ambientObjective = Constants.MOBILE_AMBIENT_ROAD
        if H.SyncAbstractObjective then
            H.SyncAbstractObjective(
                Factions.Get(faction.id),
                Constants.MOBILE_AMBIENT_ROAD,
                target,
                at
            )
        end
        if H.RepairMobileOrders then
            H.RepairMobileOrders(Factions.Get(faction.id))
        end
    end
    return true, "mobile_road_roaming_forced", mobile
end

return Director
