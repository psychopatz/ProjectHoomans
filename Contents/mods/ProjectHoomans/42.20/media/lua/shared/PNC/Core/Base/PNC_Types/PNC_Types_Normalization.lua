PNC = PNC or {}
PNC.Types = PNC.Types or {}

local Types = PNC.Types
local Internal = Types.Internal or {}
Types.Internal = Internal

function Internal.NormalizeString(value)
    if value == nil or value == "" then return nil end
    return tostring(value)
end

function Internal.NormalizeStringMap(source)
    local output = {}
    local key
    local value
    if type(source) ~= "table" then return output end
    for key, value in pairs(source) do
        key = Internal.NormalizeString(key)
        value = Internal.NormalizeString(value)
        if key and value then output[key] = value end
    end
    return output
end

function Internal.NormalizeEquipment(equipment)
    local source = type(equipment) == "table" and equipment or {}
    return {
        primaryFullType = Internal.NormalizeString(source.primaryFullType),
        secondaryFullType = Internal.NormalizeString(source.secondaryFullType),
        worn = Internal.NormalizeStringMap(source.worn),
        attached = Internal.NormalizeStringMap(source.attached),
    }
end

function Internal.NormalizeIdentity(identity)
    if type(identity) ~= "table" then return nil end
    return PNC.Core.DeepCopy(identity)
end

function Internal.NormalizeInventory(inventory)
    if type(inventory) ~= "table" then return nil end
    return PNC.Core.DeepCopy(inventory)
end

function Internal.NormalizeEquipmentSpawnMode(value)
    value = Internal.NormalizeString(value)
    if value == "melee" or value == "ranged" or value == "both" then
        return value
    end
    return nil
end

function Internal.NormalizePatrolPoints(points, fallbackX, fallbackY, fallbackZ)
    local output = {}
    local i
    local entry
    if type(points) == "table" then
        for i = 1, #points do
            entry = points[i]
            if type(entry) == "table" and entry.x ~= nil
                and entry.y ~= nil
            then
                output[#output + 1] = {
                    x = tonumber(entry.x) or fallbackX or 0,
                    y = tonumber(entry.y) or fallbackY or 0,
                    z = tonumber(entry.z) or fallbackZ or 0,
                }
            end
        end
    end
    if #output <= 0 then
        output[1] = {
            x = fallbackX or 0,
            y = fallbackY or 0,
            z = fallbackZ or 0,
        }
    end
    return output
end

return Types
