-- ProjectHoomans medical-event wording projected from final ConvoEngine plans into
-- the existing phrase-family/SpeechRealization authority.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local ConvoPlanFamily = require
    "PNC/ConvoEngine/ResponseCatalog/ConvoPlanFamily"

local MEDICAL_TEMPLATES = {
    "medical.distress.call.bandage",
    "medical.distress.call.bleedout",
    "medical.distress.call.default",
    "medical.distress.call.dehydration",
    "medical.distress.call.exhaustion",
    "medical.distress.call.mercy",
    "medical.distress.call.rescue",
    "medical.distress.call.starvation",
    "medical.distress.default",
    "medical.distress.mercy",
    "medical.distress.urgent",
    "medical.distress.repeat.bandage",
    "medical.distress.repeat.bleedout",
    "medical.distress.repeat.default",
    "medical.distress.repeat.dehydration",
    "medical.distress.repeat.exhaustion",
    "medical.distress.repeat.mercy",
    "medical.distress.repeat.rescue",
    "medical.distress.repeat.starvation",
    "medical.distress.teammate.default",
    "medical.distress.teammate.found",
    "medical.distress.teammate.missing",
    "medical.distress.treatment.bandage",
    "medical.distress.treatment.default",
    "medical.distress.update.bandage",
    "medical.distress.update.bleedout",
    "medical.distress.update.default",
    "medical.distress.update.dehydration",
    "medical.distress.update.exhaustion",
    "medical.distress.update.mercy",
    "medical.distress.update.rescue",
    "medical.distress.update.starvation",
}

for _, templateID in ipairs(MEDICAL_TEMPLATES) do
    ConvoPlanFamily.install(templateID, {
        defaultContentOwner = "projecthoomans.dialogue_content.events",
    })
end

return true
