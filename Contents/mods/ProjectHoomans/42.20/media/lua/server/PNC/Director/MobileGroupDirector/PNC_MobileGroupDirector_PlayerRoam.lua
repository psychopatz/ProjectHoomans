if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.MobileGroupDirector = PNC.MobileGroupDirector or {}
PNC.MobileGroupDirectorInternal = PNC.MobileGroupDirectorInternal or {}

local H = PNC.MobileGroupDirectorInternal
local Constants = PNC.FactionConstants
local Config = PNC.DirectorConfig or {}
local Factions = PNC.Factions
local Core = PNC.Core
local Const = PNC.Const

local function finite(value, fallback)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then
        return tonumber(fallback) or 0
    end
    return value
end

local function copy(value)
    return Core and Core.DeepCopy and Core.DeepCopy(value) or value
end

local function phaseOf(mobile)
    local state = mobile and mobile.playerRoam or nil
    return state and state.phase
        or Constants.MOBILE_PLAYER_ROAM_PHASE_APPROACH
end

function H.IsPlayerRoamArea(mobile)
    return type(mobile) == "table"
        and mobile.pathMode == Constants.MOBILE_PATH_PLAYER
        and phaseOf(mobile) == Constants.MOBILE_PLAYER_ROAM_PHASE_AREA
end

function H.IsPlayerRoamStreetPool(mobile)
    return type(mobile) == "table"
        and mobile.active == true
        and mobile.pathMode == Constants.MOBILE_PATH_PLAYER
        and phaseOf(mobile)
            == Constants.MOBILE_PLAYER_ROAM_PHASE_STREET_POOL
        and mobile.activity
            ~= Constants.MOBILE_ACTIVITY_TRAVELING_TO_SETTLEMENT
        and mobile.controlMode == Constants.MOBILE_CONTROL_AMBIENT
        and not mobile.travel
end

function H.PlayerRoamAreaOrder(faction, mobile, site)
    local home = site and site.home or {}
    local area = mobile and mobile.playerRoam
        and mobile.playerRoam.area or nil
    if not area then return nil end
    return {
        kind = Const.ORDER_ROAM,
        roamMode = Const.ROAM_MODE_AREA,
        x = area.x,
        y = area.y,
        z = area.z,
        radius = math.max(
            1,
            finite(area.radius, Const.ROAM_DEFAULT_RADIUS)
        ),
        targetRadius = Const.ROAM_TARGET_RADIUS,
        reachedDistance = Const.ROAM_REACHED_DISTANCE,
    }
end

-- During the short hand-off between the area timer expiring and the ambient
-- director selecting a road target, hold the group near its staging site.
-- This prevents a stale player order from reactivating for one tick.
function H.PlayerRoamStreetPoolOrder(faction, mobile, site)
    local home = site and site.home or {}
    return {
        kind = Const.ORDER_ROAM,
        roamMode = Const.ROAM_MODE_AREA,
        x = home.x,
        y = home.y,
        z = home.z,
        radius = math.max(1, finite(home.radius, Const.ROAM_DEFAULT_RADIUS)),
        targetRadius = Const.ROAM_TARGET_RADIUS,
    }
end

local function updateFaction(faction, patch, reason)
    if not faction or not Factions.UpdateMobileGroup then
        return false, "mobile_update_unavailable", faction
    end
    local ok, updateReason = Factions.UpdateMobileGroup(
        faction.id,
        patch,
        reason
    )
    if not ok then return false, updateReason, faction end
    local updated = Factions.Get(faction.id) or faction
    if H.RepairMobileOrders then H.RepairMobileOrders(updated) end
    return true, updateReason, updated
end

local function playerRoamState(mobile)
    local state = copy(mobile and mobile.playerRoam) or {}
    state.phase = state.phase
        or Constants.MOBILE_PLAYER_ROAM_PHASE_APPROACH
    state.lastArrivalAt = finite(state.lastArrivalAt, 0)
    state.lastRollDay = math.floor(finite(state.lastRollDay, -1))
    return state
end

function H.EnterPlayerRoamArea(record, target, at)
    if not record or not Factions or not Factions.Get then
        return false, "mobile_record_unavailable"
    end
    local factionID = record.factionID or record.factionId
    local faction = factionID and Factions.Get(factionID) or nil
    if not faction and Factions.GetNPCFaction then
        faction = Factions.GetNPCFaction(record.id)
    end
    local mobile = faction and faction.mobile or nil
    if not faction or not mobile or faction.archetypeID == "looter" then
        return false, "not_neutral_player_roam"
    end
    if mobile.pathMode ~= Constants.MOBILE_PATH_PLAYER then
        return false, "mobile_player_path_disabled"
    end
    if H.IsPlayerRoamArea(mobile) then
        return false, "mobile_player_roam_area_active"
    end
    if H.IsPlayerRoamStreetPool(mobile) then
        return false, "mobile_player_roam_in_street_pool"
    end
    at = finite(at, H.WorldAge and H.WorldAge() or 0)
    local state = playerRoamState(mobile)
    local area = {
        kind = "player_roam_area",
        x = finite(record.x, 0),
        y = finite(record.y, 0),
        z = finite(record.z, 0),
        radius = math.max(1, finite(
            Const.ROAM_PLAYER_AREA_RADIUS,
            Const.ROAM_DEFAULT_RADIUS
        )),
    }
    state.phase = Constants.MOBILE_PLAYER_ROAM_PHASE_AREA
    state.area = area
    state.untilAt = at + math.max(
        1,
        finite(
            Constants.MOBILE_PLAYER_ROAM_AREA_HOURS,
            Constants.MOBILE_PLAYER_ROAM_AREA_HOURS
        )
    )
    state.lastArrivalAt = at
    local ok, reason = updateFaction(
        faction,
        {
            controlMode = Constants.MOBILE_CONTROL_AMBIENT,
            strategicTarget = nil,
            ambient = nil,
            activity = Constants.MOBILE_ACTIVITY_STREET_ROAMING,
            travel = nil,
            playerRoam = state,
        },
        "mobile_player_roam_arrived"
    )
    return ok, reason or "mobile_player_roam_area_started"
end

function H.ExpirePlayerRoamArea(faction, at)
    local mobile = faction and faction.mobile or nil
    if not mobile or not H.IsPlayerRoamArea(mobile) then
        return false, "mobile_player_roam_area_inactive", faction
    end
    at = finite(at, H.WorldAge and H.WorldAge() or 0)
    if at < finite(mobile.playerRoam.untilAt, 0) then
        return false, "mobile_player_roam_area_not_expired", faction
    end
    local state = playerRoamState(mobile)
    state.phase = Constants.MOBILE_PLAYER_ROAM_PHASE_STREET_POOL
    state.area = nil
    state.untilAt = 0
    local ok, reason, updated = updateFaction(
        faction,
        {
            controlMode = Constants.MOBILE_CONTROL_AMBIENT,
            strategicTarget = nil,
            ambient = nil,
            playerRoam = state,
        },
        "mobile_player_roam_area_expired"
    )
    return ok, reason or "mobile_player_roam_street_pool", updated
end

local function playerRoamChance()
    local chance = finite(
        Config.MOBILE_PLAYER_ROAM_BASE_CHANCE,
        Config.MOBILE_DAILY_DEPARTURE_BASE_CHANCE or 0.10
    )
    local sandbox
    if PNC.PopulationSandbox and PNC.PopulationSandbox.Resolve then
        local ok, value = pcall(PNC.PopulationSandbox.Resolve)
        sandbox = ok and value or nil
    end
    local multiplier = sandbox
        and finite(sandbox.roamingGroupMultiplier, 1) or 1
    return math.max(0, math.min(1, chance * multiplier))
end

function H.PlayerRoamChance()
    return playerRoamChance()
end

function H.RollPlayerRoam(faction, at)
    local mobile = faction and faction.mobile or nil
    if not H.IsPlayerRoamStreetPool(mobile) then
        return false, "mobile_player_roam_not_in_street_pool"
    end
    at = finite(at, H.WorldAge and H.WorldAge() or 0)
    local day = math.floor(math.max(0, at) / 24)
    local dayStart = day * 24 + finite(
        Constants.MOBILE_AMBIENT_DAY_START_HOUR,
        6
    )
    if at < dayStart then return false, "mobile_player_roam_roll_not_due" end
    local state = playerRoamState(mobile)
    if state.lastRollDay >= day then
        return false, "mobile_player_roam_roll_already_done"
    end
    state.lastRollDay = day
    local roll = H.DailyDepartureRoll
        and H.DailyDepartureRoll(faction.id, day)
        or 0
    if finite(roll, 1) >= playerRoamChance() then
        local ok, reason = updateFaction(
            faction,
            { playerRoam = state },
            "mobile_player_roam_roll_failed"
        )
        return false, ok and "mobile_player_roam_roll_failed" or reason
    end
    state.phase = Constants.MOBILE_PLAYER_ROAM_PHASE_APPROACH
    state.area = nil
    state.untilAt = 0
    local ok, reason = updateFaction(
        faction,
        {
            controlMode = Constants.MOBILE_CONTROL_STRATEGIC,
            strategicTarget = nil,
            ambient = nil,
            playerRoam = state,
        },
        "mobile_player_roam_roll_started"
    )
    return ok, reason or "mobile_player_roam_started"
end

return PNC.MobileGroupDirector
