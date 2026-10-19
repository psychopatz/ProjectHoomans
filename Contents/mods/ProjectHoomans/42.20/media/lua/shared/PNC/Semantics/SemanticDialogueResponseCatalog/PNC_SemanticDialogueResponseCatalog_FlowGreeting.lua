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
            id = "semantic.flow.greeting.opening.rain",
            templateID = "semantic.flow.greeting.opening.rain",
            fallback = "Hey there. Wet one today.",
            when = { raining = true },
            priority = 3,
            plan = {
                dialogueAct = "GREETING_OPENING",
                sourcePoolID = "semantic.flow.greeting.opening",
                turns = {
                    {
                        id = "greeting",
                        continuation = "continue",
                        segments = {
                            {
                                kind = "translation",
                                templateID = "semantic.flow.greeting.opening.rain",
                                fallback = "Hey there. Wet one today.",
                            },
                        },
                    },
                    {
                        id = "check_in",
                        continuation = "await_player",
                        segments = {
                            {
                                kind = "translation",
                                templateID = "semantic.flow.greeting.opening.question.default",
                                fallback = "How have you been?",
                            },
                        },
                    },
                },
            },
        },
        {
            id = "semantic.flow.greeting.opening.friendly",
            templateID = "semantic.flow.greeting.opening.friendly",
            fallback = "Hey! Good to see you.",
            when = { socialStyle = "friendly" },
            priority = 2,
            plan = {
                dialogueAct = "GREETING_OPENING",
                sourcePoolID = "semantic.flow.greeting.opening",
                turns = {
                    {
                        id = "greeting",
                        continuation = "continue",
                        segments = {
                            {
                                kind = "translation",
                                templateID =
                                    "semantic.flow.greeting.opening.friendly",
                                fallback = "Hey! Good to see you.",
                            },
                        },
                    },
                    {
                        id = "check_in",
                        continuation = "await_player",
                        segments = {
                            {
                                kind = "translation",
                                templateID =
                                    "semantic.flow.greeting.opening.question.friendly",
                                fallback = "How have you been holding up?",
                            },
                        },
                    },
                },
            },
        },
        {
            id = "semantic.flow.greeting.opening.default",
            templateID = "semantic.flow.greeting.opening.default",
            fallback = "Hello. Good to see you.",
            plan = {
                dialogueAct = "GREETING_OPENING",
                sourcePoolID = "semantic.flow.greeting.opening",
                turns = {
                    {
                        id = "greeting",
                        continuation = "continue",
                        segments = {
                            {
                                kind = "translation",
                                templateID =
                                    "semantic.flow.greeting.opening.default",
                                fallback = "Hello. Good to see you.",
                            },
                        },
                    },
                    {
                        id = "check_in",
                        continuation = "await_player",
                        segments = {
                            {
                                kind = "translation",
                                templateID =
                                    "semantic.flow.greeting.opening.question.default",
                                fallback = "How have you been?",
                            },
                        },
                    },
                },
            },
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
