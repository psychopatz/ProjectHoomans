-- Defensive constructors and deterministic normalization for communities.

PNC = PNC or {}
PNC.CommunityTypes = PNC.CommunityTypes or {}

local Types = PNC.CommunityTypes
local Constants = PNC.CommunityConstants
local Profiles = PNC.CommunityProfiles
local CommunityMath = PNC.CommunityMath

local function revision(value)
    return math.max(0, math.floor(
        CommunityMath.Clamp(value, 0, 2147483647, 0)
    ))
end

local function timestamp(value, fallback)
    return CommunityMath.Clamp(value, 0, 1000000000, fallback or 0)
end

local function integer(value, minimum, maximum, fallback)
    return math.floor(CommunityMath.Clamp(
        value,
        minimum,
        maximum,
        fallback
    ))
end

local function safeString(value, maximum)
    if type(value) ~= "string" then return nil end
    value = string.match(value, "^%s*(.-)%s*$")
    if value == "" or #value > maximum then return nil end
    return value
end

function Types.IsValidCommunityID(value)
    return type(value) == "string"
        and #value > #Constants.ID_PREFIX
        and #value <= Constants.ID_MAX_LENGTH
        and string.sub(value, 1, #Constants.ID_PREFIX)
            == Constants.ID_PREFIX
        and string.match(value, "^[%w_%-%.]+$") ~= nil
end

function Types.IsValidSiteID(value)
    return type(value) == "string"
        and #value > #Constants.SITE_ID_PREFIX
        and #value <= Constants.SITE_ID_MAX_LENGTH
        and string.sub(value, 1, #Constants.SITE_ID_PREFIX)
            == Constants.SITE_ID_PREFIX
        and string.match(value, "^[%w_%-%.]+$") ~= nil
end

function Types.IsValidFactionID(value)
    return PNC.FactionTypes
        and PNC.FactionTypes.IsValidFactionID
        and PNC.FactionTypes.IsValidFactionID(value)
        or type(value) == "string"
            and string.sub(value, 1, 8) == "faction_"
end

function Types.IsValidNPCID(value)
    return PNC.FactionTypes
        and PNC.FactionTypes.IsValidNPCID
        and PNC.FactionTypes.IsValidNPCID(value)
        or type(value) == "string"
            and string.sub(value, 1, 4) == "npc_"
end

function Types.NormalizeMode(value, fallback)
    if Constants.VALID_MODES[value] then return value end
    return Constants.VALID_MODES[fallback] and fallback
        or "settled"
end

function Types.NormalizeStatus(value, mode)
    local status = Constants.VALID_STATUSES[value]
        and value or "inactive"
    if mode == "destroyed" or status == "destroyed" then
        return "destroyed", "destroyed"
    end
    if status == "archived" then
        return "abandoned", "archived"
    end
    if mode == "abandoned" then
        return mode, status == "active" and "inactive" or status
    end
    if mode ~= "settled" and mode ~= "camped"
        and status == "active"
    then
        status = "inactive"
    end
    return mode, status
end

function Types.NormalizeHome(value, mode)
    local source = type(value) == "table" and value or {}
    local profile = Profiles.GetMode(mode)
        or Profiles.GetMode("settled")
    if not CommunityMath.IsFinite(source.x)
        or not CommunityMath.IsFinite(source.y)
    then
        return nil
    end
    return {
        x = tonumber(source.x),
        y = tonumber(source.y),
        z = integer(
            source.z,
            Constants.Z_MIN,
            Constants.Z_MAX,
            Constants.Z_MIN
        ),
        radius = CommunityMath.Clamp(
            source.radius,
            Constants.RADIUS_MIN,
            Constants.RADIUS_MAX,
            profile.radius
        ),
    }
end

function Types.NormalizeSiteBounds(value, home)
    local source = type(value) == "table" and value or {}
    local minX = CommunityMath.IsFinite(source.minX)
        and tonumber(source.minX) or home and home.x
    local minY = CommunityMath.IsFinite(source.minY)
        and tonumber(source.minY) or home and home.y
    local maxX = CommunityMath.IsFinite(source.maxX)
        and tonumber(source.maxX) or minX
    local maxY = CommunityMath.IsFinite(source.maxY)
        and tonumber(source.maxY) or minY
    if not minX or not minY or not maxX or not maxY then
        return nil
    end
    if maxX < minX then minX, maxX = maxX, minX end
    if maxY < minY then minY, maxY = maxY, minY end
    local minZ = integer(
        source.minZ,
        Constants.Z_MIN,
        Constants.Z_MAX,
        home and home.z or 0
    )
    local maxZ = integer(
        source.maxZ,
        Constants.Z_MIN,
        Constants.Z_MAX,
        home and home.z or 0
    )
    if maxZ < minZ then minZ, maxZ = maxZ, minZ end
    return {
        minX = minX,
        minY = minY,
        maxX = maxX,
        maxY = maxY,
        minZ = minZ,
        maxZ = maxZ,
    }
end

function Types.NormalizeSite(value, siteID)
    local source = type(value) == "table" and value or {}
    local id = Types.IsValidSiteID(siteID)
        and siteID
        or Types.IsValidSiteID(source.id) and source.id
        or nil
    local kind = Constants.VALID_SITE_KINDS[source.kind]
        and source.kind or "radius"
    local home = Types.NormalizeHome(
        source.home or {
            x = source.x,
            y = source.y,
            z = source.z,
            radius = source.radius,
        },
        "settled"
    )
    local bounds = Types.NormalizeSiteBounds(
        source.bounds,
        home
    )
    if not id or not home or not bounds then return nil end
    local claimantKey = PNC.EntityRef
        and PNC.EntityRef.IsPlayer
        and PNC.EntityRef.IsPlayer(source.claimantKey)
        and source.claimantKey or nil
    local occupantCommunityID =
        Types.IsValidCommunityID(source.occupantCommunityID)
        and source.occupantCommunityID or nil
    local status = claimantKey and "claimed"
        or occupantCommunityID and "occupied"
        or "vacant"
    return {
        schemaVersion = Constants.SITE_SCHEMA_VERSION,
        id = id,
        kind = kind,
        home = home,
        bounds = bounds,
        occupantCommunityID = occupantCommunityID,
        claimantKey = claimantKey,
        status = status,
        createdAt = timestamp(source.createdAt, 0),
        vacatedAt = timestamp(source.vacatedAt, 0),
        claimedAt = claimantKey
            and timestamp(source.claimedAt, 0) or 0,
        revision = revision(source.revision),
    }
end

function Types.NormalizeCapacity(value, defaults)
    local source = type(value) == "table" and value or {}
    defaults = type(defaults) == "table" and defaults or {}
    return {
        population = integer(
            source.population,
            0,
            Constants.POPULATION_CAPACITY_MAX,
            defaults.population or 0
        ),
        beds = integer(
            source.beds,
            0,
            Constants.BEDS_MAX,
            defaults.beds or 0
        ),
        storage = integer(
            source.storage,
            0,
            Constants.STORAGE_MAX,
            defaults.storage or 0
        ),
    }
end

function Types.NormalizeSupplies(value, defaults)
    local source = type(value) == "table" and value or {}
    defaults = type(defaults) == "table" and defaults or {}
    local output = {}
    for _, category in ipairs(Constants.SUPPLY_CATEGORIES) do
        output[category] = integer(
            source[category],
            Constants.SUPPLY_MIN,
            Constants.SUPPLY_MAX,
            defaults[category] or 0
        )
    end
    return output
end

function Types.NormalizeMemberIDs(value)
    local output = {}
    for npcID, present in pairs(
        type(value) == "table" and value or {}
    ) do
        if present == true and Types.IsValidNPCID(npcID) then
            output[npcID] = true
        end
    end
    return output
end

function Types.BuildCreationDefaults(mode, archetypeID)
    mode = Types.NormalizeMode(mode)
    local profile = Profiles.GetMode(mode)
    local archetype = Profiles.GetArchetype(archetypeID) or {}
    local capacity = {
        population = profile.capacity.population,
        beds = profile.capacity.beds,
        storage = profile.capacity.storage
            + (tonumber(archetype.storage) or 0),
    }
    local supplies = {}
    for _, category in ipairs(Constants.SUPPLY_CATEGORIES) do
        supplies[category] = math.max(
            0,
            tonumber(archetype[category]) or 0
        )
    end
    return {
        radius = profile.radius,
        capacity = Types.NormalizeCapacity(capacity),
        security = CommunityMath.Clamp(
            profile.security + (tonumber(archetype.security) or 0),
            Constants.SECURITY_MIN,
            Constants.SECURITY_MAX,
            0
        ),
        morale = CommunityMath.Clamp(
            profile.morale + (tonumber(archetype.morale) or 0),
            Constants.MORALE_MIN,
            Constants.MORALE_MAX,
            0
        ),
        supplies = Types.NormalizeSupplies(supplies),
    }
end

function Types.NormalizeCommunity(value, communityID)
    local source = type(value) == "table" and value or {}
    local id = Types.IsValidCommunityID(communityID)
        and communityID
        or Types.IsValidCommunityID(source.id) and source.id
        or nil
    local factionID = Types.IsValidFactionID(source.factionID)
        and source.factionID or nil
    local name = safeString(source.name, Constants.NAME_MAX_LENGTH)
    local mode = Types.NormalizeMode(source.mode)
    local status
    mode, status = Types.NormalizeStatus(source.status, mode)
    local home = Types.NormalizeHome(source.home, mode)
    if not id or not factionID or not name or not home then
        return nil
    end
    local defaults = Types.BuildCreationDefaults(mode)
    local output = {
        schemaVersion = Constants.RECORD_SCHEMA_VERSION,
        id = id,
        factionID = factionID,
        name = name,
        renamePending = source.renamePending == true,
        mode = mode,
        status = status,
        createdAt = timestamp(source.createdAt, 0),
        archivedAt = timestamp(source.archivedAt, 0),
        destroyedAt = timestamp(source.destroyedAt, 0),
        archiveReason = safeString(
            source.archiveReason,
            Constants.NAME_MAX_LENGTH
        ),
        destroyReason = safeString(
            source.destroyReason,
            Constants.NAME_MAX_LENGTH
        ),
        home = home,
        siteID = Types.IsValidSiteID(source.siteID)
            and source.siteID or nil,
        leaderNPCID = Types.IsValidNPCID(source.leaderNPCID)
            and source.leaderNPCID or nil,
        memberIDs = Types.NormalizeMemberIDs(source.memberIDs),
        capacity = Types.NormalizeCapacity(
            source.capacity,
            defaults.capacity
        ),
        security = CommunityMath.Clamp(
            source.security,
            Constants.SECURITY_MIN,
            Constants.SECURITY_MAX,
            defaults.security
        ),
        morale = CommunityMath.Clamp(
            source.morale,
            Constants.MORALE_MIN,
            Constants.MORALE_MAX,
            defaults.morale
        ),
        supplies = Types.NormalizeSupplies(
            source.supplies,
            defaults.supplies
        ),
        revision = revision(source.revision),
    }
    if output.status == "archived"
        or output.status == "destroyed"
    then
        output.leaderNPCID = nil
        output.memberIDs = {}
    end
    return output
end

function Types.NewCommunity(spec)
    return Types.NormalizeCommunity(spec, spec and spec.id)
end

function Types.NormalizeRegistry(value)
    local source = type(value) == "table" and value or {}
    local output = {
        schemaVersion = Constants.REGISTRY_SCHEMA_VERSION,
        revision = revision(source.revision),
        byID = {},
        byFaction = {},
        sitesByID = {},
    }
    for communityID, raw in pairs(
        type(source.byID) == "table" and source.byID or {}
    ) do
        local community = Types.NormalizeCommunity(
            raw,
            communityID
        )
        if community and community.id == communityID then
            output.byID[communityID] = community
            output.byFaction[community.factionID] =
                output.byFaction[community.factionID] or {}
            output.byFaction[community.factionID][communityID] =
                true
        end
    end
    for siteID, raw in pairs(
        type(source.sitesByID) == "table"
            and source.sitesByID or {}
    ) do
        local site = Types.NormalizeSite(raw, siteID)
        if site and site.id == siteID then
            output.sitesByID[siteID] = site
        end
    end
    -- Occupancy is derived deterministically from active communities. Retired
    -- communities keep siteID as history but do not reserve the reusable site.
    local activeBySite = {}
    for communityID, community in pairs(output.byID) do
        local siteID = community.siteID
        local site = siteID and output.sitesByID[siteID] or nil
        if site and community.status == "active"
            and not site.claimantKey
        then
            local current = activeBySite[siteID]
            if not current or communityID < current then
                activeBySite[siteID] = communityID
            end
        elseif siteID and not site then
            community.siteID = nil
        end
    end
    for siteID, site in pairs(output.sitesByID) do
        if site.claimantKey then
            site.occupantCommunityID = nil
            site.status = "claimed"
        else
            site.occupantCommunityID = activeBySite[siteID]
            site.status = site.occupantCommunityID
                and "occupied" or "vacant"
        end
    end
    return output
end

function Types.NewRegistry(value)
    return Types.NormalizeRegistry(value)
end

function Types.AreEqual(left, right, seen)
    if type(left) ~= type(right) then return false end
    if type(left) ~= "table" then return left == right end
    seen = seen or {}
    if seen[left] == right then return true end
    seen[left] = right
    for key, item in pairs(left) do
        if not Types.AreEqual(item, right[key], seen) then
            return false
        end
    end
    for key, _ in pairs(right) do
        if left[key] == nil then return false end
    end
    return true
end

return Types
