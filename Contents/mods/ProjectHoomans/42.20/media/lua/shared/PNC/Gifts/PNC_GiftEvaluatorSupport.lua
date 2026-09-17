-- Numeric and context helpers for the pure gift evaluator.

PNC = PNC or {}
PNC.Gifts = PNC.Gifts or {}
PNC.Gifts.Foundation = PNC.Gifts.Foundation or {}
local Foundation = PNC.Gifts.Foundation
local Support = Foundation.EvaluatorSupport or {}
Foundation.EvaluatorSupport = Support
local Evaluator = Foundation.Evaluator

function Support.Finite(value, fallback)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge then
        return tonumber(fallback)
    end
    return value
end

function Support.Clamp(value, minimum, maximum)
    value = Support.Finite(value, minimum) or minimum
    return math.max(minimum, math.min(maximum, value))
end

function Support.Bounded(value, maximum)
    value = tostring(value or "")
    if #value > (maximum or 96) then
        return string.sub(value, 1, maximum or 96)
    end
    return value
end

function Support.NumberOption(options, key, fallback)
    return Support.Finite(options and options[key], fallback) or fallback
end

function Support.PriceBand(price, options)
    local anchor = math.max(0.01, Support.NumberOption(options,
        "priceAnchor", Evaluator.DEFAULTS.priceAnchor))
    local ceiling = math.max(anchor, Support.NumberOption(options,
        "priceCeiling", Evaluator.DEFAULTS.priceCeiling))
    price = math.max(0, Support.Finite(price, 0) or 0)
    local denominator = math.log(1 + ceiling / anchor)
    if denominator <= 0 then return 0 end
    return Support.Clamp(math.log(1 + price / anchor) / denominator, 0, 1)
end

function Support.ItemKey(facts, fallback)
    if type(facts) == "table" then
        return Support.Bounded(facts.subcategoryKey or facts.categoryKey
            or facts.primaryKey or facts.leafKey or facts.fullType
            or fallback or "gift", 96)
    end
    return Support.Bounded(fallback or "gift", 96)
end

function Support.NeedMultiplier(facts, options)
    options = type(options) == "table" and options or {}
    local values = options.needMultipliers
    if type(values) ~= "table" or type(facts) ~= "table" then return 1 end
    local candidates = {
        facts.subcategoryKey, facts.categoryKey,
        facts.primaryKey, facts.leafKey,
    }
    local index
    local value
    for index = 1, #candidates do
        value = Support.Finite(values[candidates[index]])
        if value ~= nil then
            return Support.Clamp(value,
                Support.NumberOption(options, "minimumNeedMultiplier",
                    Evaluator.DEFAULTS.minimumNeedMultiplier),
                Support.NumberOption(options, "maximumNeedMultiplier",
                    Evaluator.DEFAULTS.maximumNeedMultiplier))
        end
    end
    local capabilityOrder = {
        "edible", "drinkable", "medical", "weapon", "tool", "consumable",
    }
    local capability
    if type(facts.capabilities) == "table" then
        for index = 1, #capabilityOrder do
            capability = capabilityOrder[index]
            if facts.capabilities[capability] == true then
                value = Support.Finite(values[capability])
                if value ~= nil then
                    return Support.Clamp(value,
                        Support.NumberOption(options, "minimumNeedMultiplier",
                            Evaluator.DEFAULTS.minimumNeedMultiplier),
                        Support.NumberOption(options, "maximumNeedMultiplier",
                            Evaluator.DEFAULTS.maximumNeedMultiplier))
                end
            end
        end
    end
    return 1
end

function Support.MaterialismMultiplier(options)
    local personality = options and options.personality
    local materialism = personality and Support.Finite(personality.materialism)
    if materialism == nil then return 1 end
    return 0.80 + Support.Clamp(materialism, 0, 1) * 0.60
end

function Support.CopyPreference(value)
    value = type(value) == "table" and value or {}
    return {
        disposition = Support.Bounded(value.disposition, 32),
        multiplier = Support.Finite(value.multiplier, 1) or 1,
        confidence = Support.Clamp(value.confidence, 0, 1),
        generated = value.generated == true,
        reason = Support.Bounded(value.reason, 64),
        matchType = Support.Bounded(value.matchType, 32),
        matchKey = Support.Bounded(value.matchKey, 96),
    }
end

return Support
