-- Cached localized text access shared by backstory and gossip definitions.
PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local Memory = PNC.Conversation.Memory
local Data = Memory._registry
local Loader = PNC.Conversation.TextLoader

local function sourceKey(source)
    return table.concat({
        tostring(source.modID or ""),
        tostring(source.pathPattern or ""),
        tostring(source.domain or ""),
    }, "|")
end

local function sourceLanguageKey(source, language)
    return sourceKey(source) .. "|" .. tostring(language or "EN")
end

function Memory.NormalizeTextSource(source, fallback)
    if source == nil then
        return fallback
    end
    if type(source) ~= "table" then
        return nil, "invalid_text_source"
    end
    local modID = tostring(source.modID or "")
    local pathPattern = tostring(source.pathPattern or "")
    local domain = tostring(source.domain or "")
    if modID == "" or pathPattern == "" or domain == "" then
        return nil, "incomplete_text_source"
    end
    return {
        modID = modID,
        pathPattern = pathPattern,
        domain = domain,
    }
end

function Memory.RegisterTextKey(source, key)
    if type(source) ~= "table" or type(key) ~= "string" or key == "" then
        return false, "invalid_text_key"
    end
    local keyId = sourceKey(source)
    local group = Data.textSourceByKey[keyId]
    if not group then
        group = { source = source, keys = {}, keySet = {} }
        Data.textSourceByKey[keyId] = group
        Data.textSources[#Data.textSources + 1] = group
    end
    if not group.keySet[key] then
        group.keySet[key] = true
        group.keys[#group.keys + 1] = key
    end
    return true
end

local function loadValues(source, language, requiredKey)
    local cacheKey = sourceLanguageKey(source, language)
    local values = Data.textCache[cacheKey]
    if values then
        return values
    end
    local ok
    local result
    if Loader and type(Loader.EnsureSource) == "function" then
        ok, result = Loader.EnsureSource(source, { requiredKey })
        if not ok then
            return nil, result or "translation_source_invalid"
        end
        values = result
    elseif Loader and type(Loader.Load) == "function" then
        values = Loader.Load(source, language)
    end
    if not values then
        return nil, result or "translation_file_unavailable"
    end
    Data.textCache[cacheKey] = values
    return values
end

function Memory.GetText(source, key, language)
    if type(source) ~= "table" or type(key) ~= "string" or key == "" then
        return nil, "invalid_text_request"
    end
    if not Loader then
        return nil, "text_loader_unavailable"
    end
    language = tostring(language
        or (Loader.GetLanguage and Loader.GetLanguage())
        or "EN")
    local values, reason = loadValues(source, language, key)
    if values and type(values[key]) == "string" and values[key] ~= "" then
        return values[key]
    end
    if language ~= "EN" then
        values, reason = loadValues(source, "EN", key)
        if values and type(values[key]) == "string" and values[key] ~= "" then
            return values[key]
        end
    end
    return nil, reason or ("missing_text_key:" .. key)
end

function Memory.ValidateTextSources()
    local report = {}
    if not Loader or type(Loader.EnsureSource) ~= "function" then
        return { valid = false, reason = "text_loader_unavailable" }
    end
    for i = 1, #Data.textSources do
        local group = Data.textSources[i]
        table.sort(group.keys)
        local ok, result = Loader.EnsureSource(group.source, group.keys)
        local domain = group.source.domain
        report[domain] = { valid = ok == true }
        if not ok then
            report[domain].errors = result
        end
        if ok then
            local language = Loader.GetLanguage
                and Loader.GetLanguage() or "EN"
            Data.textCache[sourceLanguageKey(group.source, language)] =
                result
        end
    end
    Data.textValidation = report
    return report
end

function Memory.RenderText(template, arguments)
    if type(template) ~= "string" then
        return nil
    end
    arguments = type(arguments) == "table" and arguments or {}
    local rendered = string.gsub(template, "{([%w_]+)}", function(name)
        local value = arguments[name]
        if value == nil then
            return "{" .. name .. "}"
        end
        return tostring(value)
    end)
    return rendered
end
