-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "medical_event_call",
        ["id"] = "semantic.medical.distress.call.mercy",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.medical.distress.call.mercy",
            ["sourcePath"] = "psdl/dialogue/medical_event_call.json#records[5]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_medical_distress_call_mercy",
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
                ["responseTemplateID"] = "semantic.medical.distress.call.mercy",
                ["sourceSurface"] = "content/event/medical/call.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "MEDICAL_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.mercy.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm down! Please, don't kill me!",
                            },
                            ["TL"] = {
                                "Bagsak na ako! Pakiusap, huwag mo akong patayin!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.mercy.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Mercy, please! I'm completely unarmed!",
                            },
                            ["TL"] = {
                                "Maawa ka, pakiusap! Wala akong sandata!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.mercy.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Don't shoot! I'm already defeated!",
                            },
                            ["TL"] = {
                                "Huwag kang puputok! Talo na ako!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.mercy.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Please let me live! I surrender!",
                            },
                            ["TL"] = {
                                "Pakiusap buhayin mo ako! Sumusuko na ako!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.mercy.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Spare me, please! I have nothing left!",
                            },
                            ["TL"] = {
                                "Patawarin mo ako, pakiusap! Wala nang natira sa akin!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.mercy.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I beg you... don't finish me off!",
                            },
                            ["TL"] = {
                                "Nagmamakaawa ako sa'yo... huwag mo akong tapusin!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.mercy.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I yield! Don't strike again!",
                            },
                            ["TL"] = {
                                "Suko na ako! Huwag ka nang humataw ulit!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.mercy.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Show mercy! I'm bleeding out on the floor!",
                            },
                            ["TL"] = {
                                "Maawa ka! Nauubusan na ako ng dugo sa sahig!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.mercy.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Don't hurt me anymore, please!",
                            },
                            ["TL"] = {
                                "Huwag mo na akong saktan pa, pakiusap!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.mercy.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Have a heart... let me survive this.",
                            },
                            ["TL"] = {
                                "Maawa ka naman... hayaan mo akong mabuhay.",
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
        ["sourceShard"] = "psdl/dialogue/medical_event_call.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
