if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Communities = PNC.Communities or {}
PNC.Communities.Internal = PNC.Communities.Internal or {}

local Communities = PNC.Communities
local Internal = Communities.Internal
local Core = PNC.Core
local Constants = PNC.CommunityConstants
local Types = PNC.CommunityTypes
local CommunityMath = PNC.CommunityMath
local FactionTypes = PNC.FactionTypes
local authority = Internal.authority
local worldAge = Internal.worldAge
local currentWorldAgeHours = Internal.currentWorldAgeHours
local registryRecord = Internal.registryRecord
local npcRecord = Internal.npcRecord
local factionHasPlayerMembers = Internal.factionHasPlayerMembers
local touchCommunity = Internal.touchCommunity
local touchRegistry = Internal.touchRegistry
local commitAffiliation = Internal.commitAffiliation
local clearAffiliationCommunity = Internal.clearAffiliationCommunity
local population = Internal.population
local publicCommunity = Internal.publicCommunity
local releaseSiteOccupancy = Internal.releaseSiteOccupancy
local clearMembers = Internal.clearMembers

local function retireCommunity(
    community,
    status,
    reason,
    at
)
    clearMembers(community)
    releaseSiteOccupancy(community, at)
    community.mode = status == "destroyed"
        and "destroyed" or "abandoned"
    community.status = status
    if status == "destroyed" then
        community.destroyedAt = at
        community.destroyReason = tostring(
            reason or "destroyed"
        )
    else
        community.archivedAt = at
        community.archiveReason = tostring(
            reason or "archived"
        )
    end
    touchCommunity(community)
    touchRegistry()
end

function Communities.Archive(
    communityID,
    reason,
    worldAgeHours
)
    if not authority() then return false, "not_authority" end
    Communities.EnsureLoaded()
    local community = registryRecord(communityID)
    if not community then return false, "community_not_found" end
    if community.status == "archived" then
        return false, "already_archived"
    end
    if community.status == "destroyed" then
        return false, "community_destroyed"
    end
    retireCommunity(
        community,
        "archived",
        reason,
        worldAge(worldAgeHours, community.createdAt)
    )
    return true, "archived", publicCommunity(community)
end

function Communities.Destroy(
    communityID,
    reason,
    worldAgeHours
)
    if not authority() then return false, "not_authority" end
    Communities.EnsureLoaded()
    local community = registryRecord(communityID)
    if not community then return false, "community_not_found" end
    if community.status == "destroyed" then
        return false, "already_destroyed"
    end
    if PNC.PopulationDirector and PNC.PopulationDirector.OnSettlementDestroyed then
        PNC.PopulationDirector.OnSettlementDestroyed(
            publicCommunity(community), reason,
            worldAge(worldAgeHours, community.createdAt))
    end
    retireCommunity(
        community,
        "destroyed",
        reason,
        worldAge(worldAgeHours, community.createdAt)
    )
    return true, "destroyed", publicCommunity(community)
end

-- Called immediately before a faction service replaces the affiliation.
-- It updates only the derived community index, avoiding a second NPC commit.
function Communities.OnFactionMembershipChanging(record)
    if not authority() or type(record) ~= "table" then
        return false, "invalid_record"
    end
    Communities.EnsureLoaded()
    local communityID = record.affiliation
        and record.affiliation.communityID or nil
    local community = communityID
        and registryRecord(communityID) or nil
    if not community then return false, "no_community" end
    community.memberIDs[record.id] = nil
    if community.leaderNPCID == record.id then
        community.leaderNPCID = nil
    end
    touchCommunity(community)
    touchRegistry()
    return true, "community_detached"
end

function Communities.OnFactionArchived(
    factionID,
    worldAgeHours
)
    local changed = false
    Communities.EnsureLoaded()
    local communities = Communities.GetForFaction(factionID)
    for _, community in ipairs(communities) do
        if community.status ~= "archived"
            and community.status ~= "destroyed"
        then
            Communities.Archive(
                community.id,
                "faction_archived",
                worldAgeHours
            )
            changed = true
        end
    end
    return changed
end

function Communities.OnFactionDestroyed(
    factionID,
    worldAgeHours
)
    local changed = false
    Communities.EnsureLoaded()
    local communities = Communities.GetForFaction(factionID)
    for _, community in ipairs(communities) do
        if community.status ~= "destroyed" then
            Communities.Destroy(
                community.id,
                "faction_destroyed",
                worldAgeHours
            )
            changed = true
        end
    end
    return changed
end

function Communities.OnNPCDeath(npcID)
    if not authority() then return false, "not_authority" end
    Communities.EnsureLoaded()
    local record = npcRecord(npcID, true)
    if not record then return false, "npc_not_found" end
    local communityID = record.affiliation
        and record.affiliation.communityID or nil
    if not communityID then return false, "no_community" end
    local community = registryRecord(communityID)
    if not community then
        commitAffiliation(record, clearAffiliationCommunity(record))
        return true, "invalid_reference_cleared"
    end
    community.memberIDs[npcID] = nil
    if community.leaderNPCID == npcID then
        community.leaderNPCID = nil
    end
    commitAffiliation(record, clearAffiliationCommunity(record))
    if community.status == "active"
        and population(community) <= 0
        and not factionHasPlayerMembers(
            community.factionID
        )
    then
        retireCommunity(
            community,
            "destroyed",
            "population_wiped_out",
            currentWorldAgeHours()
        )
        return true, "community_wiped_out"
    end
    touchCommunity(community)
    touchRegistry()
    return true, "death_reconciled"
end


return Communities
