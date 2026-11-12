-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_ask_about",
        ["id"] = "social.ask_about.member",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "social.ask_about.member",
            ["sourcePath"] = "psdl/dialogue/social_ask_about.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/social_ask_about_member",
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
                ["audience"] = "member",
                ["category"] = "projecthoomans:ask_about",
                ["runtimeBlockID"] = "projecthoomans:ask_about_member",
                ["textDomain"] = "pnc.psdl.social.ask_about.member",
                ["textTarget"] = "psdl/social/ask_about/member",
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
                                        "Tell me about your old life.",
                                    },
                                    ["TL"] = {
                                        "Sabihin mo sa akin ang tungkol sa iyong lumang buhay.",
                                    },
                                },
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.background",
                                    ["responseKey"] = "response.background",
                                    ["responseText"] = {
                                        ["EN"] = "It feels like someone else's life now.",
                                        ["TL"] = "Parang may buhay ng iba ngayon.",
                                    },
                                },
                                ["utterance"] = {
                                    ["EN"] = {
                                        "Tell me about your old life.",
                                    },
                                    ["TL"] = {
                                        "Sabihin mo sa akin ang tungkol sa iyong lumang buhay.",
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
                                        "What can you teach the group?",
                                    },
                                    ["TL"] = {
                                        "What can you teach the grupo?",
                                    },
                                },
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.skills",
                                    ["responseKey"] = "response.skills",
                                    ["responseText"] = {
                                        ["EN"] = "Give me a job and I'll show you.",
                                        ["TL"] = "Bigyan mo ako ng trabaho at ipapakita ko sa iyo.",
                                    },
                                },
                                ["utterance"] = {
                                    ["EN"] = {
                                        "What can you teach the group?",
                                    },
                                    ["TL"] = {
                                        "What can you teach the grupo?",
                                    },
                                },
                            },
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Go ahead, {addressee.name}. What do you want to ask about?",
                            },
                            ["TL"] = {
                                "Sige, {addressee.name}. Ano ang gusto mong itanong?",
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
            ["responsePlanID"] = "social.ask_about.member",
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
                            ["labelFallback"] = "Tell me about your old life.",
                            ["labelKey"] = "psdl.social.ask_about.member.offer.background.label",
                            ["utteranceFallback"] = "Tell me about your old life.",
                            ["utteranceKey"] = "psdl.social.ask_about.member.offer.background.utterance",
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
                            ["labelFallback"] = "What can you teach the group?",
                            ["labelKey"] = "psdl.social.ask_about.member.offer.skills.label",
                            ["utteranceFallback"] = "What can you teach the group?",
                            ["utteranceKey"] = "psdl.social.ask_about.member.offer.skills.utterance",
                        },
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Go ahead, {addressee.name}. What do you want to ask about?",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.social.ask_about.member.opening",
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
