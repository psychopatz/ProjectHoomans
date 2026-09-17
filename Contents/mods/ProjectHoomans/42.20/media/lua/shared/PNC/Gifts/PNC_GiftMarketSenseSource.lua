-- Isolated MarketSense API invocation boundary.

PNC = PNC or {}
PNC.Gifts = PNC.Gifts or {}
PNC.Gifts.Foundation = PNC.Gifts.Foundation or {}
local Foundation = PNC.Gifts.Foundation
local Source = Foundation.MarketSenseSource or {}
Foundation.MarketSenseSource = Source

local function detailsFromAPI(api, fullType, inventoryItem)
    local ok
    local details
    local tags
    if inventoryItem ~= nil
        and type(api.GetPriceDetailsForInstance) == "function" then
        ok, details = pcall(api.GetPriceDetailsForInstance,
            fullType, inventoryItem, false)
        if ok and type(details) == "table" then
            if type(api.GetTags) == "function" then
                local tagOK
                tagOK, tags = pcall(api.GetTags, fullType)
                if not tagOK then tags = nil end
            end
            return details, tags, "marketsense.instance", "instance"
        end
    end
    if type(api.GetPriceDetails) == "function" then
        ok, details = pcall(api.GetPriceDetails, fullType)
        if ok and type(details) == "table" then
            if type(api.GetTags) == "function" then
                local tagOK
                tagOK, tags = pcall(api.GetTags, fullType)
                if not tagOK then tags = nil end
            end
            return details, tags, "marketsense.definition", "definition"
        end
    end
    return nil, nil, "price_details_unavailable", "unavailable"
end

function Source.Fetch(fullType, inventoryItem, options)
    options = type(options) == "table" and options or {}
    if type(options.marketSenseDetails) == "table" then
        return options.marketSenseDetails, options.marketSenseTags,
            "provided", options.priceSource or "provided"
    end
    local api = options.api or rawget(_G, "MarketSense")
    if type(api) ~= "table" then
        return nil, nil, "api_unavailable", "unavailable"
    end
    return detailsFromAPI(api, fullType, inventoryItem)
end

return Source
