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
local touchCommunity = Internal.touchCommunity
local touchRegistry = Internal.touchRegistry
local publicCommunity = Internal.publicCommunity
local clearMembers = Internal.clearMembers

local function setCommunityField(
    communityID,
    field,
    value
)
    local community = registryRecord(communityID)
    if not community then return false, "community_not_found" end
    if Types.AreEqual(community[field], value) then
        return false, "unchanged"
    end
    community[field] = value
    touchCommunity(community)
    touchRegistry()
    return true, "updated", publicCommunity(community)
end

function Communities.SetName(communityID, value)
    if not authority() then return false, "not_authority" end
    Communities.EnsureLoaded()
    local community = registryRecord(communityID)
    if not community then return false, "community_not_found" end
    local name = type(value) == "string"
        and string.match(value, "^%s*(.-)%s*$") or nil
    if not name or name == "" or #name > Constants.NAME_MAX_LENGTH then
        return false, "invalid_name"
    end
    if community.name == name and community.renamePending ~= true then
        return false, "unchanged"
    end
    community.name = name
    community.renamePending = false
    touchCommunity(community)
    touchRegistry()
    return true, "renamed", publicCommunity(community)
end

function Communities.SetMode(communityID, mode, worldAgeHours)
    if not authority() then return false, "not_authority" end
    Communities.EnsureLoaded()
    if not Constants.VALID_MODES[mode] then
        return false, "invalid_mode"
    end
    if mode == "destroyed" then
        return Communities.Destroy(
            communityID,
            "mode_changed",
            worldAgeHours
        )
    end
    local community = registryRecord(communityID)
    if not community then return false, "community_not_found" end
    if community.status == "archived"
        or community.status == "destroyed"
    then
        return false, "community_retired"
    end
    local nextMode, nextStatus =
        Types.NormalizeStatus(community.status, mode)
    if nextMode == community.mode
        and nextStatus == community.status
    then
        return false, "unchanged"
    end
    community.mode = nextMode
    community.status = nextStatus
    if nextMode == "abandoned" then
        clearMembers(community)
    end
    touchCommunity(community)
    touchRegistry()
    return true, "mode_set", publicCommunity(community)
end

function Communities.SetStatus(
    communityID,
    status,
    worldAgeHours
)
    if not authority() then return false, "not_authority" end
    Communities.EnsureLoaded()
    if not Constants.VALID_STATUSES[status] then
        return false, "invalid_status"
    end
    if status == "archived" then
        return Communities.Archive(
            communityID,
            "status_changed",
            worldAgeHours
        )
    end
    if status == "destroyed" then
        return Communities.Destroy(
            communityID,
            "status_changed",
            worldAgeHours
        )
    end
    local community = registryRecord(communityID)
    if not community then return false, "community_not_found" end
    if community.status == "archived"
        or community.status == "destroyed"
    then
        return false, "community_retired"
    end
    local nextMode, nextStatus =
        Types.NormalizeStatus(status, community.mode)
    if nextMode == community.mode
        and nextStatus == community.status
    then
        return false, "unchanged"
    end
    community.mode = nextMode
    community.status = nextStatus
    touchCommunity(community)
    touchRegistry()
    return true, "status_set", publicCommunity(community)
end

function Communities.SetHome(communityID, homeSpec)
    if not authority() then return false, "not_authority" end
    Communities.EnsureLoaded()
    local community = registryRecord(communityID)
    if not community then return false, "community_not_found" end
    local home = Types.NormalizeHome(homeSpec, community.mode)
    if not home then return false, "invalid_home" end
    return setCommunityField(communityID, "home", home)
end

function Communities.SetCapacity(
    communityID,
    capacitySpec
)
    if not authority() then return false, "not_authority" end
    Communities.EnsureLoaded()
    local community = registryRecord(communityID)
    if not community then return false, "community_not_found" end
    return setCommunityField(
        communityID,
        "capacity",
        Types.NormalizeCapacity(
            capacitySpec,
            community.capacity
        )
    )
end

function Communities.SetSecurity(communityID, value)
    if not authority() then return false, "not_authority" end
    Communities.EnsureLoaded()
    local community = registryRecord(communityID)
    if not community then return false, "community_not_found" end
    if not CommunityMath.IsFinite(value) then
        return false, "invalid_security"
    end
    return setCommunityField(
        communityID,
        "security",
        CommunityMath.Clamp(
            value,
            Constants.SECURITY_MIN,
            Constants.SECURITY_MAX,
            community.security
        )
    )
end

function Communities.SetMorale(communityID, value)
    if not authority() then return false, "not_authority" end
    Communities.EnsureLoaded()
    local community = registryRecord(communityID)
    if not community then return false, "community_not_found" end
    if not CommunityMath.IsFinite(value) then
        return false, "invalid_morale"
    end
    return setCommunityField(
        communityID,
        "morale",
        CommunityMath.Clamp(
            value,
            Constants.MORALE_MIN,
            Constants.MORALE_MAX,
            community.morale
        )
    )
end


return Communities
