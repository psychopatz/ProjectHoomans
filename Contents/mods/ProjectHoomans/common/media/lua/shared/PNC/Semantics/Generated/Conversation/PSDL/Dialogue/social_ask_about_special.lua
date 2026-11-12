-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_ask_about",
        ["id"] = "social.ask_about.special",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "social.ask_about.special",
            ["sourcePath"] = "psdl/dialogue/social_ask_about.json#records[2]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/social_ask_about_special",
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
                ["audience"] = "special",
                ["category"] = "projecthoomans:ask_about",
                ["runtimeBlockID"] = "projecthoomans:ask_about_special",
                ["textDomain"] = "pnc.psdl.social.ask_about.special",
                ["textTarget"] = "psdl/social/ask_about/special",
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
                                        "Tell me something about your old life.",
                                    },
                                    ["TL"] = {
                                        "Sabihin mo sa akin ang tungkol sa iyong dating buhay.",
                                    },
                                },
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.background",
                                    ["responseKey"] = "response.background",
                                    ["responseText"] = {
                                        ["EN"] = "Only if you tell me something about yours afterward.",
                                        ["TL"] = "Kung sasabihin mo lang sa akin ang tungkol sa iyo pagkatapos.",
                                    },
                                },
                                ["utterance"] = {
                                    ["EN"] = {
                                        "Tell me something about your old life.",
                                    },
                                    ["TL"] = {
                                        "Sabihin mo sa akin ang tungkol sa iyong dating buhay.",
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
                                        "What are you proud of?",
                                    },
                                    ["TL"] = {
                                        "Ano ang ipinagmamalaki mo?",
                                    },
                                },
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.skills",
                                    ["responseKey"] = "response.skills",
                                    ["responseText"] = {
                                        ["EN"] = "Surviving long enough to meet you.",
                                        ["TL"] = "Nakaligtas nang sapat upang makilala ka.",
                                    },
                                },
                                ["utterance"] = {
                                    ["EN"] = {
                                        "What are you proud of?",
                                    },
                                    ["TL"] = {
                                        "Ano ang ipinagmamalaki mo?",
                                    },
                                },
                            },
                        },
                        ["text"] = {
                            ["EN"] = {
                                "You can ask me anything, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Maaari mo akong tanungin tungkol sa kahit ano, {addressee.name}.",
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
            ["responsePlanID"] = "social.ask_about.special",
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
                            ["labelFallback"] = "Tell me something about your old life.",
                            ["labelKey"] = "psdl.social.ask_about.special.offer.background.label",
                            ["utteranceFallback"] = "Tell me something about your old life.",
                            ["utteranceKey"] = "psdl.social.ask_about.special.offer.background.utterance",
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
                            ["labelFallback"] = "What are you proud of?",
                            ["labelKey"] = "psdl.social.ask_about.special.offer.skills.label",
                            ["utteranceFallback"] = "What are you proud of?",
                            ["utteranceKey"] = "psdl.social.ask_about.special.offer.skills.utterance",
                        },
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "You can ask me anything, {addressee.name}.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.social.ask_about.special.opening",
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
