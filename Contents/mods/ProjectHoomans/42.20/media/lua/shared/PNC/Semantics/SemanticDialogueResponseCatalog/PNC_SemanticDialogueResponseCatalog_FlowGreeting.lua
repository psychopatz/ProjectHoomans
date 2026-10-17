-- Response content for the modular greeting flow. The flow selects these
-- pools, while the normal response catalog still owns bounded variation.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.ResponseCatalog
if type(Catalog) ~= "table" or type(Catalog.Register) ~= "function" then
    return false
end

Catalog.Register("semantic.flow.greeting.opening", {
    variants = {
        {
            id = "semantic.flow.greeting.opening.friendly",
            templateID = "semantic.flow.greeting.opening.friendly",
            fallback = "Hey! Good to see you.",
            when = { socialStyle = "friendly" },
            priority = 2,
        },
        {
            id = "semantic.flow.greeting.opening.default",
            templateID = "semantic.flow.greeting.opening.default",
            fallback = "Hello. Good to see you.",
        },
    },
})

Catalog.Register("semantic.flow.greeting.followup", {
    variants = {
        {
            id = "semantic.flow.greeting.followup.friendly",
            templateID = "semantic.flow.greeting.followup.friendly",
            fallback = "You're welcome. It's good to see you too.",
            when = { socialStyle = "friendly" },
            priority = 2,
        },
        {
            id = "semantic.flow.greeting.followup.default",
            templateID = "semantic.flow.greeting.followup.default",
            fallback = "You're welcome. Take care.",
        },
    },
})

return true
