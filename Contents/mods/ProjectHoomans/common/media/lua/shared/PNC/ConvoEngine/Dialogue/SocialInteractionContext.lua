-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_context",
        ["exchangeFamily"] = {
            ["familyID"] = "interaction.context.clarify",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["fallback"] = "What are you referring to?",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.interaction.context.clarify.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "What are you referring to?",
                                        "Can you clarify what you mean?",
                                        "What specifically are you talking about?",
                                        "I'm not following. Explain what you mean.",
                                        "Give me some more context on that.",
                                        "What do you mean by that exactly?",
                                        "Which situation are you talking about?",
                                        "Could you break that down for me?",
                                        "I need more details before I understand.",
                                        "What are you getting at?",
                                    },
                                    ["TL"] = {
                                        "Ano ang tinutukoy mo?",
                                        "Pwede mo bang linawin ang ibig mong sabihin?",
                                        "Tungkol saan ba partikular ang sinasabi mo?",
                                        "Hindi kita masundan. Ipaliwanag mo ang ibig mong sabihin.",
                                        "Bigyan mo ako ng karagdagang konteksto tungkol diyan.",
                                        "Ano nga ba ang ibig mong sabihin doon?",
                                        "Aling sitwasyon ba ang tinutukoy mo?",
                                        "Pwede mo bang himayin 'yan para sa akin?",
                                        "Kailangan ko ng dagdag na detalye bago ko maintindihan.",
                                        "Saan ba patungo ang sinasabi mo?",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "interaction.context",
            ["textRoles"] = {
                {
                    ["fallback"] = "What are you referring to?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.context.clarify.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "What are you referring to?",
                            "Can you clarify what you mean?",
                            "What specifically are you talking about?",
                            "I'm not following. Explain what you mean.",
                            "Give me some more context on that.",
                            "What do you mean by that exactly?",
                            "Which situation are you talking about?",
                            "Could you break that down for me?",
                            "I need more details before I understand.",
                            "What are you getting at?",
                        },
                        ["TL"] = {
                            "Ano ang tinutukoy mo?",
                            "Pwede mo bang linawin ang ibig mong sabihin?",
                            "Tungkol saan ba partikular ang sinasabi mo?",
                            "Hindi kita masundan. Ipaliwanag mo ang ibig mong sabihin.",
                            "Bigyan mo ako ng karagdagang konteksto tungkol diyan.",
                            "Ano nga ba ang ibig mong sabihin doon?",
                            "Aling sitwasyon ba ang tinutukoy mo?",
                            "Pwede mo bang himayin 'yan para sa akin?",
                            "Kailangan ko ng dagdag na detalye bago ko maintindihan.",
                            "Saan ba patungo ang sinasabi mo?",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "interaction.context.clarify",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "clarify",
            ["sourceId"] = "interaction.context.clarify",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_interaction_context/interaction_context_clarify.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionContext",
        ["namespace"] = "interaction.context",
        ["owner"] = "ProjectHoomans",
        ["participants"] = {
            ["addressee"] = {
                "participant",
            },
            ["speaker"] = {
                "participant",
            },
        },
        ["payload"] = {
            ["metadata"] = {
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
                ["responseAct"] = "REACT",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "What are you referring to?",
                                        "Can you clarify what you mean?",
                                        "What specifically are you talking about?",
                                        "I'm not following. Explain what you mean.",
                                        "Give me some more context on that.",
                                        "What do you mean by that exactly?",
                                        "Which situation are you talking about?",
                                        "Could you break that down for me?",
                                        "I need more details before I understand.",
                                        "What are you getting at?",
                                    },
                                    ["TL"] = {
                                        "Ano ang tinutukoy mo?",
                                        "Pwede mo bang linawin ang ibig mong sabihin?",
                                        "Tungkol saan ba partikular ang sinasabi mo?",
                                        "Hindi kita masundan. Ipaliwanag mo ang ibig mong sabihin.",
                                        "Bigyan mo ako ng karagdagang konteksto tungkol diyan.",
                                        "Ano nga ba ang ibig mong sabihin doon?",
                                        "Aling sitwasyon ba ang tinutukoy mo?",
                                        "Pwede mo bang himayin 'yan para sa akin?",
                                        "Kailangan ko ng dagdag na detalye bago ko maintindihan.",
                                        "Saan ba patungo ang sinasabi mo?",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "interaction.context.clarify",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "What are you referring to?",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.interaction.context.clarify.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/social_interaction_context/interaction_context_clarify.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "What are you referring to?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.context.clarify.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "What are you referring to?",
                        "Can you clarify what you mean?",
                        "What specifically are you talking about?",
                        "I'm not following. Explain what you mean.",
                        "Give me some more context on that.",
                        "What do you mean by that exactly?",
                        "Which situation are you talking about?",
                        "Could you break that down for me?",
                        "I need more details before I understand.",
                        "What are you getting at?",
                    },
                    ["TL"] = {
                        "Ano ang tinutukoy mo?",
                        "Pwede mo bang linawin ang ibig mong sabihin?",
                        "Tungkol saan ba partikular ang sinasabi mo?",
                        "Hindi kita masundan. Ipaliwanag mo ang ibig mong sabihin.",
                        "Bigyan mo ako ng karagdagang konteksto tungkol diyan.",
                        "Ano nga ba ang ibig mong sabihin doon?",
                        "Aling sitwasyon ba ang tinutukoy mo?",
                        "Pwede mo bang himayin 'yan para sa akin?",
                        "Kailangan ko ng dagdag na detalye bago ko maintindihan.",
                        "Saan ba patungo ang sinasabi mo?",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
