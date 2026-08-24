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

local function validateSupply(communityID, category, amount)
    local community = registryRecord(communityID)
    if not community then
        return nil, nil, "community_not_found"
    end
    if not Constants.VALID_SUPPLY_CATEGORIES[category] then
        return nil, nil, "invalid_supply_category"
    end
    if not CommunityMath.IsFinite(amount) then
        return nil, nil, "invalid_supply_amount"
    end
    amount = math.floor(tonumber(amount))
    if amount < 0 then
        return nil, nil, "invalid_supply_amount"
    end
    return community, amount
end

function Communities.GetSupply(communityID, category)
    Communities.EnsureLoaded()
    local community, _, reason =
        validateSupply(communityID, category, 0)
    if not community then return nil, reason end
    return community.supplies[category]
end

function Communities.SetSupply(
    communityID,
    category,
    amount
)
    if not authority() then return false, "not_authority" end
    Communities.EnsureLoaded()
    local community, normalized, reason =
        validateSupply(communityID, category, amount)
    if not community then return false, reason end
    normalized = math.floor(CommunityMath.Clamp(
        normalized,
        Constants.SUPPLY_MIN,
        Constants.SUPPLY_MAX,
        0
    ))
    if community.supplies[category] == normalized then
        return false, "unchanged"
    end
    community.supplies[category] = normalized
    touchCommunity(community)
    touchRegistry()
    return true, "supply_set", normalized
end

function Communities.AddSupply(
    communityID,
    category,
    amount
)
    if not authority() then return false, "not_authority" end
    Communities.EnsureLoaded()
    local community, normalized, reason =
        validateSupply(communityID, category, amount)
    if not community then return false, reason end
    return Communities.SetSupply(
        communityID,
        category,
        community.supplies[category] + normalized
    )
end

function Communities.RemoveSupply(
    communityID,
    category,
    amount
)
    if not authority() then return false, "not_authority" end
    Communities.EnsureLoaded()
    local community, normalized, reason =
        validateSupply(communityID, category, amount)
    if not community then return false, reason end
    if normalized > community.supplies[category] then
        return false, "insufficient_supply"
    end
    return Communities.SetSupply(
        communityID,
        category,
        community.supplies[category] - normalized
    )
end


return Communities
