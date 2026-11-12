-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "medical_event_repeat",
        ["id"] = "semantic.medical.distress.repeat.exhaustion",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.medical.distress.repeat.exhaustion",
            ["sourcePath"] = "psdl/dialogue/medical_event_repeat.json#records[4]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_medical_distress_repeat_exhaustion",
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
                ["responseTemplateID"] = "semantic.medical.distress.repeat.exhaustion",
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
                            ["textKey"] = "semantic.medical.distress.repeat.exhaustion.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I still need a little more time to recover.",
                            },
                            ["TL"] = {
                                "Kailangan ko pa ng kaunting oras para makabawi.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.exhaustion.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Can't rush this. My muscles are completely dead.",
                            },
                            ["TL"] = {
                                "Hindi pwedeng madaliin. Patay na ang lakas ng kalamnan ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.exhaustion.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still catching my breath. Give me another minute.",
                            },
                            ["TL"] = {
                                "Hinihingal pa rin ako. Bigyan mo pa ako ng isang minuto.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.exhaustion.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Body won't budge yet. Just a bit more rest.",
                            },
                            ["TL"] = {
                                "Ayaw pang gumalaw ng katawan ko. Kaunting pahinga pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.exhaustion.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still wiped out. Don't force me to stand yet.",
                            },
                            ["TL"] = {
                                "Ubos pa rin ako. Huwag mo muna akong piliting tumayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.exhaustion.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Heart is still racing. Need more time sitting down.",
                            },
                            ["TL"] = {
                                "Mabilis pa rin ang kabog ng dibdib ko. Kailangan pang umupo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.exhaustion.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Not ready to move yet. Fatigue is overwhelming.",
                            },
                            ["TL"] = {
                                "Hindi pa handang kumilos. Masyadong mabigat ang pagod.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.exhaustion.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Give me another thirty seconds... almost there.",
                            },
                            ["TL"] = {
                                "Bigyan mo pa ako ng tatlumpung segundo... malapit na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.exhaustion.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still completely spent. Let my legs rest.",
                            },
                            ["TL"] = {
                                "Sagad pa rin ang pagod. Pahingahin mo muna ang mga binti ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.exhaustion.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Can't run yet. Need a little more recovery.",
                            },
                            ["TL"] = {
                                "Hindi pa makakatakbo. Kailangan pa ng kaunting lakas.",
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
