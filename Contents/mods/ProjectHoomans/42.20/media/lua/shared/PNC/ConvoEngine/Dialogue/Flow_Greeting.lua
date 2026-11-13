-- A small modular social exchange. The flow owns the bounded follow-up;
-- central intent policy remains responsible for ordinary standalone replies.
local GREETING_DIALOGUE_CONSTRAINTS = {
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
}

return {
    id = "greeting",
    version = 1,
    owner = "ProjectHoomans",
    triggers = {
        { intent = "GREET", speechAct = "GREET" },
    },
    initial = "await_thanks",
    nodes = {
        await_thanks = {
            responsePool = "semantic.flow.greeting.opening",
            branchOffers = {
                {
                    id = "greeting.thanks",
                    labelKey = "UI_PNC_Conversation_Suggestion_GreetingThank_Label",
                    labelFallback = "Thank them",
                    utteranceKey = "UI_PNC_Conversation_Suggestion_GreetingThank_Utterance",
                    utteranceFallback = "Thanks.",
                    frame = {
                        intent = "THANK",
                        speechAct = "THANK",
                    },
                    constraints = GREETING_DIALOGUE_CONSTRAINTS,
                },
            },
            accepts = {
                { intent = "THANK", speechAct = "THANK" },
                {
                    intent = "INFORM",
                    speechAct = "INFORM",
                    selfDirected = true,
                    target = "SELF",
                    stateType = "WELLBEING",
                },
            },
            onMatch = "complete",
            onRefuse = "cancel",
            onUnrelated = "suspend",
        },
        complete = {
            terminal = true,
            responsePool = "semantic.flow.greeting.followup",
        },
    },
}
