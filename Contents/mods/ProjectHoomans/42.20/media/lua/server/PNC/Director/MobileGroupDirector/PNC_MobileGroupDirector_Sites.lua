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

function H.CurrentSite(faction)
    return faction and faction.mobile
        and H.Copy(faction.mobile.site) or nil
end

function H.TargetPlayerSite(spec, at)
    local target = Core and Core.GetNearestPlayerPosition
        and Core.GetNearestPlayerPosition(
            tonumber(spec.x) or 0,
            tonumber(spec.y) or 0
        ) or nil
    if not target then return nil, "no_online_player" end
    return Resolver.FindAvailableNear(
        target.x,
        target.y,
        target.z,
        {
            createdAt = at,
            searchRadius = spec.searchRadius,
        }
    )
end

function H.ResolveSite(faction, spec, at, forceNew)
    local mobile = faction and faction.mobile or nil
    local mode = H.PathMode(
        spec.mobilePathMode,
        mobile and mobile.pathMode
    )
    if type(spec.siteSpec) == "table" then
        local explicit = H.Copy(spec.siteSpec)
        if not PNC.CommunityTypes.IsValidSiteID(explicit.id) then
            explicit.id = PNC.Communities.BuildSiteID(explicit)
        end
        explicit = PNC.CommunityTypes.NormalizeSite(explicit, explicit.id)
        if explicit then return explicit, "explicit_bounded_site" end
        return nil, "invalid_explicit_site"
    end
    if forceNew ~= true and spec.useExisting ~= false then
        local existing = H.CurrentSite(faction)
        if existing then return existing, "existing_mobile_site" end
    end
    if mode == Constants.MOBILE_PATH_PLAYER then
        if mobile and mobile.controlMode
            == Constants.MOBILE_CONTROL_STRATEGIC
            and H.TargetPlayerBaseSite
        then
            local baseSite, baseReason = H.TargetPlayerBaseSite(
                faction,
                at,
                spec.searchRadius
            )
            if baseSite then return baseSite, baseReason end
        end
        local site, reason = H.TargetPlayerSite(spec, at)
        if site then return site, reason end
    end
    return Resolver.FindRandomHouse({
        z = spec.z,
        createdAt = at,
        randomIndex = spec.randomHouseIndex,
    })
end
