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
local touchCommunity = Internal.touchCommunity
local touchSite = Internal.touchSite
local touchRegistry = Internal.touchRegistry
local commitAffiliation = Internal.commitAffiliation

local function rebuildDerivedIndexes()
    local byFaction = {}
    local memberIDs = {}
    local changed = false
    for communityID, community in pairs(
        Communities.Registry.byID
    ) do
        byFaction[community.factionID] =
            byFaction[community.factionID] or {}
        byFaction[community.factionID][communityID] = true
        memberIDs[communityID] = {}
    end
    local occupiedBySite = {}
    for communityID, community in pairs(
        Communities.Registry.byID
    ) do
        if community.status == "active"
            and community.siteID
            and Communities.Registry.sitesByID[
                community.siteID
            ]
        then
            local current = occupiedBySite[community.siteID]
            if not current or communityID < current then
                occupiedBySite[community.siteID] = communityID
            end
        end
    end
    for siteID, site in pairs(
        Communities.Registry.sitesByID
    ) do
        local occupant = site.claimantKey
            and nil or occupiedBySite[siteID]
        local status = site.claimantKey
            and "claimed"
            or occupant and "occupied"
            or "vacant"
        if site.occupantCommunityID ~= occupant
            or site.status ~= status
        then
            site.occupantCommunityID = occupant
            site.status = status
            touchSite(site)
            changed = true
        end
    end
    for npcID, record in pairs(
        PNC.Registry and PNC.Registry.Data or {}
    ) do
        local communityID = record.affiliation
            and record.affiliation.communityID or nil
        local community = communityID
            and Communities.Registry.byID[communityID] or nil
        if community and record.alive ~= false
            and record.affiliation.factionID
                == community.factionID
            and community.status ~= "archived"
            and community.status ~= "destroyed"
        then
            memberIDs[communityID][npcID] = true
        end
    end
    if not Types.AreEqual(
        Communities.Registry.byFaction,
        byFaction
    ) then
        Communities.Registry.byFaction = byFaction
        changed = true
    end
    for communityID, community in pairs(
        Communities.Registry.byID
    ) do
        local expected = memberIDs[communityID] or {}
        if not Types.AreEqual(
            community.memberIDs,
            expected
        ) then
            community.memberIDs = expected
            touchCommunity(community)
            changed = true
        end
    end
    if changed then touchRegistry() end
    return changed
end

local function reconcileLeaders()
    local changed = false
    for _, community in pairs(
        Communities.Registry.byID
    ) do
        local leader = community.leaderNPCID
            and PNC.Registry.Get(community.leaderNPCID)
            or nil
        if community.leaderNPCID
            and (
                not leader
                or leader.alive == false
                or not leader.affiliation
                or leader.affiliation.communityID
                    ~= community.id
                or community.memberIDs[
                    community.leaderNPCID
                ] ~= true
                or community.status == "archived"
                or community.status == "destroyed"
            )
        then
            community.leaderNPCID = nil
            touchCommunity(community)
            changed = true
        end
    end
    if changed then touchRegistry() end
    return changed
end

local function reconcileNPCReferences()
    local changed = false
    for _, record in pairs(
        PNC.Registry and PNC.Registry.Data or {}
    ) do
        local affiliation =
            FactionTypes.NormalizeAffiliation(record.affiliation)
        local communityID = affiliation.communityID
        local community = communityID
            and Communities.Registry.byID[communityID] or nil
        local invalid = communityID ~= nil and (
            community == nil
            or record.alive == false
            or affiliation.factionID ~= community.factionID
            or community.status == "archived"
            or community.status == "destroyed"
        )
        if invalid then
            affiliation.communityID = nil
            affiliation.communityRole = "resident"
            affiliation.communityJoinedAt = 0
        end
        if not FactionTypes.AreEqual(
            record.affiliation,
            affiliation
        ) then
            commitAffiliation(record, affiliation)
            changed = true
        end
    end
    return changed
end


Internal.rebuildDerivedIndexes = rebuildDerivedIndexes
Internal.reconcileLeaders = reconcileLeaders
Internal.reconcileNPCReferences = reconcileNPCReferences

return Communities
