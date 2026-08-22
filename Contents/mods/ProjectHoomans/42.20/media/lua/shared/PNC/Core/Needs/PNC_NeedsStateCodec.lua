PNC = PNC or {}
PNC.NeedsStateCodec = PNC.NeedsStateCodec or {}

local Codec = PNC.NeedsStateCodec
-- Version 1 readers ignore the optional morale slots, so the compact layout
-- remains backward-compatible and does not force a ModData migration.
Codec.VERSION = 1

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, tonumber(value) or minimum))
end

local function roundSigned(value)
    value = clamp(value, -1, 1) * 1000
    return value >= 0 and math.floor(value + 0.5)
        or math.ceil(value - 0.5)
end

function Codec.Encode(records, at)
    local output = { v = Codec.VERSION, at = math.max(0, tonumber(at) or 0), n = {} }
    for id, state in pairs(type(records) == "table" and records or {}) do
        local needs = state.needs or state
        local nutrition = state.nutrition or {}
        local packed = {
            math.floor(clamp(needs.hunger, 0, 1) * 1000 + 0.5),
            math.floor(clamp(needs.thirst, 0, 1) * 1000 + 0.5),
            math.floor(clamp(needs.fatigue, 0, 1) * 1000 + 0.5),
            math.floor(tonumber(nutrition.calories) or 0),
            math.floor(clamp(nutrition.weight, 0, 1000) * 10 + 0.5),
        }
        local morale = state.morale or {}
        local modifiers = {}
        local hasModifiers = false
        for modifierId, modifier in pairs(morale.conditions or {}) do
            hasModifiers = true
            modifiers[tostring(modifierId)] = {
                roundSigned(modifier.value),
                math.max(0, math.floor(tonumber(modifier.days) or 0)),
            }
        end
        if hasModifiers then packed[6] = modifiers end
        if morale.lastDay ~= nil then packed[7] = math.floor(morale.lastDay) end
        output.n[tostring(id)] = packed
    end
    return output
end

function Codec.Decode(raw)
    local version = type(raw) == "table" and tonumber(raw.v) or nil
    if type(raw) ~= "table" or version ~= Codec.VERSION
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
                morale = { conditions = {}, lastDay = tonumber(packed[7]) },
            }
            for modifierId, modifier in pairs(type(packed[6]) == "table"
                and packed[6] or {}) do
                if type(modifier) == "table" then
                    output[tostring(id)].morale.conditions[tostring(modifierId)] = {
                        value = clamp(modifier[1], -1000, 1000) / 1000,
                        days = math.max(0, math.floor(tonumber(modifier[2]) or 0)),
                    }
                end
            end
        end
    end
    return output, math.max(0, tonumber(raw.at) or 0)
end

return Codec
