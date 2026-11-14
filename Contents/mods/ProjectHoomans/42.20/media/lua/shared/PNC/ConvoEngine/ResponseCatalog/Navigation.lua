-- Deterministic responses for semantic navigation exchanges.
-- Navigation changes the active semantic branch but still represents a real
-- conversational turn. It never owns gameplay execution.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Catalog = PNC.ConvoEngine.ResponseCatalog
if type(Catalog) ~= "table" or type(Catalog.Register) ~= "function" then
    return false
end

local ConvoPlanFamily = require
    "PNC/ConvoEngine/ResponseCatalog/ConvoPlanFamily"

for _, templateID in ipairs({
    "navigation.camp",
    "navigation.camp_empty",
    "navigation.default",
    "navigation.orders",
    "navigation.subject_change",
}) do
    ConvoPlanFamily.install(templateID, {
        defaultContentOwner = "projecthoomans.dialogue_content.navigation",
    })
end

Catalog.Extend("semantic.conversation.acknowledged", {
    variants = {
        {
            id = "semantic.navigation.orders",
            templateID = "navigation.orders",
            fallback = "All right. What do you need?",
            when = { subject = "COMPANION_ORDERS" },
            priority = 5,
        },
        {
            id = "semantic.navigation.camp",
            templateID = "navigation.camp",
            fallback = "Where should we set up?",
            when = { subject = "COMPANION_CAMP" },
            priority = 5,
        },
        {
            id = "semantic.navigation.camp_empty",
            templateID = "navigation.camp_empty",
            fallback = "I don't see a good place to set up here.",
            when = { subject = "COMPANION_CAMP_EMPTY" },
            priority = 5,
        },
        {
            id = "semantic.navigation.subject_change",
            templateID = "navigation.subject_change",
            fallback = "All right. What did you want to talk about?",
            when = { subject = "CONVERSATION_TOPIC" },
            priority = 5,
        },
    },
})

return true
