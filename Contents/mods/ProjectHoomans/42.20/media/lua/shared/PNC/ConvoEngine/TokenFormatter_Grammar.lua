-- Pluggable language grammar filters and actor pronoun bundles for TokenFormatter.
-- Kahlua2-safe Lua 5.1; designed so future language packs (e.g. TL) can register
-- their own Formatter.LangFilters[langCode] without touching engine code.

PNC = PNC or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Formatter = PNC.ConvoEngine.TokenFormatter or {}
PNC.ConvoEngine.TokenFormatter = Formatter

Formatter.LangFilters = Formatter.LangFilters or {}

local INVARIANT_PLURALS = {
    dead = true,
    undead = true,
    infected = true,
    people = true,
    folks = true,
    crew = true,
    squad = true,
    ammo = true,
    gear = true,
    supplies = true,
}

local IRREGULAR_VERBS_3SG = {
    be = "is",
    have = "has",
    ["do"] = "does",
    go = "goes",
}

local function startsWithVowelSound(word)
    local lower = string.lower(tostring(word or ""))
    if lower == "" then return false end
    if string.sub(lower, 1, 4) == "hour"
        or string.sub(lower, 1, 6) == "honest"
        or string.sub(lower, 1, 4) == "heir"
    then
        return true
    end
    if string.sub(lower, 1, 4) == "user"
        or string.sub(lower, 1, 4) == "unit"
        or string.sub(lower, 1, 7) == "uniform"
        or string.sub(lower, 1, 3) == "one"
    then
        return false
    end
    local first = string.sub(lower, 1, 1)
    return first == "a" or first == "e" or first == "i" or first == "o" or first == "u"
end

local function pluralizeEN(phrase)
    local text = tostring(phrase or "")
    if text == "" then return "" end
    local lower = string.lower(text)
    if INVARIANT_PLURALS[lower] then return text end
    -- Pluralize last word in multi-word noun phrases (e.g., "rotting walker")
    local prefix, last = string.match(text, "^(.-%s+)(%S+)$")
    if not last then prefix, last = "", text end
    local lLast = string.lower(last)
    if INVARIANT_PLURALS[lLast] then return text end
    if string.sub(lLast, -1) == "s" and string.sub(lLast, -2) ~= "ss" then
        return text
    end
    if string.sub(lLast, -2) == "ch" or string.sub(lLast, -2) == "sh"
        or string.sub(lLast, -1) == "x" or string.sub(lLast, -1) == "z"
        or string.sub(lLast, -2) == "ss"
    then
        return prefix .. last .. "es"
    end
    if string.sub(lLast, -1) == "y" then
        local prev = string.sub(lLast, -2, -2)
        if prev ~= "a" and prev ~= "e" and prev ~= "i" and prev ~= "o" and prev ~= "u" then
            return prefix .. string.sub(last, 1, -2) .. "ies"
        end
    end
    return prefix .. last .. "s"
end

local function conjugateEN(verb, isPlural)
    local text = tostring(verb or "")
    if text == "" then return "" end
    local lower = string.lower(text)
    if isPlural then
        if lower == "be" then return "are" end
        return text
    end
    if IRREGULAR_VERBS_3SG[lower] then
        return IRREGULAR_VERBS_3SG[lower]
    end
    if string.sub(lower, -2) == "ch" or string.sub(lower, -2) == "sh"
        or string.sub(lower, -1) == "x" or string.sub(lower, -1) == "z"
        or string.sub(lower, -1) == "s" or string.sub(lower, -1) == "o"
    then
        return text .. "es"
    end
    if string.sub(lower, -1) == "y" then
        local prev = string.sub(lower, -2, -2)
        if prev ~= "a" and prev ~= "e" and prev ~= "i" and prev ~= "o" and prev ~= "u" then
            return string.sub(text, 1, -2) .. "ies"
        end
    end
    return text .. "s"
end

local function formatListEN(value, conj, withArticle)
    if type(value) ~= "table" then
        local s = tostring(value or "")
        if s == "" then return "" end
        return withArticle and ((startsWithVowelSound(s) and "an " or "a ") .. s) or s
    end
    local items = {}
    for i = 1, #value do
        local s = tostring(value[i] or "")
        s = string.gsub(s, "^%s+", "")
        s = string.gsub(s, "%s+$", "")
        if s ~= "" then
            if withArticle then
                s = (startsWithVowelSound(s) and "an " or "a ") .. s
            end
            items[#items + 1] = s
        end
    end
    local n = #items
    if n == 0 then return "" end
    if n == 1 then return items[1] end
    conj = conj or "and"
    if n == 2 then return items[1] .. " " .. conj .. " " .. items[2] end
    return table.concat(items, ", ", 1, n - 1) .. ", " .. conj .. " " .. items[n]
end

Formatter.FormatList = formatListEN

Formatter.LangFilters.EN = {
    cap = function(val)
        return (string.gsub(tostring(val or ""), "^([a-z])", string.upper))
    end,
    lower = function(val)
        return (string.gsub(tostring(val or ""), "^([A-Z])", string.lower))
    end,
    a = function(val)
        local text = tostring(val or "")
        if text == "" then return "" end
        return (startsWithVowelSound(text) and "an " or "a ") .. text
    end,
    list = function(val) return formatListEN(val, "and", false) end,
    list_a = function(val) return formatListEN(val, "and", true) end,
    ["or"] = function(val) return formatListEN(val, "or", false) end,
    or_a = function(val) return formatListEN(val, "or", true) end,
    s = function(val, arg, tokens)
        if arg and arg ~= "" and type(tokens) == "table" then
            local rawCount = Formatter.ResolveToken(tokens, arg)
            local n = tonumber(rawCount)
            if n == 1 then return tostring(val or "") end
        end
        return pluralizeEN(val)
    end,
    verb = function(val, arg, tokens)
        local isPlural = false
        if arg and arg ~= "" and type(tokens) == "table" then
            local p = tokens[arg .. ".plural"]
            if p == true or tostring(p) == "true" then
                isPlural = true
            end
        end
        return conjugateEN(val, isPlural)
    end,
}

function Formatter.ResolveEndPunct(context)
    context = type(context) == "table" and context or {}
    local style = tostring(context.speakerStyle or context.style or "neutral")
    if context.inCombat == true or context.playerTone == "urgent"
        or style == "aggressive" or style == "brave"
    then
        return "!"
    end
    if style == "shaken" or context.speakerExhausted == true then
        return "..."
    end
    return "."
end

function Formatter.CleanPunctuation(text)
    local out = tostring(text or "")
    if out == "" then return "" end
    -- Collapse accidental duplicate punctuation from composed clauses
    out = string.gsub(out, "%.%.%.+%.+", "...")
    out = string.gsub(out, "([%!%?])%.+", "%1")
    out = string.gsub(out, ",%s*([%.%!%?])", "%1")
    out = string.gsub(out, "%s+([%.%!%?%;%:,])", "%1")
    out = string.gsub(out, "%s%s+", " ")
    out = string.gsub(out, "^%s+", "")
    out = string.gsub(out, "%s+$", "")
    -- Auto-capitalize letter after sentence-ending punctuation
    out = string.gsub(out, "([%.%!%?])%s+([a-z])", function(p, c)
        return p .. " " .. string.upper(c)
    end)
    return out
end

function Formatter.ApplyFilters(value, filterChain, tokens, lang)
    local out = value
    if type(filterChain) ~= "string" or filterChain == "" then return tostring(out or "") end
    local pack = Formatter.LangFilters[string.upper(tostring(lang or "EN"))]
        or Formatter.LangFilters.EN
    for spec in string.gmatch(filterChain, "[^|]+") do
        local name, arg = string.match(spec, "^([^:]+):?(.*)$")
        local fn = name and pack[name] or nil
        if type(fn) == "function" then
            out = fn(out, arg ~= "" and arg or nil, tokens)
        end
    end
    return tostring(out or "")
end

local function detectFemale(actor)
    if actor == nil then return nil end
    if type(actor) == "table" then
        if actor.female ~= nil then return actor.female == true end
        if actor.isFemale ~= nil then
            if type(actor.isFemale) == "function" then
                local ok, res = pcall(actor.isFemale, actor)
                if ok then return res == true end
            else
                return actor.isFemale == true
            end
        end
        if type(actor.gender) == "string" then
            local g = string.lower(actor.gender)
            if g == "female" or g == "f" then return true end
            if g == "male" or g == "m" then return false end
        end
    elseif type(actor.isFemale) == "function" then
        local ok, res = pcall(actor.isFemale, actor)
        if ok then return res == true end
    end
    return nil
end

function Formatter.BuildPronouns(actor, opts)
    opts = type(opts) == "table" and opts or {}
    if opts.plural == true then
        return { sub = "they", obj = "them", pos = "their", poss = "theirs", ref = "themselves", be = "are", was = "were", plural = true }
    end
    local female = detectFemale(actor)
    if female == true then
        return { sub = "she", obj = "her", pos = "her", poss = "hers", ref = "herself", be = "is", was = "was", plural = false }
    elseif female == false then
        return { sub = "he", obj = "him", pos = "his", poss = "his", ref = "himself", be = "is", was = "was", plural = false }
    end
    return { sub = "they", obj = "them", pos = "their", poss = "theirs", ref = "themselves", be = "are", was = "were", plural = true }
end

function Formatter.AttachPronouns(tokens, prefix, actor, opts)
    if type(tokens) ~= "table" or type(prefix) ~= "string" or prefix == "" then
        return tokens
    end
    local p = Formatter.BuildPronouns(actor, opts)
    tokens[prefix .. ".sub"] = p.sub
    tokens[prefix .. ".obj"] = p.obj
    tokens[prefix .. ".pos"] = p.pos
    tokens[prefix .. ".poss"] = p.poss
    tokens[prefix .. ".ref"] = p.ref
    tokens[prefix .. ".be"] = p.be
    tokens[prefix .. ".was"] = p.was
    tokens[prefix .. ".plural"] = p.plural
    return tokens
end

return Formatter
