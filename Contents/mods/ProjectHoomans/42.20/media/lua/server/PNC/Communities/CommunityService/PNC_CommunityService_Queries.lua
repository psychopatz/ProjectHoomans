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
local registryRecord = Internal.registryRecord
local siteRecord = Internal.siteRecord
local publicCommunity = Internal.publicCommunity
local publicSite = Internal.publicSite

function Communities.Get(communityID)
    Communities.EnsureLoaded()
    local community = registryRecord(communityID)
    return publicCommunity(community),
        community and nil or "community_not_found"
end

function Communities.List()
    local output = {}
    Communities.EnsureLoaded()
    for _, community in pairs(Communities.Registry.byID) do
        output[#output + 1] = publicCommunity(community)
    end
    table.sort(output, function(left, right)
        if left.name ~= right.name then
            return left.name < right.name
        end
        return left.id < right.id
    end)
    return output
end

function Communities.GetForFaction(factionID)
    local output = {}
    Communities.EnsureLoaded()
    if not Types.IsValidFactionID(factionID) then
        return output, "invalid_faction_id"
    end
    for communityID, present in pairs(
        Communities.Registry.byFaction[factionID] or {}
    ) do
        if present == true
            and Communities.Registry.byID[communityID]
        then
            output[#output + 1] = publicCommunity(
                Communities.Registry.byID[communityID]
            )
        end
    end
    table.sort(output, function(left, right)
        return left.id < right.id
    end)
    return output
end

function Communities.BuildSiteID(siteSpec)
    local source = type(siteSpec) == "table"
        and siteSpec or {}
    local bounds = type(source.bounds) == "table"
        and source.bounds or {}
    local home = type(source.home) == "table"
        and source.home or source
    local kind = Constants.VALID_SITE_KINDS[source.kind]
        and source.kind or "radius"
    local function token(value)
        value = tonumber(value) or 0
        if value >= 0 then
            return tostring(math.floor(value * 10 + 0.5))
        end
        return tostring(math.ceil(value * 10 - 0.5))
    end
    return Constants.SITE_ID_PREFIX .. kind .. "_"
        .. token(bounds.minX or home.x) .. "_"
        .. token(bounds.minY or home.y) .. "_"
        .. token(bounds.maxX or home.x) .. "_"
        .. token(bounds.maxY or home.y) .. "_"
        .. token(home.z)
end

function Communities.GetSite(siteID)
    Communities.EnsureLoaded()
    local site = siteRecord(siteID)
    return publicSite(site),
        site and nil or "site_not_found"
end

function Communities.ListSites()
    Communities.EnsureLoaded()
    local output = {}
    for _, site in pairs(Communities.Registry.sitesByID) do
        output[#output + 1] = publicSite(site)
    end
    table.sort(output, function(left, right)
        return left.id < right.id
    end)
    return output
end


return Communities
