local Types = PNC.AbstractWorldTypes
local Internal = Types.Internal
local Config = PNC.DirectorConfig

function Types.NormalizeLocationRef(value)
    local source = type(value) == "table" and value or {}
    local id = Internal.SafeID(source.id, "aloc_")
    if not id then return nil end
    return {
        id = id,
        type = Config.LOCATION_TYPES[source.type]
            and source.type or "TEMPORARY",
        x = Internal.Finite(source.x, 0),
        y = Internal.Finite(source.y, 0),
        z = Internal.Finite(source.z, 0),
    }
end

function Types.NormalizeCombatProfile(value)
    local source = type(value) == "table" and value or {}
    local output = {}
    local fields = {
        "manpower", "meleePower", "rangedPower", "defense",
        "mobility", "morale", "experience", "medical", "ammoState",
        "condition", "overallPower", "memberCount", "combatantCount",
    }
    local field
    for _, field in ipairs(fields) do
        output[field] = math.max(0, Internal.Finite(source[field], 0))
    end
    output.builtAt = math.max(0, Internal.Finite(source.builtAt, 0))
    output.revision = Internal.Integer(
        source.revision, 0, 2147483647, 0
    )
    output.ammoLabel = type(source.ammoLabel) == "string"
        and source.ammoLabel or "EMPTY"
    return output
end

function Types.NormalizeBehaviorProfile(value)
    local source = type(value) == "table" and value or {}
    local output = {}
    local field
    for _, field in ipairs({
        "aggression", "bravery", "greed", "caution",
        "mercy", "discipline", "civilianHostility",
    }) do
        output[field] = math.max(
            0,
            math.min(1, Internal.Finite(source[field], 0))
        )
    end
    output.builtAt = math.max(0, Internal.Finite(source.builtAt, 0))
    output.source = type(source.source) == "string"
        and source.source or "normalized"
    return output
end

function Types.NormalizeAction(value)
    local source = type(value) == "table" and value or nil
    local actionType
    local locationID
    local startedAt
    local endsAt
    if not source then return nil end
    actionType = tostring(source.type or "")
    locationID = Internal.SafeID(source.locationId, "aloc_")
    if actionType == "" or not locationID then return nil end
    startedAt = math.max(0, Internal.Finite(source.startedAt, 0))
    endsAt = math.max(
        startedAt,
        Internal.Finite(source.endsAt, startedAt)
    )
    return {
        type = actionType,
        locationId = locationID,
        startedAt = startedAt,
        endsAt = endsAt,
        seed = Internal.Integer(source.seed, 0, 2147483647, 0),
        status = type(source.status) == "string"
            and source.status or "ACTIVE",
    }
end

function Internal.PreviousMission(value)
    local source = type(value) == "table" and value or nil
    if not source or not Config.MISSIONS[source.type] then return nil end
    return {
        type = source.type,
        targetLocationId = Internal.SafeID(
            source.targetLocationId,
            "aloc_"
        ),
    }
end

function Internal.ExpiryMap(value, prefix)
    local output = {}
    local key
    local expiry
    local count = 0
    local oldestKey
    local oldestExpiry
    for key, expiry in pairs(type(value) == "table" and value or {}) do
        if Internal.SafeID(key, prefix) then
            output[key] = math.max(0, Internal.Finite(expiry, 0))
            count = count + 1
        end
    end
    while count > Config.RECENT_THREAT_HISTORY_LIMIT do
        oldestKey = nil
        oldestExpiry = nil
        for key, expiry in pairs(output) do
            if not oldestExpiry or expiry < oldestExpiry then
                oldestKey = key
                oldestExpiry = expiry
            end
        end
        if not oldestKey then break end
        output[oldestKey] = nil
        count = count - 1
    end
    return output
end
