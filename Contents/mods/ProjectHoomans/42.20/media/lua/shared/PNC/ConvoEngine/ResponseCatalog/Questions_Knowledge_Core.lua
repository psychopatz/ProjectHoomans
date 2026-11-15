-- Core-owned knowledge wording projected into the existing PNC phrase-family
-- and SpeechRealization authorities. This module selects no gameplay path.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local ConvoPlanFamily = require
    "PNC/ConvoEngine/ResponseCatalog/ConvoPlanFamily"

local function installConvoFamily(templateID, extraOptions)
    local options = {
        defaultContentOwner = "psychopatzcore.dialogue_content.knowledge",
    }
    if type(extraOptions) == "table" then
        for k, v in pairs(extraOptions) do
            options[k] = v
        end
    end
    return ConvoPlanFamily.install(templateID, options)
end

local function installBackstoryFamily(templateID)
    -- Canonical semantic.question.backstory.* response pools come from
    -- ConversationRegistry via ResponseCatalog_Conversation; here we only
    -- ensure the underlying ConvoPlan phrase family is installed.
    return installConvoFamily(templateID, { targetStyle = "neutral" })
end

installConvoFamily("question.identity")
installConvoFamily("question.identity.known")
installConvoFamily("question.knowledge.known")
installConvoFamily("question.knowledge.unknown")
installConvoFamily("question.activity.fishing")
installConvoFamily("question.activity.dataset.keep_moving")
installConvoFamily("gossip.unknown")

installBackstoryFamily("question.backstory.known")
installBackstoryFamily("question.backstory.known.education")
installBackstoryFamily("question.backstory.known.family_background")
installBackstoryFamily("question.backstory.known.fear")
installBackstoryFamily("question.backstory.known.former_job")
installBackstoryFamily("question.backstory.known.hobby")
installBackstoryFamily("question.backstory.known.hometown")
installBackstoryFamily("question.backstory.known.tragedy")
installBackstoryFamily("question.backstory.refusal")
installBackstoryFamily("question.backstory.ambiguous")
installBackstoryFamily("question.backstory.suspected")
installBackstoryFamily("question.backstory.follow_up.location")
installBackstoryFamily("question.backstory.follow_up.miss")

return true
