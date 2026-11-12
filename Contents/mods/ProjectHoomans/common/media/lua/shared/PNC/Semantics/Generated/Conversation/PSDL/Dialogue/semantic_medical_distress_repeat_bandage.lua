-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "medical_event_repeat",
        ["id"] = "semantic.medical.distress.repeat.bandage",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.medical.distress.repeat.bandage",
            ["sourcePath"] = "psdl/dialogue/medical_event_repeat.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_medical_distress_repeat_bandage",
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
                ["responseTemplateID"] = "semantic.medical.distress.repeat.bandage",
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
                            ["textKey"] = "semantic.medical.distress.repeat.bandage.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I still need these wounds patched! Hurry!",
                            },
                            ["TL"] = {
                                "Kailangan ko pa ring mabendahan ang sugat na 'to! Bilis!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.bandage.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Where's that bandage?! Still bleeding out here!",
                            },
                            ["TL"] = {
                                "Nasaan na 'yung benda?! Dumurugo pa rin ako rito!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.bandage.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Don't forget about me! I need a wrap now!",
                            },
                            ["TL"] = {
                                "Huwag niyo akong kalimutan! Kailangan ko ng benda ngayon!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.bandage.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still waiting on that bandage! It's soaking through!",
                            },
                            ["TL"] = {
                                "Naghihintay pa rin ako sa benda! Bumababad na ang dugo!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.bandage.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Please, hurry with the bandages! I'm fading!",
                            },
                            ["TL"] = {
                                "Pakiusap, bilisan ang benda! Nanghihina na ako!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.bandage.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I asked for a bandage! Did you find one?!",
                            },
                            ["TL"] = {
                                "Humihingi ako ng benda! May nahanap ka ba?!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.bandage.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Wound is still open! Bring the dressing over!",
                            },
                            ["TL"] = {
                                "Bukas pa rin ang sugat! Dalhin mo na ang pambenda!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.bandage.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Can someone please patch me up already?!",
                            },
                            ["TL"] = {
                                "May magbe-benda ba sa akin ngayon din?!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.bandage.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Blood is still pooling! Get that bandage on me!",
                            },
                            ["TL"] = {
                                "Nag-iipon pa rin ang dugo! Ilagay mo na ang benda sa akin!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.bandage.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still bleeding here! Hurry with the cloth!",
                            },
                            ["TL"] = {
                                "Dumurugo pa rin ako rito! Bilisan mo ang tela!",
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
