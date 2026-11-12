-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_check_in",
        ["id"] = "social.wellbeing.special",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "social.wellbeing.special",
            ["sourcePath"] = "psdl/dialogue/social_check_in.json#records[2]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/social_wellbeing_special",
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
                ["category"] = "projecthoomans:wellbeing",
                ["runtimeBlockID"] = "projecthoomans:wellbeing_special",
                ["textDomain"] = "pnc.psdl.social.wellbeing.special",
                ["textTarget"] = "psdl/social/wellbeing/special",
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
                                        "How are you really doing?",
                                    },
                                    ["TL"] = {
                                        "Kamusta ka na talaga?",
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
                                        ["EN"] = "Better now that you're here.",
                                        ["TL"] = "Mas mabuti na ngayong nandito ka na.",
                                    },
                                },
                                ["utterance"] = {
                                    ["EN"] = {
                                        "How are you really doing?",
                                    },
                                    ["TL"] = {
                                        "Kamusta ka na talaga?",
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
                                        "Let me help.",
                                    },
                                    ["TL"] = {
                                        "Hayaan mo akong tumulong.",
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
                                        ["EN"] = "All right. Just stay close for a minute.",
                                        ["TL"] = "Sige. Manatiling malapit sa isang minuto.",
                                    },
                                },
                                ["utterance"] = {
                                    ["EN"] = {
                                        "Let me help.",
                                    },
                                    ["TL"] = {
                                        "Hayaan mo akong tumulong.",
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
                                "I'll be honest with you, {addressee.name}. Ask.",
                            },
                            ["TL"] = {
                                "Magiging tapat ako sa iyo, {addressee.name}. Magtanong.",
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
            ["responsePlanID"] = "social.wellbeing.special",
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
                            ["labelFallback"] = "How are you really doing?",
                            ["labelKey"] = "psdl.social.wellbeing.special.offer.condition.label",
                            ["utteranceFallback"] = "How are you really doing?",
                            ["utteranceKey"] = "psdl.social.wellbeing.special.offer.condition.utterance",
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
                            ["labelFallback"] = "Let me help.",
                            ["labelKey"] = "psdl.social.wellbeing.special.offer.offer_help.label",
                            ["utteranceFallback"] = "Let me help.",
                            ["utteranceKey"] = "psdl.social.wellbeing.special.offer.offer_help.utterance",
                        },
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "I'll be honest with you, {addressee.name}. Ask.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.social.wellbeing.special.opening",
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
