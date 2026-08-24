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
local registryRecord = Internal.registryRecord
local npcRecord = Internal.npcRecord
local touchCommunity = Internal.touchCommunity
local touchRegistry = Internal.touchRegistry
local commitAffiliation = Internal.commitAffiliation
local affiliationWithCommunity = Internal.affiliationWithCommunity
local publicCommunity = Internal.publicCommunity

function Communities.SetLeader(
    communityID,
    npcID,
    worldAgeHours
)
    local community
    local record
    if not authority() then return false, "not_authority" end
    Communities.EnsureLoaded()
    community = registryRecord(communityID)
    if not community then return false, "community_not_found" end
    if npcID == nil then
        if community.leaderNPCID == nil then
            return false, "unchanged"
        end
        local oldLeader = PNC.Registry.Get(
            community.leaderNPCID
        )
        if oldLeader and oldLeader.affiliation
            and oldLeader.affiliation.communityID
                == communityID
            and oldLeader.affiliation.communityRole
                == "leader"
        then
            commitAffiliation(
                oldLeader,
                affiliationWithCommunity(
                    oldLeader,
                    communityID,
                    "resident",
                    oldLeader.affiliation.communityJoinedAt
                )
            )
        end
        community.leaderNPCID = nil
        touchCommunity(community)
        touchRegistry()
        return true, "leader_cleared", publicCommunity(community)
    end
    record = npcRecord(npcID, false)
    if not record then return false, "npc_not_found" end
    if not record.affiliation
        or record.affiliation.communityID ~= communityID
        or community.memberIDs[npcID] ~= true
    then
        return false, "leader_not_member"
    end
    if community.leaderNPCID == npcID
        and record.affiliation.communityRole == "leader"
    then
        return false, "unchanged"
    end
    local oldLeader = community.leaderNPCID
        and PNC.Registry.Get(community.leaderNPCID)
        or nil
    if oldLeader and oldLeader.affiliation
        and oldLeader.affiliation.communityID == communityID
        and oldLeader.affiliation.communityRole == "leader"
    then
        commitAffiliation(
            oldLeader,
            affiliationWithCommunity(
                oldLeader,
                communityID,
                "resident",
                oldLeader.affiliation.communityJoinedAt
            )
        )
    end
    community.leaderNPCID = npcID
    if record.affiliation.communityRole ~= "leader" then
        commitAffiliation(
            record,
            affiliationWithCommunity(
                record,
                communityID,
                "leader",
                record.affiliation.communityJoinedAt
            )
        )
    end
    touchCommunity(community)
    touchRegistry()
    return true, "leader_set", publicCommunity(community)
end


return Communities
