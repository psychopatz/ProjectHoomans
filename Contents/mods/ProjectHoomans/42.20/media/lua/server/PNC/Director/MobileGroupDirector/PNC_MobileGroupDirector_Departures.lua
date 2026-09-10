if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.MobileGroupDirector = PNC.MobileGroupDirector or {}
PNC.MobileGroupDirectorInternal = PNC.MobileGroupDirectorInternal or {}

local Director = PNC.MobileGroupDirector
local H = PNC.MobileGroupDirectorInternal
local Constants = PNC.FactionConstants
local Config = PNC.DirectorConfig
local Factions = PNC.Factions

local function finite(value, fallback)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then
        return fallback
    end
    return value
end

function H.IsStreetRoaming(faction)
    local mobile = faction and faction.mobile or nil
    return mobile and mobile.active == true
        and (mobile.activity == nil
            or mobile.activity == Constants.MOBILE_ACTIVITY_STREET_ROAMING)
        and not mobile.travel
        and mobile.controlMode == Constants.MOBILE_CONTROL_AMBIENT
        and mobile.ambient
        and mobile.ambient.objective == Constants.MOBILE_AMBIENT_ROAD
end

function H.DepartureDay(at)
    return math.floor(math.max(0, finite(at, 0)) / 24)
end

function H.NextDailyDepartureAt(at)
    at = math.max(0, finite(at, 0))
    local day = H.DepartureDay(at)
    local startHour = tonumber(Constants.MOBILE_AMBIENT_DAY_START_HOUR)
        or 6
    local nextAt = day * 24 + startHour
    if nextAt < at then nextAt = nextAt + 24 end
    return nextAt
end

function H.DepartureChance()
    local chance = finite(
        Config.MOBILE_DAILY_DEPARTURE_BASE_CHANCE,
        0.10
    )
    local sandbox
    if PNC.PopulationSandbox
        and PNC.PopulationSandbox.Resolve
    then
        local ok, value = pcall(
            PNC.PopulationSandbox.Resolve
        )
        sandbox = ok and value or nil
    end
    local multiplier = sandbox
        and finite(sandbox.roamingGroupMultiplier, 1) or 1
    return math.max(0, math.min(1, chance * multiplier))
end

function H.DailyDepartureRoll(factionID, day)
    if type(Director.DailyDepartureRoll) == "function" then
        return math.max(0, math.min(1,
            finite(Director.DailyDepartureRoll(factionID, day), 1)))
    end
    local token = tostring(factionID or "") .. ":" .. tostring(day or 0)
    local hash = 17
    for index = 1, #token do
        hash = (hash * 31 + string.byte(token, index)) % 1000003
    end
    return hash / 1000003
end

local function targetLocation(target)
    local locations = PNC.AbstractLocations
    if not target or not locations then return nil end
    if target.locationID and locations.Get then
        return locations.Get(target.locationID)
    end
    return nil
end

function Director.StartSettlementTravel(factionID, target, at)
    if not H.Authority() then return false, "not_authority" end
    local faction = Factions.Get(factionID)
    if not faction then return false, "faction_not_found" end
    if not Factions.IsMobileGroup(faction) then
        return false, "not_mobile_group"
    end
    if not H.IsStreetRoaming(faction) then
        return false, "mobile_group_not_street_roaming"
    end
    target = type(target) == "table" and H.Copy(target)
        or H.ResolveSettlementDepartureTarget(faction)
    local location = targetLocation(target)
    if not target or not location then
        return false, "no_settlement_target"
    end
    at = H.WorldAge(at)
    local travel = {
        kind = Constants.MOBILE_TRAVEL_SETTLEMENT,
        destination = target,
        startedAt = at,
        departureDay = H.DepartureDay(at),
        revision = (faction.mobile.travel
            and tonumber(faction.mobile.travel.revision) or 0) + 1,
    }
    local ok, reason, mobile = Factions.UpdateMobileGroup(
        faction.id,
        {
            activity = Constants.MOBILE_ACTIVITY_TRAVELING_TO_SETTLEMENT,
            travel = travel,
            ambient = nil,
            lastDepartureAt = at,
        },
        "mobile_settlement_departure"
    )
    if not ok then return false, reason end
    local groups = PNC.AbstractGroups
    local traversal = PNC.AbstractTraversal
    local group = groups and groups.FindByFactionID
        and groups.FindByFactionID(faction.id) or nil
    if group then
        local live = groups.HasLiveMembers
            and groups.HasLiveMembers(group) == true
        group.mobileAmbient = false
        group.ambientObjective = nil
        if live and PNC.Presence and PNC.Presence.Abstract then
            for _, npcID in ipairs(group.memberIds or {}) do
                local record = PNC.Registry and PNC.Registry.Get
                    and PNC.Registry.Get(npcID) or nil
                if record and record.alive ~= false then
                    PNC.Presence.Abstract(
                        record, "mobile_settlement_departure")
                end
            end
            live = groups.HasLiveMembers
                and groups.HasLiveMembers(group) == true
            if not live and groups.RefreshLOD then
                groups.RefreshLOD(group, at)
            end
        end
        if PNC.AbstractGroupManagerInternal
            and PNC.AbstractGroupManagerInternal.Touch
        then
            PNC.AbstractGroupManagerInternal.Touch(
                group,
                "mobile_settlement_departure"
            )
        end
        if not live and group.state == "TRAVELING" then
            -- A street-roaming abstract group may already be moving toward
            -- its current road sample. Settlement travel supersedes that
            -- ambient leg, so do not leave the old nav target in flight.
            group.targetLocation = nil
            if groups.SetState then
                groups.SetState(group, "ARRIVED", at, at)
            else
                group.state = "ARRIVED"
            end
        end
        if not live and not (group.location
            and group.location.id == location.id)
        then
            if not traversal or not traversal.Begin then
                return false, "traversal_unavailable"
            end
            local started, startReason = traversal.Begin(
                group,
                location,
                at
            )
            if not started then return false, startReason end
        end
    end
    return true, "mobile_settlement_departed", mobile
end

local function markDepartureAttempt(faction, at)
    return Factions.UpdateMobileGroup(
        faction.id,
        { lastDepartureAt = at },
        "mobile_settlement_departure_roll"
    )
end

function Director.PumpDepartures(at, budget)
    if not H.Authority() then return 0 end
    at = H.WorldAge(at)
    budget = math.max(1, math.floor(tonumber(budget) or 12))
    local moved = 0
    local day = H.DepartureDay(at)
    local dayStart = day * 24
    local chance = H.DepartureChance()
    local factionIDs = {}
    for factionID, faction in pairs(
        Factions.Registry and Factions.Registry.byID or {}
    ) do
        if faction.status == "active" and Factions.IsMobileGroup(faction)
            and H.IsStreetRoaming(faction)
            and finite(faction.mobile.lastDepartureAt, -1) < dayStart
        then
            factionIDs[#factionIDs + 1] = factionID
        end
    end
    table.sort(factionIDs)
    for _, factionID in ipairs(factionIDs) do
        local faction = Factions.Get(factionID)
        if faction and H.IsStreetRoaming(faction) then
            local roll = H.DailyDepartureRoll(factionID, day)
            if roll < chance then
                -- A daily departure budget is an execution cap, not a reason
                -- to consume a faction's once-per-day chance. Leave overflow
                -- candidates untouched so later groups are not permanently
                -- starved by sorted iteration order.
                if moved < budget then
                    local target = H.ResolveSettlementDepartureTarget(faction)
                    local ok = target
                        and Director.StartSettlementTravel(
                            factionID, target, at
                        ) or false
                    if ok then moved = moved + 1 end
                    if not ok then markDepartureAttempt(faction, at) end
                end
            else
                markDepartureAttempt(faction, at)
            end
        end
    end
    return moved
end

return Director
