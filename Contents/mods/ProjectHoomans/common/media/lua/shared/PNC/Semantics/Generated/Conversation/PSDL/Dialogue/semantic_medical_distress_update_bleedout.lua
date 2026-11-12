-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "medical_event_update",
        ["id"] = "semantic.medical.distress.update.bleedout",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.medical.distress.update.bleedout",
            ["sourcePath"] = "psdl/dialogue/medical_event_update.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_medical_distress_update_bleedout",
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
                ["responseTemplateID"] = "semantic.medical.distress.update.bleedout",
                ["sourceSurface"] = "content/event/medical/update.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "MEDICAL_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.bleedout.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "The bleeding has not stopped. I still need a bandage.",
                            },
                            ["TL"] = {
                                "Hindi pa tumitigil ang dugo. Kailangan ko pa rin ng benda.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.bleedout.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still hemorrhaging. I need pressure and a wrap immediately.",
                            },
                            ["TL"] = {
                                "Patuloy pa ring umaagos ang dugo. Kailangan ng diin at benda agad.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.bleedout.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Bleeding is continuing. I'm getting lightheaded.",
                            },
                            ["TL"] = {
                                "Dumurugo pa rin. Nahihilo na ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.bleedout.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Blood is still flowing. Please get that bandage on me.",
                            },
                            ["TL"] = {
                                "Umaagos pa rin ang dugo. Pakiusap lagyan mo na ako ng benda.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.bleedout.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Hasn't stopped bleeding yet. Running out of time.",
                            },
                            ["TL"] = {
                                "Hindi pa rin humihinto ang pagdurugo. Nauubusan na ako ng oras.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.bleedout.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still losing red. My clothes are soaked.",
                            },
                            ["TL"] = {
                                "Nauubusan pa rin ng dugo. Babad na ang damit ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.bleedout.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "The wound won't seal itself. Need a dressing now.",
                            },
                            ["TL"] = {
                                "Hindi kusang magsasara ang sugat. Kailangan ng benda ngayon din.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.bleedout.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still bleeding steadily. Hurry up with the aid.",
                            },
                            ["TL"] = {
                                "Tuloy-tuloy pa rin ang pagdurugo. Bilisan mo ang tulong.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.bleedout.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Losing blood by the second. Please hurry.",
                            },
                            ["TL"] = {
                                "Bawat segundo nauubusan ako ng dugo. Pakiusap magmadali ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.bleedout.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "The cut won't stop bleeding. Wrap it, please.",
                            },
                            ["TL"] = {
                                "Ayaw tumigil ng pagdurugo ng hiwa. Balutin mo na, pakiusap.",
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
        ["sourceShard"] = "psdl/dialogue/medical_event_update.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
