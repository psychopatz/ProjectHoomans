-- Settlement arrival admission policy for eligible mobile groups.
-- Hostile groups may use the deferred arrival handoff, but never enter the
-- admission path; the existing encounter system remains authoritative.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.MobileSettlementVisitService = PNC.MobileSettlementVisitService or {}

local Service = PNC.MobileSettlementVisitService
local Constants = PNC.FactionConstants
local Config = PNC.DirectorConfig
local Factions = PNC.Factions
local Communities = PNC.Communities
local Store = PNC.AbstractWorldStore

local function copy(value)
    return PNC.Core and PNC.Core.DeepCopy and PNC.Core.DeepCopy(value)
        or value
end

local function hasEntries(value)
    for _, present in pairs(type(value) == "table" and value or {}) do
        if present == true then return true end
    end
    return false
end

local function worldAge(value)
    value = tonumber(value)
    if value and value == value
        and value ~= math.huge and value ~= -math.huge
    then
        return math.max(0, value)
    end
    local time = getGameTime and getGameTime() or nil
    return time and time.getWorldAgeHours
        and math.max(0, tonumber(time:getWorldAgeHours()) or 0) or 0
end

local function factionIDFor(record)
    if not record then return nil end
    if Factions and Factions.GetFactionID then
        return Factions.GetFactionID(record)
    end
    return record.affiliation and record.affiliation.factionID or nil
end

local function targetCommunity(target)
    local community
    local base
    if not target then return nil, "settlement_target_missing" end
    if target.communityID and Communities and Communities.Get then
        community = Communities.Get(target.communityID)
        if community then return community end
    end
    if target.baseID and PNC.BaseService and PNC.BaseService.Get then
        base = PNC.BaseService.Get(target.baseID)
        if base and base.colonyId and Communities
            and Communities.Get
        then
            community = Communities.Get(base.colonyId)
            if community then return community end
        end
    end
    return nil, "settlement_community_missing"
end

local function targetFaction(target, community)
    local factionID = target and target.factionID
        or community and community.factionID
    if not factionID or not Factions or not Factions.Get then
        return nil
    end
    return Factions.Get(factionID)
end

local function relationFor(source, destination, at)
    if not source or not destination
        or source.id == destination.id
    then
        return nil, "same_faction"
    end
    local relation = Factions.GetRelation
        and Factions.GetRelation(source.id, destination.id)
        or source.relations and source.relations[destination.id]
    if not relation then return nil, "unknown" end
    local state = relation.state
    if PNC.FactionDiplomacyMath
        and PNC.FactionDiplomacyMath.ResolveState
    then
        state = PNC.FactionDiplomacyMath.ResolveState(relation, at)
    end
    return relation, tostring(state or "unknown")
end

local function relationIsHostile(relation, state)
    return relation and (
        relation.atWar == true
        or state == "war"
        or state == "hostile"
    ) or false
end

local function isHostileToSettlement(source, destination, at)
    if source and source.archetypeID == "looter" then return true end
    local relation, state = relationFor(source, destination, at)
    if relationIsHostile(relation, state) then return true end
    -- Treat either side's explicit war/hostile state as unsafe. This keeps a
    -- stale or asymmetric relation from opening a recruitment visit.
    local reverse, reverseState = relationFor(destination, source, at)
    return relationIsHostile(reverse, reverseState)
end

local function hasPlayerMembers(faction)
    if not faction then return false end
    for _, present in pairs(faction.playerMemberKeys or {}) do
        if present == true then return true end
    end
    return faction.ownerPlayerKey ~= nil
        and tostring(faction.ownerPlayerKey) ~= ""
end

function Service.IsAdmissionEligible(factionOrID, target, at)
    local faction = type(factionOrID) == "table" and factionOrID
        or Factions and Factions.Get and Factions.Get(factionOrID)
    local community
    local destination
    if not faction or not faction.mobile
        or faction.mobile.active ~= true
    then
        return false, "not_mobile_group"
    end
    if faction.archetypeID == "looter" then
        return false, "hostile_mobile_group"
    end
    if not target or (target.kind ~= "ai_settlement"
        and target.kind ~= "player_colony")
    then
        return false, "not_admission_target"
    end
    community = targetCommunity(target)
    if not community then return false, "settlement_community_missing" end
    destination = targetFaction(target, community)
    if not destination or destination.status ~= "active" then
        return false, "settlement_faction_missing"
    end
    if target.kind == "player_colony"
        and not hasPlayerMembers(destination)
    then
        return false, "player_settlement_owner_missing"
    end
    if tostring(community.factionID or "") ~= tostring(destination.id) then
        return false, "settlement_faction_mismatch"
    end
    if isHostileToSettlement(faction, destination, worldAge(at)) then
        return false, "hostile_settlement_relationship"
    end
    return true, "eligible", community, destination
end

function Service.IsVisitActive(visit, at)
    return type(visit) == "table"
        and tostring(visit.kind or "") == "settlement_admission"
        and (tonumber(visit.expiresAt) or 0) > worldAge(at)
end

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

local function deterministicRoll(factionID, npcID, revision)
    local token = tostring(factionID or "") .. ":"
        .. tostring(npcID or "") .. ":" .. tostring(revision or 0)
    local hash = 17
    for index = 1, #token do
        hash = (hash * 31 + string.byte(token, index)) % 1000003
    end
    return hash / 1000003
end

local function aiJoinChance()
    local settings = PNC.Sandbox
    local configured
    if settings and settings.MobileSettlementAIJoinChance then
        configured = settings.MobileSettlementAIJoinChance()
    end
    if configured == nil then
        configured = (tonumber(Config.MOBILE_SETTLEMENT_AI_JOIN_CHANCE)
            or 0.35) * 100
    end
    configured = tonumber(configured) or 35
    return math.max(0, math.min(1, configured / 100))
end

local function memberIDs(faction, group)
    local output = {}
    local seen = {}
    local source = group and group.memberIds or nil
    if type(source) ~= "table" then
        source = {}
        for npcID, present in pairs(faction.memberIDs or {}) do
            if present == true then source[#source + 1] = npcID end
        end
    end
    for key, npcID in pairs(source) do
        npcID = type(key) == "number" and npcID or key
        if not seen[npcID] then
            seen[npcID] = true
            output[#output + 1] = tostring(npcID)
        end
    end
    table.sort(output)
    return output
end

local function rollbackTransfer(npcID, sourceID, affiliation, at)
    if not sourceID or not Factions.TransferNPC then return false end
    return Factions.TransferNPC(npcID, sourceID, {
        role = affiliation and affiliation.role,
        rank = affiliation and affiliation.rank,
        membershipStatus = affiliation and affiliation.membershipStatus,
        worldAgeHours = at,
        leaveReason = "transferred",
    })
end

local function reconcileGroup(factionID, reason)
    local groups = PNC.AbstractGroups
    local group = groups and groups.FindByFactionID
        and groups.FindByFactionID(factionID) or nil
    if not group then return false end
    if groups.ReconcileMembers then
        groups.ReconcileMembers(group)
    end
    if #(group.memberIds or {}) == 0 and groups.Remove
        and not (groups.HasLiveMembers and groups.HasLiveMembers(group))
    then
        groups.Remove(group.id, reason or "mobile_group_empty")
    end
    return true
end

local function admitNPC(sourceFaction, destination, community, npcID, at)
    local record = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(npcID) or nil
    local affiliation = record and copy(record.affiliation) or {}
    local sourceID = affiliation.factionID
    local transferred = false
    local ok
    local reason
    if not record or record.alive == false then
        return false, "npc_not_found"
    end
    if sourceID ~= sourceFaction.id then
        return false, "npc_not_in_mobile_group"
    end
    if sourceFaction.id ~= destination.id then
        ok, reason = Factions.TransferNPC(npcID, destination.id, {
            membershipStatus = "member",
            worldAgeHours = at,
            leaveReason = "transferred",
        })
        if not ok then return false, reason end
        transferred = true
    end
    ok, reason = Communities.AddNPC(community.id, npcID, {
        communityRole = "resident",
        joinedAt = at,
        strictCapacity = true,
    })
    if not ok and reason ~= "unchanged" then
        if transferred then rollbackTransfer(npcID, sourceID, affiliation, at) end
        return false, reason
    end
    return true, "admitted"
end

local function sourceStillHasMembers(factionID)
    local faction = Factions.Get(factionID)
    for _, present in pairs(faction and faction.memberIDs or {}) do
        if present == true then return true end
    end
    return false
end

local function finishMemberAdmission(sourceID, visit, npcID, at)
    local current = Factions.Get(sourceID)
    local currentVisit = current and current.mobile and current.mobile.visit
    if not currentVisit then return false, "visit_missing" end
    currentVisit = copy(currentVisit)
    currentVisit.pendingMemberIDs[tostring(npcID)] = nil
    currentVisit.completedMemberIDs[tostring(npcID)] = true
    if not hasEntries(currentVisit.pendingMemberIDs) then
        if not sourceStillHasMembers(sourceID)
            and Factions.ClearMobileGroup
        then
            return Factions.ClearMobileGroup(
                sourceID,
                "mobile_settlement_visit_completed"
            )
        end
        return clearVisit(sourceID, "mobile_settlement_visit_completed")
    end
    currentVisit.revision = (tonumber(currentVisit.revision) or 0) + 1
    return Factions.UpdateMobileGroup(
        sourceID,
        { visit = currentVisit },
        "mobile_settlement_member_admitted"
    )
end

function Service.AdmitPlayer(player, npcID, visitID, at)
    local record = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(tostring(npcID or "")) or nil
    local sourceID = factionIDFor(record)
    local source = sourceID and Factions.Get and Factions.Get(sourceID) or nil
    local visit = source and source.mobile and source.mobile.visit or nil
    local playerFaction = Factions.GetPlayerFaction
        and Factions.GetPlayerFaction(player) or nil
    local community
    local destination
    local ok
    local reason
    at = worldAge(at)
    if not record or not source or not visit then
        return false, "settlement_visit_missing"
    end
    if not Service.IsVisitActive(visit, at) then
        Service.ExpireFaction(source, at)
        return false, "settlement_visit_expired"
    end
    if tostring(visit.id or "") ~= tostring(visitID or "") then
        return false, "settlement_visit_mismatch"
    end
    if visit.pendingMemberIDs[tostring(record.id)] ~= true then
        return false, "npc_not_pending"
    end
    if not playerFaction
        or tostring(playerFaction.id) ~= tostring(visit.settlementFactionID)
    then
        return false, "settlement_owner_required"
    end
    if record.hostility and record.hostility.attackPlayers == true then
        return false, "hostile_audience"
    end
    local groups = PNC.AbstractGroups
    local group = groups and groups.FindByFactionID
        and groups.FindByFactionID(source.id) or nil
    if group and group.location and visit.locationID
        and tostring(group.location.id or "")
            ~= tostring(visit.locationID)
    then
        return false, "settlement_visit_location_changed"
    end
    community = Communities.Get(visit.communityID)
    destination = community and Factions.Get(visit.settlementFactionID)
        or nil
    if not community or not destination then
        return false, "settlement_missing"
    end
    if tostring(community.factionID or "")
        ~= tostring(destination.id or "")
    then
        return false, "settlement_faction_mismatch"
    end
    if isHostileToSettlement(source, destination, at) then
        return false, "hostile_settlement_relationship"
    end
    ok, reason = admitNPC(source, destination, community, record.id, at)
    if not ok then return false, reason end
    reconcileGroup(source.id, "mobile_settlement_member_admitted")
    finishMemberAdmission(source.id, visit, record.id, at)
    return true, "settlement_member_admitted", {
        npcID = record.id,
        communityID = community.id,
        factionID = destination.id,
    }
end

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
    eligible, reason, community, destination =
        Service.IsAdmissionEligible(faction, target, at)
    if not eligible then return false, reason end
    ids = memberIDs(faction, group)
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
        id = tostring(faction.id) .. ":settlement_visit:"
            .. tostring(travel.revision or 0),
        kind = "settlement_admission",
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
    return Factions.UpdateMobileGroup(
        faction.id,
        { visit = visit },
        "mobile_settlement_visit_started"
    )
end

return Service
