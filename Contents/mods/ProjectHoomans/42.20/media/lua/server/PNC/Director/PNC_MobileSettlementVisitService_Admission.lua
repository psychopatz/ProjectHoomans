if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

-- Member admission transfer, rollback, and player admission.
local Service = PNC.MobileSettlementVisitService
local Internal = Service.Internal
local copy = Internal.copy
local hasEntries = Internal.hasEntries
local worldAge = Internal.worldAge
local factionIDFor = Internal.factionIDFor
local isHostileToSettlement = Internal.isHostileToSettlement
local clearVisit = Internal.clearVisit
local Constants = Internal.Constants
local Config = Internal.Config
local Factions = Internal.Factions
local Communities = Internal.Communities

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


Internal.deterministicRoll = deterministicRoll
Internal.aiJoinChance = aiJoinChance
Internal.memberIDs = memberIDs
Internal.admitNPC = admitNPC
Internal.reconcileGroup = reconcileGroup
Internal.sourceStillHasMembers = sourceStillHasMembers

return Service
