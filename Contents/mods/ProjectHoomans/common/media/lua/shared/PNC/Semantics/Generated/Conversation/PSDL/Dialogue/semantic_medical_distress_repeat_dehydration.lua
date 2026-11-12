-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "medical_event_repeat",
        ["id"] = "semantic.medical.distress.repeat.dehydration",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.medical.distress.repeat.dehydration",
            ["sourcePath"] = "psdl/dialogue/medical_event_repeat.json#records[3]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_medical_distress_repeat_dehydration",
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
                ["responseTemplateID"] = "semantic.medical.distress.repeat.dehydration",
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
                            ["textKey"] = "semantic.medical.distress.repeat.dehydration.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I still need water to recover. My throat is on fire.",
                            },
                            ["TL"] = {
                                "Kailangan ko pa rin ng tubig para makabawi. Parang may apoy sa lalamunan ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.dehydration.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still dying of thirst... did you find any bottle?",
                            },
                            ["TL"] = {
                                "Mamamatay pa rin sa uhaw... may nahanap ka bang bote?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.dehydration.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Water, please! I can't take this parched feeling.",
                            },
                            ["TL"] = {
                                "Tubig, pakiusap! Hindi ko na makayanan ang matinding uhaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.dehydration.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I asked for water... please tell me you have some.",
                            },
                            ["TL"] = {
                                "Humihingi ako ng tubig... sabihin mong may dala ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.dehydration.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Tongue feels like sandpaper. Bring water quickly.",
                            },
                            ["TL"] = {
                                "Parang liha ang dila ko. Magdala ka ng tubig agad.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.dehydration.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still completely dehydrated. I can't stand up like this.",
                            },
                            ["TL"] = {
                                "Dehydrated pa rin ako. Hindi ako makakatayo nang ganito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.dehydration.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Water... I'm begging you, just one cup.",
                            },
                            ["TL"] = {
                                "Tubig... nagmamakaawa ako, kahit isang baso lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.dehydration.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still dry as bone. Please bring hydration.",
                            },
                            ["TL"] = {
                                "Tuyot pa rin ako. Pakiusap dalhan mo ako ng tubig.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.dehydration.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I can't recover without liquids. Help me.",
                            },
                            ["TL"] = {
                                "Hindi ako makakabawi nang walang inumin. Tulong.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.dehydration.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still waiting for a drink... head is pounding.",
                            },
                            ["TL"] = {
                                "Naghihintay pa rin ng maiinom... sumasakit ang ulo ko.",
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
