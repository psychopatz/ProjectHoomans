-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "medical_event_treatment",
        ["id"] = "semantic.medical.distress.treatment.bandage",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.medical.distress.treatment.bandage",
            ["sourcePath"] = "psdl/dialogue/medical_event_treatment.json#records[0]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/MedicalEventTreatment",
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
    {
        ["domain"] = "medical_event_treatment",
        ["id"] = "semantic.medical.distress.treatment.default",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.medical.distress.treatment.default",
            ["sourcePath"] = "psdl/dialogue/medical_event_treatment.json#records[1]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/MedicalEventTreatment",
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
                ["responseTemplateID"] = "semantic.medical.distress.treatment.default",
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
                            ["textKey"] = "semantic.medical.distress.treatment.default.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Thank you. That treatment helped.",
                            },
                            ["TL"] = {
                                "Salamat. Malaking tulong ang panggagamot na 'yon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.treatment.default.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Feeling much better. I appreciate the aid.",
                            },
                            ["TL"] = {
                                "Medyo maayos na pakiramdam ko. Salamat sa tulong.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.treatment.default.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Much better now. Thank you for patching me up.",
                            },
                            ["TL"] = {
                                "Mas maayos na ngayon. Salamat sa paggamot sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.treatment.default.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Pain is subsiding. Thanks for taking care of it.",
                            },
                            ["TL"] = {
                                "Humuhupa na ang sakit. Salamat sa pag-asikaso no'n.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.treatment.default.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Good work on that treatment. I'm indebted to you.",
                            },
                            ["TL"] = {
                                "Magaling ang panggagamot mo. May utang na loob ako sa'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.treatment.default.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "That took the edge off. Thank you.",
                            },
                            ["TL"] = {
                                "Nabawasan ang kirot. Salamat sa'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.treatment.default.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I can function again. Thanks for the quick aid.",
                            },
                            ["TL"] = {
                                "Makakagalaw na ulit ako. Salamat sa mabilis na lunas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.treatment.default.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Appreciate the medical help. I owe you one.",
                            },
                            ["TL"] = {
                                "Salamat sa tulong medikal. May utang ako sa'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.treatment.default.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Thanks, that helped a lot. Ready to move.",
                            },
                            ["TL"] = {
                                "Salamat, malaking tulong 'yon. Handa nang kumilos.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.treatment.default.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "You saved my skin with that aid. Thank you.",
                            },
                            ["TL"] = {
                                "Iniligtas mo ang buhay ko sa lunas na 'yon. Maraming salamat.",
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
