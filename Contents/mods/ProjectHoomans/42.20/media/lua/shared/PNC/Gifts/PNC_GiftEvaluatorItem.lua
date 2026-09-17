-- Pure valuation of one gift entry; bundle aggregation lives in the parent.

PNC = PNC or {}
PNC.Gifts = PNC.Gifts or {}
PNC.Gifts.Foundation = PNC.Gifts.Foundation or {}
local Foundation = PNC.Gifts.Foundation
local Item = Foundation.EvaluatorItem or {}
Foundation.EvaluatorItem = Item
local Support = Foundation.EvaluatorSupport
local Preference = Foundation.PreferenceProfile
local Evaluator = Foundation.Evaluator

function Item.Evaluate(entry, profile, options, state)
    local facts = entry.facts or entry
    local quantity = math.max(1, math.min(999,
        math.floor(Support.Finite(entry.quantity, 1) or 1)))
    local unitPrice = Support.Finite(facts and facts.price, nil)
        or Support.Finite(entry.unitPrice, 0) or 0
    unitPrice = math.max(0, unitPrice)
    local band = Support.PriceBand(unitPrice, options)
    local preference = Preference and Preference.Resolve
        and Preference.Resolve(profile, facts) or {
            disposition = "neutral", multiplier = 1, confidence = 0,
        }
    preference = Support.CopyPreference(preference)
    local key = Support.ItemKey(facts, entry.fullType)
    local previous = state.seenKeys[key] or 0
    state.seenKeys[key] = previous + quantity
    local duplicateMultiplier = 1 / (1 + previous
        * Support.NumberOption(options, "duplicatePenalty",
            Evaluator.DEFAULTS.duplicatePenalty))
    local quantityWeight = quantity ^ Support.NumberOption(options,
        "quantityExponent", Evaluator.DEFAULTS.quantityExponent)
    local need = Support.NeedMultiplier(facts, options)
    local baseValue = Support.NumberOption(options, "baseItemValue",
        Evaluator.DEFAULTS.baseItemValue)
    local value = (baseValue
        + band * Support.NumberOption(options, "priceWeight",
            Evaluator.DEFAULTS.priceWeight) * state.valueSensitivity)
        * quantityWeight * duplicateMultiplier
        * preference.multiplier * need * state.economicMultiplier
    return {
        key = key,
        value = value,
        magnitude = math.abs(value),
        positiveValue = math.max(0, value),
        negativeValue = math.min(0, value),
        preferenceMagnitude = math.abs((preference.multiplier or 1) - 1),
        preference = preference,
        quantity = quantity,
        unitPrice = unitPrice,
        row = {
            fullType = Support.Bounded(facts and facts.fullType
                or entry.fullType, 160),
            quantity = quantity, unitPrice = unitPrice, priceBand = band,
            disposition = preference.disposition,
            multiplier = preference.multiplier, contribution = value,
            duplicateMultiplier = duplicateMultiplier, needMultiplier = need,
            matchType = preference.matchType, matchKey = preference.matchKey,
        },
    }
end

return Item
