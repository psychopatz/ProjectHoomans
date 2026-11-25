-- Modular, context-aware compositional Lexicon and surface expander.
-- Language-pack native (Lexicon.Packs[lang]), Kahlua2-safe Lua 5.1, O(1) lookup,
-- bounded recursion (MAX_DEPTH=3), and O(1) ring-buffer anti-repeat.

PNC = PNC or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Lexicon = PNC.ConvoEngine.Lexicon or {}
PNC.ConvoEngine.Lexicon = Lexicon

local Formatter = PNC.ConvoEngine.TokenFormatter
    or require "PNC/ConvoEngine/TokenFormatter"

Lexicon.VERSION = 1
Lexicon.MAX_DEPTH = 3
Lexicon.MAX_HISTORY = 256
Lexicon.Packs = Lexicon.Packs or {}
Lexicon._history = Lexicon._history or {}
Lexicon._historyOrder = Lexicon._historyOrder or {}
Lexicon._historyHead = tonumber(Lexicon._historyHead) or 1
Lexicon._historyCount = tonumber(Lexicon._historyCount) or 0

local function hashText(text)
    local h = 2166136261
    local s = tostring(text or "")
    for i = 1, #s do
        h = ((h * 31) + string.byte(s, i)) % 2147483647
    end
    return h
end

local function countKeys(tbl)
    if type(tbl) ~= "table" then return 0 end
    local n = 0
    for _ in pairs(tbl) do n = n + 1 end
    return n
end

local function matchesWhen(when, ctx)
    if type(when) ~= "table" then return true, 0 end
    if type(ctx) ~= "table" then return false, 0 end
    local spec = 0
    for k, expected in pairs(when) do
        local actual = ctx[k]
        if type(expected) == "boolean" then
            if (actual == true) ~= expected then return false, 0 end
        elseif tostring(actual or "") ~= tostring(expected) then
            return false, 0
        end
        spec = spec + 1
    end
    return true, spec
end

function Lexicon.Register(lang, key, entries)
    lang = string.upper(tostring(lang or "EN"))
    key = tostring(key or "")
    if key == "" or type(entries) ~= "table" or #entries == 0 then return false end
    Lexicon.Packs[lang] = Lexicon.Packs[lang] or {}
    local normalized = {}
    for i = 1, #entries do
        local e = entries[i]
        if type(e) == "table" and type(e.words) == "table" and #e.words > 0 then
            local pri = tonumber(e.priority) or 6
            local kc = countKeys(e.when)
            normalized[#normalized + 1] = {
                when = e.when,
                priority = pri,
                words = e.words,
                _maxScore = pri * 100 + kc,
                _idx = i,
            }
        end
    end
    if #normalized == 0 then return false end
    table.sort(normalized, function(a, b)
        if a._maxScore ~= b._maxScore then return a._maxScore > b._maxScore end
        return a._idx < b._idx
    end)
    Lexicon.Packs[lang][key] = normalized
    return true
end

function Lexicon.Extend(lang, key, entries)
    lang = string.upper(tostring(lang or "EN"))
    key = tostring(key or "")
    if key == "" or type(entries) ~= "table" or #entries == 0 then return false end
    local pack = Lexicon.Packs[lang]
    local existing = type(pack) == "table" and pack[key] or nil
    if type(existing) ~= "table" or #existing == 0 then
        return Lexicon.Register(lang, key, entries)
    end
    local merged = {}
    for i = 1, #existing do
        merged[i] = existing[i]
    end
    local baseCount = #merged
    local added = 0
    for i = 1, #entries do
        local e = entries[i]
        if type(e) == "table" and type(e.words) == "table" and #e.words > 0 then
            local pri = tonumber(e.priority) or 6
            local kc = countKeys(e.when)
            added = added + 1
            merged[#merged + 1] = {
                when = e.when,
                priority = pri,
                words = e.words,
                _maxScore = pri * 100 + kc,
                _idx = baseCount + added,
            }
        end
    end
    if added == 0 then return false end
    table.sort(merged, function(a, b)
        if a._maxScore ~= b._maxScore then return a._maxScore > b._maxScore end
        return a._idx < b._idx
    end)
    Lexicon.Packs[lang][key] = merged
    return true
end

local function resolveActiveLanguage(explicit)
    if explicit ~= nil and tostring(explicit) ~= "" then
        return string.upper(tostring(explicit))
    end
    local dsl = PNC and PNC.ConvoEngine and PNC.ConvoEngine.ConvoDSL
    if type(dsl) == "table" and type(dsl.ActiveLanguage) == "function" then
        return dsl.ActiveLanguage()
    end
    local manager = rawget(_G, "CustomTranslationManager")
        or (PsychopatzCore and PsychopatzCore.CustomTranslationManager)
    if type(manager) == "table" and type(manager.getLanguage) == "function" then
        local ok, value = pcall(manager.getLanguage)
        if ok and value and tostring(value) ~= "" then
            return string.upper(tostring(value))
        end
    end
    return "EN"
end

function Lexicon.Has(key, lang)
    local k = tostring(key or "")
    local reqLang = resolveActiveLanguage(lang)
    local pack = Lexicon.Packs[reqLang]
    if type(pack) == "table" and pack[k] ~= nil then
        return true
    end
    return type(Lexicon.Packs.EN) == "table" and Lexicon.Packs.EN[k] ~= nil
end

local function recordHistory(hKey, wordIndex)
    local cap = Lexicon.MAX_HISTORY
    local prev = Lexicon._history[hKey]
    if prev == nil then
        local order = Lexicon._historyOrder
        local count = Lexicon._historyCount
        local head = Lexicon._historyHead
        if count >= cap then
            local oldest = order[head]
            if oldest ~= nil then Lexicon._history[oldest] = nil end
            order[head] = hKey
            Lexicon._historyHead = (head % cap) + 1
        else
            local slot = ((head + count - 1) % cap) + 1
            order[slot] = hKey
            Lexicon._historyCount = count + 1
        end
    end
    Lexicon._history[hKey] = wordIndex
end

function Lexicon.Pick(key, context, salt, lang)
    local k = tostring(key or "")
    local reqLang = resolveActiveLanguage(lang)
    local pack = Lexicon.Packs[reqLang]
    local entries = (type(pack) == "table" and pack[k])
        or (type(Lexicon.Packs.EN) == "table" and Lexicon.Packs.EN[k])
        or nil
    if type(entries) ~= "table" then return nil end

    local bestScore = nil
    local pool = nil
    for i = 1, #entries do
        local e = entries[i]
        if bestScore ~= nil and e._maxScore < bestScore then
            break
        end
        local ok, spec = matchesWhen(e.when, context)
        if ok then
            local score = e.priority * 100 + spec
            if bestScore == nil or score > bestScore then
                bestScore = score
                pool = {}
                for w = 1, #e.words do pool[#pool + 1] = e.words[w] end
            elseif score == bestScore then
                for w = 1, #e.words do pool[#pool + 1] = e.words[w] end
            end
        end
    end
    if not pool or #pool == 0 then return nil end

    local npcID = type(context) == "table" and tostring(context.npcID or "") or ""
    local hKey = npcID .. "|" .. tostring(key)
    local idx = (hashText(tostring(salt or "") .. "|" .. hKey) % #pool) + 1
    if #pool > 1 and Lexicon._history[hKey] == idx then
        idx = (idx % #pool) + 1
    end
    recordHistory(hKey, idx)
    return pool[idx]
end

local function expandPass(text, context, tokens, lang, salt, depth)
    if depth > Lexicon.MAX_DEPTH or not string.find(text, "{", 1, true) then
        return text
    end
    local changed = false
    local out = string.gsub(text, "{([^}]+)}", function(expr)
        local raw = expr
        local optional = false
        if string.sub(raw, 1, 1) == "?" then
            optional = true
            raw = string.sub(raw, 2)
        end
        local key, filters = string.match(raw, "^([^|]+)|?(.*)$")
        if not key or key == "" then return "" end

        local val = type(tokens) == "table" and Formatter.ResolveToken(tokens, key) or nil
        if val == nil then
            val = Lexicon.Pick(key, context, tostring(salt or "") .. ":" .. tostring(depth), lang)
            if val ~= nil and string.find(val, "{", 1, true) then
                val = expandPass(val, context, tokens, lang, salt, depth + 1)
            end
        end
        if val ~= nil then
            changed = true
            if filters and filters ~= "" and type(Formatter.ApplyFilters) == "function" then
                return Formatter.ApplyFilters(val, filters, tokens, lang)
            end
            return val
        end
        if optional then
            changed = true
            return ""
        end
        return "{" .. expr .. "}"
    end)
    if changed and depth < Lexicon.MAX_DEPTH and string.find(out, "{", 1, true) then
        return expandPass(out, context, tokens, lang, salt, depth + 1)
    end
    return out
end

function Lexicon.Expand(text, context, tokens, opts)
    local out = tostring(text or "")
    if out == "" or not string.find(out, "{", 1, true) then
        return out
    end
    opts = type(opts) == "table" and opts or {}
    local lang = resolveActiveLanguage(opts.language)
    local salt = opts.salt or (type(context) == "table" and context.eventRef) or ""
    out = expandPass(out, context, tokens, lang, salt, 1)
    out = Formatter.Format(out, tokens, { language = lang, context = context })
    if type(Formatter.CleanPunctuation) == "function" then
        out = Formatter.CleanPunctuation(out)
    end
    return out
end

function Lexicon.ResetHistory()
    Lexicon._history = {}
    Lexicon._historyOrder = {}
    Lexicon._historyHead = 1
    Lexicon._historyCount = 0
    return true
end

return Lexicon
