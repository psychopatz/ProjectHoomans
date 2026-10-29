if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

-- Settlement arrival orchestration for AI and player colonies.
local Service = PNC.MobileSettlementVisitService
local Internal = Service.Internal
local copy = Internal.copy
local hasEntries = Internal.hasEntries
local worldAge = Internal.worldAge
local clearPendingSettlementArrival = Internal.clearPendingSettlementArrival
local deterministicRoll = Internal.deterministicRoll
local aiJoinChance = Internal.aiJoinChance
local memberIDs = Internal.memberIDs
local admitNPC = Internal.admitNPC
local reconcileGroup = Internal.reconcileGroup
local sourceStillHasMembers = Internal.sourceStillHasMembers
local Constants = Internal.Constants
local Config = Internal.Config
local Factions = Internal.Factions
local Communities = Internal.Communities

function Service.OnSettlementArrival(factionOrID, target, travel, at, group, reports)
    local faction = type(factionOrID) == "table" and factionOrID
        or Factions.Get(factionOrID)
    local eligible
    local reason
    local community
    local destination
    local ids
    local visit
    local joined = 0
    local lastAdmissionReason
    local joinChance = 0
    local temporaryVisit
    local visitKind
    local visitIntent
    local visitID
    local currentVisit
    local updated
    local updatedReason
    local updatedMobile
    if type(travel) ~= "table"
        or travel.kind ~= Constants.MOBILE_TRAVEL_SETTLEMENT
    then
        return false, "not_settlement_travel"
    end
    if type(reports) == "table" and #reports > 0 then
        local deferred, deferReason = Service.DeferSettlementArrival(
            faction,
            target,
            travel,
            at,
            reports
        )
        if not deferred then return false, deferReason end
        return false, "encounter_pending"
    end
    if faction and faction.mobile
        and faction.mobile.pendingSettlementArrival
    then
        local cleared, clearReason = clearPendingSettlementArrival(
            faction.id,
            "mobile_settlement_arrival_resolved"
        )
        if not cleared then return false, clearReason end
    end
    if travel.purpose == Constants.MOBILE_TRAVEL_PURPOSE_HOSTILE_CONTACT then
        return false, "hostile_contact_travel"
    end
    temporaryVisit = travel.purpose
        == Constants.MOBILE_TRAVEL_PURPOSE_SETTLEMENT_VISIT
    visitKind = temporaryVisit and "settlement_visit"
        or "settlement_admission"
    visitIntent = temporaryVisit
        and Service.NormalizeSettlementVisitIntent(travel.intent)
        or nil
    visitID = tostring(faction and faction.id or "") .. ":"
        .. tostring(visitKind) .. ":"
        .. tostring(travel.revision or 0)
    currentVisit = faction and faction.mobile and faction.mobile.visit or nil
    if temporaryVisit and currentVisit
        and tostring(currentVisit.id or "") == visitID
        and Service.IsVisitActive(currentVisit, at)
    then
        return true, "duplicate_settlement_visit", currentVisit
    end
    eligible, reason, community, destination =
        Service.IsSettlementVisitEligible(faction, target, at)
    if not eligible then return false, reason end

    -- The arrival is now accepted by the Hoomans-owned lifecycle. Notify
    -- observers before any optional admission transfer; the source faction,
    -- target community, and travel revision are the stable context that
    -- downstream systems need, while Hoomans retains all movement authority.
    Service.NotifySettlementArrival({
        faction = copy(faction),
        target = copy(target),
        travel = copy(travel),
        at = worldAge(at),
        group = copy(group),
        reports = copy(reports),
        community = copy(community),
        destination = copy(destination),
        visitKind = visitKind,
        visitIntent = visitIntent,
    })

    ids = memberIDs(faction, group)
    if temporaryVisit then
        visit = {
            active = true,
            id = visitID,
            kind = visitKind,
            intent = visitIntent,
            settlementFactionID = destination.id,
            communityID = community.id,
            siteID = target.siteID,
            locationID = target.locationID,
            startedAt = worldAge(at),
            expiresAt = worldAge(at)
                + (tonumber(Config.MOBILE_SETTLEMENT_VISIT_HOURS) or 12),
            pendingMemberIDs = {},
            completedMemberIDs = {},
            revision = 1,
        }
        for _, npcID in ipairs(ids) do
            local record = PNC.Registry and PNC.Registry.Get
                and PNC.Registry.Get(npcID) or nil
            if record and record.alive ~= false
                and not (record.hostility
                    and record.hostility.attackPlayers == true)
            then
                visit.pendingMemberIDs[npcID] = true
            end
        end
        if not hasEntries(visit.pendingMemberIDs) then
            return false, "no_settlement_visit_members"
        end
        updated, updatedReason, updatedMobile = Factions.UpdateMobileGroup(
            faction.id,
            { visit = visit },
            "mobile_settlement_visit_started"
        )
        if not updated then return false, updatedReason end
        Service.RecordSettlementVisit(
            faction,
            travel.destination or target,
            at
        )
        return true, "settlement_visit_started", updatedMobile
    end
    if target.kind == "ai_settlement" then
        joinChance = aiJoinChance()
        for _, npcID in ipairs(ids) do
            if deterministicRoll(
                faction.id,
                npcID,
                travel.revision
            ) < joinChance
            then
                local ok, admissionReason = admitNPC(
                    faction,
                    destination,
                    community,
                    npcID,
                    at
                )
                if ok then joined = joined + 1 end
                if not ok then lastAdmissionReason = admissionReason end
            end
        end
        if joined > 0 then
            reconcileGroup(faction.id,
                "mobile_settlement_ai_admission_completed")
            if not sourceStillHasMembers(faction.id)
                and Factions.ClearMobileGroup
            then
                Factions.ClearMobileGroup(
                    faction.id,
                    "mobile_settlement_ai_admission_completed"
                )
            end
        end
        return joined > 0, joined > 0 and "ai_members_admitted"
            or lastAdmissionReason or "ai_admission_roll_failed", joined
    end
    visit = {
        active = true,
        id = visitID,
        kind = visitKind,
        settlementFactionID = destination.id,
        communityID = community.id,
        siteID = target.siteID,
        locationID = target.locationID,
        startedAt = worldAge(at),
        expiresAt = worldAge(at)
            + (tonumber(Config.MOBILE_SETTLEMENT_VISIT_HOURS) or 12),
        pendingMemberIDs = {},
        completedMemberIDs = {},
        revision = 1,
    }
    for _, npcID in ipairs(ids) do
        local record = PNC.Registry and PNC.Registry.Get
            and PNC.Registry.Get(npcID) or nil
        if record and record.alive ~= false
            and not (record.hostility
                and record.hostility.attackPlayers == true)
        then
            visit.pendingMemberIDs[npcID] = true
        end
    end
    if not hasEntries(visit.pendingMemberIDs) then
        return false, "no_admission_members"
    end
    updated, updatedReason, updatedMobile = Factions.UpdateMobileGroup(
        faction.id,
        { visit = visit },
        "mobile_settlement_visit_started"
    )
    if not updated then return false, updatedReason end
    Service.RecordSettlementVisit(
        faction,
        travel.destination or target,
        at
    )
    return true, "settlement_visit_started", updatedMobile
end

return Service
