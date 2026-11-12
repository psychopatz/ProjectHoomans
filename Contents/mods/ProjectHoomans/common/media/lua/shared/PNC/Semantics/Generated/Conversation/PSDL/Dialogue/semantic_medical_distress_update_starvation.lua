-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "medical_event_update",
        ["id"] = "semantic.medical.distress.update.starvation",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.medical.distress.update.starvation",
            ["sourcePath"] = "psdl/dialogue/medical_event_update.json#records[7]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_medical_distress_update_starvation",
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
                ["responseTemplateID"] = "semantic.medical.distress.update.starvation",
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
                            ["textKey"] = "semantic.medical.distress.update.starvation.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I still need food before I can get up.",
                            },
                            ["TL"] = {
                                "Kailangan ko pa rin ng pagkain bago makatayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.starvation.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Starvation is worsening. Did you find anything edible?",
                            },
                            ["TL"] = {
                                "Lumalala ang gutom ko. May nahanap ka bang makakain?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.starvation.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still too weak from hunger to stand.",
                            },
                            ["TL"] = {
                                "Nanghihina pa rin sa gutom para makatayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.starvation.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Can't move on an empty stomach. Bring food.",
                            },
                            ["TL"] = {
                                "Hindi makakilos nang walang laman ang tiyan. Dalhan mo ako ng pagkain.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.starvation.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still starving on the floor. Please bring a ration.",
                            },
                            ["TL"] = {
                                "Nagugutom pa rin sa sahig. Pakiusap dalhan mo ako ng rasyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.starvation.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Body needs calories right now. I'm fading.",
                            },
                            ["TL"] = {
                                "Kailangan ng katawan ng pagkain ngayon din. Nanghihina na ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.starvation.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still waiting for a meal. Stomach cramps are brutal.",
                            },
                            ["TL"] = {
                                "Naghihintay pa rin ng pagkain. Matindi ang pulikat ng tiyan ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.starvation.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Can't regain strength without food. Help me.",
                            },
                            ["TL"] = {
                                "Hindi maibabalik ang lakas nang walang pagkain. Tulungan mo ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.starvation.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still starving here. Any can of beans or soup?",
                            },
                            ["TL"] = {
                                "Gutom pa rin ako rito. May de-latang beans ba o sabaw?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.starvation.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Need nourishment before I can take a step.",
                            },
                            ["TL"] = {
                                "Kailangan ko ng makakain bago ako makahakbang.",
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
