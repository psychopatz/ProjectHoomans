-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_context",
        ["id"] = "semantic.interaction.context.clarify.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.interaction.context.clarify.neutral",
            ["sourcePath"] = "psdl/dialogue/social_interaction_context.json",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionContext",
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
                ["responseTemplateID"] = "semantic.interaction.context.clarify",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/context/clarify.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "What are you referring to?",
                            },
                            ["TL"] = {
                                "Ano ang tinutukoy mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Can you clarify what you mean?",
                            },
                            ["TL"] = {
                                "Pwede mo bang linawin ang ibig mong sabihin?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "What specifically are you talking about?",
                            },
                            ["TL"] = {
                                "Tungkol saan ba partikular ang sinasabi mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I'm not following. Explain what you mean.",
                            },
                            ["TL"] = {
                                "Hindi kita masundan. Ipaliwanag mo ang ibig mong sabihin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Give me some more context on that.",
                            },
                            ["TL"] = {
                                "Bigyan mo ako ng karagdagang konteksto tungkol diyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "What do you mean by that exactly?",
                            },
                            ["TL"] = {
                                "Ano nga ba ang ibig mong sabihin doon?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Which situation are you talking about?",
                            },
                            ["TL"] = {
                                "Aling sitwasyon ba ang tinutukoy mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Could you break that down for me?",
                            },
                            ["TL"] = {
                                "Pwede mo bang himayin 'yan para sa akin?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "I need more details before I understand.",
                            },
                            ["TL"] = {
                                "Kailangan ko ng dagdag na detalye bago ko maintindihan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "What are you getting at?",
                            },
                            ["TL"] = {
                                "Saan ba patungo ang sinasabi mo?",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/social_interaction_context.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
