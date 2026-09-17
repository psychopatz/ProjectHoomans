-- Shared classification for semantic gift offers.
--
-- The parser recognizes speech; this module only decides whether an OFFER is
-- an item gift or the older group "who wants ..." offer. It never opens UI,
-- moves inventory, or changes relationships.
PNC = PNC or {}
PNC.Gifts = PNC.Gifts or {}
PNC.Gifts.Foundation = PNC.Gifts.Foundation or {}

local SemanticOffer = PNC.Gifts.Foundation.SemanticOffer or {}
PNC.Gifts.Foundation.SemanticOffer = SemanticOffer

SemanticOffer.VERSION = 1

local GENERIC_TERMS = {
    gift = true,
    present = true,
    something = true,
    anything = true,
    item = true,
}

local function copyValue(value, depth)
    if type(value) ~= "table" then return value end
    depth = tonumber(depth) or 0
    if depth >= 8 then return nil end
    local output = {}
    for key, item in pairs(value) do
        output[key] = copyValue(item, depth + 1)
    end
    return output
end

local function normalized(value)
    value = string.lower(tostring(value or ""))
    value = string.gsub(value, "[^%w]+", " ")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    return value
end

local function objectQuery(object)
    if type(object) ~= "table" then return "" end
    return normalized(object.text or object.value or object.name
        or object.category or object.concept or "")
end

local function isGeneric(object, query)
    if type(object) ~= "table" then return true end
    if object.reference ~= nil then return true end
    query = query or objectQuery(object)
    if query == "" then return true end
    if GENERIC_TERMS[query] then return true end
    if object.concept == "GIFT" or object.concept == "PRESENT" then
        return true
    end
    if object.category == "GIFT" or object.category == "PRESENT" then
        return true
    end
    return false
end

function SemanticOffer.Classify(ir)
    if type(ir) ~= "table"
        or (ir.intent ~= "OFFER" and ir.speechAct ~= "OFFER")
    then
        return nil
    end
    local extensions = type(ir.extensions) == "table"
        and ir.extensions or {}
    local marker = extensions.giftOffer
    if marker == nil and tostring(ir.action or "") ~= "GIFT" then
        return nil
    end

    local object = type(ir.object) == "table" and ir.object or nil
    local query = objectQuery(object)
    local selection = isGeneric(object, query)
    local output = {
        schemaVersion = SemanticOffer.VERSION,
        recognized = true,
        mode = selection and "selection" or "explicit",
        reason = selection and "gift_item_selection_required"
            or "gift_item_query_ready",
        query = query,
        quantity = object and object.quantity or nil,
        object = copyValue(object),
        marker = copyValue(marker),
    }
    return output
end

function SemanticOffer.IsGiftOffer(ir)
    return SemanticOffer.Classify(ir) ~= nil
end

return SemanticOffer
