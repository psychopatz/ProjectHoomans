-- Semantic response pools for first-party tool outcomes.
--
-- Tool execution remains authoritative in the gameplay/tool handlers. This
-- provider only maps bounded result facts to one semantic realization; it

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Catalog = PNC.ConvoEngine.ResponseCatalog
if type(Catalog) ~= "table" or type(Catalog.Register) ~= "function" then
    return false
end

local CONTENT_OWNER = "projecthoomans.dialogue_content.tool_replies"

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
        owner = CONTENT_OWNER,
        contentOwner = CONTENT_OWNER,
        _psdl = true,
        styles = { neutral = phrases },
    }
    ConversationRegistry.PHRASE_FAMILIES[templateID] = family
    return family
end

local function line(id)
    installPSDLFamily(id)
    return {
        id = id,
        templateID = id,
        contentOwner = CONTENT_OWNER,
    }
end

local function register(id, variants)
    return Catalog.Register(id, { variants = variants })
end

-- Accepted social reactions.
register("semantic.tool_reply.social.accepted.compliment", {
    line("semantic.tool_reply.compliment.1"),
    line("semantic.tool_reply.compliment.2"),
    line("semantic.tool_reply.compliment.3"),
})
register("semantic.tool_reply.social.accepted.romantic_interest", {
    line("semantic.tool_reply.romantic.1"),
    line("semantic.tool_reply.romantic.2"),
    line("semantic.tool_reply.romantic.3"),
})
register("semantic.tool_reply.social.accepted.sexual_advance", {
    line("semantic.tool_reply.sexual.1"),
    line("semantic.tool_reply.sexual.2"),
    line("semantic.tool_reply.sexual.3"),
})
register("semantic.tool_reply.social.accepted.hostile_abuse", {
    line("semantic.tool_reply.hostile.1"),
    line("semantic.tool_reply.hostile.2"),
    line("semantic.tool_reply.hostile.3"),
})
register("semantic.tool_reply.social.accepted.admire", {
    line("semantic.tool_reply.admire.1"),
    line("semantic.tool_reply.admire.2"),
    line("semantic.tool_reply.admire.3"),
})
register("semantic.tool_reply.social.accepted.praise", {
    line("semantic.tool_reply.praise.1"),
    line("semantic.tool_reply.praise.2"),
    line("semantic.tool_reply.praise.3"),
})
register("semantic.tool_reply.social.accepted.comfort", {
    line("semantic.tool_reply.comfort.1"),
    line("semantic.tool_reply.comfort.2"),
    line("semantic.tool_reply.comfort.3"),
})
register("semantic.tool_reply.social.accepted.apologize", {
    line("semantic.tool_reply.apology.1"),
    line("semantic.tool_reply.apology.2"),
    line("semantic.tool_reply.apology.3"),
})
register("semantic.tool_reply.social.accepted.flirt", {
    line("semantic.tool_reply.flirt.1"),
    line("semantic.tool_reply.flirt.2"),
    line("semantic.tool_reply.flirt.3"),
})
register("semantic.tool_reply.social.accepted.insult", {
    line("semantic.tool_reply.insult.1"),
    line("semantic.tool_reply.insult.2"),
    line("semantic.tool_reply.insult.3"),
})
register("semantic.tool_reply.social.accepted.generic", {
    line("semantic.tool_reply.accepted_generic.1"),
    line("semantic.tool_reply.accepted_generic.2"),
})

-- Network-queued reactions remain explicitly non-committal.
register("semantic.tool_reply.social.queued.compliment", {
    line("semantic.tool_reply.queued_compliment.1"),
    line("semantic.tool_reply.queued_compliment.2"),
})
register("semantic.tool_reply.social.queued.romantic_interest", {
    line("semantic.tool_reply.queued_romantic.1"),
    line("semantic.tool_reply.queued_romantic.2"),
})
register("semantic.tool_reply.social.queued.sexual_advance", {
    line("semantic.tool_reply.queued_sexual.1"),
    line("semantic.tool_reply.queued_sexual.2"),
})
register("semantic.tool_reply.social.queued.hostile_abuse", {
    line("semantic.tool_reply.queued_hostile.1"),
    line("semantic.tool_reply.queued_hostile.2"),
})
register("semantic.tool_reply.social.queued.admire", {
    line("semantic.tool_reply.queued_admire.1"),
    line("semantic.tool_reply.queued_admire.2"),
})
register("semantic.tool_reply.social.queued.praise", {
    line("semantic.tool_reply.queued_praise.1"),
    line("semantic.tool_reply.queued_praise.2"),
})
register("semantic.tool_reply.social.queued.comfort", {
    line("semantic.tool_reply.queued_comfort.1"),
    line("semantic.tool_reply.queued_comfort.2"),
})
register("semantic.tool_reply.social.queued.apologize", {
    line("semantic.tool_reply.queued_apology.1"),
    line("semantic.tool_reply.queued_apology.2"),
})
register("semantic.tool_reply.social.queued.flirt", {
    line("semantic.tool_reply.queued_flirt.1"),
    line("semantic.tool_reply.queued_flirt.2"),
})
register("semantic.tool_reply.social.queued.insult", {
    line("semantic.tool_reply.queued_insult.1"),
    line("semantic.tool_reply.queued_insult.2"),
})
register("semantic.tool_reply.social.queued.generic", {
    line("semantic.tool_reply.queued_generic.1"),
    line("semantic.tool_reply.queued_generic.2"),
})

-- Rejections preserve the result reason/boundary chosen by the tool handler.
register("semantic.tool_reply.social.rejected.positive_cooldown_active", {
    line("semantic.tool_reply.cooldown.1"),
    line("semantic.tool_reply.cooldown.2"),
})
register("semantic.tool_reply.social.rejected.relationship_gate", {
    line("semantic.tool_reply.relationship.1"),
    line("semantic.tool_reply.relationship.2"),
})
register("semantic.tool_reply.social.rejected.personality_gate", {
    line("semantic.tool_reply.personality.1"),
    line("semantic.tool_reply.personality.2"),
})
register("semantic.tool_reply.social.rejected.orientation_gate", {
    line("semantic.tool_reply.orientation.1"),
    line("semantic.tool_reply.orientation.2"),
})
register("semantic.tool_reply.social.rejected.rejected_by_game", {
    line("semantic.tool_reply.rejected_game.1"),
    line("semantic.tool_reply.rejected_game.2"),
})
register("semantic.tool_reply.social.rejected.sexual_advance", {
    line("semantic.tool_reply.rejected_sexual.1"),
    line("semantic.tool_reply.rejected_sexual.2"),
    line("semantic.tool_reply.rejected_sexual.3"),
})
register("semantic.tool_reply.social.rejected.hostile_abuse", {
    line("semantic.tool_reply.rejected_hostile.1"),
    line("semantic.tool_reply.rejected_hostile.2"),
})
register("semantic.tool_reply.social.rejected.generic", {
    line("semantic.tool_reply.rejected_generic.1"),
    line("semantic.tool_reply.rejected_generic.2"),
})

register("semantic.tool_reply.ask_name.prompt", {
    line("semantic.tool_reply.ask_name.prompt"),
})
register("semantic.tool_reply.ask_name.named", {
    line("semantic.tool_reply.ask_name.named.1"),
    line("semantic.tool_reply.ask_name.named.2"),
    line("semantic.tool_reply.ask_name.named.3"),
})
register("semantic.tool_reply.ask_name.unnamed", {
    line("semantic.tool_reply.ask_name.unnamed.1"),
    line("semantic.tool_reply.ask_name.unnamed.2"),
})
register("semantic.tool_reply.ask_name.rejected", {
    line("semantic.tool_reply.ask_name.rejected.1"),
    line("semantic.tool_reply.ask_name.rejected.2"),
})

register("semantic.tool_reply.order.follow", {
    line("semantic.tool_reply.order_follow.1"),
    line("semantic.tool_reply.order_follow.2"),
    line("semantic.tool_reply.order_follow.3"),
})
register("semantic.tool_reply.order.stay", {
    line("semantic.tool_reply.order_stay.1"),
    line("semantic.tool_reply.order_stay.2"),
})
register("semantic.tool_reply.order.camp", {
    line("semantic.tool_reply.order_camp.1"),
    line("semantic.tool_reply.order_camp.2"),
    line("semantic.tool_reply.order_camp.3"),
})
register("semantic.tool_reply.order.accepted.generic", {
    line("semantic.tool_reply.order_generic.1"),
    line("semantic.tool_reply.order_generic.2"),
    line("semantic.tool_reply.order_generic.3"),
})
register("semantic.tool_reply.order.rejected", {
    line("semantic.tool_reply.order_rejected.1"),
    line("semantic.tool_reply.order_rejected.2"),
})

return true
