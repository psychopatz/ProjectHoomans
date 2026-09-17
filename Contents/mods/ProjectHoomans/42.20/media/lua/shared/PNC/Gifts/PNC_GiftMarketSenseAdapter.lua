-- Public MarketSense -> Gift Facts entry point.

PNC = PNC or {}
PNC.Gifts = PNC.Gifts or {}
PNC.Gifts.Foundation = PNC.Gifts.Foundation or {}

local Foundation = PNC.Gifts.Foundation
local Adapter = Foundation.MarketSenseAdapter or {}
Foundation.MarketSenseAdapter = Adapter

Adapter.VERSION = 1
Adapter.MAX_TAGS = 64
Adapter.MAX_TEXT = 160

local function bounded(value, maximum)
    value = tostring(value or "")
    if #value > (maximum or 96) then
        return string.sub(value, 1, maximum or 96)
    end
    return value
end

function Adapter.BuildFactsFromDetails(fullType, details, options)
    return Foundation.MarketSenseFacts.FromDetails(
        fullType, details, options)
end

function Adapter.BuildFacts(fullType, inventoryItem, options)
    fullType = bounded(fullType, Adapter.MAX_TEXT)
    options = type(options) == "table" and options or {}
    local details
    local tags
    local source
    local priceSource
    details, tags, source, priceSource = Foundation.MarketSenseSource.Fetch(
        fullType, inventoryItem, options)
    local buildOptions = {}
    local key
    local value
    for key, value in pairs(options) do buildOptions[key] = value end
    buildOptions.marketSenseTags = tags or options.marketSenseTags
    buildOptions.detailsSource = source
    buildOptions.priceSource = priceSource
    return Adapter.BuildFactsFromDetails(fullType, details, buildOptions)
end

Adapter.Build = Adapter.BuildFacts

require "PNC/Gifts/PNC_GiftMarketSenseSource"
require "PNC/Gifts/PNC_GiftMarketSenseCapabilities"
require "PNC/Gifts/PNC_GiftMarketSenseFacts"

return Adapter
