-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "medical_event_overview",
        ["id"] = "semantic.medical.distress.default",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.medical.distress.default",
            ["sourcePath"] = "psdl/dialogue/medical_event_overview.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_medical_distress_default",
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
                ["category"] = "projecthoomans:medical_event",
                ["responseTemplateID"] = "semantic.medical.distress.default",
                ["sourceSurface"] = "content/event/medical/overview.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "MEDICAL_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.default.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I need help with this wound.",
                            },
                            ["TL"] = {
                                "Kailangan ko ng tulong sa sugat na 'to.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.default.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Hurting pretty badly here. Need aid.",
                            },
                            ["TL"] = {
                                "Medyo malala ang tama ko rito. Kailangan ng gamot.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.default.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Got injured. Can someone look at this?",
                            },
                            ["TL"] = {
                                "Nasugatan ako. May makakatingin ba nito?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.default.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Need medical attention before this gets worse.",
                            },
                            ["TL"] = {
                                "Kailangan ng panggagamot bago lumala 'to.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.default.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Wound is throbbing. I need a hand.",
                            },
                            ["TL"] = {
                                "Pumipintig ang sugat. Kailangan ko ng saklolo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.default.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Took some damage. Could use first aid.",
                            },
                            ["TL"] = {
                                "Nasaktan ako. Kailangan ko ng first aid.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.default.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "This cut is nasty. Help me clean it.",
                            },
                            ["TL"] = {
                                "Marumi ang hiwa na 'to. Tulungan mo akong linisin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.default.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm in pain here. Need medical supplies.",
                            },
                            ["TL"] = {
                                "Nasasaktan ako rito. Kailangan ko ng gamot.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.default.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Injured and slowing down. Need treatment.",
                            },
                            ["TL"] = {
                                "Sugatan at bumabagal na. Kailangan ng lunas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.default.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Got banged up pretty good. Help me patch up.",
                            },
                            ["TL"] = {
                                "Nabugbog ako nang husto. Tulungan mo akong magbenda.",
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
        ["sourceShard"] = "psdl/dialogue/medical_event_overview.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
