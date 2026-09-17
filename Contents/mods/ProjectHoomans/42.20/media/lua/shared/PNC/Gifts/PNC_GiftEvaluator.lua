-- Pure bundle aggregation for gift valuation.

PNC = PNC or {}
PNC.Gifts = PNC.Gifts or {}
PNC.Gifts.Foundation = PNC.Gifts.Foundation or {}
local Foundation = PNC.Gifts.Foundation
local Evaluator = Foundation.Evaluator or {}
Foundation.Evaluator = Evaluator
local Contract = Foundation.Contract
local Support
local Item

Evaluator.VERSION = 1
Evaluator.DEFAULTS = Evaluator.DEFAULTS or {
    priceAnchor = 10, priceCeiling = 250, priceWeight = 0.75,
    baseItemValue = 0.25, quantityExponent = 0.65,
    duplicatePenalty = 0.35, minimumNeedMultiplier = 0.65,
    maximumNeedMultiplier = 1.60, approvalScale = 2.20,
    respectScale = 0.65, familiarityPerItem = 0.12,
    maximumApproval = 10, maximumRespect = 6, maximumFamiliarity = 4,
}

function Evaluator.Evaluate(items, profile, options)
    options = type(options) == "table" and options or {}
    local bundle = Contract and Contract.NormalizeBundle
        and Contract.NormalizeBundle(items) or {}
    local output = {
        schemaVersion = Evaluator.VERSION,
        status = #bundle > 0 and "evaluated" or "empty",
        accepted = #bundle > 0, disposition = "neutral", score = 0,
        totalQuantity = 0, totalPrice = 0,
        confidence = #bundle > 0 and 0.90 or 0,
        bestKey = nil, bestType = nil, breakdown = {}, diagnostics = {},
        relationshipEffect = { approval = 0, respect = 0, familiarity = 0 },
    }
    local state = {
        seenKeys = {},
        valueSensitivity = Foundation.PreferenceProfile
            and Foundation.PreferenceProfile.GetValueSensitivity
            and Foundation.PreferenceProfile.GetValueSensitivity(profile) or 1,
        economicMultiplier = Support.MaterialismMultiplier(options),
    }
    local strongestMagnitude = 0
    local strongestPreferenceMagnitude = 0
    local approval = 0
    local respect = 0
    local familiarity = 0
    local index
    local entry
    local result
    for index = 1, #bundle do
        entry = bundle[index]
        result = Item.Evaluate(entry, profile, options, state)
        output.score = output.score + result.value
        output.totalQuantity = output.totalQuantity + result.quantity
        output.totalPrice = output.totalPrice + result.unitPrice * result.quantity
        output.breakdown[#output.breakdown + 1] = result.row
        if result.magnitude > strongestMagnitude then
            strongestMagnitude = result.magnitude
            output.bestKey = result.key
            output.bestType = result.preference.disposition
        end
        if result.preferenceMagnitude > strongestPreferenceMagnitude then
            strongestPreferenceMagnitude = result.preferenceMagnitude
            output.disposition = result.preference.disposition
        end
        approval = approval + result.value * Support.NumberOption(options,
            "approvalScale", Evaluator.DEFAULTS.approvalScale)
        respect = respect + (result.positiveValue
            + result.negativeValue * 0.25)
            * Support.NumberOption(options, "respectScale",
                Evaluator.DEFAULTS.respectScale)
        familiarity = familiarity + Support.NumberOption(options,
            "familiarityPerItem", Evaluator.DEFAULTS.familiarityPerItem)
    end
    output.score = Support.Finite(output.score, 0) or 0
    output.totalQuantity = math.max(0, output.totalQuantity)
    output.totalPrice = math.max(0, output.totalPrice)
    output.confidence = #bundle > 0 and Support.Clamp(0.85
        + (1 - math.min(1, output.totalQuantity / 20)) * 0.10,
        0, 0.95) or 0
    output.relationshipEffect.approval = Support.Clamp(approval, -10,
        Support.NumberOption(options, "maximumApproval",
            Evaluator.DEFAULTS.maximumApproval))
    output.relationshipEffect.respect = Support.Clamp(respect, -6,
        Support.NumberOption(options, "maximumRespect",
            Evaluator.DEFAULTS.maximumRespect))
    output.relationshipEffect.familiarity = Support.Clamp(familiarity, 0,
        Support.NumberOption(options, "maximumFamiliarity",
            Evaluator.DEFAULTS.maximumFamiliarity))
    if #bundle == 0 then
        output.diagnostics[#output.diagnostics + 1] = {
            code = "empty_bundle",
            detail = "No gift entries were supplied for evaluation.",
        }
    else
        output.diagnostics[#output.diagnostics + 1] = {
            code = "identity_seed_preferences",
            detail = "Preferences were derived from the NPC identity seed; no item map was persisted.",
        }
    end
    if output.totalQuantity > 999 then
        output.totalQuantity = 999
        output.diagnostics[#output.diagnostics + 1] = {
            code = "quantity_capped",
            detail = "Bundle quantity was capped for bounded dialogue and relationship effects.",
        }
    end
    return Contract and Contract.NormalizeEvaluation
        and Contract.NormalizeEvaluation(output) or output
end

Evaluator.EvaluateBundle = Evaluator.Evaluate

require "PNC/Gifts/PNC_GiftEvaluatorSupport"
require "PNC/Gifts/PNC_GiftEvaluatorItem"
Support = Foundation.EvaluatorSupport
Item = Foundation.EvaluatorItem

return Evaluator
