if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

local Factions = PNC.Factions
local Internal = Factions.Internal
local Core = PNC.Core
local Constants = PNC.FactionConstants
local Types = PNC.FactionTypes
local Archetypes = PNC.FactionArchetypes
local EntityRef = PNC.EntityRef
function Factions.AddNPC(factionID, npcID, options)
    local faction
    local record
    local affiliation
    local role
    local rank
    local membershipStatus
    local at
    if not Internal.authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    options = type(options) == "table" and options or {}
    faction = Internal.registryRecord(factionID)
    if not faction then return false, "faction_not_found" end
    if faction.status ~= "active" then
        return false, "faction_not_active"
    end
    record = Internal.npcRecord(npcID, false)
    if not record then return false, "npc_not_found" end
    affiliation = Internal.affiliationFor(record)
    if affiliation.factionID
        and affiliation.factionID ~= factionID
    then
        return false, "npc_already_affiliated"
    end
    role = Internal.normalizeRole(faction, options.role)
    if not role then return false, "role_not_allowed" end
    rank = Internal.normalizeRank(options.rank)
    if not rank then return false, "invalid_rank" end
    membershipStatus =
        Internal.normalizeMembershipStatus(options.membershipStatus)
    if not membershipStatus then
        return false, "invalid_membership_status"
    end
    at = Internal.finiteTimestamp(options.joinedAt, 0)
    local nextAffiliation = Types.NormalizeAffiliation({
        factionID = factionID,
        membershipStatus = membershipStatus,
        role = role,
        rank = rank,
        joinedAt = affiliation.factionID
            and affiliation.joinedAt or at,
        originArchetypeID = affiliation.originArchetypeID
            or faction.archetypeID,
        communityID = affiliation.factionID == factionID
            and affiliation.communityID or nil,
        communityRole = affiliation.factionID == factionID
            and affiliation.communityRole or "resident",
        communityJoinedAt = affiliation.factionID == factionID
            and affiliation.communityJoinedAt or 0,
        formerFactionIDs = affiliation.formerFactionIDs,
        revision = affiliation.revision,
    }, faction)
    if Types.AreEqual(affiliation, nextAffiliation)
        and faction.memberIDs[npcID] == true
    then
        return false, "unchanged"
    end
    faction.memberIDs[npcID] = true
    Internal.commitAffiliation(record, nextAffiliation)
    Internal.touchFaction(faction)
    Internal.touchRegistry()
    if PNC.FactionBehavior
        and PNC.FactionBehavior.ApplyNPC
    then
        PNC.FactionBehavior.ApplyNPC(record, "faction_joined")
    end
    if PNC.ProvisionScheduler then
        PNC.ProvisionScheduler.MarkAllDirty(record)
    end
    return true, "added", Internal.copy(nextAffiliation)
end

function Factions.RemoveNPC(
    factionID,
    npcID,
    reason,
    worldAgeHours
)
    local faction
    local record
    local affiliation
    local former
    if not Internal.authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    faction = Internal.registryRecord(factionID)
    if not faction then return false, "faction_not_found" end
    record = Internal.npcRecord(npcID, true)
    if not record then return false, "npc_not_found" end
    affiliation = Internal.affiliationFor(record, faction)
    if affiliation.factionID ~= factionID then
        return false, "not_a_member"
    end
    reason = Constants.VALID_LEAVE_REASONS[reason]
        and reason or "unknown"
    former = Internal.addHistory(
        affiliation,
        factionID,
        Internal.finiteTimestamp(worldAgeHours, affiliation.joinedAt),
        reason
    )
    local nextAffiliation = Types.NewAffiliation({
        leftAt = Internal.finiteTimestamp(
            worldAgeHours,
            affiliation.joinedAt
        ),
        originArchetypeID = affiliation.originArchetypeID,
        formerFactionIDs = former,
        revision = affiliation.revision,
    })
    if PNC.Communities
        and PNC.Communities.OnFactionMembershipChanging
    then
        PNC.Communities.OnFactionMembershipChanging(record)
    end
    faction.memberIDs[npcID] = nil
    if PNC.ProvisionScheduler then
        PNC.ProvisionScheduler.CancelNPC(record)
    end
    if faction.leaderNPCID == npcID then
        faction.leaderNPCID = nil
    end
    Internal.commitAffiliation(record, nextAffiliation)
    Internal.touchFaction(faction)
    Internal.touchRegistry()
    if PNC.FactionBehavior
        and PNC.FactionBehavior.ApplyUnaffiliated
    then
        PNC.FactionBehavior.ApplyUnaffiliated(
            record,
            "faction_removed"
        )
    end
    if PNC.FactionLeadership
        and PNC.FactionLeadership.OnMemberDeparture
    then
        PNC.FactionLeadership.OnMemberDeparture(
            factionID,
            "member_removed",
            worldAgeHours
        )
    end
    return true, "removed", Internal.copy(nextAffiliation)
end

function Factions.TransferNPC(npcID, destinationFactionID, options)
    local destination
    local source
    local record
    local affiliation
    local former
    local role
    local rank
    local membershipStatus
    local at
    if not Internal.authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    options = type(options) == "table" and options or {}
    destination = Internal.registryRecord(destinationFactionID)
    if not destination then return false, "faction_not_found" end
    if destination.status ~= "active" then
        return false, "faction_not_active"
    end
    record = Internal.npcRecord(npcID, false)
    if not record then return false, "npc_not_found" end
    affiliation = Internal.affiliationFor(record)
    if affiliation.factionID == destinationFactionID then
        return false, "already_a_member"
    end
    source = affiliation.factionID
        and Internal.registryRecord(affiliation.factionID) or nil
    role = Internal.normalizeRole(destination, options.role)
    if not role then return false, "role_not_allowed" end
    rank = Internal.normalizeRank(options.rank)
    if not rank then return false, "invalid_rank" end
    membershipStatus =
        Internal.normalizeMembershipStatus(options.membershipStatus)
    if not membershipStatus then
        return false, "invalid_membership_status"
    end
    at = Internal.finiteTimestamp(options.worldAgeHours, 0)
    former = affiliation.formerFactionIDs
    if source then
        if PNC.Communities
            and PNC.Communities.OnFactionMembershipChanging
        then
            PNC.Communities.OnFactionMembershipChanging(record)
        end
        former = Internal.addHistory(
            affiliation,
            source.id,
            at,
            "transferred"
        )
        source.memberIDs[npcID] = nil
        if source.leaderNPCID == npcID then
            source.leaderNPCID = nil
        end
        Internal.touchFaction(source)
    end
    local nextAffiliation = Types.NormalizeAffiliation({
        factionID = destination.id,
        membershipStatus = membershipStatus,
        role = role,
        rank = rank,
        joinedAt = at,
        originArchetypeID = affiliation.originArchetypeID
            or destination.archetypeID,
        formerFactionIDs = former,
        revision = affiliation.revision,
    }, destination)
    destination.memberIDs[npcID] = true
    Internal.commitAffiliation(record, nextAffiliation)
    Internal.touchFaction(destination)
    Internal.touchRegistry()
    if PNC.FactionBehavior
        and PNC.FactionBehavior.ApplyNPC
    then
        PNC.FactionBehavior.ApplyNPC(
            record,
            "faction_transferred"
        )
    end
    if source and PNC.FactionLeadership
        and PNC.FactionLeadership.OnMemberDeparture
    then
        PNC.FactionLeadership.OnMemberDeparture(
            source.id,
            "member_transferred",
            at
        )
    end
    if PNC.ProvisionScheduler then
        PNC.ProvisionScheduler.CancelNPC(record)
        PNC.ProvisionScheduler.MarkAllDirty(record)
    end
    return true, "transferred", Internal.copy(nextAffiliation)
end

return Factions
