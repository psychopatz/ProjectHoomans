-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_companion_topics",
        ["id"] = "work_orders.member.status",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "work_orders.member.status",
            ["sourcePath"] = "psdl/dialogue/social_companion_topics.json#records[3]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/work_orders_member_status",
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
                ["audiences"] = {
                    "member",
                },
                ["category"] = "projecthoomans:work_orders",
                ["runtimeBlockID"] = "projecthoomans:work_orders_member",
                ["textDomain"] = "pnc.psdl.work_orders.member.status",
                ["textTarget"] = "psdl/work_orders/member/status",
            },
            ["response"] = {
                ["act"] = "WORK_ORDERS",
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
                                    ["intent"] = "REQUEST",
                                    ["speechAct"] = "REQUEST",
                                    ["subject"] = "WORK",
                                    ["topic"] = "work_orders",
                                },
                                ["id"] = "orders",
                                ["label"] = {
                                    ["EN"] = {
                                        "I have work for you.",
                                    },
                                    ["TL"] = {
                                        "may trabaho ako sayo.",
                                    },
                                },
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.orders",
                                    ["responseKey"] = "response.orders",
                                    ["responseText"] = {
                                        ["EN"] = "Tell me what needs doing.",
                                        ["TL"] = "Sabihin mo sa akin kung ano ang kailangang gawin.",
                                    },
                                },
                                ["utterance"] = {
                                    ["EN"] = {
                                        "I have work for you.",
                                    },
                                    ["TL"] = {
                                        "may trabaho ako sayo.",
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
                                    ["subject"] = "WORK",
                                    ["topic"] = "work_orders",
                                },
                                ["id"] = "status",
                                ["label"] = {
                                    ["EN"] = {
                                        "Report on your current work.",
                                    },
                                    ["TL"] = {
                                        "Mag-ulat sa iyong kasalukuyang gawain.",
                                    },
                                },
                                ["metadata"] = {
                                    ["choiceKey"] = "choice.status",
                                    ["responseKey"] = "response.status",
                                    ["responseText"] = {
                                        ["EN"] = "Everything is on track for now.",
                                        ["TL"] = "Ang lahat ay nasa track sa ngayon.",
                                    },
                                },
                                ["utterance"] = {
                                    ["EN"] = {
                                        "Report on your current work.",
                                    },
                                    ["TL"] = {
                                        "Mag-ulat sa iyong kasalukuyang gawain.",
                                    },
                                },
                            },
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm ready. What needs doing?",
                            },
                            ["TL"] = {
                                "handa na ako. Ano ang kailangang gawin?",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "WORK_ORDERS",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "work_orders.member.status",
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
                                ["intent"] = "REQUEST",
                                ["speechAct"] = "REQUEST",
                                ["subject"] = "WORK",
                                ["topic"] = "work_orders",
                            },
                            ["id"] = "orders",
                            ["labelFallback"] = "I have work for you.",
                            ["labelKey"] = "psdl.work_orders.member.status.offer.orders.label",
                            ["utteranceFallback"] = "I have work for you.",
                            ["utteranceKey"] = "psdl.work_orders.member.status.offer.orders.utterance",
                        },
                        {
                            ["consumers"] = {
                                "participant",
                            },
                            ["frame"] = {
                                ["intent"] = "QUESTION",
                                ["speechAct"] = "QUESTION",
                                ["subject"] = "WORK",
                                ["topic"] = "work_orders",
                            },
                            ["id"] = "status",
                            ["labelFallback"] = "Report on your current work.",
                            ["labelKey"] = "psdl.work_orders.member.status.offer.status.label",
                            ["utteranceFallback"] = "Report on your current work.",
                            ["utteranceKey"] = "psdl.work_orders.member.status.offer.status.utterance",
                        },
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "I'm ready. What needs doing?",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.work_orders.member.status.opening",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/social_companion_topics.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
