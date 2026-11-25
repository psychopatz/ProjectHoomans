-- Surface grammar normalization and PZ-font-safe punctuation helpers.
-- Fixes missing-glyph Unicode dashes (e.g. "Good—nobody" -> "Good - nobody"),
-- normalizes smart quotes/ellipses, articles, and safe clause stitching.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Grammar = PNC.Semantics.GrammarJoin or {}
PNC.Semantics.GrammarJoin = Grammar

Grammar.VERSION = 1

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

return Grammar
