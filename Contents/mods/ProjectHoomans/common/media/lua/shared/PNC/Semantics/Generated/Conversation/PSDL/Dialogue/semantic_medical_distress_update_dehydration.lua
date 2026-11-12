-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "medical_event_update",
        ["id"] = "semantic.medical.distress.update.dehydration",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.medical.distress.update.dehydration",
            ["sourcePath"] = "psdl/dialogue/medical_event_update.json#records[3]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_medical_distress_update_dehydration",
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
                ["responseTemplateID"] = "semantic.medical.distress.update.dehydration",
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
                            ["textKey"] = "semantic.medical.distress.update.dehydration.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I still need water before I can move.",
                            },
                            ["TL"] = {
                                "Kailangan ko pa rin ng tubig bago makakilos.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.dehydration.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Thirst is still crippling me. Bring hydration.",
                            },
                            ["TL"] = {
                                "Pinapahirapan pa rin ako ng uhaw. Magdala ka ng tubig.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.dehydration.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Can't stand until I drink something clean.",
                            },
                            ["TL"] = {
                                "Hindi makakatayo hangga't hindi umiinom ng malinis.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.dehydration.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still parched and dizzy. Where is the water?",
                            },
                            ["TL"] = {
                                "Tuyot at nahihilo pa rin. Nasaan na ang tubig?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.dehydration.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Dehydration hasn't improved. I need fluids now.",
                            },
                            ["TL"] = {
                                "Hindi pa gumagaling ang dehydration. Kailangan ko ng inumin ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.dehydration.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still desperately thirsty. Bring a bottle over.",
                            },
                            ["TL"] = {
                                "Uhaw na uhaw pa rin ako. Dalhin mo ang bote rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.dehydration.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Throat is still locked up dry. Need water.",
                            },
                            ["TL"] = {
                                "Nakatuyot pa rin ang lalamunan ko. Kailangan ng tubig.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.dehydration.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Can't make progress without hydration. Help me.",
                            },
                            ["TL"] = {
                                "Hindi makakausad nang walang tubig. Tulungan mo ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.dehydration.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still waiting on that drink. Feeling very weak.",
                            },
                            ["TL"] = {
                                "Naghihintay pa rin sa inumin. Sobrang nanghihina na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.dehydration.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Need fluids before my legs will work again.",
                            },
                            ["TL"] = {
                                "Kailangan ng inumin bago gumana ulit ang mga binti ko.",
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
