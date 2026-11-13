-- ProjectHoomans combat-kill wording projected from final PSDL plans into
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

    local metadata = type(payload.metadata) == "table" and payload.metadata or {}
    local contentOwner = metadata.contentOwner
        or "projecthoomans.dialogue_content.events"
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
        owner = contentOwner,
        contentOwner = contentOwner,
        _psdl = true,
        styles = { neutral = phrases },
    }
    ConversationRegistry.PHRASE_FAMILIES[templateID] = family
    return family
end

local COMBAT_TEMPLATES = {
    "semantic.combat.kill.killer.aggressive.firearm_high_named_01",
    "semantic.combat.kill.killer.aggressive.firearm_high_named_02",
    "semantic.combat.kill.killer.aggressive.blade_head_01",
    "semantic.combat.kill.killer.aggressive.axe_head_01",
    "semantic.combat.kill.killer.aggressive.blunt_01",
    "semantic.combat.kill.killer.aggressive.spear_01",
    "semantic.combat.kill.killer.brave.firearm_high_01",
    "semantic.combat.kill.killer.brave.blade_head_01",
    "semantic.combat.kill.killer.brave.axe_01",
    "semantic.combat.kill.killer.brave.spear_01",
    "semantic.combat.kill.killer.cold.firearm_high_01",
    "semantic.combat.kill.killer.cold.blade_head_01",
    "semantic.combat.kill.killer.cold.heavy_melee_01",
    "semantic.combat.kill.killer.practical.firearm_high_01",
    "semantic.combat.kill.killer.practical.firearm_low_01",
    "semantic.combat.kill.killer.practical.blade_01",
    "semantic.combat.kill.killer.practical.axe_spear_01",
    "semantic.combat.kill.killer.practical.blunt_01",
    "semantic.combat.kill.killer.practical.unarmed_01",
    "semantic.combat.kill.killer.reserved.firearm_01",
    "semantic.combat.kill.killer.reserved.blade_01",
    "semantic.combat.kill.killer.shaken.firearm_low_01",
    "semantic.combat.kill.killer.shaken.blade_head_01",
    "semantic.combat.kill.killer.shaken.unarmed_01",
    "semantic.combat.kill.killer.supportive.firearm_01",
    "semantic.combat.kill.killer.supportive.melee_01",
    "semantic.combat.human_kill.aggressive.line_01",
    "semantic.combat.human_kill.aggressive.line_02",
    "semantic.combat.human_kill.aggressive.line_03",
    "semantic.combat.human_kill.brave.line_01",
    "semantic.combat.human_kill.brave.line_02",
    "semantic.combat.human_kill.brave.line_03",
    "semantic.combat.human_kill.cold.line_01",
    "semantic.combat.human_kill.cold.line_02",
    "semantic.combat.human_kill.cold.line_03",
    "semantic.combat.human_kill.practical.line_01",
    "semantic.combat.human_kill.practical.line_02",
    "semantic.combat.human_kill.practical.line_03",
    "semantic.combat.human_kill.reserved.line_01",
    "semantic.combat.human_kill.reserved.line_02",
    "semantic.combat.human_kill.reserved.line_03",
    "semantic.combat.human_kill.shaken.line_01",
    "semantic.combat.human_kill.shaken.line_02",
    "semantic.combat.human_kill.shaken.line_03",
    "semantic.combat.human_kill.supportive.line_01",
    "semantic.combat.human_kill.supportive.line_02",
    "semantic.combat.human_kill.supportive.line_03",
    "semantic.combat.reaction.kill_killer_aggressive_01",
    "semantic.combat.reaction.kill_killer_aggressive_02",
    "semantic.combat.reaction.kill_killer_aggressive_03",
    "semantic.combat.reaction.kill_killer_brave_01",
    "semantic.combat.reaction.kill_killer_brave_02",
    "semantic.combat.reaction.kill_killer_brave_03",
    "semantic.combat.reaction.kill_killer_cold_01",
    "semantic.combat.reaction.kill_killer_cold_02",
    "semantic.combat.reaction.kill_killer_cold_03",
    "semantic.combat.reaction.kill_killer_practical_01",
    "semantic.combat.reaction.kill_killer_practical_02",
    "semantic.combat.reaction.kill_killer_practical_03",
    "semantic.combat.reaction.kill_killer_reserved_01",
    "semantic.combat.reaction.kill_killer_reserved_02",
    "semantic.combat.reaction.kill_killer_reserved_03",
    "semantic.combat.reaction.kill_killer_shaken_01",
    "semantic.combat.reaction.kill_killer_shaken_02",
    "semantic.combat.reaction.kill_killer_shaken_03",
    "semantic.combat.reaction.kill_killer_supportive_01",
    "semantic.combat.reaction.kill_killer_supportive_02",
    "semantic.combat.reaction.kill_killer_supportive_03",
    "semantic.combat.reaction.kill_witness_aggressive_01",
    "semantic.combat.reaction.kill_witness_aggressive_02",
    "semantic.combat.reaction.kill_witness_aggressive_03",
    "semantic.combat.reaction.kill_witness_brave_01",
    "semantic.combat.reaction.kill_witness_brave_02",
    "semantic.combat.reaction.kill_witness_brave_03",
    "semantic.combat.reaction.kill_witness_cold_01",
    "semantic.combat.reaction.kill_witness_cold_02",
    "semantic.combat.reaction.kill_witness_cold_03",
    "semantic.combat.reaction.kill_witness_practical_01",
    "semantic.combat.reaction.kill_witness_practical_02",
    "semantic.combat.reaction.kill_witness_practical_03",
    "semantic.combat.reaction.kill_witness_reserved_01",
    "semantic.combat.reaction.kill_witness_reserved_02",
    "semantic.combat.reaction.kill_witness_reserved_03",
    "semantic.combat.reaction.kill_witness_shaken_01",
    "semantic.combat.reaction.kill_witness_shaken_02",
    "semantic.combat.reaction.kill_witness_shaken_03",
    "semantic.combat.reaction.kill_witness_supportive_01",
    "semantic.combat.reaction.kill_witness_supportive_02",
    "semantic.combat.reaction.kill_witness_supportive_03",
    "semantic.combat.player_assaulted.shaken",
    "semantic.combat.player_assaulted.aggressive",
    "semantic.combat.player_assaulted.brave",
    "semantic.combat.player_assaulted.reserved",
    "semantic.combat.player_assaulted.default",
}

for _, templateID in ipairs(COMBAT_TEMPLATES) do
    installPSDLFamily(templateID)
end

return true
