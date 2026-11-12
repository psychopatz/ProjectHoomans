-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "medical_event_overview",
        ["id"] = "semantic.medical.distress.urgent",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.medical.distress.urgent",
            ["sourcePath"] = "psdl/dialogue/medical_event_overview.json#records[2]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_medical_distress_urgent",
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
                ["responseTemplateID"] = "semantic.medical.distress.urgent",
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
                            ["textKey"] = "semantic.medical.distress.urgent.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I am hurt! I need help now!",
                            },
                            ["TL"] = {
                                "Sugatan ako! Kailangan ko ng tulong ngayon na!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.urgent.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Emergency! I need immediate medical attention!",
                            },
                            ["TL"] = {
                                "Kagipitan! Kailangan ko ng agarang gamot ngayon din!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.urgent.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Hit bad! Come over here right now!",
                            },
                            ["TL"] = {
                                "Grabe ang tama ko! Halika rito ngayon din!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.urgent.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Urgent! I'm bleeding and falling down!",
                            },
                            ["TL"] = {
                                "Apurahan! Dumurugo ako at bumabagsak!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.urgent.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I need aid this second! Hurry!",
                            },
                            ["TL"] = {
                                "Kailangan ko ng gamot sa segundong ito! Bilis!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.urgent.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Severe injury! Drop what you're doing and help me!",
                            },
                            ["TL"] = {
                                "Malubhang pinsala! Bitawan ang ginagawa mo at tulungan mo ako!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.urgent.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I won't last long without treatment! Now!",
                            },
                            ["TL"] = {
                                "Hindi ako magtatagal nang walang gamot! Ngayon na!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.urgent.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Critical wound! Bandage me now!",
                            },
                            ["TL"] = {
                                "Kritikal na sugat! Bendahan mo ako ngayon din!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.urgent.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm going down hard! Medic, help me!",
                            },
                            ["TL"] = {
                                "Bumabagsak na ako! Saklolo, tulungan mo ako!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.urgent.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Urgent distress! Someone patch me up right now!",
                            },
                            ["TL"] = {
                                "Apurahang saklolo! May magbenda sa akin ngayon din!",
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
