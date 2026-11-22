-- ProjectHoomans event-reaction wording projected from final ConvoEngine plans into
-- the existing phrase-family/SpeechRealization authority.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local ConvoPlanFamily = require
    "PNC/ConvoEngine/ResponseCatalog/ConvoPlanFamily"

local EVENT_REACTION_TEMPLATES = {
    "combat.reaction.default",
    "combat.reaction.retreat",
    "combat.reaction.threat",
    "companion.reaction.abandonment",
    "companion.reaction.camp_rejected",
    "companion.reaction.default",
    "corpse.reaction.default",
    "corpse.reaction.revenge",
    "flow.farewell.default",
    "flow.farewell.friendly",
    "leader_loss.close",
    "leader_loss.colonist",
    "leader_loss.default",
    "leader_loss.devoted",
    "leader_loss.dissent",
    "leader_loss.distant",
    "conversation.safety.danger",
    "conversation.safety.default",
    "social.reaction.default",
    "combat.ally_warn.callout.zombie_neutral",
    "combat.ally_warn.callout.zombie_tactical",
    "combat.ally_warn.callout.zombie_hostile",
    "combat.ally_warn.callout.hostile_neutral",
    "combat.ally_warn.callout.hostile_tactical",
    "combat.ally_warn.callout.hostile_hostile",
    "combat.ally_warn.reply.engaging_neutral",
    "combat.ally_warn.reply.engaging_tactical",
    "combat.ally_warn.reply.engaging_hostile",
    "combat.ally_warn.reply.alerted_neutral",
    "combat.ally_warn.reply.alerted_tactical",
    "combat.ally_warn.reply.alerted_hostile",
    "combat.ally_warn.reply.defensive_neutral",
    "combat.ally_warn.reply.defensive_shaken",
}

for _, templateID in ipairs(EVENT_REACTION_TEMPLATES) do
    ConvoPlanFamily.install(templateID, {
        defaultContentOwner = "projecthoomans.dialogue_content.events",
    })
end

return true
