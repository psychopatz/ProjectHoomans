-- Core-owned knowledge wording projected into the existing PNC phrase-family
-- and SpeechRealization authorities. This module selects no gameplay path.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local ConversationRegistry = require
    "PNC/ConvoEngine/Registry"

local function activeLanguage()
    if Translator and type(Translator.getLanguage) == "function" then
        local language = Translator.getLanguage()
        if language and type(language.toString) == "function" then
            return tostring(language:toString())
        end
    end
    return "EN"
end

local function installPSDLFamily(templateID, styles)
    local existing = ConversationRegistry.PHRASE_FAMILIES[templateID]
    if type(existing) == "table" and existing._psdl == true then
        return existing
    end

    local familyStyles = {}
    local language = activeLanguage()
    local found = false
    for _, style in ipairs(styles) do
        familyStyles[style] = {}
        local plan = ConversationRegistry.ConvoPlan(
            templateID .. "." .. style
        )
        local payload = type(plan) == "table" and plan.payload or nil
        local response = type(payload) == "table" and payload.response or nil
        local authored = type(response) == "table" and response.variants or nil
        if type(authored) == "table" then
            for index, variant in ipairs(authored) do
                local text = type(variant) == "table" and variant.text or nil
                local localized = type(text) == "table"
                    and (text[language] or text.EN) or nil
                local fallback = type(localized) == "table"
                    and localized[1] or localized
                if type(fallback) == "string" and fallback ~= "" then
                    familyStyles[style][#familyStyles[style] + 1] = {
                        id = templateID .. "." .. style .. "."
                            .. string.format("%02d", index),
                        key = "",
                        fallback = fallback,
                        phraseID = tostring(
                            variant.id or (style .. "." .. index)
                        ),
                    }
                    found = true
                end
            end
        end
    end
    if not found then return nil end

    local family = {
        id = "phrase." .. templateID,
        semanticTemplateID = templateID,
        owner = "psychopatzcore.dialogue_content.knowledge",
        _psdl = true,
        styles = familyStyles,
    }
    ConversationRegistry.PHRASE_FAMILIES[templateID] = family
    return family
end

local STYLE_VARIANTS = { "neutral", "warm", "terse", "guarded" }
installPSDLFamily("semantic.question.identity", STYLE_VARIANTS)
installPSDLFamily("semantic.question.identity.known", STYLE_VARIANTS)
installPSDLFamily("semantic.question.knowledge.known", STYLE_VARIANTS)
installPSDLFamily("semantic.question.knowledge.unknown", STYLE_VARIANTS)
installPSDLFamily("semantic.question.activity.fishing", STYLE_VARIANTS)
installPSDLFamily(
    "semantic.question.activity.dataset.keep_moving", STYLE_VARIANTS
)
installPSDLFamily("semantic.gossip.unknown", {
    "neutral", "warm", "terse", "guarded",
    "bond_neutral", "bond_warm", "bond_terse", "bond_guarded",
})

return true
