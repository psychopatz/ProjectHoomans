PNC = PNC or {}
PNC.NeedsStateCodec = PNC.NeedsStateCodec or {}

local Codec = PNC.NeedsStateCodec
local Definitions = PNC.NeedsDefinitions

-- V2 keeps the tuple compact while adding the three player Nutrition values.
-- Nutrition presence is explicit so SIMPLE-mode records do not allocate or
-- rehydrate a detailed nutrition state when they are loaded.
Codec.VERSION = 2

local tuning = Definitions and Definitions.NUTRITION or {}
local MIN_CALORIES = tonumber(tuning.minimumCalories) or -2200
local MAX_CALORIES = tonumber(tuning.maximumCalories) or 3700
local MIN_MACRO = tonumber(tuning.minimumMacro) or -500
local MAX_MACRO = tonumber(tuning.maximumMacro) or 1000
local MIN_WEIGHT = tonumber(tuning.minimumWeight) or 35
local MAX_WEIGHT = tonumber(tuning.maximumWeight) or 200

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, tonumber(value) or minimum))
end

local function roundSigned(value)
    value = clamp(value, -1, 1) * 1000
    return value >= 0 and math.floor(value + 0.5)
        or math.ceil(value - 0.5)
end

local function decodeNutrition(packed)
    local calories = tonumber(packed[4])
        or (tonumber(tuning.defaultCalories) or 800)
    local weight = clamp(packed[5], 0, 2000) / 10
    return {
        calories = math.floor(clamp(calories, MIN_CALORIES, MAX_CALORIES)),
        calorieOverflow = 0,
        carbohydrates = math.floor(clamp(packed[8] or 0,
            MIN_MACRO, MAX_MACRO)),
        proteins = math.floor(clamp(packed[9] or 0,
            MIN_MACRO, MAX_MACRO)),
        lipids = math.floor(clamp(packed[10] or 0,
            MIN_MACRO, MAX_MACRO)),
        weight = math.max(MIN_WEIGHT, math.min(MAX_WEIGHT,
            weight > 0 and weight or (tonumber(tuning.defaultWeight) or 80))),
    }
end

local function decodeMorale(packed)
    local morale = { conditions = {}, lastDay = tonumber(packed[7]) }
    for modifierId, modifier in pairs(type(packed[6]) == "table"
        and packed[6] or {}) do
        if type(modifier) == "table" then
            morale.conditions[tostring(modifierId)] = {
                value = clamp(modifier[1], -1000, 1000) / 1000,
                days = math.max(0, math.floor(tonumber(modifier[2]) or 0)),
            }
        end
    end
    return morale
end

function Codec.Encode(records, at)
    local output = { v = Codec.VERSION, at = math.max(0, tonumber(at) or 0), n = {} }
    for id, state in pairs(type(records) == "table" and records or {}) do
        local needs = state.needs or state
        local nutrition = type(state.nutrition) == "table"
            and state.nutrition or nil
        -- Fixed slots avoid sparse ModData arrays. The marker is the only
        -- source of truth for whether the optional runtime state is active.
        local packed = {
            math.floor(clamp(needs.hunger, 0, 1) * 1000 + 0.5),
            math.floor(clamp(needs.thirst, 0, 1) * 1000 + 0.5),
            math.floor(clamp(needs.fatigue, 0, 1) * 1000 + 0.5),
            math.floor(clamp(nutrition and nutrition.calories or 0,
                MIN_CALORIES, MAX_CALORIES)),
            math.floor(clamp(nutrition and nutrition.weight or 0, 0, 1000)
                * 10 + 0.5),
            nil,
            nil,
            math.floor(clamp(nutrition and nutrition.carbohydrates or 0,
                MIN_MACRO, MAX_MACRO)),
            math.floor(clamp(nutrition and nutrition.proteins or 0,
                MIN_MACRO, MAX_MACRO)),
            math.floor(clamp(nutrition and nutrition.lipids or 0,
                MIN_MACRO, MAX_MACRO)),
            nutrition and 1 or 0,
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
    if type(raw) ~= "table" or type(raw.n) ~= "table" then
        if type(raw) == "table"
            and (raw.v ~= nil or raw.at ~= nil or raw.n ~= nil)
        then
            return {}, 0, "invalid_state"
        end
        return {}, 0, "empty_state"
    end
    if version ~= Codec.VERSION then
        return {}, 0, "version_mismatch"
    end
    local output = {}
    for id, packed in pairs(raw.n) do
        if type(packed) == "table" then
            local hasNutrition = packed[11] == 1
            -- Accept populated slots when the same-version marker is absent.
            -- This is a shape guard, not cross-version migration.
            if not hasNutrition
                and (packed[4] ~= 0 or packed[5] ~= 0
                    or packed[8] ~= 0 or packed[9] ~= 0 or packed[10] ~= 0)
            then
                hasNutrition = true
            end
            output[tostring(id)] = {
                needs = {
                    hunger = clamp(packed[1], 0, 1000) / 1000,
                    thirst = clamp(packed[2], 0, 1000) / 1000,
                    fatigue = clamp(packed[3], 0, 1000) / 1000,
                },
                nutrition = hasNutrition
                    and decodeNutrition(packed) or nil,
                morale = decodeMorale(packed),
            }
        end
    end
    return output, math.max(0, tonumber(raw.at) or 0), nil
end

return Codec
