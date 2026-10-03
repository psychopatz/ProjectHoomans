if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

-- Deferred settlement-arrival handoff and visit expiry.
local Service = PNC.MobileSettlementVisitService
local Internal = Service.Internal
local copy = Internal.copy
local worldAge = Internal.worldAge
local factionIDFor = Internal.factionIDFor
local Constants = Internal.Constants
local Factions = Internal.Factions
local Store = Internal.Store

local function clearVisit(factionID, reason)
    if not Factions or not Factions.SetMobileGroup then
        return false, "mobile_service_unavailable"
    end
    local mobile = Factions.GetMobileGroup
        and Factions.GetMobileGroup(factionID) or nil
    if not mobile then return false, "mobile_group_missing" end
    mobile.visit = nil
    return Factions.SetMobileGroup(
        factionID,
        mobile,
        reason or "mobile_settlement_visit_expired"
    )
end

local function clearPendingSettlementArrival(factionID, reason)
    if not Factions or not Factions.SetMobileGroup then
        return false, "mobile_service_unavailable"
    end
    local mobile = Factions.GetMobileGroup
        and Factions.GetMobileGroup(factionID) or nil
    if not mobile then return false, "mobile_group_missing" end
    if not mobile.pendingSettlementArrival then
        return true, "unchanged"
    end
    mobile.pendingSettlementArrival = nil
    return Factions.SetMobileGroup(
        factionID,
        mobile,
        reason or "mobile_settlement_arrival_resolved"
    )
end

function Service.DeferSettlementArrival(
    factionOrID,
    target,
    travel,
    at,
    reports
)
    local faction = type(factionOrID) == "table" and factionOrID
        or Factions.Get(factionOrID)
    local mobile = faction and Factions.GetMobileGroup
        and Factions.GetMobileGroup(faction.id) or nil
    local pending = {
        schemaVersion = Constants.MOBILE_SETTLEMENT_ARRIVAL_SCHEMA_VERSION,
        travel = copy(travel),
        locationID = target and target.id or target and target.locationID,
        reportIDs = {},
        startedAt = worldAge(at),
    }
    if not faction or not mobile or type(travel) ~= "table"
        or type(pending.travel) ~= "table"
        or not pending.travel.destination
        or not pending.locationID
    then
        return false, "settlement_arrival_state_unavailable"
    end
    for _, report in ipairs(type(reports) == "table" and reports or {}) do
        if report and report.id then
            pending.reportIDs[tostring(report.id)] = true
        end
    end
    mobile.pendingSettlementArrival = pending
    return Factions.SetMobileGroup(
        faction.id,
        mobile,
        "mobile_settlement_encounter_pending"
    )
end

local function pendingReportsOpen(pending)
    local encounters = Store and Store.Registry
        and Store.Registry.encounters or {}
    for reportID, present in pairs(pending and pending.reportIDs or {}) do
        if present == true then
            for _, report in ipairs(encounters) do
                if tostring(report.id or "") == tostring(reportID)
                    and (report.outcome == nil
                        or report.outcome == "QUEUED"
                        or report.outcome == "MATERIALIZATION_REQUIRED")
                then
                    return true
                end
            end
        end
    end
    return false
end

function Service.PumpPendingArrivals(at, budget)
    local count = 0
    at = worldAge(at)
    budget = math.floor(tonumber(budget) or 12)
    if budget <= 0 then return 0 end
    for factionID, faction in pairs(
        Factions and Factions.Registry and Factions.Registry.byID or {}
    ) do
        if count >= budget then break end
        local pending = faction.status == "active"
            and faction.mobile
            and faction.mobile.pendingSettlementArrival or nil
        if pending and not pendingReportsOpen(pending) then
            local groups = PNC.AbstractGroups
            local group = groups and groups.FindByFactionID
                and groups.FindByFactionID(factionID) or nil
            local locationID = group and group.location
                and group.location.id or nil
            if not group or tostring(locationID or "")
                ~= tostring(pending.locationID or "")
            then
                clearPendingSettlementArrival(
                    factionID,
                    "mobile_settlement_arrival_location_changed"
                )
                count = count + 1
            else
                local ok, reason = Service.OnSettlementArrival(
                    faction,
                    pending.travel.destination,
                    pending.travel,
                    at,
                    group,
                    {}
                )
                if ok or reason ~= "encounter_pending" then
                    count = count + 1
                end
            end
        end
    end
    return count
end

function Service.ExpireFaction(factionOrID, at)
    local faction = type(factionOrID) == "table" and factionOrID
        or Factions and Factions.Get and Factions.Get(factionOrID)
    if not faction or not faction.mobile or not faction.mobile.visit then
        return false, "no_visit"
    end
    if Service.IsVisitActive(faction.mobile.visit, at) then
        return false, "active"
    end
    return clearVisit(faction.id, "mobile_settlement_visit_expired")
end

function Service.ExpireVisits(at, budget)
    local count = 0
    budget = math.max(1, math.floor(tonumber(budget) or 12))
    for factionID, faction in pairs(
        Factions and Factions.Registry and Factions.Registry.byID or {}
    ) do
        if count >= budget then break end
        if faction.status == "active" and faction.mobile
            and faction.mobile.visit
            and not Service.IsVisitActive(faction.mobile.visit, at)
        then
            if Service.ExpireFaction(factionID, at) then count = count + 1 end
        end
    end
    return count
end

function Service.GetNPCVisit(npcID, player, at)
    local record = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(tostring(npcID or "")) or nil
    local factionID = factionIDFor(record)
    local faction = factionID and Factions and Factions.Get
        and Factions.Get(factionID) or nil
    local visit = faction and faction.mobile and faction.mobile.visit or nil
    local playerFaction
    if not record or record.alive == false or not faction
        or not Service.IsVisitActive(visit, at)
    then
        if faction and visit then Service.ExpireFaction(faction, at) end
        return nil
    end
    if visit.pendingMemberIDs[tostring(record.id)] ~= true then return nil end
    if record.hostility and record.hostility.attackPlayers == true then
        return nil
    end
    playerFaction = Factions.GetPlayerFaction
        and Factions.GetPlayerFaction(player) or nil
    if not playerFaction
        or tostring(playerFaction.id) ~= tostring(visit.settlementFactionID)
    then
        return nil
    end
    return {
        active = true,
        kind = "settlement_admission",
        visitID = visit.id,
        communityID = visit.communityID,
        settlementFactionID = visit.settlementFactionID,
        startedAt = visit.startedAt,
        expiresAt = visit.expiresAt,
        revision = visit.revision,
    }
end


Internal.clearVisit = clearVisit
Internal.clearPendingSettlementArrival = clearPendingSettlementArrival
Internal.pendingReportsOpen = pendingReportsOpen

return Service
