-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "medical_event_treatment",
        ["id"] = "semantic.medical.distress.treatment.bandage",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.medical.distress.treatment.bandage",
            ["sourcePath"] = "psdl/dialogue/medical_event_treatment.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_medical_distress_treatment_bandage",
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
                ["responseTemplateID"] = "semantic.medical.distress.treatment.bandage",
                ["sourceSurface"] = "content/event/medical/treatment.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "MEDICAL_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.treatment.bandage.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "The wound is treated. I can move when you are ready.",
                            },
                            ["TL"] = {
                                "Nagamot na ang sugat. Makakakilos na ako kapag handa ka na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.treatment.bandage.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Bandaged up tight. Good to go when you are.",
                            },
                            ["TL"] = {
                                "Nabendahan nang mahigpit. Handa nang umalis kapag handa ka na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.treatment.bandage.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Bleeding has stopped. Ready to step out.",
                            },
                            ["TL"] = {
                                "Tumigil na ang dugo. Handa nang lumabas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.treatment.bandage.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Dressings are secure. I can walk now.",
                            },
                            ["TL"] = {
                                "Ligtas na ang benda. Makakalakad na ako ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.treatment.bandage.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "That did the trick. I'm back on my feet.",
                            },
                            ["TL"] = {
                                "Bumisa 'yon. Nakatayo na ulit ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.treatment.bandage.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Wrapped up properly. Lead on.",
                            },
                            ["TL"] = {
                                "Nabalot na nang maayos. Manguna ka na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.treatment.bandage.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Wound is stabilized. Ready for your call.",
                            },
                            ["TL"] = {
                                "Maayos na ang sugat. Handa sa utos mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.treatment.bandage.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Bandage is holding. Let's get moving.",
                            },
                            ["TL"] = {
                                "Kumakapit ang benda. Kilos na tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.treatment.bandage.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Cleanly wrapped. I'm ready to follow.",
                            },
                            ["TL"] = {
                                "Malinis na nabalutan. Handa na akong sumunod.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.treatment.bandage.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "All patched up. Let's hit the road.",
                            },
                            ["TL"] = {
                                "Maayos na ang lahat. Tara na sa daan.",
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
        ["sourceShard"] = "psdl/dialogue/medical_event_treatment.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
