-- Translation adapters and bounded lookup instrumentation for the harness.

local Translations = {}

function Translations.language(value)
    value = string.upper(tostring(value or "EN"))
    if value == "" or string.find(value, "..", 1, true)
        or string.match(value, "^[%w_%-]+$") == nil
    then
        return "EN"
    end
    return value
end

function Translations.scenarioLanguage(context)
    local scenario = context.Runtime.scenario or {}
    local runtime = scenario.runtime or {}
    return Translations.language(runtime.language or "EN")
end

function Translations.nativeText(context, key, ...)
    local scenario = context.Runtime.scenario or {}
    local runtime = scenario.runtime or {}
    local catalog = runtime.nativeTranslations or {}
    local value = catalog[key]
    if type(value) ~= "string" or value == "" then return key end
    local args = { ... }
    for index = 1, #args do
        value = string.gsub(value, "%%" .. tostring(index), function()
            return tostring(args[index])
        end)
    end
    return value
end

function Translations.translationManager()
    return type(CustomTranslationManager) == "table"
        and CustomTranslationManager or nil
end

function Translations.currentLanguage(context)
    local manager = Translations.translationManager()
    if manager and type(manager.getLanguage) == "function" then
        local ok, value = pcall(manager.getLanguage)
        if ok and value then return Translations.language(value) end
    end
    return Translations.scenarioLanguage(context)
end

function Translations.record(context, kind, key, fallback, value, args)
    local Runtime = context.Runtime
    local keyText = tostring(key or "")
    if keyText == "" then return end
    local fallbackText = fallback ~= nil and tostring(fallback) or nil
    local resolved = value ~= nil and tostring(value) or ""
    Runtime.translationLookups[#Runtime.translationLookups + 1] = {
        kind = kind,
        key = keyText,
        fallback = fallbackText,
        value = resolved,
        args = context.Values.copy(args),
        language = Translations.currentLanguage(context),
        fallbackUsed = fallbackText ~= nil
            and resolved == fallbackText
            and Translations.currentLanguage(context) ~= "EN",
        turn = Runtime.turn,
    }
    if #Runtime.translationLookups > 128 then
        table.remove(Runtime.translationLookups, 1)
    end
end

function Translations.installInstrumentation(context)
    local translation = PNC and PNC.Translation
    if type(translation) ~= "table" or translation._harnessWrapped then
        return
    end
    local originalGetKey = translation.GetKey
    local originalGet = translation.Get
    local originalTr = translation.Tr
    local originalTrFormat = translation.TrFormat
    if type(originalGetKey) == "function" then
        translation.GetKey = function(key, fallback, source)
            local value = originalGetKey(key, fallback, source)
            Translations.record(context, "getKey", key, fallback, value, nil)
            return value
        end
    end
    if type(originalGet) == "function" then
        translation.Get = function(systemName, key, fallback)
            local value = originalGet(systemName, key, fallback)
            Translations.record(context, "get", key, fallback, value, nil)
            return value
        end
    end
    if type(originalTr) == "function" then
        translation.Tr = function(first, second, third)
            local value = originalTr(first, second, third)
            Translations.record(context, "tr",
                third ~= nil and second or first,
                third ~= nil and third or second, value, nil)
            return value
        end
    end
    if type(originalTrFormat) == "function" then
        translation.TrFormat = function(key, fallback, ...)
            local args = { ... }
            local value = originalTrFormat(key, fallback, ...)
            Translations.record(context, "trFormat", key, fallback, value, args)
            return value
        end
    end
    translation._harnessWrapped = true
end

function Translations.snapshot(context)
    local Runtime = context.Runtime
    local manager = Translations.translationManager()
    local diagnostics
    if manager and type(manager.GetTranslationAuditSnapshot) == "function" then
        local ok, value = pcall(manager.GetTranslationAuditSnapshot)
        if ok then diagnostics = value end
    end
    return {
        language = Translations.currentLanguage(context),
        lookupCount = #Runtime.translationLookups,
        lookups = context.Values.copy(Runtime.translationLookups),
        audit = diagnostics,
    }
end

function Translations.setLanguage(context, value)
    local Runtime = context.Runtime
    local selected = Translations.language(value)
    local scenario = Runtime.scenario or {}
    scenario.runtime = scenario.runtime or {}
    scenario.runtime.language = selected
    local manager = Translations.translationManager()
    if manager and type(manager.setLanguageOverride) == "function" then
        manager.setLanguageOverride(selected)
    end
    Runtime.translationLanguage = Translations.currentLanguage(context)
    return {
        ok = true,
        type = "language",
        language = Runtime.translationLanguage,
        translation = Translations.snapshot(context),
    }
end

return Translations
