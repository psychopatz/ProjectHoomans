-- Surface grammar normalization and PZ-font-safe punctuation helpers.
-- Fixes missing-glyph Unicode dashes (e.g. "Good—nobody" -> "Good - nobody"),
-- normalizes smart quotes/ellipses, articles, safe clause stitching, and
-- compressed semantic loot summaries.

PNC = PNC or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Grammar = PNC.ConvoEngine.GrammarJoin or {}
PNC.ConvoEngine.GrammarJoin = Grammar

Grammar.VERSION = 2

local EM_DASH = "\226\128\148"
local EN_DASH = "\226\128\147"
local ELLIPSIS = "\226\128\166"
local RSQUOTE = "\226\128\153"
local LSQUOTE = "\226\128\152"
local LDQUOTE = "\226\128\156"
local RDQUOTE = "\226\128\157"

local NO_ARTICLE_WORDS = {
    here = true,
    there = true,
    ["over there"] = true,
    ["right here"] = true,
    home = true,
    camp = true,
    base = true,
    me = true,
    us = true,
}

local function trim(s)
    return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

function Grammar.CleanSurface(text)
    if text == nil then return nil end
    local s = tostring(text)
    if s == "" then return nil end
    -- Project Zomboid's bitmap font lacks Unicode em/en-dash & smart quote glyphs.
    s = string.gsub(s, "%s*" .. EM_DASH .. "%s*", " - ")
    s = string.gsub(s, "%s*" .. EN_DASH .. "%s*", " - ")
    s = string.gsub(s, ELLIPSIS, "...")
    s = string.gsub(s, RSQUOTE, "'")
    s = string.gsub(s, LSQUOTE, "'")
    s = string.gsub(s, LDQUOTE, '"')
    s = string.gsub(s, RDQUOTE, '"')
    -- Collapse repeated spaces and fix space before punctuation.
    s = string.gsub(s, "%s+", " ")
    s = string.gsub(s, "%s+([,%.!%?])", "%1")
    s = trim(s)
    return s ~= "" and s or nil
end

local LEADING_ARTICLES = {
    the = true, a = true, an = true,
    this = true, that = true, my = true, our = true, your = true,
}

function Grammar.FormatTargetWithArticle(target)
    local t = trim(target)
    if t == "" then return nil end
    local lower = string.lower(t)
    if NO_ARTICLE_WORDS[lower] then return t end
    local firstWord = string.match(lower, "^(%S+)%s+")
    if firstWord and LEADING_ARTICLES[firstWord] then
        return t
    end
    return "the " .. t
end

function Grammar.JoinClause(prefix, body, sep)
    local p = Grammar.CleanSurface(prefix)
    local b = Grammar.CleanSurface(body)
    if not p then return b end
    if not b then return p end
    local endsPunct = string.match(p, "[%.!%?,:%-]$") ~= nil
    if endsPunct then
        return Grammar.CleanSurface(p .. " " .. b)
    end
    return Grammar.CleanSurface(p .. (sep or ", ") .. b)
end

function Grammar.JoinNaturalList(parts)
    if type(parts) ~= "table" or #parts == 0 then return nil end
    if #parts == 1 then return Grammar.CleanSurface(parts[1]) end
    if #parts == 2 then
        return Grammar.CleanSurface(tostring(parts[1]) .. " and " .. tostring(parts[2]))
    end
    local copy = {}
    for i = 1, #parts - 1 do
        copy[#copy + 1] = tostring(parts[i])
    end
    return Grammar.CleanSurface(table.concat(copy, ", ") .. ", and " .. tostring(parts[#parts]))
end

local CATEGORY_LABELS = {
    canned_food = { singular = "canned food", plural = "canned foods" },
    food = { singular = "food item", plural = "food items" },
    water = { singular = "drink", plural = "drinks" },
    medical = { singular = "medical supply", plural = "medical supplies" },
    firstaid = { singular = "medical supply", plural = "medical supplies" },
    firearm = { singular = "firearm", plural = "firearms" },
    weapon = { singular = "weapon", plural = "weapons" },
    ammo = { singular = "ammo box", plural = "ammo boxes" },
    tool = { singular = "tool", plural = "tools" },
    mechanics = { singular = "auto part", plural = "auto parts" },
    camping = { singular = "camping item", plural = "camping gear" },
    fishing = { singular = "fishing item", plural = "fishing gear" },
    farming = { singular = "farming item", plural = "farming supplies" },
    cooking = { singular = "cooking item", plural = "cooking supplies" },
    fuel = { singular = "fuel item", plural = "fuel supplies" },
    clothing = { singular = "piece of clothing", plural = "clothes" },
    literature = { singular = "book", plural = "books" },
    electronics = { singular = "electronic part", plural = "electronics" },
    material = { singular = "crafting item", plural = "crafting materials" },
    container = { singular = "bag", plural = "bags" },
    junk = { singular = "misc item", plural = "misc items" },
    item = { singular = "item", plural = "items" },
}

local function normalizeCategoryKey(raw)
    local c = string.lower(trim(raw))
    if c == "" then return "item" end
    if CATEGORY_LABELS[c] then return c end
    if string.find(c, "canned", 1, true) then return "canned_food" end
    if string.find(c, "food", 1, true) then return "food" end
    if string.find(c, "water", 1, true) or string.find(c, "drink", 1, true) or string.find(c, "bever", 1, true) then return "water" end
    if string.find(c, "med", 1, true) or string.find(c, "firstaid", 1, true) or string.find(c, "aid", 1, true) or string.find(c, "pharm", 1, true) then return "medical" end
    if string.find(c, "firearm", 1, true) or string.find(c, "gun", 1, true) then return "firearm" end
    if string.find(c, "weapon", 1, true) or string.find(c, "melee", 1, true) then return "weapon" end
    if string.find(c, "ammo", 1, true) then return "ammo" end
    if string.find(c, "mech", 1, true) or string.find(c, "auto", 1, true) then return "mechanics" end
    if string.find(c, "camp", 1, true) or string.find(c, "surviv", 1, true) then return "camping" end
    if string.find(c, "fish", 1, true) then return "fishing" end
    if string.find(c, "farm", 1, true) or string.find(c, "garden", 1, true) then return "farming" end
    if string.find(c, "cook", 1, true) or string.find(c, "kitchen", 1, true) then return "cooking" end
    if string.find(c, "fuel", 1, true) or string.find(c, "gas", 1, true) then return "fuel" end
    if string.find(c, "tool", 1, true) or string.find(c, "carpent", 1, true) then return "tool" end
    if string.find(c, "cloth", 1, true) or string.find(c, "wear", 1, true) or string.find(c, "access", 1, true) or string.find(c, "apparel", 1, true) then return "clothing" end
    if string.find(c, "lit", 1, true) or string.find(c, "book", 1, true) then return "literature" end
    if string.find(c, "elec", 1, true) or string.find(c, "radio", 1, true) then return "electronics" end
    if string.find(c, "mater", 1, true) or string.find(c, "craft", 1, true) then return "material" end
    if string.find(c, "contain", 1, true) or string.find(c, "bag", 1, true) then return "container" end
    return "item"
end

-- Formats collected loot entries ({ name, category } or plain strings) into a
-- natural, compressed English summary:
-- - <= 3 distinct items: exact counted names ("Canned Beans, 2 Bandages, and Hammer")
-- - 4+ distinct items & <= 6 total: top 3 names + "and N more items"
-- - > 6 total items & 4+ distinct names: category-compressed summary
--   ("4 food items, 3 medical supplies, and 5 other items")
function Grammar.FormatLootSummary(items, options)
    if type(items) ~= "table" or #items == 0 then return nil end
    options = type(options) == "table" and options or {}
    local maxNamed = tonumber(options.maxNamed) or 3
    local compressTotalThreshold = tonumber(options.compressTotalThreshold) or 6

    local nameCounts, nameOrder = {}, {}
    local catCounts, catOrder = {}, {}
    local total = 0

    for i = 1, #items do
        local entry = items[i]
        local rawName = type(entry) == "table" and entry.name or entry
        local name = Grammar.CleanSurface(rawName)
        if name then
            total = total + 1
            if not nameCounts[name] then
                nameCounts[name] = 0
                nameOrder[#nameOrder + 1] = name
            end
            nameCounts[name] = nameCounts[name] + 1

            local cat = normalizeCategoryKey(type(entry) == "table" and entry.category or nil)
            if not catCounts[cat] then
                catCounts[cat] = 0
                catOrder[#catOrder + 1] = cat
            end
            catCounts[cat] = catCounts[cat] + 1
        end
    end

    if total == 0 then return nil end

    table.sort(nameOrder, function(a, b)
        if nameCounts[a] ~= nameCounts[b] then return nameCounts[a] > nameCounts[b] end
        return a < b
    end)

    if total > compressTotalThreshold and #nameOrder > maxNamed then
        table.sort(catOrder, function(a, b)
            if catCounts[a] ~= catCounts[b] then return catCounts[a] > catCounts[b] end
            return a < b
        end)
        local parts = {}
        local shown = 0
        local maxCats = 3
        for i = 1, math.min(maxCats, #catOrder) do
            local cat = catOrder[i]
            local cnt = catCounts[cat]
            shown = shown + cnt
            local spec = CATEGORY_LABELS[cat] or CATEGORY_LABELS.item
            local label = cnt == 1 and spec.singular or spec.plural
            parts[#parts + 1] = tostring(cnt) .. " " .. label
        end
        local rest = total - shown
        if rest > 0 then
            parts[#parts + 1] = tostring(rest) .. (rest == 1 and " other item" or " other items")
        end
        return Grammar.JoinNaturalList(parts)
    end

    local parts = {}
    local shown = 0
    for i = 1, math.min(maxNamed, #nameOrder) do
        local name = nameOrder[i]
        local cnt = nameCounts[name]
        shown = shown + cnt
        if cnt > 1 then
            parts[#parts + 1] = tostring(cnt) .. " " .. name
        else
            parts[#parts + 1] = name
        end
    end
    local rest = total - shown
    if rest > 0 then
        parts[#parts + 1] = tostring(rest) .. (rest == 1 and " more item" or " more items")
    end
    return Grammar.JoinNaturalList(parts)
end

return Grammar
