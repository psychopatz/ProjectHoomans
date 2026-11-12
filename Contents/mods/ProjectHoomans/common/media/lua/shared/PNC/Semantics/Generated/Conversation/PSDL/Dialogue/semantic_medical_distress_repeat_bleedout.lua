-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "medical_event_repeat",
        ["id"] = "semantic.medical.distress.repeat.bleedout",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.medical.distress.repeat.bleedout",
            ["sourcePath"] = "psdl/dialogue/medical_event_repeat.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_medical_distress_repeat_bleedout",
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
                ["responseTemplateID"] = "semantic.medical.distress.repeat.bleedout",
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
                            ["textKey"] = "semantic.medical.distress.repeat.bleedout.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I am still losing blood! Please, help me!",
                            },
                            ["TL"] = {
                                "Nauubusan pa rin ako ng dugo! Pakiusap, tulungan mo ako!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.bleedout.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Pressure isn't working! The bleeding won't stop!",
                            },
                            ["TL"] = {
                                "Hindi gumagana ang diin! Ayaw tumigil ng pagdurugo!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.bleedout.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I don't have much time left... blood is gushing!",
                            },
                            ["TL"] = {
                                "Wala na akong gaanong oras... bumubuhos ang dugo!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.bleedout.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Hurry, damn it! I'm going to bleed to death!",
                            },
                            ["TL"] = {
                                "Bilisan mo naman! Mamamatay na ako sa pagdurugo!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.bleedout.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "My pulse is getting weak... stop the bleed!",
                            },
                            ["TL"] = {
                                "Humihina na ang pulso ko... patigilin ang pagdurugo!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.bleedout.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still bleeding out! Don't let me die on this floor!",
                            },
                            ["TL"] = {
                                "Nauubusan pa rin ng dugo! Huwag mo akong hayaang mamatay sa sahig!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.bleedout.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm freezing cold from blood loss... hurry!",
                            },
                            ["TL"] = {
                                "Giniginaw na ako sa nawalang dugo... bilisan mo!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.bleedout.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Blood won't clot! I need immediate help!",
                            },
                            ["TL"] = {
                                "Ayaw mamuo ng dugo! Kailangan ko ng agarang tulong!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.bleedout.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Everything is fading... stop the bleeding, please!",
                            },
                            ["TL"] = {
                                "Naglalaho ang lahat... patigilin mo ang dugo, pakiusap!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.repeat.bleedout.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Hurry up! I can't hold my own artery closed!",
                            },
                            ["TL"] = {
                                "Bilisan mo! Hindi ko kayang pigilin ang ugat ko nang mag-isa!",
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
