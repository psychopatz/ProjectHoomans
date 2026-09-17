-- Bounded normalization for gift evaluation results.

PNC = PNC or {}
PNC.Gifts = PNC.Gifts or {}
PNC.Gifts.Foundation = PNC.Gifts.Foundation or {}

local Foundation = PNC.Gifts.Foundation
local Contract = Foundation.Contract or {}
Foundation.Contract = Contract

local function text(value, maximum)
    value = tostring(value or "")
    if #value > (maximum or 96) then
        return string.sub(value, 1, maximum or 96)
    end
    return value
end

local function number(value, fallback)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge then
        return fallback
    end
    return value
end

local function clamp(value, low, high)
    return math.max(low, math.min(high, number(value, low) or low))
end

function Contract.NormalizeEvaluation(value)
    local source = type(value) == "table" and value or {}
    local relationship = type(source.relationshipEffect) == "table"
        and source.relationshipEffect or {}
    local output = {
        schemaVersion = Contract.VERSION,
        status = text(source.status, 48),
        accepted = source.accepted == true,
        disposition = text(source.disposition, 32),
        score = number(source.score, 0) or 0,
        totalQuantity = math.max(0, math.min(999,
            math.floor(number(source.totalQuantity, 0) or 0))),
        totalPrice = math.max(0, number(source.totalPrice, 0) or 0),
        confidence = clamp(source.confidence, 0, 1),
        bestKey = text(source.bestKey, 96),
        bestType = text(source.bestType, 32),
        breakdown = {},
        diagnostics = {},
        relationshipEffect = {
            approval = number(relationship.approval, 0) or 0,
            respect = number(relationship.respect, 0) or 0,
            familiarity = number(relationship.familiarity, 0) or 0,
        },
    }
    local index
    local item
    for index = 1, math.min(#(source.breakdown or {}), Contract.MAX_ITEMS) do
        item = source.breakdown[index]
        if type(item) == "table" then
            output.breakdown[#output.breakdown + 1] = {
                fullType = text(item.fullType, Contract.MAX_TEXT),
                quantity = math.max(1, math.min(999,
                    math.floor(number(item.quantity, 1) or 1))),
                unitPrice = math.max(0, number(item.unitPrice, 0) or 0),
                priceBand = clamp(item.priceBand, 0, 1),
                disposition = text(item.disposition, 32),
                multiplier = number(item.multiplier, 1) or 1,
                contribution = number(item.contribution, 0) or 0,
                duplicateMultiplier = number(item.duplicateMultiplier, 1)
                    or 1,
                needMultiplier = number(item.needMultiplier, 1) or 1,
                matchType = text(item.matchType, 32),
                matchKey = text(item.matchKey, 96),
            }
        end
    end
    local diagnostic
    for index = 1, math.min(#(source.diagnostics or {}),
        Contract.MAX_DIAGNOSTICS) do
        diagnostic = source.diagnostics[index]
        if type(diagnostic) == "table" then
            output.diagnostics[#output.diagnostics + 1] = {
                code = text(diagnostic.code, 48),
                detail = text(diagnostic.detail, 160),
            }
        elseif type(diagnostic) == "string" then
            output.diagnostics[#output.diagnostics + 1] = {
                code = text(diagnostic, 48),
            }
        end
    end
    if output.status == "" then output.status = "evaluated" end
    if output.disposition == "" then output.disposition = "neutral" end
    if output.bestKey == "" then output.bestKey = nil end
    if output.bestType == "" then output.bestType = nil end
    return output
end

return Contract
