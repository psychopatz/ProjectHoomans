-- Deterministic responses for semantic navigation exchanges.
-- Navigation changes the active semantic branch but still represents a real
-- conversational turn. It never owns gameplay execution.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.ResponseCatalog
if type(Catalog) ~= "table" or type(Catalog.Register) ~= "function" then
    return false
end

Catalog.Extend("semantic.conversation.acknowledged", {
    variants = {
        {
            id = "semantic.navigation.orders",
            templateID = "semantic.navigation.orders",

            when = { subject = "COMPANION_ORDERS" },
            priority = 5,
        },
        {
            id = "semantic.navigation.camp",
            templateID = "semantic.navigation.camp",

            when = { subject = "COMPANION_CAMP" },
            priority = 5,
        },
        {
            id = "semantic.navigation.camp_empty",
            templateID = "semantic.navigation.camp_empty",

            when = { subject = "COMPANION_CAMP_EMPTY" },
            priority = 5,
        },
        {
            id = "semantic.navigation.subject_change",
            templateID = "semantic.navigation.subject_change",

            when = { subject = "CONVERSATION_TOPIC" },
            priority = 5,
        },
    },
})

return true
