-- Core-owned knowledge wording projected into the existing PNC phrase-family
-- and SpeechRealization authorities. This module selects no gameplay path.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local ConvoPlanFamily = require
    "PNC/ConvoEngine/ResponseCatalog/ConvoPlanFamily"

local function installConvoFamily(templateID)
    return ConvoPlanFamily.install(templateID, {
        defaultContentOwner = "psychopatzcore.dialogue_content.knowledge",
    })
end

installConvoFamily("question.identity")
installConvoFamily("question.identity.known")
installConvoFamily("question.knowledge.known")
installConvoFamily("question.knowledge.unknown")
installConvoFamily("question.activity.fishing")
installConvoFamily("question.activity.dataset.keep_moving")
installConvoFamily("gossip.unknown")

return true
