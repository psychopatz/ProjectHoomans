-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "medical_event_repeat",
        ["id"] = "semantic.medical.distress.repeat.default",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.medical.distress.repeat.default",
            ["sourcePath"] = "psdl/dialogue/medical_event_repeat.json#records[2]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_medical_distress_repeat_default",
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
                ["responseTemplateID"] = "semantic.medical.distress.repeat.default",
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
                            ["textKey"] = "semantic.medical.distress.repeat.default.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm not up yet. Please help me.",
                            },
                            ["TL"] = {
                                "Hindi pa ako nakakabangon. Pakiusap tulungan mo ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.default.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still down here! Don't leave me behind!",
                            },
                            ["TL"] = {
                                "Nandito pa rin ako sa sahig! Huwag mo akong iwan!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.default.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I still need assistance to get on my feet.",
                            },
                            ["TL"] = {
                                "Kailangan ko pa rin ng tulong para makatayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.default.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Can someone help me up? Still grounded.",
                            },
                            ["TL"] = {
                                "May tutulong ba sa aking tumayo? Bagsak pa rin ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.default.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm still incapacitated! Come over here!",
                            },
                            ["TL"] = {
                                "Hindi pa rin ako makakilos! Pumunta ka rito!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.default.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still hurting, still stuck. Give me a hand.",
                            },
                            ["TL"] = {
                                "Masakit pa rin, naipit pa rin. Tulungan mo ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.default.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Haven't moved an inch. Need someone to help.",
                            },
                            ["TL"] = {
                                "Hindi pa ako nakakagalaw kahit kaunti. Kailangan ng tulong.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.default.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Please, I'm still on the ground waiting.",
                            },
                            ["TL"] = {
                                "Pakiusap, nasa lupa pa rin ako at naghihintay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.default.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still can't stand. Don't forget I'm down.",
                            },
                            ["TL"] = {
                                "Hindi pa rin makatayo. Huwag mong kalimutang bagsak ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.default.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm still here! Help me up already!",
                            },
                            ["TL"] = {
                                "Nandito pa rin ako! Tulungan mo na akong tumayo!",
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
