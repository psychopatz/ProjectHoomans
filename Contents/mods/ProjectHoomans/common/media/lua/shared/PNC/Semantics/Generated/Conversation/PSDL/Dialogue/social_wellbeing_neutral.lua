-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_check_in",
        ["id"] = "social.wellbeing.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "social.wellbeing.neutral",
            ["sourcePath"] = "psdl/dialogue/social_check_in.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/social_wellbeing_neutral",
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
                ["category"] = "projecthoomans:wellbeing",
                ["runtimeBlockID"] = "projecthoomans:wellbeing_neutral",
                ["textDomain"] = "pnc.psdl.social.wellbeing.neutral",
                ["textTarget"] = "psdl/social/wellbeing/neutral",
            },
            ["response"] = {
                ["act"] = "CHECK_IN",
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
                                    ["subject"] = "WELLBEING",
                                    ["topic"] = "wellbeing",
                                },
                                ["id"] = "condition",
                                ["label"] = {
                                    ["EN"] = {
                                        "How are you holding up?",
                                    },
                                    ["TL"] = {
                                        "Kamusta ka na?",
                                    },
                                },
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.condition",
                                    ["effects"] = {
                                        {
                                            ["approval"] = 1,
                                            ["familiarity"] = 1,
                                            ["type"] = "pnc:relationship",
                                        },
                                    },
                                    ["responseKey"] = "response.condition",
                                    ["responseText"] = {
                                        ["EN"] = "I'm still breathing. That's enough for now.",
                                        ["TL"] = "humihinga pa ako. Tama na sa ngayon.",
                                    },
                                },
                                ["utterance"] = {
                                    ["EN"] = {
                                        "How are you holding up?",
                                    },
                                    ["TL"] = {
                                        "Kamusta ka na?",
                                    },
                                },
                                ["when"] = {
                                    ["all"] = {
                                        {
                                            ["op"] = "gte",
                                            ["path"] = "relationship.speakerToAddressee.approval",
                                            ["value"] = 1,
                                        },
                                        {
                                            ["op"] = "gte",
                                            ["path"] = "relationship.speakerToAddressee.familiarity",
                                            ["value"] = 1,
                                        },
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
                                    ["subject"] = "HELP",
                                    ["topic"] = "wellbeing",
                                },
                                ["id"] = "offer_help",
                                ["label"] = {
                                    ["EN"] = {
                                        "Do you need any help?",
                                    },
                                    ["TL"] = {
                                        "Kailangan mo ba ng anumang tulong?",
                                    },
                                },
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.offer_help",
                                    ["effects"] = {
                                        {
                                            ["approval"] = 2,
                                            ["respect"] = 1,
                                            ["type"] = "pnc:relationship",
                                        },
                                    },
                                    ["responseKey"] = "response.offer_help",
                                    ["responseText"] = {
                                        ["EN"] = "I'll manage, but thanks for asking.",
                                        ["TL"] = "Aayusin ko, pero salamat sa pagtatanong.",
                                    },
                                },
                                ["utterance"] = {
                                    ["EN"] = {
                                        "Do you need any help?",
                                    },
                                    ["TL"] = {
                                        "Kailangan mo ba ng anumang tulong?",
                                    },
                                },
                                ["when"] = {
                                    ["all"] = {
                                        {
                                            ["op"] = "gte",
                                            ["path"] = "relationship.speakerToAddressee.approval",
                                            ["value"] = 2,
                                        },
                                        {
                                            ["op"] = "gte",
                                            ["path"] = "relationship.speakerToAddressee.respect",
                                            ["value"] = 1,
                                        },
                                    },
                                },
                            },
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm managing. What did you want to ask?",
                            },
                            ["TL"] = {
                                "pinamamahalaan ko. Ano ang gusto mong itanong?",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "CHECK_IN",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "social.wellbeing.neutral",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "opening",
                    ["offers"] = {
                        {
                            ["constraints"] = {
                                ["all"] = {
                                    {
                                        ["op"] = "gte",
                                        ["path"] = "relationship.speakerToAddressee.approval",
                                        ["value"] = 1,
                                    },
                                    {
                                        ["op"] = "gte",
                                        ["path"] = "relationship.speakerToAddressee.familiarity",
                                        ["value"] = 1,
                                    },
                                },
                            },
                            ["consumers"] = {
                                "participant",
                            },
                            ["frame"] = {
                                ["intent"] = "QUESTION",
                                ["speechAct"] = "QUESTION",
                                ["subject"] = "WELLBEING",
                                ["topic"] = "wellbeing",
                            },
                            ["id"] = "condition",
                            ["labelFallback"] = "How are you holding up?",
                            ["labelKey"] = "psdl.social.wellbeing.neutral.offer.condition.label",
                            ["utteranceFallback"] = "How are you holding up?",
                            ["utteranceKey"] = "psdl.social.wellbeing.neutral.offer.condition.utterance",
                        },
                        {
                            ["constraints"] = {
                                ["all"] = {
                                    {
                                        ["op"] = "gte",
                                        ["path"] = "relationship.speakerToAddressee.approval",
                                        ["value"] = 2,
                                    },
                                    {
                                        ["op"] = "gte",
                                        ["path"] = "relationship.speakerToAddressee.respect",
                                        ["value"] = 1,
                                    },
                                },
                            },
                            ["consumers"] = {
                                "participant",
                            },
                            ["frame"] = {
                                ["intent"] = "QUESTION",
                                ["speechAct"] = "QUESTION",
                                ["subject"] = "HELP",
                                ["topic"] = "wellbeing",
                            },
                            ["id"] = "offer_help",
                            ["labelFallback"] = "Do you need any help?",
                            ["labelKey"] = "psdl.social.wellbeing.neutral.offer.offer_help.label",
                            ["utteranceFallback"] = "Do you need any help?",
                            ["utteranceKey"] = "psdl.social.wellbeing.neutral.offer.offer_help.utterance",
                        },
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "I'm managing. What did you want to ask?",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.social.wellbeing.neutral.opening",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/social_check_in.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
