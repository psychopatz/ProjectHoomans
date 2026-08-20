local Conversation = PNC.Conversation
local Composer = Conversation.Composer
Composer.Internal = Composer.Internal or {}
local Internal = Composer.Internal

-- The needs block normally supplies the gift text source. Keep a neutral
-- fallback so an inventory result can never become a silent transaction when
-- a stale/reloaded conversation view no longer has its active block attached.
local NEEDS_FALLBACK_SOURCE = {
    modID = "ProjectHoomans",
    pathPattern = "media/conversation/needs/neutral/{language}/basic.json",
    domain = "pnc.needs.neutral.basic",
}

local GIFT_OFFER_KEYS = {
    "gift.offer.single",
    "gift.offer.single.alt",
    "gift.offer.multiple",
    "gift.offer.multiple.alt",
}

local function friendlyGiftName(itemType)
    local value = tostring(itemType or "")
    local short = string.match(value, "([^%.]+)$") or value
    short = string.gsub(short, "_", " ")
    short = string.gsub(short, "(%l)(%u)", "%1 %2")
    short = string.gsub(short, "(%a)(%d)", "%1 %2")
    short = string.gsub(short, "(%d)(%a)", "%1 %2")
    short = string.gsub(short, "^%s+", "")
    short = string.gsub(short, "%s+$", "")
    return short ~= "" and short or "item"
end

local function giftArticle(value)
    local initial = string.lower(string.sub(tostring(value or "item"), 1, 1))
    return string.find("aeiou", initial, 1, true) and "an" or "a"
end

local function formatGiftOffer(itemTypes)
    local counts = {}
    local order = {}
    for _, itemType in ipairs(type(itemTypes) == "table" and itemTypes or {}) do
        local name = friendlyGiftName(itemType)
        if not counts[name] then
            counts[name] = 0
            order[#order + 1] = name
        end
        counts[name] = counts[name] + 1
    end
    local total = 0
    local parts = {}
    for _, name in ipairs(order) do
        local count = counts[name]
        total = total + count
        parts[#parts + 1] = count > 1
            and tostring(count) .. " x " .. name or name
    end
    if total == 1 then
        local name = order[1] or "item"
        return {
            count = 1,
            itemName = giftArticle(name) .. " " .. name,
            itemSummary = name,
            variant = "single",
        }
    end
    return {
        count = total,
        itemName = #parts > 0 and table.concat(parts, ", ") or "these items",
        itemSummary = #parts > 0 and table.concat(parts, ", ") or "these items",
        variant = "multiple",
    }
end

local function giftOfferKey(offer, itemTypes, context)
    local hash = 17
    local source = table.concat({
        tostring(context and context.npcID or ""),
        table.concat(type(itemTypes) == "table" and itemTypes or {}, ":"),
        tostring(math.floor(tonumber(context and context.worldAgeHours) or 0) / 24),
    }, "|")
    for index = 1, #source do
        hash = (hash * 31 + string.byte(source, index)) % 2147483647
    end
    if offer.variant == "single" then
        return hash % 2 == 0 and "gift.offer.single" or "gift.offer.single.alt"
    end
    return hash % 2 == 0 and "gift.offer.multiple" or "gift.offer.multiple.alt"
end


Internal.NEEDS_FALLBACK_SOURCE = NEEDS_FALLBACK_SOURCE
Internal.GIFT_OFFER_KEYS = GIFT_OFFER_KEYS
Internal.FormatGiftOffer = formatGiftOffer
Internal.GiftOfferKey = giftOfferKey

return Composer

