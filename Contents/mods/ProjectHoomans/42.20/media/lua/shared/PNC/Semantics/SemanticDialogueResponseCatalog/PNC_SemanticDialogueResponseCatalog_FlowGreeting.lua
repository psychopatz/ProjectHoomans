-- Response content for the modular greeting flow. The flow selects these
-- pools, while the normal response catalog still owns bounded variation.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.ResponseCatalog
if type(Catalog) ~= "table" or type(Catalog.Register) ~= "function" then
    return false
end

local GREETING_CHECK_IN_OFFERS = {
    {
        id = "greeting.check_in.report_wellbeing",
        labelKey = "UI_PNC_Conversation_Suggestion_GreetingReportFine_Label",
        labelFallback = "Say you're doing fine",
        utteranceKey = "UI_PNC_Conversation_Suggestion_GreetingReportFine_Utterance",
        utteranceFallback = "I'm fine, thank you.",
        frame = {
            intent = "INFORM",
            speechAct = "INFORM",
            subject = "WELLBEING",
            selfDirected = true,
            target = "SELF",
            stateType = "WELLBEING",
            stateValue = "fine",
        },
        constraints = {
            all = {
                {
                    path = "npcState.activeBehavior",
                    op = "not_in",
                    values = { "hostile", "combat", "busy", "dead" },
                },
                {
                    path = "npcState.healthState",
                    op = "not_in",
                    values = { "dead", "incapacitated" },
                },
            },
        },
    },
}

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
                topic = "WELLBEING",
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
                        offers = GREETING_CHECK_IN_OFFERS,
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
                topic = "WELLBEING",
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
                        offers = GREETING_CHECK_IN_OFFERS,
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
                topic = "WELLBEING",
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
                        offers = GREETING_CHECK_IN_OFFERS,
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
