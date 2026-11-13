-- Core-owned world-event wording projected into the existing PNC phrase-family
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

local function installPSDLFamily(templateID)
    local existing = ConversationRegistry.PHRASE_FAMILIES[templateID]
    if type(existing) == "table" and existing._psdl == true then
        return existing
    end

    local styles = {}
    local language = activeLanguage()
    local found = false
    for _, style in ipairs({ "neutral", "warm", "terse", "guarded" }) do
        styles[style] = {}
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
                    styles[style][#styles[style] + 1] = {
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
        owner = "psychopatzcore.dialogue_content.world_event",
        _psdl = true,
        styles = styles,
    }
    ConversationRegistry.PHRASE_FAMILIES[templateID] = family
    return family
end

installPSDLFamily("semantic.interaction.world_event.warning")
installPSDLFamily("semantic.interaction.world_event.warning_flavor")

return true
