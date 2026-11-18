-- Generated; do not edit by hand.
return {
    {
        ["constraints"] = {
            ["all"] = {
                {
                    ["op"] = "not_in",
                    ["path"] = "npcState.activeBehavior",
                    ["values"] = {
                        "hostile",
                        "combat",
                        "busy",
                        "dead",
                    },
                },
                {
                    ["op"] = "not_in",
                    ["path"] = "situation.activeBehavior",
                    ["values"] = {
                        "hostile",
                        "combat",
                        "busy",
                        "dead",
                    },
                },
                {
                    ["op"] = "neq",
                    ["path"] = "roles.hostile",
                    ["value"] = true,
                },
                {
                    ["op"] = "neq",
                    ["path"] = "actorConversationContext.roles.hostile",
                    ["value"] = true,
                },
                {
                    ["op"] = "not_in",
                    ["path"] = "actorConversationContext.situation.activeBehavior",
                    ["values"] = {
                        "hostile",
                        "combat",
                        "busy",
                        "dead",
                    },
                },
                {
                    ["op"] = "not_in",
                    ["path"] = "npcState.healthState",
                    ["values"] = {
                        "dead",
                        "incapacitated",
                    },
                },
            },
        },
        ["domain"] = "semantic",
        ["id"] = "greeting",
        ["initial"] = "await_thanks",
        ["nodes"] = {
            ["await_thanks"] = {
                ["accepts"] = {
                    {
                        ["intent"] = "THANK",
                        ["speechAct"] = "THANK",
                    },
                    {
                        ["intent"] = "INFORM",
                        ["selfDirected"] = true,
                        ["speechAct"] = "INFORM",
                        ["stateType"] = "WELLBEING",
                        ["target"] = "SELF",
                    },
                },
                ["branchOffers"] = {
                    {
                        ["constraints"] = {
                            ["all"] = {
                                {
                                    ["op"] = "not_in",
                                    ["path"] = "npcState.activeBehavior",
                                    ["values"] = {
                                        "hostile",
                                        "combat",
                                        "busy",
                                        "dead",
                                    },
                                },
                                {
                                    ["op"] = "not_in",
                                    ["path"] = "npcState.healthState",
                                    ["values"] = {
                                        "dead",
                                        "incapacitated",
                                    },
                                },
                            },
                        },
                        ["frame"] = {
                            ["intent"] = "THANK",
                            ["speechAct"] = "THANK",
                        },
                        ["id"] = "greeting.thanks",
                        ["labelFallback"] = "Thank them",
                        ["labelKey"] = "UI_PNC_Conversation_Suggestion_GreetingThank_Label",
                        ["utteranceFallback"] = "Thanks.",
                        ["utteranceKey"] = "UI_PNC_Conversation_Suggestion_GreetingThank_Utterance",
                    },
                },
                ["onMatch"] = "complete",
                ["onRefuse"] = "cancel",
                ["onUnrelated"] = "suspend",
                ["responsePool"] = "semantic.flow.greeting.opening",
            },
            ["complete"] = {
                ["responsePool"] = "semantic.flow.greeting.followup",
                ["terminal"] = true,
            },
        },
        ["owner"] = "ProjectHoomans",
        ["triggers"] = {
            {
                ["intent"] = "GREET",
                ["speechAct"] = "GREET",
            },
        },
        ["version"] = 1,
    },
}
