-- ProjectHoomans event-reaction wording projected from final PSDL plans into
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
}

for _, templateID in ipairs(EVENT_REACTION_TEMPLATES) do
    ConvoPlanFamily.install(templateID, {
        defaultContentOwner = "projecthoomans.dialogue_content.events",
    })
end

return true
