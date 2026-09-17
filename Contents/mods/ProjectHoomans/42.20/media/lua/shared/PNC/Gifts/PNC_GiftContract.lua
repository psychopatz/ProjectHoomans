-- Bounded, side-effect-free gift data contract.

PNC = PNC or {}
PNC.Gifts = PNC.Gifts or {}
PNC.Gifts.Foundation = PNC.Gifts.Foundation or {}

local Foundation = PNC.Gifts.Foundation
local Contract = Foundation.Contract or {}
Foundation.Contract = Contract

Contract.VERSION = 1
Contract.MAX_ITEMS = 32
Contract.MAX_TAGS = 64
Contract.MAX_DIAGNOSTICS = 24
Contract.MAX_TEXT = 160
Contract.DISPOSITIONS = {
    FAVORITE = "favorite",
    LIKED = "liked",
    NEUTRAL = "neutral",
    DISLIKED = "disliked",
    HATED = "hated",
}

local function text(value, maximum)
    value = tostring(value or "")
    if #value > (maximum or Contract.MAX_TEXT) then
        return string.sub(value, 1, maximum or Contract.MAX_TEXT)
    end
    return value
end

local function finite(value, fallback)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge then
        return tonumber(fallback)
    end
    return value
end

local function list(source, maximum)
    local output = {}
    local seen = {}
    local index
    local value
    maximum = maximum or 64
    if type(source) ~= "table" then return output end
    for index = 1, #source do
        if #output >= maximum then break end
        value = source[index]
        if value ~= nil and value ~= "" and not seen[value] then
            seen[value] = true
            output[#output + 1] = value
        end
    end
    return output
end

local function booleanMap(source, maximum)
    local output = {}
    local count = 0
    local key
    if type(source) ~= "table" then return output end
    for key in pairs(source) do
        if count >= (maximum or 64) then break end
        if type(key) == "string" and source[key] == true then
            output[text(key, 96)] = true
            count = count + 1
        end
    end
    return output
end

local function quantity(value)
    return math.max(1, math.min(999,
        math.floor(finite(value, 1) or 1)))
end

function Contract.NormalizeQuantity(value)
    return quantity(value)
end

function Contract.NormalizeFacts(value)
    local source = type(value) == "table" and value or {}
    local output = {
        schemaVersion = Contract.VERSION,
        fullType = text(source.fullType, Contract.MAX_TEXT),
        primary = text(source.primary, 96),
        category = text(source.category, 96),
        subcategory = text(source.subcategory, 96),
        leaf = text(source.leaf, 96),
        primaryKey = text(source.primaryKey, 96),
        categoryKey = text(source.categoryKey, 96),
        subcategoryKey = text(source.subcategoryKey, 96),
        leafKey = text(source.leafKey, 96),
        tags = list(source.tags, Contract.MAX_TAGS),
        expandedTags = list(source.expandedTags, Contract.MAX_TAGS),
        marketSenseTags = list(source.marketSenseTags, Contract.MAX_TAGS),
        tagSet = booleanMap(source.tagSet, Contract.MAX_TAGS),
        price = math.max(0, finite(source.price, 0) or 0),
        priceSource = text(source.priceSource, 64),
        marketRole = text(source.marketRole, 64),
        condition = math.max(0, math.min(1,
            finite(source.condition, 1) or 1)),
        capabilities = booleanMap(source.capabilities, 32),
        preferenceCandidates = {},
    }
    local index
    local candidate
    for index = 1, math.min(#(source.preferenceCandidates or {}), 16) do
        candidate = source.preferenceCandidates[index]
        if type(candidate) == "table" then
            output.preferenceCandidates[#output.preferenceCandidates + 1] = {
                type = text(candidate.type, 32),
                key = text(candidate.key, 96),
                value = text(candidate.value, 96),
                priority = math.max(0, math.min(10,
                    finite(candidate.priority, 0) or 0)),
            }
        end
    end
    if output.fullType == "" then output.fullType = nil end
    if output.priceSource == "" then output.priceSource = nil end
    if output.marketRole == "" then output.marketRole = nil end
    return output
end

function Contract.NormalizeItem(value)
    local source = type(value) == "table" and value or {}
    local facts = source.facts or source.itemFacts
    if facts == nil and (source.price ~= nil or source.tags ~= nil
        or source.expandedTags ~= nil or source.subcategory ~= nil
        or source.capabilities ~= nil
        or source.preferenceCandidates ~= nil) then
        facts = source
    end
    local output = {
        itemID = text(source.itemID, 96),
        fullType = text(source.fullType, Contract.MAX_TEXT),
        quantity = quantity(source.quantity),
    }
    if output.itemID == "" then output.itemID = nil end
    if output.fullType == "" then output.fullType = nil end
    if type(facts) == "table" then
        output.facts = Contract.NormalizeFacts(facts)
    end
    return output
end

function Contract.NormalizeBundle(value)
    local source = type(value) == "table" and value or {}
    local output = {}
    local index
    local item
    for index = 1, math.min(#source, Contract.MAX_ITEMS) do
        item = Contract.NormalizeItem(source[index])
        if item.itemID or item.fullType or item.facts then
            output[#output + 1] = item
        end
    end
    return output
end

function Contract.NormalizeOffer(value)
    local source = type(value) == "table" and value or {}
    return {
        schemaVersion = Contract.VERSION,
        action = text(source.action, 48),
        rawText = text(source.rawText, Contract.MAX_TEXT),
        items = Contract.NormalizeBundle(source.items or source.bundle),
        vague = source.vague == true,
    }
end

-- Keep this entry point sufficient for isolated tests and consumers that only
-- require the main contract file.
require "PNC/Gifts/PNC_GiftEvaluationContract"

return Contract
