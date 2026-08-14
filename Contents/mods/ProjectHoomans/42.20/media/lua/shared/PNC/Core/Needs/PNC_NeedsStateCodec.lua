PNC = PNC or {}
PNC.NeedsStateCodec = PNC.NeedsStateCodec or {}

local Codec = PNC.NeedsStateCodec
Codec.VERSION = 1

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, tonumber(value) or minimum))
end

function Codec.Encode(records, at)
    local output = { v = Codec.VERSION, at = math.max(0, tonumber(at) or 0), n = {} }
    for id, state in pairs(type(records) == "table" and records or {}) do
        local needs = state.needs or state
        local nutrition = state.nutrition or {}
        output.n[tostring(id)] = {
            math.floor(clamp(needs.hunger, 0, 1) * 1000 + 0.5),
            math.floor(clamp(needs.thirst, 0, 1) * 1000 + 0.5),
            math.floor(clamp(needs.fatigue, 0, 1) * 1000 + 0.5),
            math.floor(tonumber(nutrition.calories) or 0),
            math.floor(clamp(nutrition.weight, 0, 1000) * 10 + 0.5),
        }
    end
    return output
end

function Codec.Decode(raw)
    if type(raw) ~= "table" or tonumber(raw.v) ~= Codec.VERSION
        or type(raw.n) ~= "table" then return {}, 0, "invalid_v1" end
    local output = {}
    for id, packed in pairs(raw.n) do
        if type(packed) == "table" then
            output[tostring(id)] = {
                needs = {
                    hunger = clamp(packed[1], 0, 1000) / 1000,
                    thirst = clamp(packed[2], 0, 1000) / 1000,
                    fatigue = clamp(packed[3], 0, 1000) / 1000,
                },
                nutrition = {
                    calories = math.floor(tonumber(packed[4]) or 0),
                    weight = clamp(packed[5], 0, 2000) / 10,
                },
            }
        end
    end
    return output, math.max(0, tonumber(raw.at) or 0)
end

return Codec
