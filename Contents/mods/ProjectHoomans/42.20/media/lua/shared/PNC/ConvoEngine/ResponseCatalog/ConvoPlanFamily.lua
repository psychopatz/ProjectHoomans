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
    if Translator and type(Translator.getLanguage) == "function" then
        local language = Translator.getLanguage()
        if language and type(language.toString) == "function" then
            return tostring(language:toString())
        end
    end
    return "EN"
end

local function appendLocalizedLines(phrases, installAs, styleKey, localized, basePhraseID)
    if type(localized) == "string" then
        localized = { localized }
    end
    if type(localized) ~= "table" then return end
    for index = 1, #localized do
        local fallback = localized[index]
        if type(fallback) == "string" and fallback ~= "" then
            phrases[#phrases + 1] = {
                id = "phrase." .. installAs .. "." .. styleKey .. "."
                    .. string.format("%02d", #phrases + 1),
                key = "",
                fallback = fallback,
                phraseID = tostring(basePhraseID or (styleKey .. "." .. index)),
            }
        end
    end
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
        end
    end
    return nil, nil, nil
end

local function collectVariants(stylesMap, variants, installAs, language, options, onlyStyle)
    local targetStyleOverride = options.targetStyle and tostring(options.targetStyle) or nil
    local added = false
    for _, variant in ipairs(variants) do
        if type(variant) == "table" then
            local variantStyle = tostring(variant.id or "neutral")
            if variantStyle == "default" then
                variantStyle = "neutral"
            end
            if not onlyStyle or variantStyle == onlyStyle then
                local destStyle = targetStyleOverride or variantStyle
                local textMap = type(variant.translations) == "table"
                    and variant.translations
                    or (type(variant.text) == "table" and variant.text or nil)
                local localized = type(textMap) == "table"
                    and (textMap[language] or textMap.EN) or nil
                stylesMap[destStyle] = stylesMap[destStyle] or {}
                local before = #stylesMap[destStyle]
                appendLocalizedLines(
                    stylesMap[destStyle],
                    installAs,
                    destStyle,
                    localized,
                    variant.id
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
