local Types = PNC.AbstractWorldTypes
local Internal = Types.Internal

function Internal.Copy(value, seen)
    local output
    local key
    local item
    local keyType
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return nil end
    seen[value] = true
    output = {}
    for key, item in pairs(value) do
        keyType = type(key)
        if keyType == "string" or keyType == "number" then
            output[key] = Internal.Copy(item, seen)
        end
    end
    seen[value] = nil
    return output
end

function Internal.Finite(value, fallback)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then
        value = tonumber(fallback) or 0
    end
    return value
end

function Internal.Integer(value, minimum, maximum, fallback)
    return math.max(
        minimum,
        math.min(maximum, math.floor(Internal.Finite(value, fallback)))
    )
end

function Internal.SafeID(value, prefix)
    value = type(value) == "string" and value or nil
    if not value or #value < 3 or #value > 192
        or string.find(value, "%c")
        or string.match(value, "^[%w_%-%.:]+$") == nil
    then
        return nil
    end
    if prefix and string.sub(value, 1, #prefix) ~= prefix then
        return nil
    end
    return value
end

function Internal.StringSet(value)
    local output = {}
    local key
    local item
    for key, item in pairs(type(value) == "table" and value or {}) do
        if type(key) == "number" then
            item = type(item) == "string" and item or nil
            if item then output[item] = true end
        elseif item == true and type(key) == "string" then
            output[key] = true
        end
    end
    return output
end

function Internal.IDArray(value)
    local set = Internal.StringSet(value)
    local output = {}
    local id
    for id in pairs(set) do output[#output + 1] = id end
    table.sort(output)
    return output
end

function Internal.Resources(value)
    value = type(value) == "table" and value or {}
    return {
        food = math.max(0, Internal.Finite(value.food, 0)),
        water = math.max(0, Internal.Finite(value.water, 0)),
        ammo = math.max(0, Internal.Finite(value.ammo, 0)),
        medical = math.max(
            0,
            Internal.Finite(value.medical, value.medicine)
        ),
        materials = math.max(0, Internal.Finite(value.materials, 0)),
        weapons = math.max(0, Internal.Finite(value.weapons, 0)),
    }
end

function Internal.Generation(value)
    local source = type(value) == "table" and value or nil
    local generationID
    if not source then return nil end
    generationID = Internal.SafeID(source.generationId)
    if not generationID then return nil end
    return {
        source = type(source.source) == "string" and source.source
            or "WORLD_POPULATION_DIRECTOR",
        generationId = generationID,
        sectorId = Internal.SafeID(source.sectorId),
        createdAt = math.max(0, Internal.Finite(source.createdAt, 0)),
        seed = Internal.Integer(source.seed, 0, 2147483647, 0),
    }
end

Types.SafeID = Internal.SafeID
Types.IDArray = Internal.IDArray
Types.Resources = Internal.Resources
