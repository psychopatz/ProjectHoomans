-- Stateless scalar/map/point normalization. Domain schemas supply their policies.
local Codec = {}

function Codec.normalizeString(value)
    if value == nil or value == "" then
        return nil
    end
    return tostring(value)
end

function Codec.normalizeNumber(value, fallback)
    local numeric = tonumber(value)
    if numeric == nil then
        numeric = tonumber(fallback)
    end
    if numeric == nil then
        numeric = 0
    end
    return numeric
end

function Codec.hasTableEntries(source)
    local _
    if type(source) ~= "table" then
        return false
    end
    for _, _ in pairs(source) do
        return true
    end
    return false
end

function Codec.copyStringMap(source)
    local output = {}
    local key
    local value
    if type(source) ~= "table" then
        return output
    end
    for key, value in pairs(source) do
        key = Codec.normalizeString(key)
        value = Codec.normalizeString(value)
        if key and value then
            output[key] = value
        end
    end
    return output
end

function Codec.copyPoints(points, fallbackX, fallbackY, fallbackZ)
    local output = {}
    local i
    local entry
    if type(points) == "table" then
        for i = 1, #points do
            entry = points[i]
            if type(entry) == "table" and entry.x ~= nil and entry.y ~= nil then
                output[#output + 1] = {
                    x = Codec.normalizeNumber(entry.x, fallbackX),
                    y = Codec.normalizeNumber(entry.y, fallbackY),
                    z = Codec.normalizeNumber(entry.z, fallbackZ),
                }
            end
        end
    end
    if #output <= 0 then
        output[1] = {
            x = Codec.normalizeNumber(fallbackX, 0),
            y = Codec.normalizeNumber(fallbackY, 0),
            z = Codec.normalizeNumber(fallbackZ, 0),
        }
    end
    return output
end

return Codec
