-- ProjectHoomans projects Core-compiled social, health, and wellbeing PSDL
-- records into the established phrase-family/SpeechRealization authority.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Registry = require
    "PNC/Semantics/Generated/Conversation/Registry"

local OWNED_CATEGORIES = {
    ["projecthoomans:core_social_content"] = true,
    ["projecthoomans:health_content"] = true,
    ["projecthoomans:wellbeing_content"] = true,
}

local function activeLanguage()
    if Translator and type(Translator.getLanguage) == "function" then
        local language = Translator.getLanguage()
        if language and type(language.toString) == "function" then
            return tostring(language:toString())
        end
    end
    return "EN"
end

local function addPlan(families, plan)
    local payload = type(plan) == "table" and plan.payload or nil
    local metadata = type(payload) == "table"
        and payload.metadata or nil
    if type(metadata) ~= "table"
        or not OWNED_CATEGORIES[metadata.category]
    then
        return
    end
    local templateID = metadata.responseTemplateID
    local style = metadata.style or "neutral"
    if type(templateID) ~= "string" or templateID == ""
        or type(style) ~= "string" or style == ""
    then
        return
    end
    local response = payload.response
    local authored = type(response) == "table" and response.variants or nil
    if type(authored) ~= "table" then return end

    local family = families[templateID]
    if not family then
        family = {
            id = "phrase." .. templateID,
            semanticTemplateID = templateID,
            owner = metadata.contentOwner
                or "projecthoomans.dialogue_content.social",
            contentOwner = metadata.contentOwner
                or "projecthoomans.dialogue_content.social",
            _psdl = true,
            styles = {},
        }
        families[templateID] = family
    end
    local phrases = family.styles[style] or {}
    family.styles[style] = phrases
    local language = activeLanguage()
    for index, variant in ipairs(authored) do
        local text = type(variant) == "table" and variant.text or nil
        local localized = type(text) == "table"
            and (text[language] or text.EN) or nil
        local fallback = type(localized) == "table"
            and localized[1] or localized
        if type(fallback) == "string" and fallback ~= "" then
            phrases[#phrases + 1] = {
                id = "phrase." .. templateID .. "." .. style .. "."
                    .. string.format("%02d", index),
                key = "",
                fallback = fallback,
                phraseID = tostring(
                    variant.id or (style .. "." .. index)
                ),
            }
        end
    end
end

local families = {}
for _, plan in pairs(Registry.PSDL_PLANS or {}) do
    addPlan(families, plan)
end
for templateID, family in pairs(families) do
    Registry.PHRASE_FAMILIES[templateID] = family
end

return true
