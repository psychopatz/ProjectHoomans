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
function Internal.updateAffiliationField(npcID, field, value)
    local record = Internal.npcRecord(npcID, false)
    if not record then return false, "npc_not_found" end
    local affiliation = Types.NormalizeAffiliation(record.affiliation)
    local faction = affiliation.factionID
        and Internal.registryRecord(affiliation.factionID) or nil
    if not faction then return false, "unaffiliated" end
    local nextAffiliation = Types.NormalizeAffiliation(
        affiliation,
        faction
    )
    nextAffiliation[field] = value
    nextAffiliation = Types.NormalizeAffiliation(
        nextAffiliation,
        faction
    )
    if Types.AreEqual(affiliation, nextAffiliation) then
        return false, "unchanged"
    end
    Internal.commitAffiliation(record, nextAffiliation)
    Internal.touchFaction(faction)
    Internal.touchRegistry()
    return true, "updated", Internal.copy(nextAffiliation)
end

function Factions.SetNPCStatus(npcID, membershipStatus)
    if not Internal.authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    membershipStatus =
        Internal.normalizeMembershipStatus(membershipStatus)
    if not membershipStatus then
        return false, "invalid_membership_status"
    end
    return Internal.updateAffiliationField(
        npcID,
        "membershipStatus",
        membershipStatus
    )
end

function Factions.SetNPCRole(npcID, role)
    if not Internal.authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    local affiliation = Factions.GetNPCAffiliation(npcID)
    local faction = affiliation and affiliation.factionID
        and Internal.registryRecord(affiliation.factionID) or nil
    if not faction then return false, "unaffiliated" end
    role = Internal.normalizeRole(faction, role)
    if not role then return false, "role_not_allowed" end
    local ok, reason, result = Internal.updateAffiliationField(npcID, "role", role)
    if ok and PNC.ProvisionScheduler then
        PNC.ProvisionScheduler.MarkAllDirty(npcID)
    end
    return ok, reason, result
end

function Factions.SetNPCRank(npcID, rank)
    if not Internal.authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    rank = Internal.normalizeRank(rank)
    if not rank then return false, "invalid_rank" end
    return Internal.updateAffiliationField(npcID, "rank", rank)
end

function Factions.SetLeader(
    factionID,
    npcID,
    worldAgeHours,
    options
)
    local faction
    local record
    local affiliation
    local oldRecord
    local oldAffiliation
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
    at = Internal.finiteTimestamp(worldAgeHours, 0)
    if affiliation.factionID ~= factionID then
        if options.addIfMissing ~= true then
            return false, "leader_not_member"
        end
        if affiliation.factionID then
            return false, "npc_already_affiliated"
        end
        affiliation = Types.NormalizeAffiliation({
            factionID = factionID,
            membershipStatus = "member",
            role = "leader",
            rank = "leader",
            joinedAt = at,
            originArchetypeID = faction.archetypeID,
            formerFactionIDs =
                affiliation.formerFactionIDs,
            revision = affiliation.revision,
        }, faction)
        faction.memberIDs[npcID] = true
    else
        affiliation = Types.NormalizeAffiliation(
            affiliation,
            faction
        )
        affiliation.role = "leader"
        affiliation.rank = "leader"
    end
    if faction.leaderNPCID
        and faction.leaderNPCID ~= npcID
    then
        oldRecord = PNC.Registry.Get(faction.leaderNPCID)
        if oldRecord then
            oldAffiliation = Internal.affiliationFor(oldRecord, faction)
            oldAffiliation.rank = "member"
            if oldAffiliation.role == "leader" then
                oldAffiliation.role =
                    Archetypes.GetDefaultRole(
                        faction.archetypeID
                    )
            end
            Internal.commitAffiliation(oldRecord, oldAffiliation)
        end
    end
    if faction.leaderNPCID == npcID
        and record.affiliation
        and record.affiliation.role == "leader"
        and record.affiliation.rank == "leader"
    then
        return false, "unchanged"
    end
    faction.leaderNPCID = npcID
    Internal.commitAffiliation(record, affiliation)
    Internal.touchFaction(faction)
    Internal.touchRegistry()
    return true, "leader_set", Internal.copy(faction)
end

return Factions
