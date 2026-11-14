-- Core-owned world-event wording projected into the existing PNC phrase-family
-- and SpeechRealization authorities. This module selects no gameplay path.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local ConvoPlanFamily = require
    "PNC/ConvoEngine/ResponseCatalog/ConvoPlanFamily"

local function installConvoFamily(templateID)
    return ConvoPlanFamily.install(templateID, {
        defaultContentOwner = "psychopatzcore.dialogue_content.world_event",
    })
end

installConvoFamily("interaction.world_event.warning")
installConvoFamily("interaction.world_event.warning_flavor")

return true
