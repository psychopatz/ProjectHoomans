-- ProjectHoomans projects Core-compiled social, health, and wellbeing PSDL
-- records into the established phrase-family/SpeechRealization authority.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Registry = require
    "PNC/ConvoEngine/Registry"
local ConvoPlanFamily = require
    "PNC/ConvoEngine/ResponseCatalog/ConvoPlanFamily"

local OWNED_CATEGORIES = {
    ["projecthoomans:core_social_content"] = true,
    ["projecthoomans:conversation_content"] = true,
    ["projecthoomans:compatibility_content"] = true,
    ["projecthoomans:health_content"] = true,
    ["projecthoomans:quest_content"] = true,
    ["projecthoomans:wellbeing_content"] = true,
}

local function addPlan(families, plan)
    local payload = type(plan) == "table" and plan.payload or nil
    local metadata = type(payload) == "table"
        and payload.metadata or nil
    if type(metadata) ~= "table"
        or not OWNED_CATEGORIES[metadata.category]
    then
        return
    end
    local playerChoice = metadata.playerChoice
    if type(playerChoice) == "table"
        and type(playerChoice.id) == "string"
        and playerChoice.id ~= ""
    then
        local choiceID = playerChoice.id
        local canonical = string.upper(
            string.gsub(choiceID, "[^%w]+", "_")
        )
        Registry.PLAYER_CHOICES[choiceID] = {
            canonicalConcept = canonical,
            choiceKey = "conversation.content.choice."
                .. choiceID .. ".choice",
            hubID = playerChoice.hubID or "whats_up",
            id = choiceID,
            kind = playerChoice.kind or "player_landing_choice",
            labelKey = "conversation.content.choice."
                .. choiceID .. ".label",
            route = playerChoice.route or "semantic_hub",
            labelFallback = type(playerChoice.label) == "table"
                and (playerChoice.label.EN or playerChoice.label.TL)
                or playerChoice.label,
            utteranceFallback = type(playerChoice.choice) == "table"
                and (playerChoice.choice.EN or playerChoice.choice.TL)
                or playerChoice.choice,
        }
    end
    local defaultOwner = metadata.contentOwner
        or "projecthoomans.dialogue_content.social"
    local templateID = metadata.responseTemplateID
    ConvoPlanFamily.installPlan(families, plan, {
        defaultContentOwner = defaultOwner,
    })
    if type(templateID) == "string" and templateID ~= ""
        and templateID ~= plan.id
    then
        ConvoPlanFamily.installPlan(families, plan, {
            installAs = templateID,
            defaultContentOwner = defaultOwner,
        })
    end
end

local families = {}
for _, plan in pairs(Registry.CONVO_PLANS or {}) do
    addPlan(families, plan)
end

return true
