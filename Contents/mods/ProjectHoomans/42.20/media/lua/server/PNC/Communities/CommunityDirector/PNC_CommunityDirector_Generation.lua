if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Director = PNC.CommunityDirector
local H = Director.Internal
local Communities = PNC.Communities
local Resolver = PNC.CommunitySiteResolver
local Factions = PNC.Factions
local Core = PNC.Core

function Director.GenerateForFaction(factionID, spec)
    if not Core.IsAuthority() then
        return false, "not_authority"
    end
    spec = type(spec) == "table" and spec or {}
    local faction = Factions.Get(factionID)
    if not faction then return false, "faction_not_found" end
    if faction.status ~= "active" then
        return false, "faction_not_active"
    end
    -- A mobile group only carries a transient primitive staging site. It is
    -- not a community and must never reserve a building or acquire a home.
    if Factions.IsMobileGroup
        and Factions.IsMobileGroup(faction)
    then
        return false, "mobile_faction_cannot_create_community"
    end
    local at = H.WorldAge(spec.worldAgeHours)
    local site
    local siteReason
    site, siteReason = H.ResolveSite(faction, spec, at)
    if not site then return false, siteReason end

    local community
    local reason
    local createdCommunity
    community, reason, createdCommunity = H.ResolveCommunity(
        faction,
        site,
        spec,
        at
    )
    if not community then return false, reason end
    if faction.archetypeID == "looter"
        and community.mode == "settled"
        and Factions.MarkTerritorialTollFaction
    then
        Factions.MarkTerritorialTollFaction(
            faction.id,
            "settled_looter_community_generated"
        )
        faction = Factions.Get(faction.id) or faction
    end

    site = community.site or site
    local presenceMode =
        H.NormalizedPresenceMode(spec.presenceMode)
    local siteLoaded = Resolver.IsSiteLoaded(site)
    local created
    local liveCount
    local abstractCount
    local requestedCount
    created, liveCount, abstractCount, requestedCount, reason =
        H.SpawnCommunityMembers(
            faction,
            community,
            site,
            spec,
            at,
            presenceMode,
            siteLoaded,
            createdCommunity
        )
    if not created then return false, reason end

    local ids = {}
    for _, record in ipairs(created) do
        ids[#ids + 1] = record.id
    end
    return true, "group_generated", {
        factionID = faction.id,
        communityID = community.id,
        siteID = site.id,
        siteKind = site.kind,
        siteLoaded = siteLoaded,
        siteSelectionReason = siteReason,
        presenceMode = presenceMode,
        requestedCount = requestedCount,
        createdCount = #ids,
        liveCount = liveCount,
        abstractCount = abstractCount,
        npcIDs = ids,
    }
end
