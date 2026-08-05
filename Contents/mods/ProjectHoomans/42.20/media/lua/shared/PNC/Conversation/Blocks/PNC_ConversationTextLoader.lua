-- Shared strict flat-JSON conversation translation loader for Build 42.20.
PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local Loader = PNC.Conversation.TextLoader or {}
PNC.Conversation.TextLoader = Loader
Loader.cache = Loader.cache or {}
Loader.diagnostics = Loader.diagnostics or {}

local function utf8Character(code)
    if code <= 0x7f then return string.char(code) end
    if code <= 0x7ff then
        return string.char(
            0xc0 + math.floor(code / 0x40),
            0x80 + code % 0x40
        )
    end
    if code <= 0xffff then
        return string.char(
            0xe0 + math.floor(code / 0x1000),
            0x80 + math.floor(code / 0x40) % 0x40,
            0x80 + code % 0x40
        )
    end
    return string.char(
        0xf0 + math.floor(code / 0x40000),
        0x80 + math.floor(code / 0x1000) % 0x40,
        0x80 + math.floor(code / 0x40) % 0x40,
        0x80 + code % 0x40
    )
end

local function skipWhitespace(text, index)
    while index <= #text do
        local byte = string.byte(text, index)
        if byte ~= 32 and byte ~= 9 and byte ~= 10 and byte ~= 13 then break end
        index = index + 1
    end
    return index
end

local function parseHex(text, index)
    local value = tonumber(string.sub(text, index, index + 3), 16)
    if value == nil then return nil, index, "invalid unicode escape" end
    return value, index + 4
end

local function parseString(text, index)
    if string.sub(text, index, index) ~= '"' then
        return nil, index, "expected string"
    end
    index = index + 1
    local output = {}
    local start = index
    while index <= #text do
        local character = string.sub(text, index, index)
        if character == '"' then
            output[#output + 1] = string.sub(text, start, index - 1)
            return table.concat(output), index + 1
        end
        if character == "\\" then
            output[#output + 1] = string.sub(text, start, index - 1)
            index = index + 1
            local escaped = string.sub(text, index, index)
            local replacements = {
                ['"'] = '"', ["\\"] = "\\", ["/"] = "/",
                b = "\b", f = "\f", n = "\n", r = "\r", t = "\t",
            }
            if replacements[escaped] then
                output[#output + 1] = replacements[escaped]
                index = index + 1
            elseif escaped == "u" then
                local code
                code, index = parseHex(text, index + 1)
                if not code then return nil, index, "invalid unicode escape" end
                if code >= 0xd800 and code <= 0xdbff
                    and string.sub(text, index, index + 1) == "\\u"
                then
                    local low
                    low, index = parseHex(text, index + 2)
                    if not low or low < 0xdc00 or low > 0xdfff then
                        return nil, index, "invalid unicode surrogate"
                    end
                    code = 0x10000 + (code - 0xd800) * 0x400
                        + (low - 0xdc00)
                elseif code >= 0xd800 and code <= 0xdfff then
                    return nil, index, "unpaired unicode surrogate"
                end
                output[#output + 1] = utf8Character(code)
            else
                return nil, index, "invalid escape"
            end
            start = index
        else
            if string.byte(text, index) < 32 then
                return nil, index, "control character in string"
            end
            index = index + 1
        end
    end
    return nil, index, "unterminated string"
end

function Loader.Decode(text)
    if type(text) ~= "string" then return nil, "json text required" end
    if #text > 1048576 then return nil, "translation file too large" end
    if string.sub(text, 1, 3) == "\239\187\191" then text = string.sub(text, 4) end
    local values = {}
    local index = skipWhitespace(text, 1)
    if string.sub(text, index, index) ~= "{" then
        return nil, "expected object"
    end
    index = skipWhitespace(text, index + 1)
    if string.sub(text, index, index) == "}" then
        index = skipWhitespace(text, index + 1)
        if index <= #text then return nil, "trailing content" end
        return values
    end
    while index <= #text do
        local key, reason
        key, index, reason = parseString(text, index)
        if not key then return nil, reason end
        if values[key] ~= nil then return nil, "duplicate key " .. key end
        index = skipWhitespace(text, index)
        if string.sub(text, index, index) ~= ":" then return nil, "expected colon" end
        index = skipWhitespace(text, index + 1)
        local value
        value, index, reason = parseString(text, index)
        if value == nil then return nil, reason or "values must be strings" end
        values[key] = value
        index = skipWhitespace(text, index)
        local separator = string.sub(text, index, index)
        if separator == "}" then
            index = skipWhitespace(text, index + 1)
            if index <= #text then return nil, "trailing content" end
            return values
        end
        if separator ~= "," then return nil, "expected comma or object end" end
        index = skipWhitespace(text, index + 1)
    end
    return nil, "unterminated object"
end

local function replaceLanguage(pattern, language)
    local marker = "{language}"
    local output = tostring(pattern or "")
    while true do
        local first, last = string.find(output, marker, 1, true)
        if not first then break end
        output = string.sub(output, 1, first - 1)
            .. tostring(language)
            .. string.sub(output, last + 1)
    end
    return output
end

local function readWithPZ(modID, path)
    if not getModFileReader then return nil end
    local reader = getModFileReader(modID, path, false)
    if not reader then return nil end
    local lines = {}
    local line = reader:readLine()
    while line ~= nil do
        lines[#lines + 1] = line
        line = reader:readLine()
    end
    reader:close()
    return table.concat(lines, "\n")
end

function Loader.GetLanguage()
    if Translator and Translator.getLanguage and Translator.getLanguage() then
        return tostring(Translator.getLanguage():toString())
    end
    return "EN"
end

function Loader.Load(source, language)
    if type(source) ~= "table" then return nil, "invalid_text_source" end
    language = tostring(language or "EN")
    local path = replaceLanguage(source.pathPattern, language)
    local cacheKey = table.concat({ source.modID, path }, "|")
    if Loader.cache[cacheKey] then return Loader.cache[cacheKey] end
    local raw = readWithPZ(source.modID, path)
    if not raw then return nil, "translation_file_missing:" .. path end
    local values, reason = Loader.Decode(raw)
    if not values then return nil, reason end
    Loader.cache[cacheKey] = values
    return values
end

function Loader.EnsureSource(source, requiredKeys)
    local english, reason = Loader.Load(source, "EN")
    if not english then
        Loader.diagnostics[source and source.domain or "unknown"] = {
            valid = false, errors = { reason },
        }
        return false, { reason }
    end
    local errors = {}
    for _, key in ipairs(requiredKeys or {}) do
        if type(english[key]) ~= "string" or english[key] == "" then
            errors[#errors + 1] = "missing EN key " .. tostring(key)
        end
    end
    if #errors > 0 then
        Loader.diagnostics[source.domain] = { valid = false, errors = errors }
        return false, errors
    end
    local language = Loader.GetLanguage()
    local localized = english
    local localizedReason
    local usedFallback = false
    local missingLocalizedKeys = {}
    if language ~= "EN" then
        localized, localizedReason = Loader.Load(source, language)
        if not localized then
            localized = english
            usedFallback = true
        end
    end
    if language ~= "EN" and localized ~= english then
        for _, key in ipairs(requiredKeys or {}) do
            if type(localized[key]) ~= "string" or localized[key] == "" then
                missingLocalizedKeys[#missingLocalizedKeys + 1] =
                    "missing " .. language .. " key " .. tostring(key)
            end
        end
        if #missingLocalizedKeys > 0 then usedFallback = true end
    end
    local text = PsychopatzCore and PsychopatzCore.Conversation
        and PsychopatzCore.Conversation.Text or nil
    if text and text.RegisterTable then
        text.RegisterTable(source.domain, "EN", english)
        if language ~= "EN" then text.RegisterTable(source.domain, language, localized) end
    end
    Loader.diagnostics[source.domain] = {
        valid = true,
        language = language,
        path = replaceLanguage(source.pathPattern, language),
        fallbackPath = replaceLanguage(source.pathPattern, "EN"),
        usedFallback = usedFallback,
        localizedError = localizedReason,
        missingLocalizedKeys = missingLocalizedKeys,
    }
    return true, localized
end

function Loader.Payload(source, key, args)
    return { key = key, domain = source and source.domain, args = args }
end

function Loader.Reset()
    Loader.cache = {}
    Loader.diagnostics = {}
end

return Loader
