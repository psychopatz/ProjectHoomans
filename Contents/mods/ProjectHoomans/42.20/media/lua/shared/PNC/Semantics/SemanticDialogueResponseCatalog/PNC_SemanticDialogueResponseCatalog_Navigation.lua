-- Deterministic responses for semantic navigation exchanges.
-- Navigation changes the active semantic branch but still represents a real
-- conversational turn. It never owns gameplay execution.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.ResponseCatalog
if type(Catalog) ~= "table" or type(Catalog.Register) ~= "function" then
    return false
end

local ConversationRegistry = require
    "PNC/Semantics/Generated/Conversation/Registry"

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
    local styles = { neutral = {}, warm = {}, terse = {}, guarded = {} }
    local language = activeLanguage()
    local found = false
    for _, style in ipairs({ "neutral", "warm", "terse", "guarded" }) do
        local plan = ConversationRegistry.PSDLPlan(
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
        owner = "projecthoomans.dialogue_content.navigation",
        _psdl = true,
        styles = styles,
    }
    ConversationRegistry.PHRASE_FAMILIES[templateID] = family
    return family
end

for _, templateID in ipairs({
    "semantic.navigation.camp",
    "semantic.navigation.camp_empty",
    "semantic.navigation.default",
    "semantic.navigation.orders",
    "semantic.navigation.subject_change",
}) do
    installPSDLFamily(templateID)
end

Catalog.Extend("semantic.conversation.acknowledged", {
    variants = {
        {
            id = "semantic.navigation.orders",
            templateID = "semantic.navigation.orders",
            fallback = "All right. What do you need?",
            when = { subject = "COMPANION_ORDERS" },
            priority = 5,
        },
        {
            id = "semantic.navigation.camp",
            templateID = "semantic.navigation.camp",
            fallback = "Where should we set up?",
            when = { subject = "COMPANION_CAMP" },
            priority = 5,
        },
        {
            id = "semantic.navigation.camp_empty",
            templateID = "semantic.navigation.camp_empty",
            fallback = "I don't see a good place to set up here.",
            when = { subject = "COMPANION_CAMP_EMPTY" },
            priority = 5,
        },
        {
            id = "semantic.navigation.subject_change",
            templateID = "semantic.navigation.subject_change",
            fallback = "All right. What did you want to talk about?",
            when = { subject = "CONVERSATION_TOPIC" },
            priority = 5,
        },
    },
})

return true
