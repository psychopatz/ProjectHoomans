-- Shared dynamic dialogue token formatter and punctuation cleaner.
-- Kahlua2-safe Lua 5.1 helper: resolves {token} placeholders from a token
-- map and cleanly collapses missing/empty optional tokens (vocatives,
-- location/clock phrases) without leaving raw braces or broken punctuation.

PNC = PNC or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Formatter = PNC.ConvoEngine.TokenFormatter or {}
PNC.ConvoEngine.TokenFormatter = Formatter

Formatter.VERSION = 1

local UNKNOWN_VALUES = {
    ["unknown"] = true,
    ["unknown survivor"] = true,
    ["unknown background"] = true,
    ["unknown faction"] = true,
    ["nil"] = true,
}

local function trim(value)
    if value == nil then return "" end
    local text = tostring(value)
    text = string.gsub(text, "^%s+", "")
    text = string.gsub(text, "%s+$", "")
    return text
end

function Formatter.CleanName(raw)
    if type(raw) ~= "string" and type(raw) ~= "number" then return nil end
    local cleaned = trim(raw)
    if cleaned == "" then return nil end
    if UNKNOWN_VALUES[string.lower(cleaned)] then return nil end
    return cleaned
end

function Formatter.FirstTokenName(raw)
    local cleaned = Formatter.CleanName(raw)
    if not cleaned then return nil end
    return string.match(cleaned, "^(%S+)") or cleaned
end

function Formatter.CleanLocation(raw)
    if type(raw) ~= "string" and type(raw) ~= "number" then return nil end
    local cleaned = trim(raw)
    if cleaned == "" then return nil end
    local lower = string.lower(cleaned)
    if lower == "room" or UNKNOWN_VALUES[lower] then return nil end
    return cleaned
end

function Formatter.ResolveToken(tokens, key)
    if type(tokens) ~= "table" or type(key) ~= "string" or key == "" then
        return nil
    end
    local direct = tokens[key]
    if direct ~= nil and type(direct) ~= "table" then
        local cleaned = trim(direct)
        if cleaned ~= "" then return cleaned end
        return nil
    end
    local cursor = tokens
    for part in string.gmatch(key, "[^%.]+") do
        if type(cursor) ~= "table" then
            cursor = nil
            break
        end
        cursor = cursor[part]
    end
    if cursor ~= nil and type(cursor) ~= "table" then
        local cleaned = trim(cursor)
        if cleaned ~= "" then return cleaned end
    end
    return nil
end

local function collapseMissingTokens(text)
    if not string.find(text, "{", 1, true) then return text end
    local out = text
    local strippedLeading = string.find(out, "^%s*{[%w_%.]+}") ~= nil

    -- Leading optional token with trailing separator (comma, colon, semicolon, dash, em-dash).
    out = string.gsub(out, "^%s*{[%w_%.]+}%s*\226\128\148%s*", "")
    out = string.gsub(out, "^%s*{[%w_%.]+}%s*%-%-%s*", "")
    out = string.gsub(out, "^%s*{[%w_%.]+}%s*[,;:!%-]*%s*", "")

    -- Parenthesized optional token.
    out = string.gsub(out, "%s*%({[%w_%.]+}%)", "")

    -- Comma- or dash-bounded middle vocative: "Hey, {addressee.name}, watch out".
    out = string.gsub(out, ",%s*{[%w_%.]+}%s*,%s*", ", ")
    out = string.gsub(out, "%s*\226\128\148%s*{[%w_%.]+}%s*\226\128\148%s*", " ")
    out = string.gsub(out, "%s*%-%-%s*{[%w_%.]+}%s*%-%-%s*", " ")

    -- Trailing or pre-punctuation vocative: "Watch out, {addressee.name}!".
    out = string.gsub(out, ",%s*{[%w_%.]+}%s*([%.%!%?%;%:])", "%1")
    out = string.gsub(out, "\226\128\148%s*{[%w_%.]+}%s*([%.%!%?%;%:])", "%1")
    out = string.gsub(out, "{[%w_%.]+}%s*,%s*", "")
    out = string.gsub(out, ",%s*{[%w_%.]+}", "")
    out = string.gsub(out, "\226\128\148%s*{[%w_%.]+}", "")
    out = string.gsub(out, "{[%w_%.]+}%s*\226\128\148%s*", "")
    out = string.gsub(out, "%s+{[%w_%.]+}%s*([%.%!%?%;%:,])", "%1")
    out = string.gsub(out, "%s*{[%w_%.]+}%s*", " ")

    -- Clean residual punctuation spacing artifacts.
    out = string.gsub(out, "%s+([%.%!%?%;%:,])", "%1")
    out = string.gsub(out, "([,;])%s*([%.%!%?])", "%2")
    out = string.gsub(out, ",%s*,+", ",")
    out = string.gsub(out, "%s%s+", " ")
    out = string.gsub(out, "^[,;:%s]+", "")
    out = string.gsub(out, "%s+$", "")

    if strippedLeading and out ~= "" then
        out = string.gsub(out, "^([a-z])", string.upper)
    end
    return out
end

function Formatter.Format(text, tokens)
    local out = tostring(text or "")
    if out == "" then return "" end
    if string.find(out, "{", 1, true) then
        if type(tokens) == "table" then
            out = string.gsub(out, "{([%w_%.]+)}", function(key)
                local val = Formatter.ResolveToken(tokens, key)
                if val ~= nil then return val end
                return "{" .. key .. "}"
            end)
        end
        out = collapseMissingTokens(out)
    end
    return out
end

return Formatter
