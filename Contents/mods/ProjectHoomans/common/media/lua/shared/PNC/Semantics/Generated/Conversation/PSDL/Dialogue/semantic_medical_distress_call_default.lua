-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "medical_event_call",
        ["id"] = "semantic.medical.distress.call.default",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.medical.distress.call.default",
            ["sourcePath"] = "psdl/dialogue/medical_event_call.json#records[2]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_medical_distress_call_default",
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
                ["responseTemplateID"] = "semantic.medical.distress.call.default",
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
                            ["textKey"] = "semantic.medical.distress.call.default.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm down! I need help over here!",
                            },
                            ["TL"] = {
                                "Bagsak ako! Kailangan ko ng tulong dito!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.default.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Can't stand! Someone help me up!",
                            },
                            ["TL"] = {
                                "Hindi ako makatayo! Tulungan niyo akong makatayo!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.default.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm hit! Get over here!",
                            },
                            ["TL"] = {
                                "Tinamaan ako! Halika rito!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.default.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Need medical attention immediately!",
                            },
                            ["TL"] = {
                                "Kailangan ko ng agarang panggagamot!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.default.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Down and helpless! Don't leave me!",
                            },
                            ["TL"] = {
                                "Bagsak at walang laban! Huwag niyo akong iwan!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.default.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I took a bad fall! Help me!",
                            },
                            ["TL"] = {
                                "Napasama ang bagsak ko! Tulungan mo ako!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.default.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Can't get back on my feet! Help!",
                            },
                            ["TL"] = {
                                "Hindi ako makabangon! Tulong!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.default.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Hurt bad! Over here, please!",
                            },
                            ["TL"] = {
                                "Malubha ang tama ko! Dito, pakiusap!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.default.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm down on the ground! Need a hand!",
                            },
                            ["TL"] = {
                                "Nasa sahig ako! Pasaklolo naman!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.default.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Injured and stranded! Come help!",
                            },
                            ["TL"] = {
                                "Sugatan at nastranded! Tulungan niyo ako!",
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
