-- ProjectHoomans event-reaction wording projected from final PSDL plans into
-- the existing phrase-family/SpeechRealization authority.
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

    local plan = ConversationRegistry.ConvoPlan(templateID)
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

local EVENT_REACTION_TEMPLATES = {
    "semantic.combat.reaction.default",
    "semantic.combat.reaction.retreat",
    "semantic.combat.reaction.threat",
    "semantic.companion.reaction.abandonment",
    "semantic.companion.reaction.camp_rejected",
    "semantic.companion.reaction.default",
    "semantic.corpse.reaction.default",
    "semantic.corpse.reaction.revenge",
    "semantic.flow.farewell.default",
    "semantic.flow.farewell.friendly",
    "semantic.leader_loss.close",
    "semantic.leader_loss.colonist",
    "semantic.leader_loss.default",
    "semantic.leader_loss.devoted",
    "semantic.leader_loss.dissent",
    "semantic.leader_loss.distant",
    "semantic.conversation.safety.danger",
    "semantic.conversation.safety.default",
    "semantic.social.reaction.default",
}

for _, templateID in ipairs(EVENT_REACTION_TEMPLATES) do
    installPSDLFamily(templateID)
end

return true
