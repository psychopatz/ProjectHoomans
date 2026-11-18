-- Shared ConvoPlan -> PHRASE_FAMILIES extractor for canonical ConvoEngine say plans.
PNC = PNC or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}
local cachedRegistry = PNC.ConvoEngine.Registry
    or require "PNC/ConvoEngine/Registry"

local function activeRegistry()
    return (PNC and PNC.ConvoEngine and PNC.ConvoEngine.Registry)
        or cachedRegistry
end

local ConvoPlanFamily = PNC.ConvoEngine.ConvoPlanFamily or {}
PNC.ConvoEngine.ConvoPlanFamily = ConvoPlanFamily

local function activeLanguage()
    local manager = CustomTranslationManager
        or (PsychopatzCore and PsychopatzCore.CustomTranslationManager)
    if type(manager) == "table" and type(manager.getLanguage) == "function" then
        local ok, language = pcall(manager.getLanguage)
        if ok and language and tostring(language) ~= "" then
            return string.upper(tostring(language))
        end
    end
    if Translator and type(Translator.getLanguage) == "function" then
        local language = Translator.getLanguage()
        if language and type(language.toString) == "function" then
            return string.upper(tostring(language:toString()))
        end
    end
    return "EN"
end

ConvoPlanFamily.ActiveLanguage = activeLanguage

local function appendLocalizedLines(phrases, installAs, styleKey, localized, basePhraseID, textMap, variant)
    if type(localized) == "string" then
        localized = { localized }
    end
    if type(localized) ~= "table" then return end
    local templateKey = type(variant) == "table" and variant.templateID or nil
    local explicitKey = type(variant) == "table"
        and (variant.translationKey or variant.key
            or (type(templateKey) == "string"
                and string.sub(templateKey, 1, 3) == "UI_"
                and templateKey or nil))
        or nil
    for index = 1, #localized do
        local fallback = localized[index]
        if type(fallback) == "string" and fallback ~= "" then
            local seq = string.format("%02d", #phrases + 1)
            local translationsByLang = {}
            local hasTranslations = false
            if type(textMap) == "table" then
                for langCode, rawList in pairs(textMap) do
                    local code = string.upper(tostring(langCode))
                    if type(rawList) == "table" then
                        local item = rawList[index]
                        if type(item) == "string" and item ~= "" then
                            translationsByLang[code] = item
                            hasTranslations = true
                        end
                    elseif type(rawList) == "string" and rawList ~= "" and index == 1 then
                        translationsByLang[code] = rawList
                        hasTranslations = true
                    end
                end
            end
            local enFallback = translationsByLang.EN or fallback
            local styleToken = tostring(styleKey or "neutral")
            if styleToken ~= "neutral"
                and string.sub(installAs, -(#styleToken + 1)) == ("." .. styleToken)
            then
                styleToken = "neutral"
            end
            local contentKey = (#localized == 1 and type(explicitKey) == "string" and explicitKey ~= "")
                and explicitKey
                or ("conversation.content.semantic." .. installAs .. "." .. styleToken .. "." .. seq)
            if hasTranslations and PNC and PNC.Translation
                and type(PNC.Translation.RegisterInlineText) == "function"
            then
                for langCode, text in pairs(translationsByLang) do
                    PNC.Translation.RegisterInlineText(langCode, contentKey, text)
                end
            end
            phrases[#phrases + 1] = {
                id = "phrase." .. installAs .. "." .. styleKey .. "." .. seq,
                key = contentKey,
                fallback = enFallback,
                translations = hasTranslations and translationsByLang or nil,
                convoPlanTemplateID = type(variant) == "table" and variant.templateID or nil,
                phraseID = tostring(basePhraseID or (styleKey .. "." .. index)),
            }
        end
    end
end

local function hasSayVariant(plan, variantId)
    if type(plan) ~= "table" or type(variantId) ~= "string" or variantId == "" then
        return false
    end
    local fam = type(plan.exchangeFamily) == "table" and plan.exchangeFamily or nil
    local say = type(fam) == "table" and fam.initiatingSay or nil
    if type(say) ~= "table" then
        local payload = type(plan.payload) == "table" and plan.payload or nil
        say = type(payload) == "table" and payload.say or nil
    end
    if type(say) ~= "table" or type(say.realizations) ~= "table" then
        return false
    end
    local keys = type(say.keyOrder) == "table" and say.keyOrder or { "1" }
    for _, rkey in ipairs(keys) do
        local realization = say.realizations[tostring(rkey)]
        local variants = type(realization) == "table" and realization.variants or nil
        if type(variants) == "table" then
            for _, variant in ipairs(variants) do
                if type(variant) == "table" and tostring(variant.id or "") == variantId then
                    return true
                end
            end
        end
    end
    return false
end

local function resolvePlanTarget(registry, planID, options)
    local plan = type(registry.ConvoPlan) == "function" and registry.ConvoPlan(planID) or nil
    if type(plan) == "table" then
        return plan, options.outcome and tostring(options.outcome) or nil, options.style and tostring(options.style) or nil
    end
    if type(registry.ConvoOutcome) == "function" then
        local ref = registry.ConvoOutcome(planID)
        if type(ref) == "table" and type(ref.plan) == "table" then
            return ref.plan, options.outcome and tostring(options.outcome) or ref.outcome, options.style and tostring(options.style) or nil
        end
    end
    local baseID, suffix = string.match(planID, "^(.+)%.([^%.]+)$")
    if baseID and suffix and type(registry.ConvoPlan) == "function" then
        local directPlan = registry.ConvoPlan(baseID)
        local fam = type(directPlan) == "table" and directPlan.exchangeFamily or nil
        if type(fam) == "table" and type(fam.replies) == "table" and type(fam.replies[suffix]) == "table" then
            return directPlan, options.outcome and tostring(options.outcome) or suffix, options.style and tostring(options.style) or nil
        end
        if hasSayVariant(directPlan, suffix) then
            return directPlan, options.outcome and tostring(options.outcome) or nil, options.style and tostring(options.style) or suffix
        end
        if type(registry.ConvoOutcome) == "function" then
            local ref = registry.ConvoOutcome(baseID)
            if type(ref) == "table" and type(ref.plan) == "table" then
                return ref.plan, options.outcome and tostring(options.outcome) or ref.outcome, options.style and tostring(options.style) or suffix
            end
        end
        local rootID, outcomeName = string.match(baseID, "^(.+)%.([^%.]+)$")
        if rootID and outcomeName then
            local rootPlan = registry.ConvoPlan(rootID)
            local rootFam = type(rootPlan) == "table" and rootPlan.exchangeFamily or nil
            if type(rootFam) == "table" and type(rootFam.replies) == "table" and type(rootFam.replies[outcomeName]) == "table" then
                return rootPlan, options.outcome and tostring(options.outcome) or outcomeName, options.style and tostring(options.style) or suffix
            end
            local combinedVariant = outcomeName .. "." .. suffix
            if hasSayVariant(rootPlan, combinedVariant) then
                return rootPlan, options.outcome and tostring(options.outcome) or nil, options.style and tostring(options.style) or combinedVariant
            end
        end
    end
    return nil, nil, nil
end

local function collectVariants(stylesMap, variants, installAs, language, options, onlyStyle)
    local targetStyleOverride = options.targetStyle and tostring(options.targetStyle) or nil
    local added = false
    for _, variant in ipairs(variants) do
        if type(variant) == "table" then
            local rawId = tostring(variant.id or "neutral")
            local variantStyle = rawId
            local matched = false
            if not onlyStyle then
                matched = true
                if variantStyle == "default" then
                    variantStyle = "neutral"
                end
            elseif rawId == onlyStyle or variantStyle == onlyStyle then
                matched = true
                variantStyle = "neutral"
            elseif string.sub(rawId, 1, #onlyStyle + 1) == (onlyStyle .. ".") then
                matched = true
                variantStyle = string.sub(rawId, #onlyStyle + 2)
                if variantStyle == "default" then
                    variantStyle = "neutral"
                end
            end
            if matched then
                local destStyle = targetStyleOverride or variantStyle
                local textMap = type(variant.translations) == "table"
                    and variant.translations
                    or (type(variant.text) == "table" and variant.text or nil)
                local localized = type(textMap) == "table"
                    and (textMap[language] or textMap.EN) or nil
                if localized == nil and type(variant.fallback) == "string"
                    and variant.fallback ~= ""
                then
                    localized = variant.fallback
                end
                stylesMap[destStyle] = stylesMap[destStyle] or {}
                local before = #stylesMap[destStyle]
                appendLocalizedLines(
                    stylesMap[destStyle],
                    installAs,
                    destStyle,
                    localized,
                    variant.id,
                    textMap,
                    variant
                )
                if #stylesMap[destStyle] > before then
                    added = true
                end
            end
        end
    end
    return added
end

local function collectFromSay(stylesMap, plan, installAs, language, options, outcomeName, resolvedStyle)
    local family = type(plan.exchangeFamily) == "table" and plan.exchangeFamily or nil
    local onlyStyle = resolvedStyle or (options.style and tostring(options.style) or nil)
    if outcomeName ~= nil and outcomeName ~= "" then
        local branch = type(family) == "table" and type(family.replies) == "table"
            and family.replies[outcomeName] or nil
        if type(branch) ~= "table" then return false end
        if type(branch.say) == "table" and type(branch.say.realizations) == "table" then
            local keys = options.realizationKey and { tostring(options.realizationKey) }
                or (type(branch.say.keyOrder) == "table" and branch.say.keyOrder or { "1" })
            local added = false
            for _, rkey in ipairs(keys) do
                local realization = branch.say.realizations[tostring(rkey)]
                local variants = type(realization) == "table" and realization.variants or nil
                if type(variants) == "table" and collectVariants(stylesMap, variants, installAs, language, options, onlyStyle) then
                    added = true
                end
            end
            return added
        elseif type(branch.variants) == "table" then
            return collectVariants(stylesMap, branch.variants, installAs, language, options, onlyStyle)
        end
        return false
    end

    local say = type(family) == "table" and family.initiatingSay or nil
    if type(say) ~= "table" then
        local payload = type(plan.payload) == "table" and plan.payload or nil
        say = type(payload) == "table" and payload.say or nil
    end
    if type(say) ~= "table" or type(say.realizations) ~= "table" then
        return false
    end

    local keys = options.realizationKey and { tostring(options.realizationKey) }
        or (type(say.keyOrder) == "table" and say.keyOrder or { "1" })

    local added = false
    for _, rkey in ipairs(keys) do
        local realization = say.realizations[tostring(rkey)]
        local variants = type(realization) == "table" and realization.variants or nil
        if type(variants) == "table" and collectVariants(stylesMap, variants, installAs, language, options, onlyStyle) then
            added = true
        end
    end
    return added
end

local function collectFromLegacyResponse(stylesMap, plan, installAs, language, options)
    local payload = type(plan.payload) == "table" and plan.payload or nil
    local response = type(payload) == "table" and payload.response or nil
    local authored = type(response) == "table" and response.variants or nil
    if type(authored) ~= "table" then return false end

    local destStyle = tostring(options.targetStyle or options.style or "neutral")
    stylesMap[destStyle] = stylesMap[destStyle] or {}
    local before = #stylesMap[destStyle]
    for index, variant in ipairs(authored) do
        if type(variant) == "table" then
            local text = variant.text
            local localized = type(text) == "table" and (text[language] or text.EN) or nil
            appendLocalizedLines(
                stylesMap[destStyle],
                installAs,
                destStyle,
                localized,
                variant.id or (destStyle .. "." .. index)
            )
        end
    end
    return #stylesMap[destStyle] > before
end

function ConvoPlanFamily.install(templateID, options)
    options = type(options) == "table" and options or {}
    local planID = tostring(options.planID or templateID or "")
    local installAs = tostring(options.installAs or templateID or "")
    if planID == "" or installAs == "" then return nil end

    local registry = activeRegistry()
    if type(registry) ~= "table" then return nil end

    local existing = registry.PHRASE_FAMILIES[installAs]
    if type(existing) == "table" and existing._convoPlan == true then
        return existing
    end

    local plan, outcomeName, resolvedStyle = resolvePlanTarget(registry, planID, options)
    if type(plan) ~= "table" then return nil end

    local payload = type(plan.payload) == "table" and plan.payload or {}
    local metadata = type(payload.metadata) == "table" and payload.metadata or {}
    local contentOwner = metadata.contentOwner
        or options.defaultContentOwner
        or "projecthoomans.dialogue_content.events"
    local language = activeLanguage()
    local stylesMap = {}

    if not collectFromSay(stylesMap, plan, installAs, language, options, outcomeName, resolvedStyle) then
        if outcomeName ~= nil or not collectFromLegacyResponse(stylesMap, plan, installAs, language, options) then
            return nil
        end
    end
    if resolvedStyle and type(stylesMap[resolvedStyle]) == "table" and stylesMap.neutral == nil then
        stylesMap.neutral = stylesMap[resolvedStyle]
    end
    local hasStyles = false
    for _ in pairs(stylesMap) do
        hasStyles = true
        break
    end
    if not hasStyles then return nil end

    local family = {
        id = "phrase." .. installAs,
        semanticTemplateID = installAs,
        owner = contentOwner,
        contentOwner = contentOwner,
        _convoPlan = true,
        styles = stylesMap,
    }
    registry.PHRASE_FAMILIES[installAs] = family
    return family
end

function ConvoPlanFamily.installPlan(families, plan, options)
    if type(plan) ~= "table" or not plan.id then return end
    local planID = tostring(plan.id)
    local family = ConvoPlanFamily.install(planID, options)
    if family and type(families) == "table" then
        families[planID] = family
    end
    return family
end

return ConvoPlanFamily
