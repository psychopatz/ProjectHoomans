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
local copy = Internal.copy
local worldAge = Internal.worldAge
local registryRecord = Internal.registryRecord
local siteRecord = Internal.siteRecord
local touchCommunity = Internal.touchCommunity
local touchSite = Internal.touchSite
local touchRegistry = Internal.touchRegistry
local publicSite = Internal.publicSite
local releaseSiteOccupancy = Internal.releaseSiteOccupancy

function Communities.ReserveSite(
    communityID,
    siteSpec,
    worldAgeHours
)
    if not authority() then return false, "not_authority" end
    Communities.EnsureLoaded()
    local community = registryRecord(communityID)
    if not community then
        return false, "community_not_found"
    end
    if community.status ~= "active" then
        return false, "community_not_active"
    end
    siteSpec = type(siteSpec) == "table"
        and copy(siteSpec) or {}
    siteSpec.id = Types.IsValidSiteID(siteSpec.id)
        and siteSpec.id
        or Communities.BuildSiteID(siteSpec)
    siteSpec.createdAt = worldAge(
        siteSpec.createdAt,
        worldAgeHours
    )
    local normalized = Types.NormalizeSite(
        siteSpec,
        siteSpec.id
    )
    if not normalized then return false, "invalid_site" end
    local existing = siteRecord(normalized.id)
    if existing and existing.claimantKey then
        return false, "site_claimed"
    end
    if existing and existing.occupantCommunityID
        and existing.occupantCommunityID ~= communityID
    then
        return false, "site_occupied"
    end
    if community.siteID
        and community.siteID ~= normalized.id
    then
        releaseSiteOccupancy(community, worldAgeHours)
    end
    local site = existing or normalized
    if not existing then
        site.revision = math.max(1, site.revision)
        Communities.Registry.sitesByID[site.id] = site
    end
    site.occupantCommunityID = communityID
    site.claimantKey = nil
    site.claimedAt = 0
    site.status = "occupied"
    if existing then touchSite(site) end
    community.siteID = site.id
    community.home = copy(site.home)
    touchCommunity(community)
    touchRegistry()
    return true, "site_reserved", publicSite(site)
end

function Communities.ReleaseSite(
    communityID,
    worldAgeHours
)
    if not authority() then return false, "not_authority" end
    Communities.EnsureLoaded()
    local community = registryRecord(communityID)
    if not community then
        return false, "community_not_found"
    end
    if not releaseSiteOccupancy(community, worldAgeHours) then
        return false, "site_not_occupied_by_community"
    end
    community.siteID = nil
    touchCommunity(community)
    touchRegistry()
    return true, "site_released",
        publicSite(siteRecord(community.siteID))
end

function Communities.ClaimSite(
    siteID,
    playerKey,
    worldAgeHours
)
    if not authority() then return false, "not_authority" end
    Communities.EnsureLoaded()
    local site = siteRecord(siteID)
    if not site then return false, "site_not_found" end
    if not PNC.EntityRef
        or not PNC.EntityRef.IsPlayer
        or not PNC.EntityRef.IsPlayer(playerKey)
    then
        return false, "invalid_player_key"
    end
    if site.occupantCommunityID then
        return false, "site_occupied"
    end
    if site.claimantKey then
        if site.claimantKey == playerKey then
            return false, "already_claimed_by_player"
        end
        return false, "site_claimed"
    end
    site.claimantKey = playerKey
    site.claimedAt = worldAge(worldAgeHours, 0)
    site.status = "claimed"
    touchSite(site)
    touchRegistry()
    return true, "site_claimed", publicSite(site)
end

function Communities.UnclaimSite(siteID, playerKey)
    if not authority() then return false, "not_authority" end
    Communities.EnsureLoaded()
    local site = siteRecord(siteID)
    if not site then return false, "site_not_found" end
    if not site.claimantKey then
        return false, "site_not_claimed"
    end
    if playerKey and site.claimantKey ~= playerKey then
        return false, "site_claimed_by_other_player"
    end
    site.claimantKey = nil
    site.claimedAt = 0
    site.status = "vacant"
    touchSite(site)
    touchRegistry()
    return true, "site_unclaimed", publicSite(site)
end


return Communities
