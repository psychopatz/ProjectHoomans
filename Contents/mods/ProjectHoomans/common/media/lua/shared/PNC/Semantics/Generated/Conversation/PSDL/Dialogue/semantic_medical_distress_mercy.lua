-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "medical_event_overview",
        ["id"] = "semantic.medical.distress.mercy",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.medical.distress.mercy",
            ["sourcePath"] = "psdl/dialogue/medical_event_overview.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_medical_distress_mercy",
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
                ["responseTemplateID"] = "semantic.medical.distress.mercy",
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
                            ["textKey"] = "semantic.medical.distress.mercy.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Please. I need help with this wound, don't let me die.",
                            },
                            ["TL"] = {
                                "Pakiusap. Tulungan mo ako sa sugat na 'to, huwag mo akong hayaang mamatay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.mercy.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Have mercy on me... patch me up, please.",
                            },
                            ["TL"] = {
                                "Maawa ka sa akin... bendahan mo ako, pakiusap.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.mercy.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I won't survive this cut without your mercy.",
                            },
                            ["TL"] = {
                                "Hindi ako mabubuhay sa hiwang 'to kung wala ang awa mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.mercy.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Please help... I'm begging for aid.",
                            },
                            ["TL"] = {
                                "Pakiusap tulungan mo ako... nagmamakaawa ako sa lunas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.mercy.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Don't leave me to bleed out like an animal.",
                            },
                            ["TL"] = {
                                "Huwag mo akong iwang maubusan ng dugo na parang hayop.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.mercy.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Show some kindness. This wound is killing me.",
                            },
                            ["TL"] = {
                                "Magpakita ka ng kabutihan. Pinapatay ako ng sugat na 'to.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.mercy.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Please, just dress the wound. That's all I ask.",
                            },
                            ["TL"] = {
                                "Pakiusap, gamutin lang ang sugat. 'Yon lang ang hinihiling ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.mercy.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm at your mercy. Help stop this pain.",
                            },
                            ["TL"] = {
                                "Nasa awa mo ako. Tulungan mong matigil ang sakit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.mercy.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Spare my life and treat this injury, please.",
                            },
                            ["TL"] = {
                                "Iligtas mo ang buhay ko at gamutin 'tong pinsala, pakiusap.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.mercy.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I have so much to live for... please help me.",
                            },
                            ["TL"] = {
                                "Marami pa akong dahilan para mabuhay... tulungan mo ako.",
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
