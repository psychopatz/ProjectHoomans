-- Pure recruitment interpretation of an NPC's persistent personality.
-- This is intentionally limited to the currently shipped personality rules.
-- New dimensions should be added here only after their balance is audited.

PNC = PNC or {}
PNC.RecruitmentPersonalityPolicy =
    PNC.RecruitmentPersonalityPolicy or {}

local Policy = PNC.RecruitmentPersonalityPolicy

Policy.VERSION = 1

local function finite(value, fallback)
    value = tonumber(value)
    if value == nil
        or value ~= value
        or value == math.huge
        or value == -math.huge
    then
        value = tonumber(fallback) or 0
    end
    return value
end

local function clampUnit(value)
    return math.max(0, math.min(1, finite(value, 0)))
end

local function modifier(id, label, value)
    return {
        id = tostring(id),
        label = tostring(label),
        value = finite(value, 0),
    }
end

local function copy(value)
    if type(value) ~= "table" then return value end
    local output = {}
    for key, item in pairs(value) do
        output[key] = copy(item)
    end
    return output
end

function Policy.Evaluate(personality, context)
    personality = type(personality) == "table" and personality or {}
    context = type(context) == "table" and context or {}

    local loyalty = clampUnit(personality.loyalty)
    local bravery = clampUnit(personality.bravery)
    local loyaltyScale = math.max(
        0,
        finite(context.loyaltyPenaltyScale, 20)
    )
    local braveryScale = math.max(
        0,
        finite(context.fearBraveryPenaltyScale, 25)
    )
    local loyaltyPenalty = loyalty * loyaltyScale
    local braveryPenalty = bravery * braveryScale

    return {
        version = Policy.VERSION,
        loyalty = loyalty,
        bravery = bravery,
        loyaltyPenalty = loyaltyPenalty,
        braveryPenalty = braveryPenalty,
        admire = {
            scoreModifier = -loyaltyPenalty,
            modifiers = {
                modifier(
                    "loyalty",
                    "Existing allegiance",
                    -loyaltyPenalty
                ),
            },
        },
        fear = {
            scoreModifier = -loyaltyPenalty - braveryPenalty,
            modifiers = {
                modifier(
                    "loyalty",
                    "Existing allegiance",
                    -loyaltyPenalty
                ),
                modifier(
                    "bravery",
                    "Resistance to fear",
                    -braveryPenalty
                ),
            },
        },
    }
end

function Policy.CopyBreakdown(evaluation)
    if type(evaluation) ~= "table" then return nil end
    return copy({
        version = evaluation.version,
        admire = evaluation.admire,
        fear = evaluation.fear,
    })
end

return Policy
