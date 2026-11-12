-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "medical_event_repeat",
        ["id"] = "semantic.medical.distress.repeat.mercy",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.medical.distress.repeat.mercy",
            ["sourcePath"] = "psdl/dialogue/medical_event_repeat.json#records[5]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_medical_distress_repeat_mercy",
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
                ["responseTemplateID"] = "semantic.medical.distress.repeat.mercy",
                ["sourceSurface"] = "content/event/medical/repeat.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "MEDICAL_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.mercy.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I am still asking you to spare me. Please.",
                            },
                            ["TL"] = {
                                "Hinihiling ko pa rin na buhayin mo ako. Pakiusap.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.mercy.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Please don't change your mind... let me live.",
                            },
                            ["TL"] = {
                                "Pakiusap huwag magbago ang isip mo... hayaan mo akong mabuhay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.mercy.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm still begging for mercy. Don't shoot.",
                            },
                            ["TL"] = {
                                "Nagmamakaawa pa rin ako sa awa. Huwag kang bumaril.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.mercy.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Show mercy once more. I mean you no harm.",
                            },
                            ["TL"] = {
                                "Maawa ka pa ulit. Wala akong masamang balak sa'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.mercy.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I am defenseless. Please keep your weapon down.",
                            },
                            ["TL"] = {
                                "Wala akong laban. Pakiusap ibaba mo ang sandata mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.mercy.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Don't finish me off. I surrender completely.",
                            },
                            ["TL"] = {
                                "Huwag mo akong tapusin. Sumusuko ako nang buo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.mercy.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still pleading for my life. Have pity on me.",
                            },
                            ["TL"] = {
                                "Nagmamakaawa pa rin para sa buhay ko. Kaawaan mo ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.mercy.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Please... I just want to survive.",
                            },
                            ["TL"] = {
                                "Pakiusap... gusto ko lang mabuhay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.mercy.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm at your feet. Spare me, I beg you.",
                            },
                            ["TL"] = {
                                "Nasa paanan mo na ako. Huwag mo akong patayin, nagmamakaawa ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.mercy.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Don't execute me. Let me crawl away.",
                            },
                            ["TL"] = {
                                "Huwag mo akong patayin. Hayaan mo akong gumapang palayo.",
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
        ["sourceShard"] = "psdl/dialogue/medical_event_repeat.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
