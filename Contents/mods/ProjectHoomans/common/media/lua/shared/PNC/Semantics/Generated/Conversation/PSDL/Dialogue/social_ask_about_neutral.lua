-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_ask_about",
        ["id"] = "social.ask_about.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "social.ask_about.neutral",
            ["sourcePath"] = "psdl/dialogue/social_ask_about.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/social_ask_about_neutral",
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
                ["audience"] = "neutral",
                ["category"] = "projecthoomans:ask_about",
                ["runtimeBlockID"] = "projecthoomans:ask_about_neutral",
                ["textDomain"] = "pnc.psdl.social.ask_about.neutral",
                ["textTarget"] = "psdl/social/ask_about/neutral",
            },
            ["response"] = {
                ["act"] = "ASK_ABOUT",
                ["turns"] = {
                    {
                        ["id"] = "opening",
                        ["metadata"] = {
                            ["textKey"] = "opening",
                        },
                        ["offers"] = {
                            {
                                ["consumers"] = {
                                    "participant",
                                },
                                ["frame"] = {
                                    ["intent"] = "QUESTION",
                                    ["speechAct"] = "QUESTION",
                                    ["subject"] = "BACKGROUND",
                                    ["topic"] = "ask_about",
                                },
                                ["id"] = "background",
                                ["label"] = {
                                    ["EN"] = {
                                        "What did you do before all this?",
                                    },
                                    ["TL"] = {
                                        "Ano ang ginawa mo bago ang lahat ng ito?",
                                    },
                                },
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.background",
                                    ["responseKey"] = "response.background",
                                    ["responseText"] = {
                                        ["EN"] = "That's a long story. Maybe one worth telling.",
                                        ["TL"] = "mahabang kwento yan. Siguro isa na dapat sabihin.",
                                    },
                                },
                                ["utterance"] = {
                                    ["EN"] = {
                                        "What did you do before all this?",
                                    },
                                    ["TL"] = {
                                        "Ano ang ginawa mo bago ang lahat ng ito?",
                                    },
                                },
                            },
                            {
                                ["consumers"] = {
                                    "participant",
                                },
                                ["frame"] = {
                                    ["intent"] = "QUESTION",
                                    ["speechAct"] = "QUESTION",
                                    ["subject"] = "SKILLS",
                                    ["topic"] = "ask_about",
                                },
                                ["id"] = "skills",
                                ["label"] = {
                                    ["EN"] = {
                                        "What are you good at?",
                                    },
                                    ["TL"] = {
                                        "Ano ang kaya mong gawin?",
                                    },
                                },
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.skills",
                                    ["responseKey"] = "response.skills",
                                    ["responseText"] = {
                                        ["EN"] = "Enough things to have survived this long.",
                                        ["TL"] = "Sapat na ang mga bagay para mabuhay ng ganito katagal.",
                                    },
                                },
                                ["utterance"] = {
                                    ["EN"] = {
                                        "What are you good at?",
                                    },
                                    ["TL"] = {
                                        "Ano ang kaya mong gawin?",
                                    },
                                },
                            },
                        },
                        ["text"] = {
                            ["EN"] = {
                                "What do you want to know?",
                            },
                            ["TL"] = {
                                "Ano ang gusto mong malaman?",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "ASK_ABOUT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "social.ask_about.neutral",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "opening",
                    ["offers"] = {
                        {
                            ["consumers"] = {
                                "participant",
                            },
                            ["frame"] = {
                                ["intent"] = "QUESTION",
                                ["speechAct"] = "QUESTION",
                                ["subject"] = "BACKGROUND",
                                ["topic"] = "ask_about",
                            },
                            ["id"] = "background",
                            ["labelFallback"] = "What did you do before all this?",
                            ["labelKey"] = "psdl.social.ask_about.neutral.offer.background.label",
                            ["utteranceFallback"] = "What did you do before all this?",
                            ["utteranceKey"] = "psdl.social.ask_about.neutral.offer.background.utterance",
                        },
                        {
                            ["consumers"] = {
                                "participant",
                            },
                            ["frame"] = {
                                ["intent"] = "QUESTION",
                                ["speechAct"] = "QUESTION",
                                ["subject"] = "SKILLS",
                                ["topic"] = "ask_about",
                            },
                            ["id"] = "skills",
                            ["labelFallback"] = "What are you good at?",
                            ["labelKey"] = "psdl.social.ask_about.neutral.offer.skills.label",
                            ["utteranceFallback"] = "What are you good at?",
                            ["utteranceKey"] = "psdl.social.ask_about.neutral.offer.skills.utterance",
                        },
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "What do you want to know?",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.social.ask_about.neutral.opening",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/social_ask_about.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
