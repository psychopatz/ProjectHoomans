-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "medical_event_update",
        ["id"] = "semantic.medical.distress.update.exhaustion",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.medical.distress.update.exhaustion",
            ["sourcePath"] = "psdl/dialogue/medical_event_update.json#records[4]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_medical_distress_update_exhaustion",
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
                ["responseTemplateID"] = "semantic.medical.distress.update.exhaustion",
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
                            ["textKey"] = "semantic.medical.distress.update.exhaustion.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I still need time to recover my strength.",
                            },
                            ["TL"] = {
                                "Kailangan ko pa ng oras para manumbalik ang lakas ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.exhaustion.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Stamina is still drained. Catching my breath.",
                            },
                            ["TL"] = {
                                "Ubos pa rin ang stamina. Humihinga pa rin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.exhaustion.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still exhausted. Give me a little more time.",
                            },
                            ["TL"] = {
                                "Pagod na pagod pa rin. Bigyan mo pa ako ng kaunting oras.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.exhaustion.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Muscles are still aching. Recovering slowly.",
                            },
                            ["TL"] = {
                                "Kumikirot pa rin ang kalamnan. Dahan-dahang nagpapagaling.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.exhaustion.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Lungs still burning from running. Give me a moment.",
                            },
                            ["TL"] = {
                                "Nasusunog pa rin ang baga sa pagtakbo. Bigyan mo ako ng saglit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.exhaustion.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Fatigue hasn't cleared yet. Still resting here.",
                            },
                            ["TL"] = {
                                "Hindi pa humuhupa ang pagod. Nagpapahinga pa rin dito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.exhaustion.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Energy is very low. Still need a few breaths.",
                            },
                            ["TL"] = {
                                "Napakababa pa ng lakas. Kailangan pa ng ilang malalalim na hininga.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.exhaustion.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Legs are still shaking from exhaustion. Give me time.",
                            },
                            ["TL"] = {
                                "Nanginginig pa rin ang mga binti sa pagod. Bigyan mo ako ng oras.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.exhaustion.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still spent. Don't rush me to run again.",
                            },
                            ["TL"] = {
                                "Ubos pa rin. Huwag mo akong apurahin tumakbo ulit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.exhaustion.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Recharging my stamina. Just a little longer.",
                            },
                            ["TL"] = {
                                "Nagpapalakas ulit. Kaunti na lang.",
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
