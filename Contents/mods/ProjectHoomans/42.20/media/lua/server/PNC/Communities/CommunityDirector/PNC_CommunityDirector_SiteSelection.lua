if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local H = PNC.CommunityDirector.Internal
local Communities = PNC.Communities
local Resolver = PNC.CommunitySiteResolver
local Core = PNC.Core

function H.ResolveSite(faction, spec, at)
    local preferredCommunity = spec.communityID
        and Communities.Get(spec.communityID) or nil
    if not preferredCommunity
        and spec.useExisting ~= false
    then
        preferredCommunity =
            H.FindActiveCommunity(faction.id)
    end
    local primitiveSite = type(spec.siteSpec) == "table"
        and Core.DeepCopy(spec.siteSpec) or nil
    if primitiveSite
        and not PNC.CommunityTypes.IsValidSiteID(
            primitiveSite.id
        )
    then
        primitiveSite.id =
            Communities.BuildSiteID(primitiveSite)
    end
    local site = preferredCommunity
        and preferredCommunity.site
        or primitiveSite
        and PNC.CommunityTypes.NormalizeSite(
            primitiveSite,
            primitiveSite.id
        ) or nil
    local reason = preferredCommunity and site
        and "existing_community_site"
        or site and "primitive_site" or nil
    if site then return site, reason end
    if spec.siteSelection == "random_house" then
        return Resolver.FindRandomHouse({
            z = spec.z,
            createdAt = at,
            randomIndex = spec.randomHouseIndex,
        })
    end
    return Resolver.FindAvailableNear(
        spec.x,
        spec.y,
        spec.z,
        {
            radius = spec.radius,
            createdAt = at,
            searchRadius = spec.searchRadius,
        }
    )
end
