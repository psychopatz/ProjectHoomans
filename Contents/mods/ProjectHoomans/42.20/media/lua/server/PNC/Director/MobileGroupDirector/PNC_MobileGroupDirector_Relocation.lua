if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.MobileGroupDirector = PNC.MobileGroupDirector or {}
PNC.MobileGroupDirectorInternal = PNC.MobileGroupDirectorInternal or {}

local Director = PNC.MobileGroupDirector
local H = PNC.MobileGroupDirectorInternal
local Constants = PNC.FactionConstants
local CommunityConstants = PNC.CommunityConstants
local Factions = PNC.Factions
local Resolver = PNC.CommunitySiteResolver
local Core = PNC.Core
local Const = PNC.Const

function Director.RelocateFaction(factionID, at, force)
    if not H.Authority() then return false, "not_authority" end
    local faction = Factions.Get(factionID)
    if not faction then return false, "faction_not_found" end
    if not Factions.IsMobileGroup(faction) then
        return false, "not_mobile_group"
    end
    local mobile = faction.mobile
    at = H.WorldAge(at)
    if force ~= true and at < (tonumber(mobile.nextMoveAt) or 0) then
        return false, "not_due"
    end
    local abstract, abstractReason = H.FactionMembersAreAbstract(faction)
    if not abstract then return false, abstractReason end
    local site, siteReason = H.ResolveSite(
        faction,
        {
            x = mobile.site.home.x,
            y = mobile.site.home.y,
            z = mobile.site.home.z,
            mobilePathMode = mobile.pathMode,
            randomHouseIndex = (tonumber(mobile.relocationCount) or 0) + 2,
        },
        at,
        true
    )
    if not site then return false, siteReason end
    local members = H.ActiveMembers(faction)
    local points = Resolver.FindSpawnPoints(site, #members)
    local nextState = H.BuildMobileState(
        site,
        mobile.pathMode,
        at,
        mobile,
        true
    )
    local index
    for index = 1, #members do
        H.SetRecordAtSite(
            members[index],
            points[index],
            site,
            faction,
            nextState
        )
    end
    local ok, reason, value = Factions.SetMobileGroup(
        faction.id,
        nextState,
        "mobile_group_relocated"
    )
    if not ok then return false, reason end
    return true, "mobile_group_relocated", value
end

function Director.SetPathMode(factionID, mode)
    mode = H.PathMode(mode)
    return Factions.UpdateMobileGroup(
        factionID,
        { pathMode = mode },
        "mobile_group_path_mode"
    )
end
