-- ProjectHoomans medical-event wording projected from final PSDL plans into
-- the existing phrase-family/SpeechRealization authority.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

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

    local plan = ConversationRegistry.PSDLPlan(templateID)
    local payload = type(plan) == "table" and plan.payload or nil
    local response = type(payload) == "table" and payload.response or nil
    local authored = type(response) == "table" and response.variants or nil
    if type(authored) ~= "table" then return nil end

    local language = activeLanguage()
    local phrases = {}
    for index, variant in ipairs(authored) do
        local text = type(variant) == "table" and variant.text or nil
        local localized = type(text) == "table"
            and (text[language] or text.EN) or nil
        local fallback = type(localized) == "table"
            and localized[1] or localized
        if type(fallback) == "string" and fallback ~= "" then
            phrases[#phrases + 1] = {
                id = "phrase." .. templateID .. ".neutral."
                    .. string.format("%02d", index),
                key = "",
                fallback = fallback,
                phraseID = tostring(
                    variant.id or ("neutral." .. index)
                ),
            }
        end
    end
    if #phrases == 0 then return nil end

    local family = {
        id = "phrase." .. templateID,
        semanticTemplateID = templateID,
        owner = "projecthoomans.dialogue_content.events",
        contentOwner = "projecthoomans.dialogue_content.events",
        _psdl = true,
        styles = { neutral = phrases },
    }
    ConversationRegistry.PHRASE_FAMILIES[templateID] = family
    return family
end

local MEDICAL_TEMPLATES = {
    "semantic.medical.distress.call.bandage",
    "semantic.medical.distress.call.bleedout",
    "semantic.medical.distress.call.default",
    "semantic.medical.distress.call.dehydration",
    "semantic.medical.distress.call.exhaustion",
    "semantic.medical.distress.call.mercy",
    "semantic.medical.distress.call.rescue",
    "semantic.medical.distress.call.starvation",
    "semantic.medical.distress.default",
    "semantic.medical.distress.mercy",
    "semantic.medical.distress.urgent",
    "semantic.medical.distress.repeat.bandage",
    "semantic.medical.distress.repeat.bleedout",
    "semantic.medical.distress.repeat.default",
    "semantic.medical.distress.repeat.dehydration",
    "semantic.medical.distress.repeat.exhaustion",
    "semantic.medical.distress.repeat.mercy",
    "semantic.medical.distress.repeat.rescue",
    "semantic.medical.distress.repeat.starvation",
    "semantic.medical.distress.teammate.default",
    "semantic.medical.distress.teammate.found",
    "semantic.medical.distress.teammate.missing",
    "semantic.medical.distress.treatment.bandage",
    "semantic.medical.distress.treatment.default",
    "semantic.medical.distress.update.bandage",
    "semantic.medical.distress.update.bleedout",
    "semantic.medical.distress.update.default",
    "semantic.medical.distress.update.dehydration",
    "semantic.medical.distress.update.exhaustion",
    "semantic.medical.distress.update.mercy",
    "semantic.medical.distress.update.rescue",
    "semantic.medical.distress.update.starvation",
}

for _, templateID in ipairs(MEDICAL_TEMPLATES) do
    installPSDLFamily(templateID)
end

return true
